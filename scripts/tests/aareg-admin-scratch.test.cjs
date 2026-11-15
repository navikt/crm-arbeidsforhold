const assert = require('node:assert/strict');
const { test } = require('node:test');
const { ADMIN_SOURCES, ADMIN_TESTS, TESTLAB_SCENARIOS, main } = require('../aareg-admin-scratch.cjs');

const SCRATCH = {
    alias: 'crm-arbeidsforhold',
    isScratch: true,
    instanceUrl: 'https://example-1.scratch.my.salesforce.com',
    username: 'scratch@example.com'
};

function fakeSf({ scratchOrgs = [SCRATCH], isSandbox = true, testsPass = true, apexResult } = {}) {
    const calls = [];
    const scripts = [];
    const runSf = (args) => {
        calls.push(args);
        const command = args.slice(0, 3).join(' ');
        if (command === 'org list --skip-connection-status') return { status: 0, result: { scratchOrgs } };
        if (command.startsWith('data query')) return { status: 0, result: { records: [{ IsSandbox: isSandbox }] } };
        if (command === 'org assign permset') return { status: 0, result: { successes: [{}], failures: [] } };
        if (command === 'project deploy start') return { status: 0, result: { success: true } };
        if (command === 'apex run test') {
            return testsPass
                ? { status: 0, result: { summary: { outcome: 'Passed' }, tests: [] } }
                : { status: 1, result: { summary: { outcome: 'Failed' }, tests: [] } };
        }
        if (command.startsWith('apex run --target-org')) {
            const file = args[args.indexOf('--file') + 1];
            scripts.push(require('node:fs').readFileSync(file, 'utf8'));
            return apexResult;
        }
        throw new Error(`Unexpected sf call: ${args.join(' ')}`);
    };
    return { calls, scripts, runSf };
}

function apexOk(result) {
    return {
        status: 0,
        result: {
            compiled: true,
            success: true,
            logs: `12:00:00.0|USER_DEBUG|[1]|INFO|AAREG_TESTLAB_RESULT=${JSON.stringify(result)}`
        }
    };
}

function run(mode, sf, scenario) {
    const output = [];
    const code = main({
        mode,
        scenario,
        runSf: sf.runSf,
        log: (line) => output.push(line),
        logError: (line) => output.push(line)
    });
    return { code, output: output.join('\n') };
}

test('refuses an org that is not the identified crm-arbeidsforhold scratch org', () => {
    const sf = fakeSf({ scratchOrgs: [{ ...SCRATCH, instanceUrl: 'https://nav.my.salesforce.com' }] });

    const { code, output } = run('verify', sf);

    assert.equal(code, 1);
    assert.match(output, /STOP/);
    assert.equal(sf.calls.length, 1, 'nothing may run after a refused target');
});

test('refuses an org that does not confirm IsSandbox', () => {
    const sf = fakeSf({ isSandbox: false });

    const { code } = run('verify', sf);

    assert.equal(code, 1);
    assert.ok(!sf.calls.some((args) => args[0] === 'project'), 'no deploy after a refused target');
});

test('verify previews before deploying, assigns the viewer, then runs the admin tests', () => {
    const sf = fakeSf();

    const { code } = run('verify', sf);

    assert.equal(code, 0);
    const deploys = sf.calls.filter((args) => args[0] === 'project');
    assert.equal(deploys.length, 2);
    assert.ok(deploys[0].includes('--dry-run'), 'first deploy must be a preview');
    assert.ok(!deploys[1].includes('--dry-run'));
    for (const source of ADMIN_SOURCES) assert.ok(deploys[1].includes(source), `deploys ${source}`);
    for (const args of [...deploys, ...sf.calls.filter((a) => a[0] === 'apex' || a[1] === 'assign')]) {
        assert.equal(args[args.indexOf('--target-org') + 1], SCRATCH.username, 'always targets the verified username');
    }
    const permsets = sf.calls.filter((args) => args[1] === 'assign').map((args) => args[args.indexOf('--name') + 1]);
    assert.deepEqual(permsets, ['AAREG_Admin_Viewer']);
    const testRun = sf.calls.find((args) => args.slice(0, 3).join(' ') === 'apex run test');
    for (const name of ADMIN_TESTS) assert.ok(testRun.includes(name), `runs ${name}`);
});

test('verify fails when the admin tests fail', () => {
    const { code, output } = run('verify', fakeSf({ testsPass: false }));

    assert.equal(code, 1);
    assert.match(output, /Apex tests did not pass/);
});

test('unknown modes are rejected without touching an org', () => {
    const sf = fakeSf();

    const { code } = run('production', sf);

    assert.equal(code, 2);
    assert.equal(sf.calls.length, 0);
});

test('seed rejects an unknown scenario before touching an org', () => {
    const sf = fakeSf();

    const { code, output } = run('seed', sf, "x'); delete [SELECT Id FROM Account]; //");

    assert.equal(code, 2);
    assert.match(output, new RegExp(TESTLAB_SCENARIOS[0]));
    assert.equal(sf.calls.length, 0);
});

test('seed refuses a target that does not confirm IsSandbox and writes nothing', () => {
    const sf = fakeSf({ isSandbox: false, apexResult: apexOk({ callouts: 0 }) });

    const { code } = run('seed', sf, TESTLAB_SCENARIOS[0]);

    assert.equal(code, 1);
    assert.ok(!sf.calls.some((args) => args[0] === 'apex' || args[0] === 'project'));
});

test('seed deploys the scratch-only test lab, then runs the named scenario against the verified username', () => {
    const sf = fakeSf({ apexResult: apexOk({ scenario: 'p360-feila', applicationName: 'S-1', callouts: 0 }) });

    const { code, output } = run('seed', sf, 'p360-feila');

    assert.equal(code, 0);
    const deploys = sf.calls.filter((args) => args[0] === 'project');
    assert.equal(deploys.length, 2);
    assert.ok(deploys[0].includes('--dry-run'));
    assert.ok(
        deploys.every((args) => args.includes('--metadata-dir')),
        'the test lab is deployed as unpackaged metadata'
    );
    const apexRuns = sf.calls.filter((args) => args.slice(0, 2).join(' ') === 'apex run' && args[2] !== 'test');
    assert.equal(apexRuns.length, 1);
    assert.equal(apexRuns[0][apexRuns[0].indexOf('--target-org') + 1], SCRATCH.username);
    assert.match(sf.scripts[0], /AAREG_AdminTestLab\.seed\('p360-feila'\)/);
    assert.match(output, /S-1/);
});

test('seed fails when the scenario made a callout', () => {
    const sf = fakeSf({ apexResult: apexOk({ scenario: 'p360-feila', callouts: 1 }) });

    const { code, output } = run('seed', sf, 'p360-feila');

    assert.equal(code, 1);
    assert.match(output, /callout/i);
});

test('reset and inspect run the matching test lab operation', () => {
    for (const mode of ['reset', 'inspect']) {
        const sf = fakeSf({ apexResult: apexOk({ callouts: 0, deleted: {} }) });

        const { code } = run(mode, sf);

        assert.equal(code, 0, mode);
        assert.match(sf.scripts[0], new RegExp(`AAREG_AdminTestLab\\.${mode}\\(\\)`));
    }
});
