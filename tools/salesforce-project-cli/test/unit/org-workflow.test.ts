import { describe, expect, it, vi } from 'vitest';
import { configureProject, createOrg } from '../../src/application/org-workflow.js';
import type { ProjectConfiguration } from '../../src/domain/config.js';
import { EXIT_CODES } from '../../src/domain/events.js';

const configuration: ProjectConfiguration = {
    projectDirectory: '/project',
    preserveRootFiles: ['README.md'],
    dependencySources: [],
    packageDependencies: [],
    packageInstallKeyEnvironmentVariable: 'PACKAGE_INSTALL_KEY',
    scratchDefinition: '/project/config/project-scratch-def.json',
    scratchDurationDays: 14,
    permissionSets: [],
    dummyDataPlan: null,
    communityName: null,
    postSteps: ['deploy'],
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

        expect(runCommand.mock.calls[0][0]).toMatchObject({
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
});
