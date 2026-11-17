const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const { test } = require('node:test');
const { compareVersions, main, sleep } = require('../check-sfdx-versions');

let fixtureNumber = 0;
function fixture(t, version = '1.2.3.LATEST') {
    const directory = path.resolve(__dirname, `.check-sfdx-fixture-${process.pid}-${fixtureNumber++}`);
    fs.mkdirSync(directory, { recursive: true });
    t.after(() => fs.rmSync(directory, { recursive: true, force: true }));
    const projectPath = path.join(directory, 'sfdx-project.json');
    const contents = {
        packageDirectories: [{ path: 'force-app', dependencies: [{ package: 'Example', versionNumber: version }] }],
        packageAliases: { Example: '0Ho000000000000AAA' }
    };
    fs.writeFileSync(projectPath, `${JSON.stringify(contents, null, 4)}\n`);
    return {
        projectPath,
        backupPath: `${projectPath}.backup`,
        original: fs.readFileSync(projectPath, 'utf8'),
        contents
    };
}

function fakeExec(version = { MajorVersion: 1, MinorVersion: 2, PatchVersion: 3 }) {
    return (command) => {
        if (command === 'sf org list --json') return '{"result":{}}';
        if (command.startsWith('sf package version list')) {
            return JSON.stringify({ result: [{ ...version }] });
        }
        throw new Error(`Unexpected command: ${command}`);
    };
}

function quietLogger() {
    return { log() {}, error() {} };
}

test('compares numeric version components and treats LATEST and NEXT as suffixes', () => {
    assert.equal(compareVersions('1.10.0', '1.9.9'), 1);
    assert.equal(compareVersions('2.0.0', '2.0.0'), 0);
    assert.equal(compareVersions('1.2.3.NEXT', '1.2.4'), -1);
});

test('returns authentication failure without attempting package checks', async (t) => {
    const f = fixture(t);
    let calls = 0;
    const errors = [];
    const result = await main({
        projectPath: f.projectPath,
        exec: () => {
            calls++;
            throw new Error('not authenticated');
        },
        prompt: async () => 'YES',
        logger: { log() {}, error: (message) => errors.push(message) }
    });

    assert.equal(result, 1);
    assert.equal(calls, 1);
    assert.match(errors.join('\n'), /sf org login devhub/);
    assert.equal(fs.existsSync(f.backupPath), false);
});

test('retries a timed-out package command then reports the exhausted failure', async (t) => {
    const f = fixture(t);
    let attempts = 0;
    const delays = [];
    const result = await main({
        projectPath: f.projectPath,
        exec: (command) => {
            if (command === 'sf org list --json') return '{}';
            attempts++;
            const error = new Error('ETIMEDOUT');
            throw error;
        },
        sleepFn: (milliseconds) => delays.push(milliseconds),
        retries: 2,
        prompt: async () => assert.fail('prompt should not run after command failure'),
        logger: quietLogger()
    });

    assert.equal(result, 0);
    assert.equal(attempts, 3);
    assert.deepEqual(delays, [5000, 5000]);
    assert.equal(fs.readFileSync(f.projectPath, 'utf8'), f.original);
});

test('does not change the manifest when a package command returns malformed JSON', async (t) => {
    const f = fixture(t, '1.2.2.LATEST');
    const result = await main({
        projectPath: f.projectPath,
        exec: (command) => (command === 'sf org list --json' ? '{}' : 'not json'),
        prompt: async () => assert.fail('prompt should not run for malformed output'),
        logger: quietLogger()
    });

    assert.equal(result, 0);
    assert.equal(fs.readFileSync(f.projectPath, 'utf8'), f.original);
    assert.equal(fs.existsSync(f.backupPath), false);
});

test('does not write when the current LATEST or NEXT version matches the latest release', async (t) => {
    for (const suffix of ['LATEST', 'NEXT']) {
        const f = fixture(t, `1.2.3.${suffix}`);
        const result = await main({
            projectPath: f.projectPath,
            exec: fakeExec(),
            prompt: async () => assert.fail('prompt should not run when versions match'),
            logger: quietLogger()
        });
        assert.equal(result, 0);
        assert.equal(fs.readFileSync(f.projectPath, 'utf8'), f.original);
        assert.equal(fs.existsSync(f.backupPath), false);
    }
});

test('leaves the manifest untouched when the user declines an update', async (t) => {
    const f = fixture(t, '1.2.2.LATEST');
    const result = await main({
        projectPath: f.projectPath,
        exec: fakeExec(),
        prompt: async () => 'no',
        logger: quietLogger()
    });

    assert.equal(result, 0);
    assert.equal(fs.readFileSync(f.projectPath, 'utf8'), f.original);
    assert.equal(fs.existsSync(f.backupPath), false);
});

test('updates the root manifest and creates a backup only after YES', async (t) => {
    const f = fixture(t, '1.2.2.LATEST');
    const result = await main({
        projectPath: f.projectPath,
        exec: fakeExec(),
        prompt: async () => ' YES ',
        logger: quietLogger()
    });

    assert.equal(result, 0);
    assert.equal(fs.readFileSync(f.backupPath, 'utf8'), f.original);
    const updated = JSON.parse(fs.readFileSync(f.projectPath, 'utf8'));
    assert.equal(updated.packageDirectories[0].dependencies[0].versionNumber, '1.2.3.LATEST');
});

test('sleep waits on non-Windows platforms without invoking a shell command', () => {
    const started = Date.now();
    sleep(20);
    assert.ok(Date.now() - started >= 15);
});
