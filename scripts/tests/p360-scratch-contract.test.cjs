const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { test } = require('node:test');
const { FLAG_SOURCE, main, sfInvocation } = require('../p360-scratch-contract.cjs');

const SCRATCH = {
    alias: 'crm-arbeidsforhold',
    isScratch: true,
    instanceUrl: 'https://example-1.scratch.my.salesforce.com',
    username: 'scratch@example.com'
};

function fakeSf({ scratchOrgs = [SCRATCH], e2eResult, apexFails = false }) {
    const calls = [];
    const runSf = (args) => {
        const command = args.slice(0, 3).join(' ');
        const metadataDir = args[args.indexOf('--metadata-dir') + 1];
        calls.push({
            args,
            flagEnabled:
                args.includes('--metadata-dir') &&
                fs
                    .readFileSync(
                        path.join(metadataDir, 'customMetadata', 'Feature_Flag.P360_Archive_Processing.md'),
                        'utf8'
                    )
                    .includes('<value xsi:type="xsd:boolean">true</value>')
        });
        if (command === 'org list --skip-connection-status') return { status: 0, result: { scratchOrgs } };
        if (command.startsWith('data query')) return { status: 0, result: { records: [{ IsSandbox: true }] } };
        if (command === 'org assign permset') return { status: 0, result: { successes: [{}], failures: [] } };
        if (command === 'project deploy start') return { status: 0, result: { success: true } };
        if (command.startsWith('apex run --target-org')) {
            if (apexFails) return { status: 1, result: { compiled: true, success: false, exceptionMessage: 'boom' } };
            return {
                status: 0,
                result: {
                    compiled: true,
                    success: true,
                    logs: `x|USER_DEBUG|[1]|INFO|P360_E2E_RESULT=${JSON.stringify(e2eResult)}`
                }
            };
        }
        throw new Error(`Unexpected sf call: ${args.join(' ')}`);
    };
    return { runSf, calls };
}

function run(t, mode, sf) {
    const tempRoot = fs.mkdtempSync(path.join(os.tmpdir(), 'p360-contract-test-'));
    t.after(() => fs.rmSync(tempRoot, { recursive: true, force: true }));
    const output = [];
    const exitCode = main({
        mode,
        runSf: sf.runSf,
        log: (line) => output.push(line),
        logError: (line) => output.push(line),
        tempRoot
    });
    return { exitCode, output: output.join('\n'), leftovers: fs.readdirSync(tempRoot) };
}

const ACCEPTED = {
    simulationOnly: true,
    claimedJobs: 1,
    jobStatus: 'Succeeded',
    filesVerified: 2,
    callouts: 0,
    receipts: [{ outcome: 'Accepted' }, { outcome: 'Accepted' }]
};

for (const [name, scratchOrgs] of [
    ['missing scratch target', []],
    ['non-scratch target with the expected alias', [{ ...SCRATCH, isScratch: false }]],
    [
        'untrusted instance domain despite scratch classification',
        [{ ...SCRATCH, instanceUrl: 'https://example.invalid' }]
    ]
]) {
    for (const mode of ['verify', 'e2e']) {
        test(`${mode} refuses ${name} without querying, deploying or running Apex`, (t) => {
            const sf = fakeSf({ scratchOrgs });
            const result = run(t, mode, sf);
            assert.equal(result.exitCode, 1);
            assert.match(result.output, /STOP: The explicit target is not a locally identified scratch org/);
            assert.deepEqual(
                sf.calls.map((call) => call.args.join(' ')),
                ['org list --skip-connection-status --json']
            );
        });
    }
}

test('rejects unknown actions before accessing Salesforce', (t) => {
    const sf = fakeSf({});
    assert.equal(run(t, 'unexpected', sf).exitCode, 2);
    assert.deepEqual(sf.calls, []);
});

test('e2e passes only with two accepted receipts and restores the flag from source', (t) => {
    const sf = fakeSf({ e2eResult: ACCEPTED });
    const result = run(t, 'e2e', sf);
    assert.equal(result.exitCode, 0, result.output);
    assert.ok(sf.calls.some((call) => call.flagEnabled));
    assert.deepEqual(sf.calls.at(-1).args.slice(0, 5), ['project', 'deploy', 'start', '--source-dir', FLAG_SOURCE]);
    assert.deepEqual(result.leftovers, []);
});

for (const [name, sfOptions] of [
    ['a succeeded job without receipts (stub transport won)', { e2eResult: { ...ACCEPTED, receipts: [] } }],
    ['a failing Apex script', { apexFails: true }]
]) {
    test(`e2e fails on ${name} and still restores the flag`, (t) => {
        const sf = fakeSf(sfOptions);
        const result = run(t, 'e2e', sf);
        assert.equal(result.exitCode, 1);
        assert.match(result.output, /FAIL:/);
        assert.deepEqual(sf.calls.at(-1).args.slice(0, 5), ['project', 'deploy', 'start', '--source-dir', FLAG_SOURCE]);
        assert.match(result.output, /flag restored from source/);
    });
}

test('quotes every sf argument for cmd.exe on Windows so SOQL and paths with spaces stay intact', () => {
    const args = [
        'data',
        'query',
        '--query',
        "SELECT Id FROM X WHERE Name IN ('a', 'b')",
        '--file',
        'C:\\My Repo\\a.layout'
    ];
    const invocation = sfInvocation('win32', args);
    assert.equal(invocation.shell, true);
    assert.deepEqual(
        invocation.args,
        args.map((arg) => `"${arg}"`)
    );
    assert.deepEqual(sfInvocation('darwin', args), { command: 'sf', args, shell: false });
});
