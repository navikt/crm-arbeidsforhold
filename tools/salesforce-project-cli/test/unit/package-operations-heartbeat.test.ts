import { describe, expect, it, vi } from 'vitest';
import { installPackages } from '../../src/application/package-operations.js';
import type { ProjectConfiguration } from '../../src/domain/config.js';
import { EXIT_CODES, type OperationEvent } from '../../src/domain/events.js';
import type { CommandRequest, CommandResult } from '../../src/infrastructure/command-runner.js';

const configuration: ProjectConfiguration = {
    projectDirectory: '/project',
    preserveRootFiles: ['README.md'],
    dependencySources: [],
    unresolvedDependencyNames: [],
    packageDependencies: [
        {
            packageName: 'shared-package',
            packageAlias: '0Ho-shared',
            configuredVersion: '1.0.0.LATEST',
            requiresInstallationKey: false
        }
    ],
    packageInstallKeyEnvironmentVariable: 'PACKAGE_INSTALL_KEY',
    commandTimeouts: { readMs: 30_000, mutationMs: 600_000 },
    scratchDefinition: '/project/config/project-scratch-def.json',
    scratchDurationDays: 14,
    permissionSets: [],
    dummyDataPlan: null,
    communityName: null,
    postSteps: ['deploy'],
    customPostSteps: [],
    pool: { use: false, tag: 'dev', fallbackToCreate: true }
};

function commandResult(request: CommandRequest, payload: unknown): CommandResult {
    return {
        executable: request.executable,
        arguments: [...(request.arguments ?? [])],
        exitCode: 0,
        stdout: JSON.stringify({ status: 0, result: payload }),
        stderr: '',
        durationMs: 1,
        failed: false,
        timedOut: false,
        canceled: false,
        attempts: 1
    };
}

describe('installPackages heartbeat', () => {
    it('emits a heartbeat progress event while a slow install command is still running', async () => {
        vi.useFakeTimers();
        try {
            const events: OperationEvent[] = [];
            let resolveInstall!: (result: CommandResult) => void;
            let installedQueryCount = 0;
            const runCommand = vi.fn(async (request: CommandRequest) => {
                if (request.arguments?.[1] === 'installed') {
                    installedQueryCount += 1;
                    return commandResult(
                        request,
                        installedQueryCount === 1
                            ? []
                            : [
                                {
                                    SubscriberPackageName: 'shared-package',
                                    SubscriberPackageVersionNumber: '1.0.0.3',
                                    SubscriberPackageVersionId: '04t-shared'
                                }
                            ]
                    );
                }
                if (request.arguments?.[1] === 'version') {
                    return commandResult(request, [
                        { PackageName: 'shared-package', MajorVersion: 1, MinorVersion: 0, PatchVersion: 0, BuildNumber: 3, SubscriberPackageVersionId: '04t-shared' }
                    ]);
                }
                if (request.arguments?.[1] === 'install' && request.arguments?.[2] === 'report') {
                    return commandResult(request, { Status: 'IN_PROGRESS' });
                }
                if (request.arguments?.[1] === 'install') {
                    return new Promise<CommandResult>((resolve) => {
                        resolveInstall = resolve;
                    });
                }
                return commandResult(request, {});
            });

            const installPromise = installPackages({
                configuration,
                targetOrg: 'scratch-org',
                installLatest: false,
                dryRun: false,
                environment: {},
                operationId: 'operation-1',
                emit: (event) => events.push(event),
                runCommand
            });

            await vi.advanceTimersByTimeAsync(15_000);
            expect(events).toContainEqual(
                expect.objectContaining({
                    kind: 'progress',
                    heartbeat: true,
                    stepId: 'install:shared-package',
                    step: 'Install package',
                    message: 'Installing shared-package (15s, attempt 1/3)'
                })
            );

            resolveInstall(commandResult({ executable: 'sf', arguments: [] }, { Id: '0Hf-shared-request', Status: 'IN_PROGRESS' }));
            await expect(installPromise).resolves.toBe(EXIT_CODES.SUCCESS);
        } finally {
            vi.useRealTimers();
        }
    });
});
