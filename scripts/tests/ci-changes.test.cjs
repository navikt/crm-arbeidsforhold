const assert = require('node:assert/strict');
const { execFileSync, spawnSync } = require('node:child_process');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { test } = require('node:test');
const { classifyChanges } = require('../ci-changes.cjs');

const packageDirectories = [{ path: 'force-app' }, { path: 'reference-package' }];

test('tooling and documentation changes do not require Salesforce or LWC validation', () => {
    assert.deepEqual(classifyChanges(['bin/create-scratch-org.sh', 'README.md'], packageDirectories), {
        salesforce: false,
        lwc: false
    });
});

for (const file of [
    'force-app/main/default/classes/Example.cls',
    'force-app/tests/classes/ExampleTest.cls',
    'reference-package/main/default/objects/Example.object-meta.xml',
    'sfdx-project.json',
    'package.json',
    'package-lock.json',
    '.github/workflows/salesforce-validation.yml',
    'scripts/ci-changes.cjs',
    'scripts/tests/ci-changes.test.cjs'
]) {
    test(`validates both surfaces for ${file}`, () => {
        assert.deepEqual(classifyChanges([file], packageDirectories), { salesforce: true, lwc: true });
    });
}

for (const file of [
    'config/project-scratch-def.json',
    'manifest/package.xml',
    '.forceignore',
    'scripts/apex/check.apex'
]) {
    test(`validates Salesforce configuration: ${file}`, () => {
        assert.equal(classifyChanges([file], packageDirectories).salesforce, true);
    });
}

for (const file of ['jest.config.js', 'jest-sa11y-setup.js']) {
    test(`validates LWC test configuration: ${file}`, () => {
        assert.deepEqual(classifyChanges([file], packageDirectories), { salesforce: false, lwc: true });
    });
}

test('matches whole package directory names and supports trailing slashes', () => {
    assert.deepEqual(classifyChanges(['force-app-extra/file.cls'], packageDirectories), {
        salesforce: false,
        lwc: false
    });
    assert.equal(classifyChanges(['reference-package/file.cls'], [{ path: 'reference-package/' }]).salesforce, true);
});

test('rejects invalid package configuration instead of skipping validation', () => {
    assert.throws(() => classifyChanges([], undefined), /packageDirectories/);
    assert.throws(() => classifyChanges([], [{}]), /package directory/);
});

function fixture(t) {
    const directory = fs.mkdtempSync(path.join(os.tmpdir(), 'ci-changes-'));
    t.after(() => fs.rmSync(directory, { recursive: true, force: true }));
    const git = (...args) =>
        execFileSync(
            'git',
            [
                '-c',
                `core.hooksPath=${path.join(directory, 'no-hooks')}`,
                '-c',
                'user.name=CI',
                '-c',
                'user.email=ci@example.invalid',
                ...args
            ],
            { cwd: directory, encoding: 'utf8' }
        ).trim();
    const write = (name, content = 'fixture') => {
        const target = path.join(directory, name);
        fs.mkdirSync(path.dirname(target), { recursive: true });
        fs.writeFileSync(target, content);
    };
    git('init', '--quiet');
    write('sfdx-project.json', JSON.stringify({ packageDirectories }));
    write('force-app/deleted.cls');
    write('force-app/renamed.cls');
    write('bin/source.cls');
    git('add', '.');
    git('commit', '--quiet', '-m', 'base');
    const base = git('rev-parse', 'HEAD');
    const output = path.join(directory, 'outputs');
    const run = (from = base) =>
        spawnSync(process.execPath, [path.resolve(__dirname, '../ci-changes.cjs'), from, 'HEAD'], {
            cwd: directory,
            encoding: 'utf8',
            env: { ...process.env, GITHUB_OUTPUT: output }
        });
    const commit = () => {
        git('add', '.');
        git('commit', '--quiet', '-m', 'change');
    };
    return { directory, git, write, output, run, commit, base };
}

for (const workflow of ['salesforce-validation.yml', 'pull_request-lwc-validation.yml']) {
    for (const trustedFilter of [false, true]) {
        test(
            `${workflow} ignores a PR-controlled filter (base filter available: ${trustedFilter})`,
            { skip: process.platform === 'win32' },
            (t) => {
                const f = fixture(t);
                let base = f.base;
                if (trustedFilter) {
                    f.write('scripts/ci-changes.cjs', fs.readFileSync(path.resolve(__dirname, '../ci-changes.cjs')));
                    f.commit();
                    base = f.git('rev-parse', 'HEAD');
                }
                f.write(
                    'scripts/ci-changes.cjs',
                    "require('node:fs').appendFileSync(process.env.GITHUB_OUTPUT, 'salesforce=false\\nlwc=false\\n');"
                );
                f.write('force-app/changed.cls');
                f.commit();
                const source = fs.readFileSync(path.resolve(__dirname, '../../.github/workflows', workflow), 'utf8');
                const match = source.match(/run: \|\n((?: {18}.*\n)+)/);
                assert.ok(match, 'Expected a classification shell step');
                const script = match[1].replace(/^ {18}/gm, '');
                const result = spawnSync('bash', ['-e', '-o', 'pipefail', '-c', script], {
                    cwd: f.directory,
                    encoding: 'utf8',
                    env: {
                        ...process.env,
                        BASE_SHA: base,
                        HEAD_SHA: 'HEAD',
                        GITHUB_OUTPUT: f.output,
                        RUNNER_TEMP: f.directory
                    }
                });
                assert.equal(result.status, 0, result.stderr);
                assert.equal(fs.readFileSync(f.output, 'utf8'), 'salesforce=true\nlwc=true\n');
            }
        );
    }
}

test('CLI reports no Salesforce or LWC work for a tooling-only diff', (t) => {
    const f = fixture(t);
    f.write('bin/tool.js');
    f.commit();
    const result = f.run();
    assert.equal(result.status, 0, result.stderr);
    assert.equal(fs.readFileSync(f.output, 'utf8'), 'salesforce=false\nlwc=false\n');
});

test('CLI uses trusted base configuration even when the PR corrupts the project file', (t) => {
    const f = fixture(t);
    f.write('sfdx-project.json', 'invalid PR configuration');
    f.commit();
    const result = f.run();
    assert.equal(result.status, 0, result.stderr);
    assert.equal(fs.readFileSync(f.output, 'utf8'), 'salesforce=true\nlwc=true\n');
});

for (const operation of ['delete', 'rename-out', 'rename-in', 'large-diff']) {
    test(`CLI detects relevant paths in ${operation} diffs`, (t) => {
        const f = fixture(t);
        if (operation === 'delete') {
            f.git('rm', 'force-app/deleted.cls');
        } else if (operation === 'rename-out') {
            f.git('mv', 'force-app/renamed.cls', 'bin/renamed.cls');
        } else if (operation === 'rename-in') {
            f.git('mv', 'bin/source.cls', 'force-app/file with spaces.cls');
        } else {
            for (let index = 0; index < 350; index++) {
                f.write(`bin/file-${index}.txt`);
            }
            f.write('force-app/last-file.cls');
        }
        f.commit();
        const result = f.run();
        assert.equal(result.status, 0, result.stderr);
        assert.equal(fs.readFileSync(f.output, 'utf8'), 'salesforce=true\nlwc=true\n');
    });
}

test('CLI preserves filenames containing newlines', { skip: process.platform === 'win32' }, (t) => {
    const f = fixture(t);
    f.write('force-app/file with\nnewline.cls');
    f.commit();
    const result = f.run();
    assert.equal(result.status, 0, result.stderr);
    assert.equal(fs.readFileSync(f.output, 'utf8'), 'salesforce=true\nlwc=true\n');
});

test('CLI fails without producing success-shaped outputs when Git cannot resolve the base', (t) => {
    const f = fixture(t);
    const result = f.run('missing-revision');
    assert.notEqual(result.status, 0);
    assert.match(result.stderr, /missing-revision/);
    assert.equal(fs.existsSync(f.output), false);
});
