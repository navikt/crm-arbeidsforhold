#!/usr/bin/env node
'use strict';

const { spawnSync } = require('node:child_process');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { sfInvocation } = require('./p360-scratch-contract.cjs');
const { ScratchTargetError, verifyScratchTarget } = require('./scratch-target.cjs');

const ROOT = path.resolve(__dirname, '..');
const FLAG_DIRECTORY = path.join(ROOT, 'force-app/contactModel/customMetadata');
const FLAGS = [
    'AAREG_ContactModel_ShadowWrite',
    'AAREG_ContactModel_OrgSelector',
    'AAREG_ContactModel_Profile',
    'AAREG_ContactModel_ContextAddress',
    'AAREG_ContactModel_LegacyMatchingOff'
];
const PILOT_PERMISSION = 'AAREG_ContactModelPilot';
const FLAG_SCOPES = ['off', 'pilot', 'all'];
const RUN_MODES = { plan: 'PLAN', apply: 'APPLY', verify: 'VERIFY', rollback: 'ROLLBACK' };
const MODES = ['status', 'setup', 'seed', 'flags', ...Object.keys(RUN_MODES)];
const SEED_DIRECTORY = path.join(ROOT, 'scripts/scratch/contactModel');
const SEED_STEPS = ['seed-1-people.apex', 'seed-2-users.apex', 'seed-3-applications.apex'];
const SEED_PERMISSION_SET = 'AAREG_ContactModel_ScratchSeed';
const PERMISSION_SETS = ['AAREG_ContactModel_Admin', 'AAREG_ContactModel_Pilot'];
const RESULT_MARKER = 'AAREG_CONTACT_MODEL_RESULT=';
const RUN_FIELDS =
    'Id, Name, Mode__c, Status__c, Total__c, Class_A__c, Class_B__c, Class_C__c, Class_D__c, Class_E__c, ' +
    'Linked__c, Deviations__c, Rolled_Back__c, Failed__c, Summary__c, Source_Run__c, CreatedDate';
const POLL_SECONDS = 5;
const POLL_LIMIT = 120;

class RunnerFailure extends Error {
    constructor(message, exitCode = 1) {
        super(message);
        this.exitCode = exitCode;
    }
}

function runSfProcess(args, { target } = {}) {
    const invocation = sfInvocation(process.platform, args, target);
    const result = spawnSync(invocation.command, invocation.args, {
        encoding: 'utf8',
        shell: invocation.shell,
        env: invocation.env,
        cwd: ROOT,
        maxBuffer: 64 * 1024 * 1024
    });
    if (result.error) {
        throw new RunnerFailure(`Unable to start the Salesforce CLI (sf): ${result.error.message}`);
    }
    const start = result.stdout.indexOf('{');
    try {
        return JSON.parse(result.stdout.slice(start));
    } catch {
        throw new RunnerFailure(
            `The Salesforce CLI returned no JSON for "sf ${args[0]} ${args[1]}".\n${result.stderr}`
        );
    }
}

function sleep(seconds) {
    Atomics.wait(new Int32Array(new SharedArrayBuffer(4)), 0, 0, seconds * 1000);
}

/**
 * Returns the flag record with Is_Enabled__c and Required_Custom_Permission__c set for the scope.
 * The source file stays unchanged; it always ships with every flag off.
 *
 * @param {string} source Feature_Flag__mdt record XML from the repository.
 * @param {'off'|'pilot'|'all'} scope Off, pilot users only, or every user.
 * @returns {string} Record XML to deploy.
 */
function flagRecord(source, scope) {
    const enabled = scope !== 'off';
    const permission =
        scope === 'pilot' ? `<value xsi:type="xsd:string">${PILOT_PERMISSION}</value>` : '<value xsi:nil="true"/>';
    const withEnabled = source.replace(
        /(<field>Is_Enabled__c<\/field>\s*)<value[^>]*>(true|false)<\/value>/,
        `$1<value xsi:type="xsd:boolean">${enabled}</value>`
    );
    const withPermission = withEnabled.replace(
        /(<field>Required_Custom_Permission__c<\/field>\s*)<value[^>]*?(\/>|>[^<]*<\/value>)/,
        `$1${permission}`
    );
    if (!withPermission.includes(`<value xsi:type="xsd:boolean">${enabled}</value>`)) {
        throw new RunnerFailure('FAIL: The flag record has an unexpected format.');
    }
    return withPermission;
}

function createRunner({ runSf, log, workDirectory, expectedOrgId }) {
    let target;
    let runOnTarget;

    function query(soql) {
        const result = runOnTarget(['data', 'query', '--target-org', target, '--query', soql, '--json']);
        if (result.status !== 0) {
            throw new RunnerFailure(`FAIL: Query failed: ${result.message}`);
        }
        return result.result.records ?? [];
    }

    function runApex(expression, preamble = '') {
        const file = path.join(workDirectory, 'contact-model.apex');
        fs.writeFileSync(
            file,
            `${preamble}System.debug(LoggingLevel.INFO, '${RESULT_MARKER}' + JSON.serialize(${expression}));\n`
        );
        const result = runOnTarget(['apex', 'run', '--target-org', target, '--file', file, '--json']);
        if (result.status !== 0 || result.result?.success !== true) {
            throw new RunnerFailure(
                `FAIL: ${expression} did not succeed: ${
                    result.result?.compileProblem || result.result?.exceptionMessage || result.message
                }`
            );
        }
        const line = String(result.result.logs ?? '')
            .split('\n')
            .find((entry) => entry.includes('|USER_DEBUG|') && entry.includes(RESULT_MARKER));
        return line ? JSON.parse(line.split(RESULT_MARKER)[1]) : null;
    }

    function status() {
        const flags = query(
            'SELECT DeveloperName, Is_Enabled__c, Required_Custom_Permission__c FROM Feature_Flag__mdt ' +
                "WHERE DeveloperName LIKE 'AAREG_ContactModel_%' ORDER BY DeveloperName"
        );
        log('Flags:');
        for (const flag of flags) {
            const scope = !flag.Is_Enabled__c ? 'off' : flag.Required_Custom_Permission__c ? 'pilot' : 'all';
            log(`  ${flag.DeveloperName.padEnd(40)} ${scope}`);
        }
        const runs = query(
            `SELECT ${RUN_FIELDS} FROM AAREG_Contact_Migration_Run__c ORDER BY CreatedDate DESC LIMIT 5`
        );
        log('Latest runs:');
        for (const run of runs) {
            log(`  ${describeRun(run)}`);
        }
        log(
            `Contact points: ${countOf('SELECT COUNT() FROM AAREG_Contact_Point__c')}, ` +
                `participations with role: ${countOf('SELECT COUNT() FROM RelatedContact__c WHERE Role__c != null')}`
        );
    }

    function countOf(soql) {
        const result = runOnTarget(['data', 'query', '--target-org', target, '--query', soql, '--json']);
        if (result.status !== 0) {
            throw new RunnerFailure(`FAIL: Query failed: ${result.message}`);
        }
        return result.result.totalSize ?? 0;
    }

    function describeRun(run) {
        return (
            `${run.Name} ${run.Mode__c} ${run.Status__c} total=${run.Total__c ?? 0} ` +
            `A=${run.Class_A__c ?? 0} B=${run.Class_B__c ?? 0} C=${run.Class_C__c ?? 0} ` +
            `D=${run.Class_D__c ?? 0} E=${run.Class_E__c ?? 0} linked=${run.Linked__c ?? 0} ` +
            `deviations=${run.Deviations__c ?? 0} rolledBack=${run.Rolled_Back__c ?? 0} failed=${run.Failed__c ?? 0}`
        );
    }

    function assignPermissionSets(names = PERMISSION_SETS) {
        for (const name of names) {
            const result = runOnTarget(['org', 'assign', 'permset', '--target-org', target, '--name', name, '--json']);
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

    function setup() {
        assignPermissionSets();
        const accountId = runApex(
            'AAREG_ContactModelService.setUpPrimaryAccount()',
            'if (AAREG_Default_Settings__c.getOrgDefaults().Id == null) { ' +
                "Contact standard = new Contact(LastName = 'Aa-registeret standardkontakt (scratch)'); " +
                'insert standard; ' +
                'insert new AAREG_Default_Settings__c(SetupOwnerId = UserInfo.getOrganizationId(), ' +
                'Default_Contact__c = standard.Id); }\n'
        );
        log(`Primary account: ${accountId}`);
    }

    function deployMetadataDirectory(directory, description) {
        const result = runOnTarget([
            'project',
            'deploy',
            'start',
            '--metadata-dir',
            directory,
            '--target-org',
            target,
            '--test-level',
            'NoTestRun',
            '--wait',
            '15',
            '--json'
        ]);
        if (result.status !== 0 || result.result?.success !== true) {
            throw new RunnerFailure(`FAIL: ${description} did not deploy: ${result.message ?? 'see deploy result'}`);
        }
    }

    function runApexFile(name) {
        const result = runOnTarget([
            'apex',
            'run',
            '--target-org',
            target,
            '--file',
            path.join(SEED_DIRECTORY, name),
            '--json'
        ]);
        if (result.status !== 0 || result.result?.success !== true) {
            throw new RunnerFailure(
                `FAIL: ${name} did not succeed: ${
                    result.result?.compileProblem || result.result?.exceptionMessage || result.message
                }`
            );
        }
        const line = String(result.result.logs ?? '')
            .split('\n')
            .find((entry) => entry.includes('|USER_DEBUG|') && entry.includes(RESULT_MARKER));
        log(`${name}: ${line ? line.split(RESULT_MARKER)[1] : 'done'}`);
    }

    function enableAuditFields() {
        const open = runOnTarget([
            'org',
            'open',
            '--target-org',
            target,
            '--url-only',
            '--path',
            '/ui/setup/org/UserInterfaceUI',
            '--json'
        ]);
        if (open.status !== 0 || !open.result?.url) {
            throw new RunnerFailure('FAIL: Could not open the scratch Setup page.');
        }
        const result = spawnSync(process.execPath, [path.join(SEED_DIRECTORY, 'enable-audit-fields.cjs')], {
            encoding: 'utf8',
            cwd: ROOT,
            env: { ...process.env, AAREG_FRONTDOOR_URL: open.result.url }
        });
        if (result.status !== 0) {
            throw new RunnerFailure(`FAIL: Could not enable the audit field preference. ${result.stderr}`);
        }
        log(result.stdout.trim());
    }

    function seed() {
        enableAuditFields();
        deployMetadataDirectory(SEED_DIRECTORY, 'The scratch seed permission set');
        assignPermissionSets([SEED_PERMISSION_SET]);
        for (const step of SEED_STEPS) {
            runApexFile(step);
        }
    }

    function setFlags(scope) {
        const directory = path.join(workDirectory, 'flags');
        fs.mkdirSync(path.join(directory, 'customMetadata'), { recursive: true });
        for (const flag of FLAGS) {
            const source = fs.readFileSync(path.join(FLAG_DIRECTORY, `Feature_Flag.${flag}.md-meta.xml`), 'utf8');
            fs.writeFileSync(
                path.join(directory, 'customMetadata', `Feature_Flag.${flag}.md`),
                flagRecord(source, scope)
            );
        }
        fs.writeFileSync(
            path.join(directory, 'package.xml'),
            '<?xml version="1.0" encoding="UTF-8"?>\n<Package xmlns="http://soap.sforce.com/2006/04/metadata">\n' +
                '    <types>\n' +
                FLAGS.map((flag) => `        <members>Feature_Flag.${flag}</members>\n`).join('') +
                '        <name>CustomMetadata</name>\n    </types>\n    <version>67.0</version>\n</Package>\n'
        );
        deployMetadataDirectory(directory, 'The contact model flags');
        log(`Contact model flags set to "${scope}" in the scratch org. The repository keeps every flag off.`);
    }

    function latestApplyRunId() {
        const runs = query(
            "SELECT Id FROM AAREG_Contact_Migration_Run__c WHERE Mode__c = 'APPLY' AND Status__c = 'Completed' " +
                'ORDER BY CreatedDate DESC LIMIT 1'
        );
        if (runs.length === 0) {
            throw new RunnerFailure('FAIL: No completed APPLY run exists. Run apply first.');
        }
        return runs[0].Id;
    }

    function startRun(mode) {
        const source = mode === 'VERIFY' || mode === 'ROLLBACK' ? `'${latestApplyRunId()}'` : 'null';
        const runId = runApex(`AAREG_ContactMigrationBatch.startRun('${mode}', ${source})`);
        log(`Started ${mode}: ${runId}`);
        for (let attempt = 0; attempt < POLL_LIMIT; attempt += 1) {
            const [run] = query(`SELECT ${RUN_FIELDS} FROM AAREG_Contact_Migration_Run__c WHERE Id = '${runId}'`);
            if (run && (run.Status__c === 'Completed' || run.Status__c === 'Failed')) {
                log(describeRun(run));
                if (run.Summary__c) log(run.Summary__c);
                if (run.Status__c === 'Failed') {
                    throw new RunnerFailure(`FAIL: ${mode} failed.`);
                }
                return run;
            }
            sleep(POLL_SECONDS);
        }
        throw new RunnerFailure(`FAIL: ${mode} did not finish within ${(POLL_LIMIT * POLL_SECONDS) / 60} minutes.`);
    }

    return {
        run(mode, argument) {
            const verified = verifyScratchTarget(runSf, log, expectedOrgId);
            target = verified.target;
            runOnTarget = verified.runSf;
            if (mode === 'status') return status();
            if (mode === 'setup') return setup();
            if (mode === 'seed') return seed();
            if (mode === 'flags') return setFlags(argument);
            return startRun(RUN_MODES[mode]);
        }
    };
}

/**
 * Operates the Aa-register contact model in the verified crm-arbeidsforhold scratch org only:
 * status, setup, synthetic seed data, feature flags and migration runs (plan, apply, verify, rollback).
 *
 * @returns {number} 0 on success, 1 on a failed or refused check, 2 on an unknown mode or argument.
 */
function main({
    mode = process.argv[2] ?? 'status',
    argument = process.argv[3],
    runSf = runSfProcess,
    expectedOrgId = process.env.AAREG_SCRATCH_ORG_ID,
    log = console.log,
    logError = console.error
} = {}) {
    if (!MODES.includes(mode)) {
        logError(`Use ${MODES.join(', ')}.`);
        return 2;
    }
    if (mode === 'flags' && !FLAG_SCOPES.includes(argument)) {
        logError(`Choose a flag scope: ${FLAG_SCOPES.join(', ')}.`);
        return 2;
    }
    const workDirectory = fs.mkdtempSync(path.join(os.tmpdir(), 'aareg-contact-model-'));
    try {
        createRunner({ runSf, log, workDirectory, expectedOrgId }).run(mode, argument);
        return 0;
    } catch (error) {
        logError(error instanceof RunnerFailure || error instanceof ScratchTargetError ? error.message : error.stack);
        return error.exitCode ?? 1;
    } finally {
        fs.rmSync(workDirectory, { recursive: true, force: true });
    }
}

if (require.main === module) {
    process.exitCode = main();
}

module.exports = { FLAGS, FLAG_SCOPES, MODES, flagRecord, main };
