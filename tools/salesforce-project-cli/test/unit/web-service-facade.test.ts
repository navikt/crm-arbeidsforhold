import { describe, expect, it, vi } from 'vitest';
import { createWebServiceFacade } from '../../src/application/web-service-facade.js';
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
    pool: { use: false, tag: 'dev', fallbackToCreate: true }
};

describe('web service facade', () => {
    it('dispatches every allowlisted command to application services without spawning the CLI', async () => {
        const services = {
            clearDependencySources: vi.fn(async () => undefined),
            refreshDependencies: vi.fn(async () => EXIT_CODES.SUCCESS),
            planPackages: vi.fn(async () => ({ items: [], summary: {} }) as never),
            installPackages: vi.fn(async () => EXIT_CODES.SUCCESS),
            updatePackages: vi.fn(async () => EXIT_CODES.SUCCESS),
            createOrg: vi.fn(async () => EXIT_CODES.SUCCESS),
            deleteOrg: vi.fn(async () => EXIT_CODES.SUCCESS),
            configureProject: vi.fn(async () => EXIT_CODES.SUCCESS),
            listOrgs: vi.fn(async () => ({ orgs: [] })),
            getOrgPackageStatus: vi.fn(async ({ targetOrg }) => ({
                targetOrg,
                packages: [],
                summary: { total: 0, current: 0, updateAvailable: 0, higher: 0, missing: 0, unknown: 0 }
            })),
            getOrgInfo: vi.fn(
                async () =>
                    ({
                        org: { orgType: 'scratch', capabilities: { mutationPolicy: 'allowed' } }
                    }) as never
            ),
            loadProjectConfiguration: vi.fn(async () => configuration)
        };
        const runCommand = vi.fn(async () => {
            throw new Error('A real command must not run');
        });
        const facade = createWebServiceFacade({
            projectDirectory: '/project',
            environment: {},
            runCommand,
            services
        });
        const emit = vi.fn();
        await expect(facade.getOrgPackages('scratch')).resolves.toMatchObject({ targetOrg: 'scratch' });
        const requests = [
            ['dependencies.clear', { dryRun: true }],
            ['dependencies.refresh', { dryRun: true }],
            ['packages.plan', { targetOrg: 'scratch', installLatest: false, dryRun: true }],
            ['packages.install', { installLatest: false, dryRun: true }],
            ['packages.update', { installLatest: false, dryRun: true }],
            ['org.create', { alias: 'scratch', dryRun: true }],
            ['org.delete', { alias: 'scratch', confirmed: true, dryRun: true }],
            ['project.configure', { dryRun: true }]
        ] as const;

        for (const [command, payload] of requests) {
            await expect(facade.execute({ operationId: command, command, payload }, emit)).resolves.toBe(
                EXIT_CODES.SUCCESS
            );
        }

        expect(services.clearDependencySources).toHaveBeenCalledOnce();
        expect(services.getOrgPackageStatus).toHaveBeenCalledWith({
            configuration,
            targetOrg: 'scratch',
            runCommand
        });
        expect(services.refreshDependencies).toHaveBeenCalledOnce();
        expect(services.planPackages).toHaveBeenCalledOnce();
        expect(services.installPackages).toHaveBeenCalledOnce();
        expect(services.updatePackages).toHaveBeenCalledOnce();
        expect(services.refreshDependencies).toHaveBeenCalledWith(
            expect.not.objectContaining({ targetOrg: 'undefined' })
        );
        expect(services.installPackages).toHaveBeenCalledWith(expect.not.objectContaining({ targetOrg: 'undefined' }));
        expect(services.updatePackages).toHaveBeenCalledWith(expect.not.objectContaining({ targetOrg: 'undefined' }));
        expect(services.createOrg).toHaveBeenCalledOnce();
        expect(services.deleteOrg).toHaveBeenCalledOnce();
        expect(services.configureProject).toHaveBeenCalledOnce();
        expect(services.configureProject).toHaveBeenCalledWith(expect.not.objectContaining({ alias: 'undefined' }));
        expect(runCommand).not.toHaveBeenCalled();
    });
});
