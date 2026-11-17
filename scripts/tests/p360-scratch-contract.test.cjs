const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { spawnSync } = require('node:child_process');
const { test } = require('node:test');
const { main, sfInvocation } = require('../p360-scratch-contract.cjs');

const SCRATCH = {
    alias: 'crm-arbeidsforhold',
    isScratchOrg: true,
    isDevHub: false,
    isExpired: false,
    instanceUrl: 'https://example-1.scratch.my.salesforce.com',
    username: 'scratch@example.com',
    orgId: 'synthetic-scratch-identity'
};

const SMOKE_RESULT = {
    simulationOnly: true,
    filesVerified: 2,
    callouts: 0,
    productJobCountUnchanged: true,
    receipts: ['scratch-case', 'scratch-document']
};
const SMOKE_RECEIPTS = [
    {
        Name: 'scratch-case',
        Operation__c: 'CaseService/CreateCase',
        Outcome__c: 'Accepted',
        Attempts__c: 1,
        RequestBody__c: JSON.stringify({ parameter: {} })
    },
    {
        Name: 'scratch-document',
        Operation__c: 'DocumentService/CreateDocument',
        Outcome__c: 'Accepted',
        Attempts__c: 1,
        RequestBody__c: JSON.stringify({
            parameter: {
                Files: [
                    { Base64Data: Buffer.from('{"kind":"synthetic-application","submission":1}').toString('base64') },
                    { Base64Data: Buffer.from('Synthetic attachment without personal data.').toString('base64') }
                ]
            }
        })
    }
];

function fakeSf({
    scratchOrgs = [SCRATCH],
    aliases = [{ alias: SCRATCH.alias, value: SCRATCH.username }],
    authStatus = 0,
    aliasStatus = 0,
    isSandbox = true,
    queryOrgId = SCRATCH.orgId,
    testsPass = true,
    apexFails = false,
    smokeResult = SMOKE_RESULT,
    receiptRecords = SMOKE_RECEIPTS,
    receiptTotal = receiptRecords.length
} = {}) {
    const calls = [];
    let aliasReads = 0;
    const runSf = (args, options) => {
        const command = args.slice(0, 3).join(' ');
        calls.push({ args, options });
        if (args[0] === 'alias' && args[1] === 'list') {
            return { status: aliasStatus, result: typeof aliases === 'function' ? aliases(aliasReads++) : aliases };
        }
        if (command === 'org list auth') return { status: authStatus, result: scratchOrgs };
        if (command.startsWith('data query')) {
            const query = args[args.indexOf('--query') + 1];
            if (query.includes('FROM Organization')) {
                return { status: 0, result: { records: [{ Id: queryOrgId, IsSandbox: isSandbox }] } };
            }
            if (query.includes('FROM P360ScratchCapture__c')) {
                return { status: 0, result: { totalSize: receiptTotal, records: receiptRecords } };
            }
            throw new Error(`Unexpected query: ${query}`);
        }
        if (command === 'org assign permset') return { status: 0, result: { successes: [{}], failures: [] } };
        if (command === 'project deploy start') return { status: 0, result: { success: true } };
        if (command === 'apex run test') {
            return { status: testsPass ? 0 : 1, result: { summary: { outcome: testsPass ? 'Passed' : 'Failed' } } };
        }
        if (command.startsWith('apex run --target-org')) {
            if (apexFails) return { status: 1, result: { compiled: true, success: false, exceptionMessage: 'boom' } };
            return {
                status: 0,
                result: {
                    compiled: true,
                    success: true,
                    logs: `x|USER_DEBUG|[1]|INFO|P360_SCRATCH_RESULT=${JSON.stringify(smokeResult)}`
                }
            };
        }
        throw new Error(`Unexpected sf call: ${args.join(' ')}`);
    };
    return { runSf, calls };
}

function run(t, mode, sf, expectedOrgId = SCRATCH.orgId) {
    const tempRoot = fs.mkdtempSync(path.join(os.tmpdir(), 'p360-contract-test-'));
    t.after(() => fs.rmSync(tempRoot, { recursive: true, force: true }));
    const output = [];
    const exitCode = main({
        mode,
        runSf: sf.runSf,
        expectedOrgId,
        log: (line) => output.push(line),
        logError: (line) => output.push(line),
        tempRoot
    });
    return { exitCode, output: output.join('\n'), leftovers: fs.readdirSync(tempRoot) };
}

test('submission end-to-end mode is unavailable without contacting an org', (t) => {
    const sf = fakeSf();
    const result = run(t, 'e2e', sf);

    assert.equal(result.exitCode, 2);
    assert.deepEqual(sf.calls, []);
});

test('scratch metadata and scripts are outside every Salesforce package directory', () => {
    const root = path.resolve(__dirname, '../..');
    const project = JSON.parse(fs.readFileSync(path.join(root, 'sfdx-project.json'), 'utf8'));
    const scratchPaths = [path.join(root, 'scripts/scratch'), path.join(root, 'scripts/apex/p360ScratchCapture.apex')];

    for (const { path: packagePath } of project.packageDirectories) {
        const packageDirectory = path.resolve(root, packagePath);
        for (const scratchPath of scratchPaths) {
            const relative = path.relative(packageDirectory, scratchPath);
            assert.ok(
                relative === '..' || relative.startsWith(`..${path.sep}`),
                `${scratchPath} must be outside ${packageDirectory}`
            );
        }
    }
});

test('test mode refuses a username that Salesforce CLI would resolve as another org alias', (t) => {
    const sf = fakeSf({
        aliases: [
            { alias: SCRATCH.alias, value: SCRATCH.username },
            { alias: SCRATCH.username, value: 'another-org@example.com' }
        ]
    });

    assert.equal(run(t, 'test', sf).exitCode, 1);
    assert.ok(!sf.calls.some((call) => call.args[0] === 'data' || call.args[0] === 'project'));
});

for (const username of ['scratch%OTHER_ORG%@example.com', 'scratch!OTHER_ORG!@example.com']) {
    test(`test mode refuses a target username that Windows command expansion could alter: ${username}`, (t) => {
        const sf = fakeSf({
            scratchOrgs: [{ ...SCRATCH, username }],
            aliases: [{ alias: SCRATCH.alias, value: username }]
        });

        assert.equal(run(t, 'test', sf).exitCode, 1);
        assert.ok(!sf.calls.some((call) => call.args[0] === 'data' || call.args[0] === 'project'));
    });
}

test('test mode rejects a comma-containing alias that only appears to contain the expected alias', (t) => {
    const sf = fakeSf({
        scratchOrgs: [{ ...SCRATCH, alias: `another,${SCRATCH.alias}` }],
        aliases: [{ alias: `another,${SCRATCH.alias}`, value: SCRATCH.username }]
    });

    assert.equal(run(t, 'test', sf).exitCode, 1);
    assert.ok(!sf.calls.some((call) => call.args[0] === 'data' || call.args[0] === 'project'));
});

test('test mode requires an independently supplied scratch identity before accessing an org', (t) => {
    const sf = fakeSf();

    assert.equal(run(t, 'test', sf, null).exitCode, 1);
    assert.deepEqual(sf.calls, []);
});

test('test mode refuses an authorization whose identity differs from the independently supplied identity', (t) => {
    const sf = fakeSf();

    assert.equal(run(t, 'test', sf, 'another-synthetic-identity').exitCode, 1);
    assert.ok(!sf.calls.some((call) => call.args[0] === 'data' || call.args[0] === 'project'));
});

test('test mode refuses a query result from an org other than the independently supplied identity', (t) => {
    const sf = fakeSf({ queryOrgId: 'another-synthetic-identity' });

    assert.equal(run(t, 'test', sf).exitCode, 1);
    assert.ok(
        !sf.calls.some((call) => call.args[0] === 'project' || call.args[0] === 'apex' || call.args[1] === 'assign')
    );
});

test('test mode checks the alias again before a later operation', (t) => {
    const valid = [{ alias: SCRATCH.alias, value: SCRATCH.username }];
    const sf = fakeSf({
        aliases: (reads) =>
            reads < 2 ? valid : [...valid, { alias: SCRATCH.username, value: 'another-org@example.com' }]
    });

    assert.equal(run(t, 'test', sf).exitCode, 1);
    assert.ok(!sf.calls.some((call) => call.args[0] === 'project' || call.args[0] === 'apex'));
});

test('targeted Salesforce CLI calls isolate the default org from the inherited environment', (t) => {
    const sf = fakeSf();
    assert.equal(run(t, 'test', sf).exitCode, 0);

    for (const call of sf.calls.filter((entry) => entry.args.includes('--target-org'))) {
        assert.equal(call.options?.target, SCRATCH.username);
    }
    const invocation = sfInvocation('darwin', ['data', 'query'], SCRATCH.username, {
        SF_TARGET_ORG: 'unrelated-org',
        SFDX_DEFAULTUSERNAME: 'another-unrelated-org'
    });
    assert.equal(invocation.env.SF_TARGET_ORG, SCRATCH.username);
    assert.equal(invocation.env.SFDX_DEFAULTUSERNAME, SCRATCH.username);
});

test('test mode uses cached authorizations instead of querying a Dev Hub', (t) => {
    const sf = fakeSf();
    const result = run(t, 'test', sf);

    assert.equal(result.exitCode, 0, result.output);
    assert.deepEqual(
        sf.calls.slice(0, 2).map((call) => call.args),
        [
            ['alias', 'list', '--json'],
            ['org', 'list', 'auth', '--json']
        ]
    );
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
    ['a scratch target with unknown expiry', [{ ...SCRATCH, isExpired: 'unknown' }]],
    ['an authorization with a local error', [{ ...SCRATCH, error: 'unreadable authorization' }]],
    ['a target with no username', [{ ...SCRATCH, username: '' }]],
    ['ambiguous authorizations for the expected alias', [SCRATCH, { ...SCRATCH }]]
]) {
    for (const mode of ['verify', 'test']) {
        test(`${mode} refuses ${name} without querying, deploying or running Apex`, (t) => {
            const sf = fakeSf({ scratchOrgs });
            const result = run(t, mode, sf);
            assert.equal(result.exitCode, 1);
            assert.match(result.output, /STOP: The explicit target is not a locally identified scratch org/);
            assert.deepEqual(
                sf.calls.map((call) => call.args.join(' ')),
                ['alias list --json', 'org list auth --json']
            );
        });
    }
}

test('test mode accepts the expected alias alongside other aliases on the same local authorization', (t) => {
    const sf = fakeSf({
        scratchOrgs: [{ ...SCRATCH, alias: `another,with,commas,${SCRATCH.alias}` }],
        aliases: [
            { alias: 'another,with,commas', value: SCRATCH.username },
            { alias: SCRATCH.alias, value: SCRATCH.username }
        ]
    });

    assert.equal(run(t, 'test', sf).exitCode, 0);
    const query = sf.calls.find((call) => call.args.slice(0, 2).join(' ') === 'data query');
    assert.equal(query.args[query.args.indexOf('--target-org') + 1], SCRATCH.username);
});

test('test mode stops when the local authorization listing fails', (t) => {
    const sf = fakeSf({ authStatus: 1 });
    const result = run(t, 'test', sf);

    assert.equal(result.exitCode, 1);
    assert.match(result.output, /Unable to inspect locally cached Salesforce authorizations/);
    assert.equal(sf.calls.length, 2);
});

test('test mode stops when the exact alias listing fails', (t) => {
    const sf = fakeSf({ aliasStatus: 1 });
    const result = run(t, 'test', sf);
    assert.equal(result.exitCode, 1);
    assert.match(result.output, /Unable to inspect locally cached Salesforce aliases/);
    assert.equal(sf.calls.length, 1);
});

test('test mode stops if the verified scratch target does not confirm IsSandbox', (t) => {
    const sf = fakeSf({ isSandbox: false });
    const result = run(t, 'test', sf);

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
        runSf(args, options) {
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
            return sf.runSf(args, options);
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

test('verify deploys the receiver and checks both persistent synthetic files', (t) => {
    const sf = fakeSf();
    const verified = run(t, 'verify', sf);
    assert.equal(verified.exitCode, 0, verified.output);
    const deploys = sf.calls.filter((call) => call.args.slice(0, 3).join(' ') === 'project deploy start');
    assert.equal(deploys.length, 2);
    assert.ok(deploys[0].args.includes('--dry-run'));
    assert.ok(!deploys[1].args.includes('--dry-run'));
    assert.ok(deploys.every((call) => call.args.includes('--metadata-dir') && !call.args.includes('--source-dir')));
    assert.match(verified.output, /"persistentReceipts": 2/);
    assert.match(verified.output, /"filesVerifiedAfterCommit": 2/);
    assert.deepEqual(verified.leftovers, []);
});

for (const [name, sfOptions] of [
    ['missing receipts', { receiptRecords: [] }],
    ['a rejected receipt', { receiptRecords: [{ ...SMOKE_RECEIPTS[0], Outcome__c: 'Rejected' }, SMOKE_RECEIPTS[1]] }],
    ['a smoke fixture that made a callout', { smokeResult: { ...SMOKE_RESULT, callouts: 1 } }],
    ['a failing Apex script', { apexFails: true }]
]) {
    test(`verify fails on ${name}`, (t) => {
        const sf = fakeSf(sfOptions);
        const result = run(t, 'verify', sf);
        assert.equal(result.exitCode, 1);
        assert.match(result.output, /FAIL:/);
        assert.deepEqual(result.leftovers, []);
    });
}

test('verify stops before creating smoke data if the receiver tests fail', (t) => {
    const sf = fakeSf({ testsPass: false });
    const result = run(t, 'verify', sf);
    assert.equal(result.exitCode, 1);
    assert.match(result.output, /Apex tests did not pass/);
    assert.ok(!sf.calls.some((call) => call.args[0] === 'apex' && call.args[1] === 'run' && call.args[2] !== 'test'));
});

for (const [name, sfOptions] of [
    ['a truncated response', { receiptRecords: [SMOKE_RECEIPTS[1]], receiptTotal: 2 }],
    [
        'a missing case receipt',
        { receiptRecords: [{ ...SMOKE_RECEIPTS[0], Operation__c: 'Unexpected/Operation' }, SMOKE_RECEIPTS[1]] }
    ],
    [
        'files attached to the case instead of the document',
        {
            receiptRecords: [
                { ...SMOKE_RECEIPTS[0], RequestBody__c: SMOKE_RECEIPTS[1].RequestBody__c },
                { ...SMOKE_RECEIPTS[1], RequestBody__c: SMOKE_RECEIPTS[0].RequestBody__c }
            ]
        }
    ]
]) {
    test(`inspect rejects ${name} even when the file contents match`, (t) => {
        const result = run(t, 'inspect', fakeSf(sfOptions));
        assert.equal(result.exitCode, 1);
        assert.match(result.output, /persistent smoke receipts are missing or changed/);
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

test('rejects Windows arguments that cmd.exe could expand or use to break quoting', () => {
    for (const argument of ['C:\\users\\%OTHER_ORG%\\file', 'C:\\users\\!OTHER_ORG!\\file', 'bad"argument']) {
        assert.throws(() => sfInvocation('win32', ['data', 'query', '--file', argument]), /unsafe/i);
    }
});

test(
    'the real process runner overrides inherited default targets for every org command',
    { skip: process.platform === 'win32' },
    (t) => {
        const directory = fs.mkdtempSync(path.join(os.tmpdir(), 'scratch-sf-process-test-'));
        t.after(() => fs.rmSync(directory, { recursive: true, force: true }));
        const executable = path.join(directory, 'sf');
        const callLog = path.join(directory, 'calls.jsonl');
        fs.writeFileSync(
            executable,
            `#!/usr/bin/env node
const fs = require('node:fs');
const args = process.argv.slice(2);
fs.appendFileSync(process.env.FAKE_SF_CALLS, JSON.stringify({
    args,
    target: process.env.SF_TARGET_ORG,
    legacy: process.env.SFDX_DEFAULTUSERNAME
}) + '\\n');
const scratch = ${JSON.stringify(SCRATCH)};
let result;
if (args[0] === 'alias') result = [{ alias: scratch.alias, value: scratch.username }];
else if (args[0] === 'org' && args[1] === 'list') result = [scratch];
else if (args[0] === 'data') result = { records: [{ Id: scratch.orgId, IsSandbox: true }] };
else if (args[0] === 'apex') result = { summary: { outcome: 'Passed' }, tests: [] };
else process.exit(1);
console.log(JSON.stringify({ status: 0, result }));
`
        );
        fs.chmodSync(executable, 0o755);
        const execution = spawnSync(process.execPath, [path.join(__dirname, '../p360-scratch-contract.cjs'), 'test'], {
            encoding: 'utf8',
            env: {
                ...process.env,
                PATH: `${directory}${path.delimiter}${path.dirname(process.execPath)}`,
                FAKE_SF_CALLS: callLog,
                AAREG_SCRATCH_ORG_ID: SCRATCH.orgId,
                SF_TARGET_ORG: 'unrelated-org',
                SFDX_DEFAULTUSERNAME: 'another-unrelated-org'
            }
        });

        assert.equal(execution.status, 0, execution.stderr);
        const calls = fs.readFileSync(callLog, 'utf8').trim().split('\n').map(JSON.parse);
        const targeted = calls.filter((call) => call.args.includes('--target-org'));
        assert.equal(targeted.length, 2);
        for (const call of targeted) {
            assert.equal(call.target, SCRATCH.username);
            assert.equal(call.legacy, SCRATCH.username);
        }
    }
);
