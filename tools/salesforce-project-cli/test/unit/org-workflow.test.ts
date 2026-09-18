import { describe, expect, it, vi } from 'vitest';
import { configureProject, createOrg } from '../../src/application/org-workflow.js';
import type { ProjectConfiguration } from '../../src/domain/config.js';
import { EXIT_CODES } from '../../src/domain/events.js';

const configuration: ProjectConfiguration = {
    projectDirectory: '/project',
    preserveRootFiles: ['README.md'],
    dependencySources: [],
    unresolvedDependencyNames: [],
    packageDependencies: [],
    packageInstallKeyEnvironmentVariable: 'PACKAGE_INSTALL_KEY',
    scratchDefinition: '/project/config/project-scratch-def.json',
    scratchDurationDays: 14,
    permissionSets: [],
    dummyDataPlan: null,
    communityName: null,
    postSteps: ['deploy'],
    customPostSteps: [],
    pool: { use: false, tag: 'dev', fallbackToCreate: true },
    defaultOrgAlias: 'configured-org'
};

describe('configure project', () => {
    it('uses the configured default alias when no explicit alias is provided', async () => {
        const emit = vi.fn();
        const runCommand = vi.fn();

        await expect(
            configureProject({
                configuration,
                postSteps: ['deploy'],
                refreshDependencySources: false,
                dryRun: true,
                environment: {},
                operationId: 'configure-default',
                emit,
                runCommand
            })
        ).resolves.toBe(EXIT_CODES.SUCCESS);

        expect(emit).toHaveBeenCalledWith(expect.objectContaining({ kind: 'org-summary', alias: 'configured-org' }));
        expect(runCommand).not.toHaveBeenCalled();
    });

    it('skips package installation and issues no package command when skipPackages is set', async () => {
        const emit = vi.fn();
        const runCommand = vi.fn(async () => ({
            executable: 'sf',
            arguments: [] as string[],
            exitCode: 0,
            failed: false,
            stdout: '',
            stderr: '',
            durationMs: 0,
            timedOut: false,
            canceled: false,
            attempts: 1,
            error: ''
        }));

        await expect(
            configureProject({
                configuration,
                alias: 'configured-org',
                postSteps: [],
                skipPackages: true,
                refreshDependencySources: false,
                dryRun: false,
                environment: {},
                operationId: 'configure-skip-packages',
                emit,
                runCommand
            })
        ).resolves.toBe(EXIT_CODES.SUCCESS);

        expect(emit).toHaveBeenCalledWith(
            expect.objectContaining({
                kind: 'progress',
                stepId: 'packages:install',
                message: 'Package installation skipped (--skip-packages)'
            })
        );
        expect(runCommand).not.toHaveBeenCalled();
    });

    it('rejects an unknown post-step without invoking the command runner', async () => {
        const emit = vi.fn();
        const runCommand = vi.fn();

        await expect(
            configureProject({
                configuration,
                alias: 'configured-org',
                postSteps: ['not-a-real-step'],
                refreshDependencySources: false,
                dryRun: false,
                environment: {},
                operationId: 'configure-unknown-step',
                emit,
                runCommand
            })
        ).resolves.toBe(EXIT_CODES.INVALID_INPUT_OR_CONFIG);

        expect(emit).toHaveBeenCalledWith(
            expect.objectContaining({ kind: 'step-failed', stepId: 'configure:post-steps' })
        );
        expect(runCommand).not.toHaveBeenCalled();
    });

    it('runs a declared custom post-step with its configured executable and arguments', async () => {
        const emit = vi.fn();
        const runCommand = vi.fn(async () => ({
            executable: 'sf',
            arguments: [] as string[],
            exitCode: 0,
            failed: false,
            stdout: '',
            stderr: '',
            durationMs: 0,
            timedOut: false,
            canceled: false,
            attempts: 1,
            error: ''
        }));

        await expect(
            configureProject({
                configuration: { ...configuration, customPostSteps: [
                    { name: 'seed-data', executable: 'sf', arguments: ['apex', 'run', '--file', 'scripts/seed.apex'] }
                ] },
                alias: 'configured-org',
                postSteps: ['seed-data'],
                skipPackages: true,
                refreshDependencySources: false,
                dryRun: false,
                environment: {},
                operationId: 'configure-custom-step',
                emit,
                runCommand
            })
        ).resolves.toBe(EXIT_CODES.SUCCESS);

        expect(runCommand).toHaveBeenCalledWith(
            expect.objectContaining({
                executable: 'sf',
                arguments: ['apex', 'run', '--file', 'scripts/seed.apex']
            })
        );
        expect(emit).toHaveBeenCalledWith(
            expect.objectContaining({ kind: 'post-step-result', postStep: 'seed-data', status: 'run' })
        );
    });
});

describe('create org workflow', () => {
    it('deletes the alias before fetching a pool org', async () => {
        const emit = vi.fn();
        const runCommand = vi.fn();
        runCommand
            .mockResolvedValueOnce({ exitCode: 0, failed: false, stdout: '', stderr: '', durationMs: 0, error: '' })
            .mockResolvedValueOnce({
                exitCode: 0,
                failed: false,
                stdout: 'Unused Scratch Orgs in the Pool\n: 1',
                stderr: '',
                durationMs: 0,
                error: ''
            })
            .mockResolvedValueOnce({ exitCode: 0, failed: false, stdout: '', stderr: '', durationMs: 0, error: '' })
            .mockResolvedValueOnce({ exitCode: 0, failed: false, stdout: '{"result":[]}', stderr: '', durationMs: 0, error: '' });

        await expect(
            createOrg({
                configuration,
                alias: 'scratch-org',
                durationDays: 14,
                postSteps: [],
                usePool: true,
                poolTag: 'dev',
                poolDevHub: 'devhub',
                fallbackToCreate: true,
                clearDependencySources: false,
                refreshDependencySources: false,
                dryRun: false,
                environment: {},
                operationId: 'pool-delete-first',
                emit,
                runCommand
            })
        ).resolves.toBe(EXIT_CODES.SUCCESS);

        expect(runCommand.mock.calls[0]?.[0]).toMatchObject({
            executable: 'sf',
            arguments: ['org', 'delete', 'scratch', '--no-prompt', '--target-org', 'scratch-org']
        });
    });

    it('emits an explicit workflow plan before acquisition begins', async () => {
        const emit = vi.fn();
        const runCommand = vi.fn();
        runCommand
            .mockResolvedValueOnce({ exitCode: 0, failed: false, stdout: '', stderr: '', durationMs: 0, error: '' })
            .mockResolvedValueOnce({
                exitCode: 0,
                failed: false,
                stdout: 'Unused Scratch Orgs in the Pool\n: 1',
                stderr: '',
                durationMs: 0,
                error: ''
            })
            .mockResolvedValueOnce({ exitCode: 0, failed: false, stdout: '', stderr: '', durationMs: 0, error: '' })
            .mockResolvedValueOnce({ exitCode: 0, failed: false, stdout: '{"result":[]}', stderr: '', durationMs: 0, error: '' });

        await createOrg({
            configuration,
            alias: 'scratch-org',
            durationDays: 14,
            postSteps: [],
            usePool: true,
            poolTag: 'dev',
            poolDevHub: 'devhub',
            fallbackToCreate: true,
            clearDependencySources: false,
            refreshDependencySources: false,
            dryRun: false,
            environment: {},
            operationId: 'workflow-plan',
            emit,
            runCommand
        });

        expect(emit).toHaveBeenCalledWith(
            expect.objectContaining({
                kind: 'progress',
                step: 'Create scratch org workflow',
                message: expect.stringMatching(/existing scratch org alias before acquisition/i)
            })
        );
    });

    it('forwards Salesforce command output as diagnostic progress events', async () => {
        const emit = vi.fn();
        const runCommand = vi.fn(async (request) => {
            request.onStdoutLine?.('Scratch org created: 00D000000000001');
            request.onStderrLine?.('Warning: source tracking is unavailable');
            return {
                executable: request.executable,
                arguments: [...(request.arguments ?? [])],
                exitCode: 0,
                failed: false,
                timedOut: false,
                canceled: false,
                attempts: 1,
                stdout: '{"result":[]}',
                stderr: '',
                durationMs: 0,
                error: ''
            };
        });

        await expect(
            createOrg({
                configuration,
                alias: 'scratch-org',
                durationDays: 14,
                postSteps: [],
                usePool: false,
                poolTag: 'dev',
                fallbackToCreate: true,
                clearDependencySources: false,
                refreshDependencySources: false,
                dryRun: false,
                environment: {},
                operationId: 'command-output',
                emit,
                runCommand
            })
        ).resolves.toBe(EXIT_CODES.SUCCESS);

        expect(emit).toHaveBeenCalledWith(
            expect.objectContaining({
                kind: 'progress',
                step: 'Create scratch org',
                message: '[stdout] Scratch org created: 00D000000000001',
                diagnostic: true
            })
        );
        expect(emit).toHaveBeenCalledWith(
            expect.objectContaining({
                kind: 'progress',
                step: 'Create scratch org',
                message: '[stderr] Warning: source tracking is unavailable',
                diagnostic: true
            })
        );
    });
});
