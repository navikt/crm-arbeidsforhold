#!/usr/bin/env node
'use strict';

const { spawnSync } = require('node:child_process');
const crypto = require('node:crypto');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');

const ROOT = path.resolve(__dirname, '..');
const ORG = 'crm-arbeidsforhold';
const MODES = ['verify', 'test', 'regression', 'smoke', 'inspect', 'e2e'];
const SCRATCH_URL = /^https:\/\/[a-zA-Z0-9.-]+\.scratch\.my\.salesforce\.com$/;
const FLAG_SOURCE = path.join(
    ROOT,
    'force-app/integration/p360/customMetadata/Feature_Flag.P360_Archive_Processing.md-meta.xml'
);
const FLAG_DISABLED = '<value xsi:type="xsd:boolean">false</value>';
const FLAG_ENABLED = '<value xsi:type="xsd:boolean">true</value>';
const SCRATCH_BUNDLE = [
    ['scripts/scratch/p360/package.xml', 'package.xml'],
    ['scripts/scratch/p360/classes/P360_ScratchRpcClient.cls', 'classes'],
    ['scripts/scratch/p360/classes/P360_ScratchRpcClient.cls-meta.xml', 'classes'],
    ['force-app/tests/classes/integration/p360/scratch/P360_ScratchRpcClientTest.cls', 'classes'],
    ['force-app/tests/classes/integration/p360/scratch/P360_ScratchRpcClientTest.cls-meta.xml', 'classes'],
    ['scripts/scratch/p360/objects/P360ScratchCapture__c.object', 'objects'],
    ['scripts/scratch/p360/objects/P360ScratchSetting__c.object', 'objects'],
    ['scripts/scratch/p360/permissionsets/P360_Scratch_Capture_Access.permissionset', 'permissionsets'],
    ['scripts/scratch/p360/tabs/P360ScratchCapture__c.tab', 'tabs'],
    ['scripts/scratch/p360/layouts/P360ScratchCapture__c-P360 Scratch Capture Layout.layout', 'layouts'],
    ['scripts/scratch/p360/flexipages/P360_Scratch_Capture_Record_Page.flexipage', 'flexipages']
];
const SMOKE_FILES = ['{"kind":"synthetic-application","submission":1}', 'Synthetic attachment without personal data.'];

class ContractFailure extends Error {
    constructor(message, exitCode = 1) {
        super(message);
        this.exitCode = exitCode;
    }
}

/**
 * Builds the platform-specific Salesforce CLI invocation. Windows installs sf as sf.cmd, which Node can only
 * start through cmd.exe, so every argument is quoted to keep spaces and SOQL intact.
 */
function sfInvocation(platform, args) {
    if (platform !== 'win32') {
        return { command: 'sf', args, shell: false };
    }
    return { command: 'sf', args: args.map((arg) => `"${String(arg).replace(/"/g, '""')}"`), shell: true };
}

function runSfProcess(args) {
    const invocation = sfInvocation(process.platform, args);
    const result = spawnSync(invocation.command, invocation.args, {
        encoding: 'utf8',
        shell: invocation.shell,
        maxBuffer: 64 * 1024 * 1024
    });
    if (result.error) {
        throw new ContractFailure(`Unable to start the Salesforce CLI (sf): ${result.error.message}`);
    }
    try {
        return JSON.parse(result.stdout);
    } catch {
        throw new ContractFailure(
            `The Salesforce CLI returned no JSON for "sf ${args[0]} ${args[1]}".\n${result.stderr}`
        );
    }
}

function sha256(value) {
    return crypto.createHash('sha256').update(value, 'utf8').digest('hex');
}

function summarize(result) {
    const value = result.result ?? {};
    return {
        status: result.status,
        deployment: {
            status: value.status,
            success: value.success,
            numberComponentErrors: value.numberComponentErrors,
            numberTestErrors: value.numberTestErrors
        },
        componentFailures: value.details?.componentFailures,
        summary: value.summary && {
            outcome: value.summary.outcome,
            testsRan: value.summary.testsRan,
            passing: value.summary.passing,
            failing: value.summary.failing,
            skipped: value.summary.skipped,
            testTotalTime: value.summary.testTotalTime
        },
        tests: (value.tests ?? []).map(({ FullName, Outcome, Message }) => ({ FullName, Outcome, Message })),
        error: result.message
    };
}

function readDebugResult(result, marker) {
    const line = String(result.result?.logs ?? '')
        .split('\n')
        .find((entry) => entry.includes('|USER_DEBUG|') && entry.includes(marker));
    if (!line) {
        throw new ContractFailure(`The Apex script did not report ${marker}`);
    }
    return JSON.parse(line.split(marker)[1]);
}

function createContract({ runSf, log, workDirectory }) {
    let target;

    function verifyTarget() {
        const orgs = runSf(['org', 'list', '--skip-connection-status', '--json']);
        const matches = (orgs.result?.scratchOrgs ?? []).filter(
            (org) => org.alias === ORG && org.isScratch === true && SCRATCH_URL.test(org.instanceUrl ?? '')
        );
        if (matches.length !== 1 || typeof matches[0].username !== 'string' || !matches[0].username) {
            throw new ContractFailure('STOP: The explicit target is not a locally identified scratch org.');
        }
        target = matches[0].username;
        const check = runSf([
            'data',
            'query',
            '--target-org',
            target,
            '--query',
            'SELECT IsSandbox FROM Organization',
            '--json'
        ]);
        if (check.status !== 0 || check.result?.records?.[0]?.IsSandbox !== true) {
            throw new ContractFailure('STOP: The target org did not confirm IsSandbox=true.');
        }
        log('Target verified: crm-arbeidsforhold, scratch domain and IsSandbox=true.');
    }

    function deploy(args, description) {
        const result = runSf([
            'project',
            'deploy',
            'start',
            ...args,
            '--target-org',
            target,
            '--test-level',
            'NoTestRun',
            '--wait',
            '10',
            '--json'
        ]);
        if (result.status !== 0 || result.result?.success !== true) {
            log(JSON.stringify(summarize(result), null, 2));
            throw new ContractFailure(`FAIL: ${description} was not deployed.`);
        }
        return result;
    }

    function deployScratchBundle() {
        const directory = path.join(workDirectory, 'metadata');
        for (const [source, folder] of SCRATCH_BUNDLE) {
            const destination = folder === 'package.xml' ? directory : path.join(directory, folder);
            fs.mkdirSync(destination, { recursive: true });
            fs.copyFileSync(path.join(ROOT, source), path.join(destination, path.basename(source)));
        }
        for (const extra of [['--dry-run'], []]) {
            const result = deploy(['--metadata-dir', directory, ...extra], 'The scratch-only P360 receiver');
            log(JSON.stringify(summarize(result), null, 2));
        }
    }

    function runTests(classNames) {
        // The CLI only allows --synchronous for a single test class.
        const result = runSf([
            'apex',
            'run',
            'test',
            '--target-org',
            target,
            ...classNames.flatMap((name) => ['--tests', name]),
            ...(classNames.length === 1 ? ['--synchronous'] : []),
            '--wait',
            '10',
            '--json'
        ]);
        log(JSON.stringify(summarize(result), null, 2));
        if (result.status !== 0 || result.result?.summary?.outcome !== 'Passed') {
            throw new ContractFailure('FAIL: Apex tests did not pass.');
        }
    }

    function assignPermissionSet(name) {
        const result = runSf(['org', 'assign', 'permset', '--target-org', target, '--name', name, '--json']);
        const successes = result.result?.successes ?? [];
        const failures = result.result?.failures ?? [];
        const accepted =
            successes.length + failures.length > 0 &&
            failures.every((failure) => String(failure.message).includes('Duplicate PermissionSetAssignment'));
        if (!accepted) {
            throw new ContractFailure(`FAIL: ${name} could not be assigned to the scratch CLI user.`);
        }
    }

    function runApexScript(relativePath, marker) {
        const result = runSf([
            'apex',
            'run',
            '--target-org',
            target,
            '--file',
            path.join(ROOT, relativePath),
            '--json'
        ]);
        if (result.status !== 0 || result.result?.compiled !== true || result.result?.success !== true) {
            log(
                JSON.stringify(
                    {
                        status: result.status,
                        message: result.message,
                        compileProblem: result.result?.compileProblem,
                        exceptionMessage: result.result?.exceptionMessage
                    },
                    null,
                    2
                )
            );
            throw new ContractFailure(`FAIL: ${path.basename(relativePath)} did not complete.`);
        }
        return readDebugResult(result, marker);
    }

    function smoke() {
        assignPermissionSet('P360_Scratch_Capture_Access');
        log('Scratch-only capture permission set is assigned to the current CLI user.');
        const outcome = runApexScript('scripts/apex/p360ScratchCapture.apex', 'P360_SCRATCH_RESULT=');
        log(JSON.stringify(outcome, null, 2));
        if (!(
            outcome.simulationOnly === true &&
            outcome.filesVerified === 2 &&
            outcome.callouts === 0 &&
            outcome.productJobCountUnchanged === true &&
            outcome.receipts?.length === 2
        )) {
            throw new ContractFailure('FAIL: The smoke fixture did not produce the expected evidence.');
        }
    }

    function inspect() {
        const caseKey = sha256('CaseService/CreateCase\nScratch P360\nscratch-p360-smoke-case-v1');
        const documentKey = sha256('DocumentService/CreateDocument\nScratch P360\nscratch-p360-smoke-document-v1');
        const result = runSf([
            'data',
            'query',
            '--target-org',
            target,
            '--query',
            `SELECT Name, Operation__c, Outcome__c, Attempts__c, RequestBody__c FROM P360ScratchCapture__c WHERE RequestKey__c IN ('${caseKey}', '${documentKey}')`,
            '--json'
        ]);
        const records = result.result?.records ?? [];
        const files = records
            .flatMap((record) => JSON.parse(record.RequestBody__c).parameter?.Files ?? [])
            .map((file) => Buffer.from(file.Base64Data, 'base64').toString('utf8'))
            .sort();
        const valid =
            result.status === 0 &&
            result.result?.totalSize === 2 &&
            records.every((record) => record.Outcome__c === 'Accepted') &&
            JSON.stringify(files) === JSON.stringify([...SMOKE_FILES].sort());
        if (!valid) {
            throw new ContractFailure('FAIL: The persistent smoke receipts are missing or changed.');
        }
        log(
            JSON.stringify(
                {
                    persistentReceipts: result.result.totalSize,
                    filesVerifiedAfterCommit: 2,
                    receipts: records.map(({ Name, Operation__c, Outcome__c, Attempts__c }) => ({
                        Name,
                        Operation__c,
                        Outcome__c,
                        Attempts__c
                    }))
                },
                null,
                2
            )
        );
    }

    function endToEnd() {
        for (const name of ['P360_Scratch_Capture_Access', 'P360_Code_Table_Access']) {
            assignPermissionSet(name);
        }
        const source = fs.readFileSync(FLAG_SOURCE, 'utf8');
        if (!source.includes(FLAG_DISABLED)) {
            throw new ContractFailure(
                'STOP: The archive-processing flag in source is not disabled; refusing to toggle it.'
            );
        }
        const flagDirectory = path.join(workDirectory, 'flag');
        fs.mkdirSync(path.join(flagDirectory, 'customMetadata'), { recursive: true });
        fs.writeFileSync(
            path.join(flagDirectory, 'package.xml'),
            [
                '<?xml version="1.0" encoding="UTF-8"?>',
                '<Package xmlns="http://soap.sforce.com/2006/04/metadata">',
                '    <types><members>Feature_Flag.P360_Archive_Processing</members><name>CustomMetadata</name></types>',
                '    <version>67.0</version>',
                '</Package>',
                ''
            ].join('\n')
        );
        fs.writeFileSync(
            path.join(flagDirectory, 'customMetadata', 'Feature_Flag.P360_Archive_Processing.md'),
            source.replace(FLAG_DISABLED, FLAG_ENABLED)
        );
        try {
            deploy(['--metadata-dir', flagDirectory], 'The temporary archive-processing flag');
            log('Archive-processing flag temporarily enabled in the scratch org.');
            const outcome = runApexScript('scripts/apex/p360ScratchSubmissionE2E.apex', 'P360_E2E_RESULT=');
            log(JSON.stringify(outcome, null, 2));
            const receipts = outcome.receipts ?? [];
            if (!(
                outcome.simulationOnly === true &&
                outcome.claimedJobs === 1 &&
                outcome.jobStatus === 'Succeeded' &&
                outcome.filesVerified === 2 &&
                outcome.callouts === 0 &&
                receipts.length === 2 &&
                receipts.every((receipt) => receipt.outcome === 'Accepted')
            )) {
                throw new ContractFailure(
                    'FAIL: The submission did not produce two accepted receipts in the scratch receiver.'
                );
            }
        } finally {
            try {
                deploy(['--source-dir', FLAG_SOURCE], 'The archive-processing flag from source');
                log('Archive-processing flag restored from source (Is_Enabled__c=false).');
            } catch {
                log(`WARNING: restore the archive-processing flag manually from ${FLAG_SOURCE}.`);
            }
        }
    }

    return {
        run(mode) {
            verifyTarget();
            if (mode === 'verify') deployScratchBundle();
            if (mode === 'verify' || mode === 'test') runTests(['P360_ScratchRpcClientTest']);
            if (mode === 'regression') {
                runTests([
                    'P360_ScratchRpcClientTest',
                    'P360_AdapterFactoryTest',
                    'AAREG_FileMapperTest',
                    'AAREG_CreateDocumentMapperTest'
                ]);
            }
            if (mode === 'verify' || mode === 'smoke') smoke();
            if (mode === 'verify' || mode === 'smoke' || mode === 'inspect') inspect();
            if (mode === 'e2e') endToEnd();
        }
    };
}

/**
 * Runs one scratch-only P360 contract mode against the verified crm-arbeidsforhold scratch org.
 *
 * @returns {number} 0 on success, 1 on a failed or refused check, 2 on an unknown mode.
 */
function main({
    mode = process.argv[2] ?? 'verify',
    runSf = runSfProcess,
    log = console.log,
    logError = console.error,
    tempRoot = os.tmpdir()
} = {}) {
    if (!MODES.includes(mode)) {
        logError(`Use ${MODES.join(', ')}.`);
        return 2;
    }
    const workDirectory = fs.mkdtempSync(path.join(tempRoot, 'p360-contract-'));
    try {
        createContract({ runSf, log, workDirectory }).run(mode);
        return 0;
    } catch (error) {
        logError(error instanceof ContractFailure ? error.message : error.stack);
        return error.exitCode ?? 1;
    } finally {
        fs.rmSync(workDirectory, { recursive: true, force: true });
    }
}

if (require.main === module) {
    // Ctrl+C still stops the running sf command; ignoring it here lets cleanup and flag restore run.
    process.on('SIGINT', () => {});
    process.exitCode = main();
}

module.exports = { FLAG_SOURCE, main, sfInvocation };
