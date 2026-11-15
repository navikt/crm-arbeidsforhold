#!/usr/bin/env node
'use strict';

const { spawnSync } = require('node:child_process');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { sfInvocation } = require('./p360-scratch-contract.cjs');

const ORG = 'crm-arbeidsforhold';
const ROOT = path.resolve(__dirname, '..');
const MODES = ['verify', 'test', 'seed', 'reset', 'inspect'];
const TESTLAB_SCENARIOS = ['soknad-ny', 'p360-arkivert', 'p360-feila', 'p360-manuell', 'p360-utgatt-lease'];
const TESTLAB_MARKER = 'AAREG_TESTLAB_RESULT=';
const TESTLAB_BUNDLE = [
    ['scripts/scratch/admin/package.xml', 'package.xml'],
    ['scripts/scratch/admin/classes/AAREG_AdminTestLab.cls', 'classes'],
    ['scripts/scratch/admin/classes/AAREG_AdminTestLab.cls-meta.xml', 'classes'],
    ['force-app/tests/classes/internalAdmin/scratch/AAREG_AdminTestLabTest.cls', 'classes'],
    ['force-app/tests/classes/internalAdmin/scratch/AAREG_AdminTestLabTest.cls-meta.xml', 'classes']
];
const SCRATCH_URL = /^https:\/\/[a-zA-Z0-9.-]+\.scratch\.my\.salesforce\.com$/;
const ADMIN_SOURCES = [
    'force-app/internalAdmin',
    'force-app/tests/classes/internalAdmin',
    'force-app/main/default/flexipages/Aa_AdminHomePage.flexipage-meta.xml',
    'force-app/main/default/applications/Arbeidsforhold_Admin.app-meta.xml',
    'force-app/main/default/objects/Application__c/fields/Status__c.field-meta.xml',
    'force-app/main/default/objects/Application__c/fields/Casehandler_Status__c.field-meta.xml',
    'force-app/main/default/objects/Application__c/fields/CasehandlerOwner__c.field-meta.xml',
    'force-app/main/default/objects/Application__c/fields/ApplicationDeadlineForReply__c.field-meta.xml',
    'force-app/main/default/objects/Application_Decision__c/fields/Process_status__c.field-meta.xml',
    'force-app/main/default/objects/Inquiry__c/fields/Status__c.field-meta.xml'
];
const ADMIN_TESTS = [
    'AAREG_AdminOverviewControllerTest',
    'AAREG_AdminConfigurationControllerTest',
    'AAREG_AdminMonitorControllerTest',
    'AAREG_AdminAccessDiagnosisControllerTest',
    'AAREG_AdminJourneyControllerTest'
];
const PERMISSION_SETS = ['AAREG_Admin_Viewer'];

class RunnerFailure extends Error {
    constructor(message, exitCode = 1) {
        super(message);
        this.exitCode = exitCode;
    }
}

function runSfProcess(args) {
    const invocation = sfInvocation(process.platform, args);
    const result = spawnSync(invocation.command, invocation.args, {
        encoding: 'utf8',
        shell: invocation.shell,
        maxBuffer: 64 * 1024 * 1024
    });
    if (result.error) {
        throw new RunnerFailure(`Unable to start the Salesforce CLI (sf): ${result.error.message}`);
    }
    try {
        return JSON.parse(result.stdout);
    } catch {
        throw new RunnerFailure(
            `The Salesforce CLI returned no JSON for "sf ${args[0]} ${args[1]}".\n${result.stderr}`
        );
    }
}

function summarize(result) {
    const value = result.result ?? {};
    return {
        status: result.status,
        success: value.success,
        componentFailures: value.details?.componentFailures,
        summary: value.summary && {
            outcome: value.summary.outcome,
            testsRan: value.summary.testsRan,
            passing: value.summary.passing,
            failing: value.summary.failing
        },
        tests: (value.tests ?? []).map(({ FullName, Outcome, Message }) => ({ FullName, Outcome, Message })),
        error: result.message
    };
}

function createRunner({ runSf, log, workDirectory }) {
    let target;

    function verifyTarget() {
        const orgs = runSf(['org', 'list', '--skip-connection-status', '--json']);
        const matches = (orgs.result?.scratchOrgs ?? []).filter(
            (org) => org.alias === ORG && org.isScratch === true && SCRATCH_URL.test(org.instanceUrl ?? '')
        );
        if (matches.length !== 1 || typeof matches[0].username !== 'string' || !matches[0].username) {
            throw new RunnerFailure('STOP: The explicit target is not a locally identified scratch org.');
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
            throw new RunnerFailure('STOP: The target org did not confirm IsSandbox=true.');
        }
        log('Target verified: crm-arbeidsforhold, scratch domain and IsSandbox=true.');
    }

    function deploy(extra, description) {
        const result = runSf([
            'project',
            'deploy',
            'start',
            ...ADMIN_SOURCES.flatMap((source) => ['--source-dir', source]),
            ...extra,
            '--target-org',
            target,
            '--test-level',
            'NoTestRun',
            '--wait',
            '15',
            '--json'
        ]);
        log(`${description}: ${JSON.stringify(summarize(result), null, 2)}`);
        if (result.status !== 0 || result.result?.success !== true) {
            throw new RunnerFailure(`FAIL: ${description} did not succeed.`);
        }
    }

    function assignPermissionSets() {
        for (const name of PERMISSION_SETS) {
            const result = runSf(['org', 'assign', 'permset', '--target-org', target, '--name', name, '--json']);
            const failures = result.result?.failures ?? [];
            const accepted =
                (result.result?.successes ?? []).length + failures.length > 0 &&
                failures.every((failure) => String(failure.message).includes('Duplicate PermissionSetAssignment'));
            if (!accepted) {
                throw new RunnerFailure(`FAIL: ${name} could not be assigned to the scratch CLI user.`);
            }
            log(`Permission set assigned: ${name}`);
        }
    }

    function deployTestLab() {
        const directory = path.join(workDirectory, 'testlab');
        for (const [source, folder] of TESTLAB_BUNDLE) {
            const destination = folder === 'package.xml' ? directory : path.join(directory, folder);
            fs.mkdirSync(destination, { recursive: true });
            fs.copyFileSync(path.join(ROOT, source), path.join(destination, path.basename(source)));
        }
        for (const [extra, description] of [
            [['--dry-run'], 'Test lab deploy preview'],
            [[], 'Test lab deploy']
        ]) {
            const result = runSf([
                'project',
                'deploy',
                'start',
                '--metadata-dir',
                directory,
                ...extra,
                '--target-org',
                target,
                '--wait',
                '15',
                '--json'
            ]);
            log(`${description}: ${JSON.stringify(summarize(result), null, 2)}`);
            if (result.status !== 0 || result.result?.success !== true) {
                throw new RunnerFailure(`FAIL: ${description} did not succeed.`);
            }
        }
    }

    function runTestLab(call) {
        const file = path.join(workDirectory, 'testlab.apex');
        fs.writeFileSync(
            file,
            `System.debug(LoggingLevel.INFO, '${TESTLAB_MARKER}' + JSON.serialize(AAREG_AdminTestLab.${call}));\n`
        );
        const result = runSf(['apex', 'run', '--target-org', target, '--file', file, '--json']);
        if (result.status !== 0 || result.result?.compiled !== true || result.result?.success !== true) {
            log(
                JSON.stringify(
                    {
                        compileProblem: result.result?.compileProblem,
                        exceptionMessage: result.result?.exceptionMessage,
                        error: result.message
                    },
                    null,
                    2
                )
            );
            throw new RunnerFailure(`FAIL: The test lab operation ${call} did not succeed.`);
        }
        const line = String(result.result.logs ?? '')
            .split('\n')
            .find((entry) => entry.includes('|USER_DEBUG|') && entry.includes(TESTLAB_MARKER));
        if (!line) {
            throw new RunnerFailure(`FAIL: The test lab operation ${call} reported no result.`);
        }
        const report = JSON.parse(line.split(TESTLAB_MARKER)[1]);
        log(JSON.stringify(report, null, 2));
        if (report.callouts !== 0) {
            throw new RunnerFailure(`FAIL: The test lab made ${report.callouts} callout(s); it must make none.`);
        }
        return report;
    }

    function runTests(classNames = ADMIN_TESTS) {
        const result = runSf([
            'apex',
            'run',
            'test',
            '--target-org',
            target,
            ...classNames.flatMap((name) => ['--tests', name]),
            ...(classNames.length === 1 ? ['--synchronous'] : []),
            '--wait',
            '15',
            '--json'
        ]);
        log(JSON.stringify(summarize(result), null, 2));
        if (result.status !== 0 || result.result?.summary?.outcome !== 'Passed') {
            throw new RunnerFailure('FAIL: Apex tests did not pass.');
        }
    }

    return {
        run(mode, scenario) {
            verifyTarget();
            if (mode === 'seed') {
                deployTestLab();
                runTests(['AAREG_AdminTestLabTest']);
                runTestLab(`seed('${scenario}')`);
                return;
            }
            if (mode === 'reset' || mode === 'inspect') {
                runTestLab(`${mode}()`);
                return;
            }
            if (mode === 'verify') {
                deploy(['--dry-run'], 'Deploy preview');
                deploy([], 'Deploy');
                assignPermissionSets();
            }
            runTests();
        }
    };
}

/**
 * Deploys and tests the Arbeidsforhold Admin app, or seeds, inspects and resets synthetic test lab scenarios,
 * in the verified crm-arbeidsforhold scratch org only.
 *
 * @returns {number} 0 on success, 1 on a failed or refused check, 2 on an unknown mode or scenario.
 */
function main({
    mode = process.argv[2] ?? 'verify',
    scenario = process.argv[3],
    runSf = runSfProcess,
    log = console.log,
    logError = console.error
} = {}) {
    if (!MODES.includes(mode)) {
        logError(`Use ${MODES.join(', ')}.`);
        return 2;
    }
    if (mode === 'seed' && !TESTLAB_SCENARIOS.includes(scenario)) {
        logError(`Choose a scenario: ${TESTLAB_SCENARIOS.join(', ')}.`);
        return 2;
    }
    const workDirectory = fs.mkdtempSync(path.join(os.tmpdir(), 'aareg-admin-'));
    try {
        createRunner({ runSf, log, workDirectory }).run(mode, scenario);
        return 0;
    } catch (error) {
        logError(error instanceof RunnerFailure ? error.message : error.stack);
        return error.exitCode ?? 1;
    } finally {
        fs.rmSync(workDirectory, { recursive: true, force: true });
    }
}

if (require.main === module) {
    process.exitCode = main();
}

module.exports = { ADMIN_SOURCES, ADMIN_TESTS, TESTLAB_SCENARIOS, main };
