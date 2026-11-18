#!/usr/bin/env node
'use strict';

const { spawnSync } = require('node:child_process');
const crypto = require('node:crypto');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { ScratchTargetError, verifyScratchTarget } = require('./scratch-target.cjs');

const ROOT = path.resolve(__dirname, '..');
const MODES = ['verify', 'test', 'regression', 'smoke', 'inspect'];
const SCRATCH_BUNDLE = [
    ['scripts/scratch/p360/package.xml', 'package.xml'],
    ['scripts/scratch/p360/classes/P360_ScratchRpcClient.cls', 'classes'],
    ['scripts/scratch/p360/classes/P360_ScratchRpcClient.cls-meta.xml', 'classes'],
    ['scripts/scratch/p360/tests/P360_ScratchRpcClientTest.cls', 'classes'],
    ['scripts/scratch/p360/tests/P360_ScratchRpcClientTest.cls-meta.xml', 'classes'],
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
function sfInvocation(platform, args, target, environment = process.env) {
    if (platform === 'win32' && args.some((arg) => /[%!"\r\n]/.test(String(arg)))) {
        throw new ScratchTargetError('STOP: Unsafe Windows Salesforce CLI argument.');
    }
    const invocation =
        platform !== 'win32'
            ? { command: 'sf', args, shell: false }
            : { command: 'sf', args: args.map((arg) => `"${String(arg).replace(/"/g, '""')}"`), shell: true };
    if (target) {
        invocation.env = { ...environment, SF_TARGET_ORG: target, SFDX_DEFAULTUSERNAME: target };
    }
    return invocation;
}

function runSfProcess(args, { target } = {}) {
    const invocation = sfInvocation(process.platform, args, target);
    const result = spawnSync(invocation.command, invocation.args, {
        encoding: 'utf8',
        shell: invocation.shell,
        env: invocation.env,
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

function createContract({ runSf, log, workDirectory, expectedOrgId }) {
    let target;
    let runOnTarget;

    function deploy(args, description) {
        const result = runOnTarget([
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
        const result = runOnTarget([
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
        const result = runOnTarget(['org', 'assign', 'permset', '--target-org', target, '--name', name, '--json']);
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
        const result = runOnTarget([
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
        const result = runOnTarget([
            'data',
            'query',
            '--target-org',
            target,
            '--query',
            `SELECT Name, Operation__c, Outcome__c, Attempts__c, RequestBody__c FROM P360ScratchCapture__c WHERE RequestKey__c IN ('${caseKey}', '${documentKey}')`,
            '--json'
        ]);
        const records = result.result?.records ?? [];
        const document = records.find((record) => record.Operation__c === 'DocumentService/CreateDocument');
        const files = (document ? (JSON.parse(document.RequestBody__c).parameter?.Files ?? []) : [])
            .map((file) => Buffer.from(file.Base64Data, 'base64').toString('utf8'))
            .sort();
        const valid =
            result.status === 0 &&
            result.result?.totalSize === 2 &&
            records.length === 2 &&
            records.some((record) => record.Operation__c === 'CaseService/CreateCase') &&
            records.some((record) => record.Operation__c === 'DocumentService/CreateDocument') &&
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

    return {
        run(mode) {
            const verified = verifyScratchTarget(runSf, log, expectedOrgId);
            target = verified.target;
            runOnTarget = verified.runSf;
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
    expectedOrgId = process.env.AAREG_SCRATCH_ORG_ID,
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
        createContract({ runSf, log, workDirectory, expectedOrgId }).run(mode);
        return 0;
    } catch (error) {
        logError(error instanceof ContractFailure || error instanceof ScratchTargetError ? error.message : error.stack);
        return error.exitCode ?? 1;
    } finally {
        fs.rmSync(workDirectory, { recursive: true, force: true });
    }
}

if (require.main === module) {
    process.on('SIGINT', () => {});
    process.exitCode = main();
}

module.exports = { main, sfInvocation };
