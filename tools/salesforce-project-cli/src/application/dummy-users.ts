/**
 * Imports configured dummy users after the `data` post-step and assigns their permission sets.
 * Existing users and existing permission-set assignments are tolerated so the step can be re-run.
 */
import { mkdtemp, readFile, rm, writeFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import path from 'node:path';
import { EXIT_CODES, type ExitCode } from '../domain/events.js';
import type { CommandResult } from '../infrastructure/command-runner.js';
import { classifySalesforceFailure } from '../infrastructure/salesforce-errors.js';
import { runCommandStep, withCommandOutput, type CommandStepRunnerOptions } from './command-step-runner.js';

/** Inputs for importing the configured dummy users into one target org. */
export interface ImportDummyUsersOptions extends CommandStepRunnerOptions {
    /** Target org alias or username. */
    alias: string;
    /** When `true`, emits the planned work without invoking any command. */
    dryRun: boolean;
}

type UserRecord = Record<string, unknown> & { Username?: unknown };

function soqlString(value: string): string {
    return `'${value.replace(/\\/g, '\\\\').replace(/'/g, "\\'")}'`;
}

function parseJsonPayload(stdout: string): {
    result?: { records?: Array<Record<string, unknown>>; failures?: Array<{ message?: unknown }> };
} {
    // Some sf versions print a banner before the JSON payload.
    const start = stdout.indexOf('{');
    if (start < 0) return {};
    try {
        return JSON.parse(stdout.slice(start)) as ReturnType<typeof parseJsonPayload>;
    } catch {
        return {};
    }
}

function failed(result: CommandResult): boolean {
    return result.failed || result.exitCode !== 0;
}

function warn(options: ImportDummyUsersOptions, message: string): void {
    options.emit({
        kind: 'warning',
        operationId: options.operationId,
        timestamp: new Date().toISOString(),
        stepId: 'dummy-users',
        step: 'Import dummy users',
        message
    });
}

function stepFailed(options: ImportDummyUsersOptions, stepId: string, step: string, result: CommandResult): ExitCode {
    options.emit({
        kind: 'step-failed',
        operationId: options.operationId,
        timestamp: new Date().toISOString(),
        stepId,
        step,
        exitCode: result.exitCode,
        durationMs: result.durationMs,
        error: result.error || result.stderr || `${step} failed`
    });
    return classifySalesforceFailure(result, EXIT_CODES.OPERATION_FAILURE);
}

async function query(
    options: ImportDummyUsersOptions,
    stepId: string,
    step: string,
    soql: string
): Promise<CommandResult> {
    return options.runCommand(
        withCommandOutput(options, stepId, step, {
            executable: 'sf',
            arguments: ['data', 'query', '--target-org', options.alias, '--query', soql, '--json'],
            cwd: options.configuration.projectDirectory
        })
    );
}

async function importMissingUsers(options: ImportDummyUsersOptions, records: UserRecord[]): Promise<ExitCode> {
    const dummyUsers = options.configuration.dummyUsers;
    if (dummyUsers === undefined || records.length === 0) return EXIT_CODES.SUCCESS;

    const profileNameByUsername = new Map<string, string>();
    for (const assignment of dummyUsers.profileAssignments) {
        for (const username of assignment.usernames) profileNameByUsername.set(username, assignment.profileName);
    }
    const profileNames = [
        ...new Set(
            records.map((record) =>
                typeof record.Username === 'string'
                    ? (profileNameByUsername.get(record.Username) ?? dummyUsers.profileName)
                    : dummyUsers.profileName
            )
        )
    ];
    const profileIdByName = new Map<string, string>();
    for (const profileName of profileNames) {
        const profileResult = await query(
            options,
            `dummy-users:profile:${profileName}`,
            `Resolve ${profileName} profile`,
            `SELECT Id FROM Profile WHERE Name = ${soqlString(profileName)} LIMIT 1`
        );
        if (failed(profileResult)) {
            return stepFailed(
                options,
                `dummy-users:profile:${profileName}`,
                `Resolve ${profileName} profile`,
                profileResult
            );
        }
        const profileId = parseJsonPayload(profileResult.stdout).result?.records?.[0]?.Id;
        if (typeof profileId === 'string' && profileId.length > 0) {
            profileIdByName.set(profileName, profileId);
        } else {
            warn(
                options,
                `Profile ${profileName} was not found in ${options.alias}; users assigned to it will be skipped`
            );
        }
    }

    const eligibleRecords = records.filter((record) => {
        const profileName =
            typeof record.Username === 'string'
                ? (profileNameByUsername.get(record.Username) ?? dummyUsers.profileName)
                : dummyUsers.profileName;
        return profileIdByName.has(profileName);
    });
    if (eligibleRecords.length === 0) return EXIT_CODES.SUCCESS;

    const usernames = eligibleRecords.flatMap((record) =>
        typeof record.Username === 'string' ? [record.Username] : []
    );
    let existingUsernames = new Set<string>();
    if (usernames.length > 0) {
        const existingResult = await query(
            options,
            'dummy-users:existing',
            'Find existing dummy users',
            `SELECT Username FROM User WHERE Username IN (${usernames.map(soqlString).join(',')})`
        );
        if (failed(existingResult)) {
            return stepFailed(options, 'dummy-users:existing', 'Find existing dummy users', existingResult);
        }
        existingUsernames = new Set(
            (parseJsonPayload(existingResult.stdout).result?.records ?? []).flatMap((record) =>
                typeof record.Username === 'string' ? [record.Username] : []
            )
        );
    }

    const missingRecords = eligibleRecords
        .filter((record) => typeof record.Username !== 'string' || !existingUsernames.has(record.Username))
        .map((record) => {
            const profileName =
                typeof record.Username === 'string'
                    ? (profileNameByUsername.get(record.Username) ?? dummyUsers.profileName)
                    : dummyUsers.profileName;
            return { ...record, ProfileId: profileIdByName.get(profileName) };
        });
    if (missingRecords.length === 0) {
        options.emit({
            kind: 'progress',
            operationId: options.operationId,
            timestamp: new Date().toISOString(),
            stepId: 'dummy-users:import',
            step: 'Import dummy users',
            message: `All dummy users already exist in ${options.alias}`
        });
        return EXIT_CODES.SUCCESS;
    }

    const temporaryDirectory = await mkdtemp(path.join(tmpdir(), 'sf-project-dummy-users-'));
    try {
        const userFile = path.join(temporaryDirectory, 'User.json');
        await writeFile(userFile, JSON.stringify({ records: missingRecords }), 'utf8');
        return await runCommandStep(options, 'dummy-users:import', 'Import dummy users', 'sf', [
            'data',
            'import',
            'tree',
            '--target-org',
            options.alias,
            '--files',
            userFile
        ]);
    } finally {
        await rm(temporaryDirectory, { recursive: true, force: true });
    }
}

async function assignPermissionSets(options: ImportDummyUsersOptions): Promise<ExitCode> {
    const assignments = options.configuration.dummyUsers?.permissionSetAssignments ?? [];
    for (const assignment of assignments) {
        const stepId = 'dummy-users:permsets';
        const step = 'Assign dummy user permission sets';
        const result = await options.runCommand(
            withCommandOutput(options, stepId, step, {
                executable: 'sf',
                arguments: [
                    'org',
                    'assign',
                    'permset',
                    '--target-org',
                    options.alias,
                    ...assignment.permissionSets.flatMap((permissionSet) => ['--name', permissionSet]),
                    ...assignment.usernames.flatMap((username) => ['--on-behalf-of', username]),
                    '--json'
                ],
                cwd: options.configuration.projectDirectory
            })
        );
        if (!failed(result)) continue;
        const failures = parseJsonPayload(result.stdout).result?.failures ?? [];
        const onlyDuplicates =
            failures.length > 0 &&
            failures.every((failure) => String(failure.message ?? '').includes('Duplicate PermissionSetAssignment'));
        if (!onlyDuplicates) return stepFailed(options, stepId, step, result);
    }
    return EXIT_CODES.SUCCESS;
}

/**
 * Imports configured dummy users that do not already exist and assigns their permission sets.
 *
 * The user file's `ProfileId` is replaced with the profile resolved by name in the target org.
 * A missing user file or profile is reported as a warning; duplicate permission-set assignments
 * are tolerated. Dry-run mode emits the plan without invoking commands.
 *
 * @param options - Target org, dry-run flag, configuration, event sink, and command runner.
 * @returns Success, or the exit code of the first failed Salesforce command.
 */
export async function importDummyUsers(options: ImportDummyUsersOptions): Promise<ExitCode> {
    const dummyUsers = options.configuration.dummyUsers;
    if (dummyUsers === undefined) return EXIT_CODES.SUCCESS;

    if (options.dryRun) {
        const profileNames = [
            ...new Set([
                dummyUsers.profileName,
                ...dummyUsers.profileAssignments.map((assignment) => assignment.profileName)
            ])
        ];
        options.emit({
            kind: 'progress',
            operationId: options.operationId,
            timestamp: new Date().toISOString(),
            stepId: 'dummy-users',
            step: 'Import dummy users',
            message: `Would import missing users from ${dummyUsers.file} with profile(s) ${profileNames.join(', ')} and assign ${dummyUsers.permissionSetAssignments.length} permission set group(s)`,
            dryRun: true
        });
        return EXIT_CODES.SUCCESS;
    }

    let records: UserRecord[];
    try {
        const tree = JSON.parse(await readFile(dummyUsers.file, 'utf8')) as { records?: UserRecord[] };
        records = tree.records ?? [];
    } catch (error) {
        if (error instanceof Error && 'code' in error && error.code === 'ENOENT') {
            warn(options, `Dummy user file ${dummyUsers.file} was not found; dummy user import skipped`);
            return EXIT_CODES.SUCCESS;
        }
        throw error;
    }

    const importExitCode = await importMissingUsers(options, records);
    if (importExitCode !== EXIT_CODES.SUCCESS) return importExitCode;
    return assignPermissionSets(options);
}
