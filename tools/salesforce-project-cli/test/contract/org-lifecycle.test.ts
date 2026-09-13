import { access, mkdir, mkdtemp, rm, writeFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import path from 'node:path';
import { afterEach, describe, expect, it, vi } from 'vitest';
import { runCli } from '../../src/cli-app.js';
import type { CommandRequest, CommandResult } from '../../src/infrastructure/command-runner.js';

const temporaryDirectories: string[] = [];

afterEach(async () => {
    await Promise.all(
        temporaryDirectories.splice(0).map((directory) => rm(directory, { force: true, recursive: true }))
    );
});

async function createProject(config: Record<string, unknown> = {}): Promise<string> {
    const projectDirectory = await mkdtemp(path.join(tmpdir(), 'sf-project-org-'));
    temporaryDirectories.push(projectDirectory);
    await writeFile(
        path.join(projectDirectory, 'sfdx-project.json'),
        JSON.stringify({
            packageDirectories: [{ path: 'force-app' }]
        })
    );
    await writeFile(
        path.join(projectDirectory, 'sf-project.config.json'),
        JSON.stringify({
            schemaVersion: 1,
            defaultOrgAlias: 'configured-org',
            scratchDefinition: 'config/project-scratch-def.json',
            scratchDurationDays: 14,
            postSteps: ['deploy'],
            ...config
        })
    );
    return projectDirectory;
}

function successfulResult(request: CommandRequest, result: unknown = {}): CommandResult {
    return {
        executable: request.executable,
        arguments: [...(request.arguments ?? [])],
        exitCode: 0,
        stdout: JSON.stringify({ status: 0, result }),
        stderr: '',
        durationMs: 1,
        failed: false,
        timedOut: false,
        canceled: false,
        attempts: 1
    };
}

describe('org lifecycle', () => {
    it('creates an explicit scratch org before package installation and selected post steps', async () => {
        const projectDirectory = await createProject();
        const requests: CommandRequest[] = [];
        const runner = vi.fn(async (request: CommandRequest) => {
            requests.push(request);
            return successfulResult(request, request.arguments?.[0] === 'package' ? [] : {});
        });

        const exitCode = await runCli(
            [
                'org',
                'create',
                '--project-dir',
                projectDirectory,
                '--alias',
                'explicit-org',
                '--duration-days',
                '7',
                '--post-steps',
                'deploy',
                '--json'
            ],
            { stdout: () => undefined, stderr: () => undefined },
            { runCommand: runner }
        );

        expect(exitCode).toBe(0);
        expect(requests.map((request) => [request.executable, ...(request.arguments ?? [])])).toEqual([
            ['sf', 'org', 'delete', 'scratch', '--no-prompt', '--target-org', 'explicit-org'],
            [
                'sf',
                'org',
                'create',
                'scratch',
                '--set-default',
                '--definition-file',
                path.join(projectDirectory, 'config/project-scratch-def.json'),
                '--duration-days',
                '7',
                '--alias',
                'explicit-org'
            ],
            ['sf', 'package', 'installed', 'list', '--target-org', 'explicit-org', '--json'],
            ['sf', 'project', 'deploy', 'start', '--target-org', 'explicit-org']
        ]);
    });

    it('fetches an available org from the configured pool without deleting or creating', async () => {
        const projectDirectory = await createProject({
            pool: { use: true, tag: 'team-dev', devHub: 'dev-hub', fallbackToCreate: true }
        });
        const requests: CommandRequest[] = [];
        const runner = vi.fn(async (request: CommandRequest) => {
            requests.push(request);
            if (request.executable === 'sfp' && request.arguments?.[1] === 'list') {
                return { ...successfulResult(request), stdout: 'Unused Scratch Orgs in the Pool : 2' };
            }
            return successfulResult(request, request.arguments?.[0] === 'package' ? [] : {});
        });

        const exitCode = await runCli(
            ['org', 'create', '--project-dir', projectDirectory, '--json'],
            { stdout: () => undefined, stderr: () => undefined },
            { runCommand: runner }
        );

        expect(exitCode).toBe(0);
        expect(requests.slice(0, 2).map((request) => [request.executable, ...(request.arguments ?? [])])).toEqual([
            ['sfp', 'pool', 'list', '--tag', 'team-dev', '-a', '--targetdevhubusername', 'dev-hub'],
            [
                'sfp',
                'pool',
                'fetch',
                '--tag',
                'team-dev',
                '--targetdevhubusername',
                'dev-hub',
                '--alias',
                'configured-org',
                '--setdefaultusername'
            ]
        ]);
        expect(requests.some((request) => request.arguments?.includes('delete'))).toBe(false);
        expect(requests.some((request) => request.arguments?.includes('create'))).toBe(false);
    });

    it('falls back to scratch creation on a pool miss when enabled', async () => {
        const projectDirectory = await createProject();
        const requests: CommandRequest[] = [];
        const runner = vi.fn(async (request: CommandRequest) => {
            requests.push(request);
            if (request.executable === 'sfp') {
                return { ...successfulResult(request), stdout: 'Unused Scratch Orgs in the Pool : 0' };
            }
            return successfulResult(request, request.arguments?.[0] === 'package' ? [] : {});
        });

        const exitCode = await runCli(
            [
                'org',
                'create',
                '--project-dir',
                projectDirectory,
                '--use-pool',
                '--pool-tag',
                'empty',
                '--pool-devhub',
                'dev-hub',
                '--fallback-to-create'
            ],
            { stdout: () => undefined, stderr: () => undefined },
            { runCommand: runner }
        );

        expect(exitCode).toBe(0);
        expect(requests.map((request) => [request.executable, ...(request.arguments ?? [])])).toEqual(
            expect.arrayContaining([
                ['sfp', 'pool', 'list', '--tag', 'empty', '-a', '--targetdevhubusername', 'dev-hub'],
                expect.arrayContaining(['sf', 'org', 'create', 'scratch'])
            ])
        );
    });

    it('stops on a pool miss when fallback is disabled', async () => {
        const projectDirectory = await createProject();
        const requests: CommandRequest[] = [];
        const runner = vi.fn(async (request: CommandRequest) => {
            requests.push(request);
            return { ...successfulResult(request), stdout: 'Unused Scratch Orgs in the Pool : 0' };
        });

        const exitCode = await runCli(
            [
                'org',
                'create',
                '--project-dir',
                projectDirectory,
                '--use-pool',
                '--pool-tag',
                'empty',
                '--pool-devhub',
                'dev-hub',
                '--no-fallback-to-create'
            ],
            { stdout: () => undefined, stderr: () => undefined },
            { runCommand: runner }
        );

        expect(exitCode).toBe(1);
        expect(requests).toHaveLength(1);
        expect(requests[0]?.executable).toBe('sfp');
    });

    it('runs selected post steps in deploy, permission, data, community order', async () => {
        const projectDirectory = await createProject({
            permissionSets: ['Permission_One', 'Permission_Two'],
            dummyDataPlan: 'dummy-data/Plan.json',
            communityName: 'Aa-registeret',
            postSteps: ['deploy', 'permsets', 'data', 'community']
        });
        const requests: CommandRequest[] = [];
        const runner = vi.fn(async (request: CommandRequest) => {
            requests.push(request);
            return successfulResult(request, request.arguments?.[0] === 'package' ? [] : {});
        });

        const exitCode = await runCli(
            [
                'project',
                'configure',
                '--project-dir',
                projectDirectory,
                '--target-org',
                'existing-org',
                '--confirm-mutation',
                'MUTATE project.configure existing-org'
            ],
            { stdout: () => undefined, stderr: () => undefined },
            { runCommand: runner }
        );

        expect(exitCode).toBe(0);
        expect(requests.map((request) => request.arguments)).toEqual([
            ['org', 'display', '--target-org', 'existing-org', '--json'],
            ['config', 'get', 'target-org', '--json'],
            ['package', 'installed', 'list', '--target-org', 'existing-org', '--json'],
            ['project', 'deploy', 'start', '--target-org', 'existing-org'],
            [
                'org',
                'assign',
                'permset',
                '--target-org',
                'existing-org',
                '--name',
                'Permission_One',
                '--name',
                'Permission_Two'
            ],
            [
                'data',
                'import',
                'tree',
                '--target-org',
                'existing-org',
                '--plan',
                path.join(projectDirectory, 'dummy-data/Plan.json')
            ],
            ['community', 'publish', '--target-org', 'existing-org', '--name', 'Aa-registeret']
        ]);
    });

    it('does not invoke any command runner in a complete dry run', async () => {
        const projectDirectory = await createProject({ postSteps: ['deploy', 'permsets'] });
        const runner = vi.fn(async (request: CommandRequest) => successfulResult(request));
        const stdout: string[] = [];

        const exitCode = await runCli(
            ['org', 'create', '--project-dir', projectDirectory, '--dry-run', '--json'],
            { stdout: (line) => stdout.push(line), stderr: () => undefined },
            { runCommand: runner }
        );

        expect(exitCode).toBe(0);
        expect(runner).not.toHaveBeenCalled();
        expect(stdout.map((line) => JSON.parse(line))).toEqual(
            expect.arrayContaining([
                expect.objectContaining({ kind: 'org-summary', acquisition: 'create', dryRun: true }),
                expect.objectContaining({ kind: 'post-step-result', postStep: 'deploy', status: 'run', dryRun: true }),
                expect.objectContaining({ kind: 'post-step-result', postStep: 'data', status: 'skipped', dryRun: true })
            ])
        );
    });

    it('inspects and deletes a confirmed scratch org', async () => {
        const projectDirectory = await createProject();
        const requests: CommandRequest[] = [];
        const runner = vi.fn(async (request: CommandRequest) => {
            requests.push(request);
            if (request.arguments?.[0] === 'org' && request.arguments[1] === 'display') {
                return successfulResult(request, {
                    alias: 'scratch-org',
                    orgType: 'Scratch Org',
                    instanceUrl: 'https://example.scratch.my.salesforce.com',
                    connectedStatus: 'Connected'
                });
            }
            return successfulResult(request);
        });

        const confirmedExitCode = await runCli(
            ['org', 'delete', '--project-dir', projectDirectory, '--target-org', 'scratch-org', '--yes'],
            { stdout: () => undefined, stderr: () => undefined },
            { runCommand: runner }
        );

        expect(confirmedExitCode).toBe(0);
        expect(requests.map((request) => [request.executable, ...(request.arguments ?? [])])).toEqual([
            ['sf', 'org', 'display', '--target-org', 'scratch-org', '--json'],
            ['sf', 'config', 'get', 'target-org', '--json'],
            ['sf', 'org', 'delete', 'scratch', '--no-prompt', '--target-org', 'scratch-org']
        ]);
    });

    it.each([
        ['production', successfulResult, { edition: 'Production', instanceUrl: 'https://example.my.salesforce.com' }],
        ['unknown', successfulResult, {}],
        ['unauthenticated', null, null],
        ['inaccessible', null, null]
    ])('rejects a %s target without invoking delete', async (scenario, resultFactory, orgResult) => {
        const projectDirectory = await createProject();
        const requests: CommandRequest[] = [];
        const runner = vi.fn(async (request: CommandRequest) => {
            requests.push(request);
            if (request.arguments?.[0] === 'org' && request.arguments[1] === 'display') {
                if (scenario === 'unauthenticated') {
                    return {
                        ...successfulResult(request),
                        exitCode: 1,
                        failed: true,
                        stderr: 'No authorization information found for target org'
                    };
                }
                if (scenario === 'inaccessible') {
                    return {
                        ...successfulResult(request),
                        exitCode: 1,
                        failed: true,
                        stderr: 'Target org is inaccessible'
                    };
                }
                return resultFactory!(request, orgResult);
            }
            return successfulResult(request);
        });

        const exitCode = await runCli(
            ['org', 'delete', '--project-dir', projectDirectory, '--target-org', 'protected-org', '--yes'],
            { stdout: () => undefined, stderr: () => undefined },
            { runCommand: runner }
        );

        expect(exitCode).toBe(scenario === 'unauthenticated' ? 4 : 2);
        expect(requests.some((request) => request.arguments?.slice(0, 3).join(' ') === 'org delete scratch')).toBe(
            false
        );
    });

    it('plans scratch deletion without confirmation or command execution in dry-run', async () => {
        const projectDirectory = await createProject();
        const runner = vi.fn(async (request: CommandRequest) => successfulResult(request));
        const stdout: string[] = [];

        const exitCode = await runCli(
            ['org', 'delete', '--project-dir', projectDirectory, '--target-org', 'scratch-org', '--dry-run', '--json'],
            { stdout: (line) => stdout.push(line), stderr: () => undefined },
            { runCommand: runner }
        );

        expect(exitCode).toBe(0);
        expect(runner).not.toHaveBeenCalled();
        expect(stdout.map((line) => JSON.parse(line))).toContainEqual(
            expect.objectContaining({
                kind: 'org-summary',
                acquisition: 'delete',
                alias: 'scratch-org',
                dryRun: true
            })
        );
    });

    it('returns partial completion when a post step fails after org creation', async () => {
        const projectDirectory = await createProject();
        const runner = vi.fn(async (request: CommandRequest) => {
            if (request.arguments?.[0] === 'project') {
                return { ...successfulResult(request), exitCode: 1, failed: true, error: 'deploy failed' };
            }
            return successfulResult(request, request.arguments?.[0] === 'package' ? [] : {});
        });

        const exitCode = await runCli(
            ['org', 'create', '--project-dir', projectDirectory],
            { stdout: () => undefined, stderr: () => undefined },
            { runCommand: runner }
        );

        expect(exitCode).toBe(5);
    });

    it('maps scratch creation authentication failure to exit 4', async () => {
        const projectDirectory = await createProject();
        const runner = vi.fn(async (request: CommandRequest) => ({
            ...successfulResult(request),
            exitCode: 1,
            failed: true,
            stderr: 'Authorization failed for the Dev Hub'
        }));

        const exitCode = await runCli(
            ['org', 'create', '--project-dir', projectDirectory],
            { stdout: () => undefined, stderr: () => undefined },
            { runCommand: runner }
        );

        expect(exitCode).toBe(4);
    });

    it('retains exit 4 when authentication fails after scratch acquisition', async () => {
        const projectDirectory = await createProject();
        const runner = vi.fn(async (request: CommandRequest) => {
            if (request.arguments?.[0] === 'package') return successfulResult(request, []);
            if (request.arguments?.[0] === 'project') {
                return {
                    ...successfulResult(request),
                    exitCode: 1,
                    failed: true,
                    stderr: 'INSUFFICIENT_ACCESS: user is not authorized'
                };
            }
            return successfulResult(request);
        });

        const exitCode = await runCli(
            ['org', 'create', '--project-dir', projectDirectory],
            { stdout: () => undefined, stderr: () => undefined },
            { runCommand: runner }
        );

        expect(exitCode).toBe(4);
    });

    it('clears dependencies before acquisition and refreshes them last only when requested', async () => {
        const projectDirectory = await createProject({ postSteps: [] });
        const dependencyDirectory = path.join(projectDirectory, 'shared-package');
        await mkdir(path.join(dependencyDirectory, 'main'), { recursive: true });
        await writeFile(path.join(dependencyDirectory, 'README.md'), 'keep');
        await writeFile(path.join(dependencyDirectory, 'main', 'stale.xml'), 'remove');
        await writeFile(
            path.join(projectDirectory, 'sfdx-project.json'),
            JSON.stringify({
                packageDirectories: [
                    { path: 'force-app', dependencies: [{ package: 'shared-package', versionNumber: '1.0.0.1' }] },
                    { path: 'shared-package' }
                ],
                packageAliases: { 'shared-package': '0Ho-shared' },
                packageKeyConfig: { 'shared-package': false }
            })
        );
        const requests: CommandRequest[] = [];
        const runner = vi.fn(async (request: CommandRequest) => {
            requests.push(request);
            await expect(access(path.join(dependencyDirectory, 'main', 'stale.xml'))).rejects.toThrow();
            if (request.arguments?.[1] === 'installed') return successfulResult(request, []);
            if (request.arguments?.[1] === 'version') {
                return successfulResult(request, [
                    {
                        MajorVersion: 1,
                        MinorVersion: 0,
                        PatchVersion: 0,
                        BuildNumber: 1,
                        SubscriberPackageVersionId: '04t-shared'
                    }
                ]);
            }
            return successfulResult(request);
        });

        const exitCode = await runCli(
            [
                'org',
                'create',
                '--project-dir',
                projectDirectory,
                '--clear-dependency-sources',
                '--refresh-dependency-sources'
            ],
            { stdout: () => undefined, stderr: () => undefined },
            { runCommand: runner }
        );

        expect(exitCode).toBe(0);
        expect(requests.at(-1)?.arguments).toEqual([
            'project',
            'retrieve',
            'start',
            '--target-org',
            'configured-org',
            '-n',
            'shared-package'
        ]);
    });

    it('returns partial completion when package resolution fails after org acquisition', async () => {
        const projectDirectory = await createProject({ postSteps: [] });
        await writeFile(
            path.join(projectDirectory, 'sfdx-project.json'),
            JSON.stringify({
                packageDirectories: [
                    { path: 'force-app', dependencies: [{ package: 'shared-package', versionNumber: '1.0.0.1' }] },
                    { path: 'shared-package' }
                ],
                packageAliases: { 'shared-package': '0Ho-shared' },
                packageKeyConfig: { 'shared-package': false }
            })
        );
        const runner = vi.fn(async (request: CommandRequest) => {
            if (request.arguments?.[1] === 'installed') return successfulResult(request, []);
            if (request.arguments?.[1] === 'version') {
                return { ...successfulResult(request), exitCode: 1, failed: true, error: 'version lookup failed' };
            }
            return successfulResult(request);
        });

        const exitCode = await runCli(
            ['org', 'create', '--project-dir', projectDirectory],
            { stdout: () => undefined, stderr: () => undefined },
            { runCommand: runner }
        );

        expect(exitCode).toBe(5);
    });

    it('validates pool prerequisites before explicitly requested dependency cleanup', async () => {
        const projectDirectory = await createProject({ pool: { use: true, tag: 'dev', fallbackToCreate: true } });
        const dependencyDirectory = path.join(projectDirectory, 'shared-package');
        await mkdir(path.join(dependencyDirectory, 'main'), { recursive: true });
        await writeFile(path.join(dependencyDirectory, 'main', 'stale.xml'), 'keep on invalid input');
        await writeFile(
            path.join(projectDirectory, 'sfdx-project.json'),
            JSON.stringify({
                packageDirectories: [
                    { path: 'force-app', dependencies: [{ package: 'shared-package' }] },
                    { path: 'shared-package' }
                ]
            })
        );
        const runner = vi.fn(async (request: CommandRequest) => successfulResult(request));

        const exitCode = await runCli(
            ['org', 'create', '--project-dir', projectDirectory, '--clear-dependency-sources'],
            { stdout: () => undefined, stderr: () => undefined },
            { runCommand: runner }
        );

        expect(exitCode).toBe(2);
        expect(runner).toHaveBeenCalledWith({
            executable: 'sf',
            arguments: ['config', 'get', 'target-dev-hub', '--json'],
            cwd: projectDirectory
        });
        await expect(access(path.join(dependencyDirectory, 'main', 'stale.xml'))).resolves.toBeUndefined();
    });
});
