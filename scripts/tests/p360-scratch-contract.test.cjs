const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { test } = require('node:test');
const { FLAG_SOURCE, main, sfInvocation } = require('../p360-scratch-contract.cjs');

const SCRATCH = {
    alias: 'crm-arbeidsforhold',
    isScratchOrg: true,
    isDevHub: false,
    isExpired: false,
    instanceUrl: 'https://example-1.scratch.my.salesforce.com',
    username: 'scratch@example.com'
};

function fakeSf({ scratchOrgs = [SCRATCH], authStatus = 0, isSandbox = true, e2eResult, apexFails = false }) {
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
        if (command === 'org list auth') return { status: authStatus, result: scratchOrgs };
        if (command.startsWith('data query')) return { status: 0, result: { records: [{ IsSandbox: isSandbox }] } };
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

test('e2e identifies the scratch target from local authorizations without listing Dev Hubs', (t) => {
    const sf = fakeSf({ e2eResult: ACCEPTED });
    const result = run(t, 'e2e', sf);

    assert.equal(result.exitCode, 0, result.output);
    assert.deepEqual(sf.calls[0].args, ['org', 'list', 'auth', '--json']);
    assert.ok(!sf.calls.some((call) => call.args.slice(0, 3).join(' ') === 'org list --skip-connection-status'));
});

for (const [name, scratchOrgs] of [
    ['missing scratch target', []],
    ['non-scratch target with the expected alias', [{ ...SCRATCH, isScratchOrg: false }]],
    [
        'untrusted instance domain despite scratch classification',
        [{ ...SCRATCH, instanceUrl: 'https://example.invalid' }]
    ],
    ['a Dev Hub using the expected alias', [{ ...SCRATCH, isDevHub: true }]],
    ['an expired scratch target', [{ ...SCRATCH, isExpired: true }]],
    ['an authorization with a local error', [{ ...SCRATCH, error: 'unreadable authorization' }]],
    ['a target with no username', [{ ...SCRATCH, username: '' }]],
    ['ambiguous authorizations for the expected alias', [SCRATCH, { ...SCRATCH }]]
]) {
    for (const mode of ['verify', 'e2e']) {
        test(`${mode} refuses ${name} without querying, deploying or running Apex`, (t) => {
            const sf = fakeSf({ scratchOrgs });
            const result = run(t, mode, sf);
            assert.equal(result.exitCode, 1);
            assert.match(result.output, /STOP: The explicit target is not a locally identified scratch org/);
            assert.deepEqual(
                sf.calls.map((call) => call.args.join(' ')),
                ['org list auth --json']
            );
        });
    }
}

test('e2e accepts the expected alias alongside other aliases on the same local authorization', (t) => {
    const sf = fakeSf({ scratchOrgs: [{ ...SCRATCH, alias: `another,${SCRATCH.alias}` }], e2eResult: ACCEPTED });

    assert.equal(run(t, 'e2e', sf).exitCode, 0);
    const query = sf.calls.find((call) => call.args.slice(0, 2).join(' ') === 'data query');
    assert.equal(query.args[query.args.indexOf('--target-org') + 1], SCRATCH.username);
});

test('e2e stops when the local authorization listing fails', (t) => {
    const sf = fakeSf({ authStatus: 1 });
    const result = run(t, 'e2e', sf);

    assert.equal(result.exitCode, 1);
    assert.match(result.output, /Unable to inspect locally cached Salesforce authorizations/);
    assert.equal(sf.calls.length, 1);
});

test('e2e stops if the verified scratch target does not confirm IsSandbox', (t) => {
    const sf = fakeSf({ isSandbox: false });
    const result = run(t, 'e2e', sf);

    assert.equal(result.exitCode, 1);
    assert.match(result.output, /did not confirm IsSandbox=true/);
    assert.ok(!sf.calls.some((call) => call.args[0] === 'project' || call.args[0] === 'apex'));
});

test('rejects unknown actions before accessing Salesforce', (t) => {
    const sf = fakeSf({});
    assert.equal(run(t, 'unexpected', sf).exitCode, 2);
    assert.deepEqual(sf.calls, []);
});

test('verify includes and activates the scratch receipt guidance page', (t) => {
    const sf = fakeSf({});
    let deployment;
    const captureDeployment = {
        runSf(args) {
            if (args[0] === 'project' && args[1] === 'deploy') {
                const directory = args[args.indexOf('--metadata-dir') + 1];
                const page = path.join(directory, 'flexipages', 'P360_Scratch_Capture_Record_Page.flexipage');
                deployment = {
                    manifest: fs.readFileSync(path.join(directory, 'package.xml'), 'utf8'),
                    object: fs.readFileSync(path.join(directory, 'objects', 'P360ScratchCapture__c.object'), 'utf8'),
                    hasPage: fs.existsSync(page)
                };
                return { status: 1, result: { success: false } };
            }
            return sf.runSf(args);
        }
    };

    run(t, 'verify', captureDeployment);

    assert.ok(deployment, 'verify must attempt the scratch metadata deployment');
    assert.match(deployment.manifest, /<members>P360_Scratch_Capture_Record_Page<\/members>\s*<name>FlexiPage<\/name>/);
    assert.match(
        deployment.object,
        /<actionName>View<\/actionName>\s*<content>P360_Scratch_Capture_Record_Page<\/content>\s*<formFactor>Large<\/formFactor>\s*<type>flexipage<\/type>/
    );
    assert.equal(deployment.hasPage, true, 'the page included in the manifest must be in the deployment bundle');
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
