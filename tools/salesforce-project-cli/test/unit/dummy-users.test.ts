import { mkdtemp, readFile, rm, writeFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import path from 'node:path';
import { afterEach, describe, expect, it, vi } from 'vitest';
import { configureProject } from '../../src/application/org-workflow.js';
import type { ProjectConfiguration } from '../../src/domain/config.js';
import { EXIT_CODES } from '../../src/domain/events.js';
import type { CommandRequest, CommandResult } from '../../src/infrastructure/command-runner.js';

const temporaryDirectories: string[] = [];

afterEach(async () => {
    await Promise.all(
        temporaryDirectories.splice(0).map((directory) => rm(directory, { force: true, recursive: true }))
    );
});

function result(request: CommandRequest, stdout = '', exitCode = 0): CommandResult {
    return {
        executable: request.executable,
        arguments: [...(request.arguments ?? [])],
        exitCode,
        failed: exitCode !== 0,
        stdout,
        stderr: '',
        durationMs: 0,
        timedOut: false,
        canceled: false,
        attempts: 1,
        error: ''
    };
}

async function createProject(records: Array<Record<string, unknown>>): Promise<ProjectConfiguration> {
    const projectDirectory = await mkdtemp(path.join(tmpdir(), 'sf-project-dummy-users-'));
    temporaryDirectories.push(projectDirectory);
    const userFile = path.join(projectDirectory, 'User.json');
    await writeFile(userFile, JSON.stringify({ records }));
    return {
        projectDirectory,
        preserveRootFiles: ['README.md'],
        dependencySources: [],
        unresolvedDependencyNames: [],
        packageDependencies: [],
        packageInstallKeyEnvironmentVariable: 'PACKAGE_INSTALL_KEY',
        commandTimeouts: { readMs: 30_000, mutationMs: 600_000 },
        scratchDefinition: path.join(projectDirectory, 'config/project-scratch-def.json'),
        scratchDurationDays: 14,
        permissionSets: [],
        dummyDataPlan: path.join(projectDirectory, 'Plan.json'),
        communityName: null,
        dummyUsers: {
            file: userFile,
            profileName: "O'Profile",
            permissionSetAssignments: [
                { permissionSets: ['P1', 'P2'], usernames: ['new@example.test', 'existing@example.test'] }
            ]
        },
        postSteps: ['data'],
        customPostSteps: [],
        pool: { use: false, tag: 'dev', fallbackToCreate: true }
    };
}

function configure(
    configuration: ProjectConfiguration,
    runCommand: (request: CommandRequest) => Promise<CommandResult>,
    dryRun = false
) {
    return configureProject({
        configuration,
        alias: 'scratch-a',
        postSteps: ['data'],
        skipPackages: true,
        refreshDependencySources: false,
        dryRun,
        environment: {},
        operationId: 'dummy-users',
        emit: vi.fn(),
        runCommand
    });
}

describe('dummy user import in the data post-step', () => {
    it('imports only missing users with the resolved profile and assigns permission sets', async () => {
        const configuration = await createProject([
            { attributes: { type: 'User', referenceId: 'U1' }, Username: 'new@example.test' },
            { attributes: { type: 'User', referenceId: 'U2' }, Username: 'existing@example.test' }
        ]);
        const commands: string[][] = [];
        let importedUsers: unknown;
        const runCommand = vi.fn(async (request: CommandRequest) => {
            const commandArguments = [...(request.arguments ?? [])];
            commands.push(commandArguments);
            const query = commandArguments[commandArguments.indexOf('--query') + 1] ?? '';
            if (query.startsWith('SELECT Id FROM Profile')) {
                return result(request, 'banner\n{"status":0,"result":{"records":[{"Id":"00e000000000001"}]}}');
            }
            if (query.startsWith('SELECT Username FROM User')) {
                return result(request, '{"status":0,"result":{"records":[{"Username":"existing@example.test"}]}}');
            }
            const filesIndex = commandArguments.indexOf('--files');
            if (filesIndex >= 0) {
                importedUsers = JSON.parse(await readFile(commandArguments[filesIndex + 1] ?? '', 'utf8'));
            }
            return result(request, '{"status":0,"result":{}}');
        });

        await expect(configure(configuration, runCommand)).resolves.toBe(EXIT_CODES.SUCCESS);

        const profileQuery = commands.find((command) =>
            command.some((argument) => argument.startsWith('SELECT Id FROM Profile'))
        );
        expect(profileQuery).toContain("SELECT Id FROM Profile WHERE Name = 'O\\'Profile' LIMIT 1");
        expect(importedUsers).toEqual({
            records: [
                {
                    attributes: { type: 'User', referenceId: 'U1' },
                    Username: 'new@example.test',
                    ProfileId: '00e000000000001'
                }
            ]
        });
        expect(commands).toContainEqual([
            'org',
            'assign',
            'permset',
            '--target-org',
            'scratch-a',
            '--name',
            'P1',
            '--name',
            'P2',
            '--on-behalf-of',
            'new@example.test',
            '--on-behalf-of',
            'existing@example.test',
            '--json'
        ]);
    });

    it('tolerates duplicate permission set assignments', async () => {
        const configuration = await createProject([]);
        const runCommand = vi.fn(async (request: CommandRequest) => {
            if ((request.arguments ?? []).includes('permset')) {
                return result(
                    request,
                    '{"status":1,"result":{"failures":[{"message":"Duplicate PermissionSetAssignment"}]}}',
                    1
                );
            }
            return result(request, '{"status":0,"result":{"records":[{"Id":"00e000000000001"}]}}');
        });

        await expect(configure(configuration, runCommand)).resolves.toBe(EXIT_CODES.SUCCESS);
    });

    it('fails the data step when a permission set assignment fails for another reason', async () => {
        const configuration = await createProject([]);
        const runCommand = vi.fn(async (request: CommandRequest) => {
            if ((request.arguments ?? []).includes('permset')) {
                return result(
                    request,
                    '{"status":1,"result":{"failures":[{"message":"Permission set not found"}]}}',
                    1
                );
            }
            return result(request, '{"status":0,"result":{"records":[{"Id":"00e000000000001"}]}}');
        });

        await expect(configure(configuration, runCommand)).resolves.not.toBe(EXIT_CODES.SUCCESS);
    });

    it('issues no dummy user command in dry-run mode', async () => {
        const configuration = await createProject([{ Username: 'new@example.test' }]);
        const runCommand = vi.fn();

        await expect(configure(configuration, runCommand, true)).resolves.toBe(EXIT_CODES.SUCCESS);
        expect(runCommand).not.toHaveBeenCalled();
    });
});
