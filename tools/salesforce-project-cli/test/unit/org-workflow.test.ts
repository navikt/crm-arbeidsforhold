import { describe, expect, it, vi } from 'vitest';
import { configureProject } from '../../src/application/org-workflow.js';
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
