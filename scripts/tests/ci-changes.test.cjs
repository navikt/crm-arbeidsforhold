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
    '.github/workflows/pull_request-validation1.yml',
    '.github/workflows/salesforce-validation.yml',
    'scripts/ci-changes.cjs',
    'scripts/tests/ci-changes.test.cjs'
]) {
    test(`validates both surfaces for ${file}`, () => {
        assert.deepEqual(classifyChanges([file], packageDirectories), { salesforce: true, lwc: true });
    });
}

for (const file of [
    'package.json',
    'package-lock.json',
    '.github/workflows/docs-pages.yml',
    '.github/workflows/package-promotion.yml',
    '.github/workflows/pull_request-lwc-validation.yml',
    '.github/workflows/scratch-org-offline.yml'
]) {
    test(`runs LWC but not Salesforce validation for developer tooling: ${file}`, () => {
        assert.deepEqual(classifyChanges([file], packageDirectories), { salesforce: false, lwc: true });
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

function fixture(t, project = { packageDirectories }) {
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
    write('sfdx-project.json', JSON.stringify(project));
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

test('CLI skips Salesforce for a promotion version bump while retaining LWC validation', (t) => {
    const project = {
        packageDirectories: [
            {
                path: 'force-app',
                package: 'crm-arbeidsforhold',
                versionNumber: '0.316.0.NEXT',
                dependencies: [{ package: 'reference-package', versionNumber: '1.0.0.LATEST' }]
            }
        ],
        sourceApiVersion: '67.0'
    };
    const f = fixture(t, project);
    project.packageDirectories[0].versionNumber = '0.317.0.NEXT';
    f.write('sfdx-project.json', JSON.stringify(project));
    f.commit();
    const result = f.run();
    assert.equal(result.status, 0, result.stderr);
    assert.equal(fs.readFileSync(f.output, 'utf8'), 'salesforce=false\nlwc=true\npackage_version_only=true\n');
});

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
                assert.equal(
                    fs.readFileSync(f.output, 'utf8'),
                    `salesforce=true\nlwc=true\n${trustedFilter ? 'package_version_only=false\n' : ''}`
                );
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
    assert.equal(fs.readFileSync(f.output, 'utf8'), 'salesforce=false\nlwc=false\npackage_version_only=false\n');
});

test('CLI skips Salesforce for combined npm and unrelated workflow changes but retains LWC validation', (t) => {
    const f = fixture(t);
    f.write('package.json', '{"devDependencies":{"prettier":"3.10.1"}}');
    f.write('package-lock.json', '{"lockfileVersion":3}');
    f.write('.github/workflows/docs-pages.yml');
    f.write('.github/workflows/package-promotion.yml');
    f.commit();
    const result = f.run();
    assert.equal(result.status, 0, result.stderr);
    assert.equal(fs.readFileSync(f.output, 'utf8'), 'salesforce=false\nlwc=true\npackage_version_only=false\n');
});

test('CLI still requires Salesforce when npm changes accompany Salesforce metadata', (t) => {
    const f = fixture(t);
    f.write('package.json', '{"devDependencies":{"prettier":"3.10.1"}}');
    f.write('force-app/changed.cls');
    f.commit();
    const result = f.run();
    assert.equal(result.status, 0, result.stderr);
    assert.equal(fs.readFileSync(f.output, 'utf8'), 'salesforce=true\nlwc=true\npackage_version_only=false\n');
});

test(
    'Salesforce gate accepts an unnecessary validation but fails closed',
    { skip: process.platform === 'win32' },
    () => {
        const source = fs.readFileSync(
            path.resolve(__dirname, '../../.github/workflows/salesforce-validation.yml'),
            'utf8'
        );
        const gate = source.indexOf('- name: Require successful or unnecessary Salesforce validation');
        assert.notEqual(gate, -1, 'Expected a Salesforce validation gate');
        const match = source.slice(gate).match(/run: \|\n((?: {18}.*\n)+)/);
        assert.ok(match, 'Expected a Salesforce validation gate script');
        const script = match[1].replace(/^ {18}/gm, '');
        for (const [changes, relevant, validation, base, head, expected] of [
            ['success', 'false', 'skipped', 'main', 'example/repository', 0],
            ['success', 'false', 'failure', 'main', 'example/repository', 1],
            ['failure', 'false', 'skipped', 'main', 'example/repository', 1],
            ['success', 'true', 'skipped', 'release', 'example/repository', 0],
            ['success', 'true', 'skipped', 'main', 'contributor/repository', 0],
            ['success', 'true', 'skipped', 'main', 'example/repository', 1],
            ['success', 'true', 'success', 'main', 'example/repository', 0]
        ]) {
            const result = spawnSync('bash', ['-e', '-o', 'pipefail', '-c', script], {
                encoding: 'utf8',
                env: {
                    ...process.env,
                    CHANGES_RESULT: changes,
                    RELEVANT: relevant,
                    VALIDATION_RESULT: validation,
                    BASE_REF: base,
                    HEAD_REPOSITORY: head,
                    REPOSITORY: 'example/repository'
                }
            });
            assert.equal(
                result.status,
                expected,
                `${changes}/${relevant}/${validation}/${base}/${head}: ${result.stderr}`
            );
        }
    }
);

test('CLI uses trusted base configuration even when the PR corrupts the project file', (t) => {
    const f = fixture(t);
    f.write('sfdx-project.json', 'invalid PR configuration');
    f.commit();
    const result = f.run();
    assert.equal(result.status, 0, result.stderr);
    assert.match(result.stderr, /Invalid head sfdx-project.json/);
    assert.equal(fs.readFileSync(f.output, 'utf8'), 'salesforce=true\nlwc=true\npackage_version_only=false\n');
});

for (const scenario of [
    'dependency',
    'api-version',
    'metadata',
    'invalid-version',
    'invalid-version-type',
    'removed-version',
    'format-only'
]) {
    test(`CLI does not exempt a promotion with ${scenario} changes`, (t) => {
        const project = {
            packageDirectories: [
                {
                    path: 'force-app',
                    package: 'crm-arbeidsforhold',
                    versionNumber: '0.316.0.NEXT',
                    dependencies: [{ package: 'reference-package', versionNumber: '1.0.0.LATEST' }]
                }
            ],
            sourceApiVersion: '67.0'
        };
        const f = fixture(t, project);
        const directory = project.packageDirectories[0];
        directory.versionNumber = '0.317.0.NEXT';
        if (scenario === 'dependency') {
            directory.dependencies[0].versionNumber = '2.0.0.LATEST';
        } else if (scenario === 'api-version') {
            project.sourceApiVersion = '68.0';
        } else if (scenario === 'metadata') {
            f.write('force-app/changed.cls');
        } else if (scenario === 'invalid-version') {
            directory.versionNumber = 'not-a-version';
        } else if (scenario === 'invalid-version-type') {
            directory.versionNumber = ['0.317.0.NEXT'];
        } else if (scenario === 'removed-version') {
            delete directory.versionNumber;
        } else {
            directory.versionNumber = '0.316.0.NEXT';
        }
        f.write('sfdx-project.json', JSON.stringify(project, null, 2));
        f.commit();
        const result = f.run();
        assert.equal(result.status, 0, result.stderr);
        assert.equal(fs.readFileSync(f.output, 'utf8'), 'salesforce=true\nlwc=true\npackage_version_only=false\n');
    });
}

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
        assert.equal(fs.readFileSync(f.output, 'utf8'), 'salesforce=true\nlwc=true\npackage_version_only=false\n');
    });
}

test('CLI preserves filenames containing newlines', { skip: process.platform === 'win32' }, (t) => {
    const f = fixture(t);
    f.write('force-app/file with\nnewline.cls');
    f.commit();
    const result = f.run();
    assert.equal(result.status, 0, result.stderr);
    assert.equal(fs.readFileSync(f.output, 'utf8'), 'salesforce=true\nlwc=true\npackage_version_only=false\n');
});

test('CLI fails without producing success-shaped outputs when Git cannot resolve the base', (t) => {
    const f = fixture(t);
    const result = f.run('missing-revision');
    assert.notEqual(result.status, 0);
    assert.match(result.stderr, /missing-revision/);
    assert.equal(fs.existsSync(f.output), false);
});
