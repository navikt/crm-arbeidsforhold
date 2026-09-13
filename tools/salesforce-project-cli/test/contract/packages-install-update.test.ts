import { mkdtemp, rm, writeFile } from 'node:fs/promises';
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

async function createProject(): Promise<string> {
    const projectDirectory = await mkdtemp(path.join(tmpdir(), 'sf-project-packages-'));
    temporaryDirectories.push(projectDirectory);
    await writeFile(
        path.join(projectDirectory, 'sfdx-project.json'),
        JSON.stringify({
            packageDirectories: [
                {
                    path: 'force-app',
                    dependencies: [
                        { package: 'keyless', versionNumber: '1.0.0.LATEST' },
                        { package: 'protected', versionNumber: '2.0.0.LATEST' }
                    ]
                },
                { path: 'keyless' },
                { path: 'protected' }
            ],
            packageAliases: { keyless: '0Ho-keyless', protected: '0Ho-protected' },
            packageKeyConfig: { keyless: false }
        })
    );
    await writeFile(
        path.join(projectDirectory, 'sf-project.config.json'),
        JSON.stringify({
            schemaVersion: 1,
            packageInstallKeyEnvironmentVariable: 'TEST_PACKAGE_KEY'
        })
    );
    return projectDirectory;
}

function commandResult(
    request: CommandRequest,
    payload: unknown,
    overrides: Partial<CommandResult> = {}
): CommandResult {
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
        attempts: 1,
        ...overrides
    };
}

function released(packageName: string, versionNumber: string, id: string) {
    const [MajorVersion, MinorVersion, PatchVersion, BuildNumber] = versionNumber.split('.').map(Number);
    return {
        PackageName: packageName,
        MajorVersion,
        MinorVersion,
        PatchVersion,
        BuildNumber,
        SubscriberPackageVersionId: id
    };
}

function createRunner(installed: unknown[] = []) {
    const requests: CommandRequest[] = [];
    const runner = vi.fn(async (request: CommandRequest) => {
        requests.push(request);
        if (request.arguments?.[1] === 'installed') {
            return commandResult(request, installed);
        }
        if (request.arguments?.[1] === 'display') {
            return commandResult(request, {
                alias: 'scratch-org',
                username: 'scratch@example.test',
                orgId: '00D000000000001',
                orgType: 'scratch',
                connectedStatus: 'Connected',
                instanceUrl: 'https://example.scratch.my.salesforce.com'
            });
        }
        if (request.arguments?.[1] === 'version') {
            const alias = request.arguments[4];
            return commandResult(
                request,
                alias === '0Ho-keyless'
                    ? [
                        released('keyless', '1.0.0.3', '04t-keyless'),
                        released('keyless', '1.1.0.1', '04t-keyless-latest')
                    ]
                    : [
                        released('protected', '2.0.0.4', '04t-protected'),
                        released('protected', '2.1.0.1', '04t-protected-latest')
                    ]
            );
        }
        return commandResult(request, { id: request.arguments?.[3] });
    });
    return { requests, runner };
}

describe('packages install and update', () => {
    it('installs selected latest versions sequentially with keys only when required', async () => {
        const projectDirectory = await createProject();
        const { requests, runner } = createRunner();
        const stdout: string[] = [];

        const exitCode = await runCli(
            [
                'packages',
                'install',
                '--project-dir',
                projectDirectory,
                '--target-org',
                'scratch-org',
                '--install-latest',
                '--json'
            ],
            { stdout: (line) => stdout.push(line), stderr: () => undefined },
            { runCommand: runner, environment: { TEST_PACKAGE_KEY: 'top-secret' } }
        );

        expect(exitCode).toBe(0);
        const installRequests = requests.filter((request) => request.arguments?.[1] === 'install');
        expect(installRequests.map((request) => request.arguments)).toEqual([
            ['package', 'install', '--package', '04t-keyless-latest', '--target-org', 'scratch-org', '--json'],
            [
                'package',
                'install',
                '--package',
                '04t-protected-latest',
                '--installation-key',
                'top-secret',
                '--target-org',
                'scratch-org',
                '--json'
            ]
        ]);
        expect(installRequests[0]?.secretValues).toBeUndefined();
        expect(installRequests[1]?.secretValues).toEqual(['top-secret']);
        expect(stdout.join('\n')).not.toContain('top-secret');
        expect(stdout.map((line) => JSON.parse(line))).toContainEqual(
            expect.objectContaining({
                kind: 'package-summary',
                installed: 2,
                updated: 0,
                failed: 0
            })
        );
    });

    it('updates only missing and older packages and never downgrades a higher installed version', async () => {
        const projectDirectory = await createProject();
        const { requests, runner } = createRunner([
            {
                SubscriberPackageName: 'keyless',
                SubscriberPackageVersionNumber: '1.0.0.2',
                SubscriberPackageVersionId: '04t-keyless-old'
            },
            {
                SubscriberPackageName: 'protected',
                SubscriberPackageVersionNumber: '2.2.0.1',
                SubscriberPackageVersionId: '04t-protected-higher'
            }
        ]);
        const stdout: string[] = [];

        const exitCode = await runCli(
            ['packages', 'update', '--project-dir', projectDirectory, '--target-org', 'scratch-org', '--json'],
            { stdout: (line) => stdout.push(line), stderr: () => undefined },
            { runCommand: runner, environment: { TEST_PACKAGE_KEY: 'top-secret' } }
        );

        expect(exitCode).toBe(0);
        expect(
            requests.filter((request) => request.arguments?.[1] === 'install').map((request) => request.arguments?.[3])
        ).toEqual(['04t-keyless']);
        expect(stdout.map((line) => JSON.parse(line))).toEqual(
            expect.arrayContaining([
                expect.objectContaining({ kind: 'package-result', packageName: 'keyless', status: 'updated' }),
                expect.objectContaining({ kind: 'package-result', packageName: 'protected', status: 'higher' })
            ])
        );

        const missingRun = createRunner([
            {
                SubscriberPackageName: 'protected',
                SubscriberPackageVersionNumber: '2.0.0.4',
                SubscriberPackageVersionId: '04t-protected'
            }
        ]);
        const missingExitCode = await runCli(
            ['packages', 'update', '--project-dir', projectDirectory, '--target-org', 'scratch-org', '--json'],
            { stdout: () => undefined, stderr: () => undefined },
            { runCommand: missingRun.runner, environment: { TEST_PACKAGE_KEY: 'top-secret' } }
        );

        expect(missingExitCode).toBe(0);
        expect(
            missingRun.requests
                .filter((request) => request.arguments?.[1] === 'install')
                .map((request) => request.arguments?.[3])
        ).toEqual(['04t-keyless']);
    });

    it('skips exact installed versions without issuing install commands', async () => {
        const projectDirectory = await createProject();
        const { requests, runner } = createRunner([
            {
                SubscriberPackageName: 'keyless',
                SubscriberPackageVersionNumber: '1.0.0.3',
                SubscriberPackageVersionId: '04t-keyless'
            },
            {
                SubscriberPackageName: 'protected',
                SubscriberPackageVersionNumber: '2.0.0.4',
                SubscriberPackageVersionId: '04t-protected'
            }
        ]);

        const exitCode = await runCli(
            ['packages', 'install', '--project-dir', projectDirectory, '--target-org', 'scratch-org', '--json'],
            { stdout: () => undefined, stderr: () => undefined },
            { runCommand: runner, environment: {} }
        );

        expect(exitCode).toBe(0);
        expect(requests.every((request) => request.arguments?.[1] !== 'install')).toBe(true);
    });

    it('performs read-only queries but no package install during dry-run', async () => {
        const projectDirectory = await createProject();
        const { requests, runner } = createRunner();

        const exitCode = await runCli(
            [
                'packages',
                'install',
                '--project-dir',
                projectDirectory,
                '--target-org',
                'scratch-org',
                '--dry-run',
                '--json'
            ],
            { stdout: () => undefined, stderr: () => undefined },
            { runCommand: runner, environment: {} }
        );

        expect(exitCode).toBe(0);
        expect(requests).toHaveLength(3);
        expect(requests.every((request) => request.arguments?.[1] !== 'install')).toBe(true);
    });

    it('retries only documented transient signatures and emits sanitized retry attempts', async () => {
        const projectDirectory = await createProject();
        const secret = 'retry-secret';
        const { runner } = createRunner();
        runner.mockImplementation(async (request) => {
            if (request.arguments?.[1] === 'display') {
                return commandResult(request, {
                    alias: 'scratch-org',
                    orgType: 'scratch',
                    connectedStatus: 'Connected'
                });
            }
            if (request.arguments?.[1] === 'installed') return commandResult(request, []);
            if (request.arguments?.[1] === 'version') {
                const alias = request.arguments[4];
                return commandResult(
                    request,
                    alias === '0Ho-keyless'
                        ? [released('keyless', '1.0.0.3', '04t-keyless')]
                        : [released('protected', '2.0.0.4', '04t-protected')]
                );
            }
            if (request.arguments?.[3] === '04t-protected') {
                const transient = commandResult(request, [], {
                    exitCode: 1,
                    failed: true,
                    stderr: `read ECONNRESET ${secret}`,
                    error: `failed ${secret}`
                });
                expect(await request.retry?.shouldRetry?.(transient)).toBe(true);
                expect(
                    await request.retry?.shouldRetry?.({ ...transient, stderr: 'INVALID_CROSS_REFERENCE_KEY' })
                ).toBe(false);
                request.retry?.onRetry?.(transient, 2, request.retry.delayMs ?? 0);
                return commandResult(request, {}, { attempts: 2 });
            }
            return commandResult(request, {});
        });
        const stdout: string[] = [];

        const exitCode = await runCli(
            ['packages', 'install', '--project-dir', projectDirectory, '--target-org', 'scratch-org', '--json'],
            { stdout: (line) => stdout.push(line), stderr: () => undefined },
            { runCommand: runner, environment: { TEST_PACKAGE_KEY: secret } }
        );

        expect(exitCode).toBe(0);
        expect(stdout.join('\n')).not.toContain(secret);
        expect(stdout.map((line) => JSON.parse(line))).toContainEqual(
            expect.objectContaining({
                kind: 'retrying',
                stepId: 'install:protected',
                attempt: 1,
                nextAttempt: 2
            })
        );
    });

    it('shows sanitized Salesforce commands in global verbose mode', async () => {
        const projectDirectory = await createProject();
        const secret = 'verbose-install-secret';
        const { runner } = createRunner();
        const stdout: string[] = [];

        const exitCode = await runCli(
            [
                '--verbose',
                'packages',
                'install',
                '--project-dir',
                projectDirectory,
                '--target-org',
                'sensitive-org-alias'
            ],
            { stdout: (line) => stdout.push(line), stderr: () => undefined },
            { runCommand: runner, environment: { TEST_PACKAGE_KEY: secret } }
        );

        const rendered = stdout.join('\n');
        expect(exitCode).toBe(0);
        expect(rendered).toContain('sf package installed list --target-org [REDACTED] --json');
        expect(rendered).toContain('--installation-key [REDACTED]');
        expect(rendered).not.toContain('sensitive-org-alias');
        expect(rendered).not.toContain(secret);
    });

    it('stops after a failed install and emits a sanitized failure summary', async () => {
        const projectDirectory = await createProject();
        const secret = 'failure-secret';
        const { requests, runner } = createRunner();
        runner.mockImplementation(async (request) => {
            requests.push(request);
            if (request.arguments?.[1] === 'display') {
                return commandResult(request, {
                    alias: 'scratch-org',
                    orgType: 'scratch',
                    connectedStatus: 'Connected'
                });
            }
            if (request.arguments?.[1] === 'installed') return commandResult(request, []);
            if (request.arguments?.[1] === 'version') {
                return commandResult(
                    request,
                    request.arguments[4] === '0Ho-keyless'
                        ? [released('keyless', '1.0.0.3', '04t-keyless')]
                        : [released('protected', '2.0.0.4', '04t-protected')]
                );
            }
            return commandResult(request, [], {
                exitCode: 1,
                failed: true,
                stderr: `INVALID_CROSS_REFERENCE_KEY ${secret}`,
                error: `Install failed with ${secret}`
            });
        });
        const stdout: string[] = [];

        const exitCode = await runCli(
            ['packages', 'install', '--project-dir', projectDirectory, '--target-org', 'scratch-org', '--json'],
            { stdout: (line) => stdout.push(line), stderr: () => undefined },
            { runCommand: runner, environment: { TEST_PACKAGE_KEY: secret } }
        );

        expect(exitCode).toBe(1);
        expect(requests.filter((request) => request.arguments?.[1] === 'install')).toHaveLength(1);
        expect(stdout.join('\n')).not.toContain(secret);
        expect(stdout.map((line) => JSON.parse(line))).toEqual(
            expect.arrayContaining([
                expect.objectContaining({ kind: 'package-result', packageName: 'keyless', status: 'failed' }),
                expect.objectContaining({ kind: 'package-summary', failed: 1 }),
                expect.objectContaining({ kind: 'operation-completed', exitCode: 1 })
            ])
        );
    });

    it.each(['plan', 'install'] as const)('maps package %s authentication failures to exit 4', async (command) => {
        const projectDirectory = await createProject();
        const authFailure = (request: CommandRequest) =>
            commandResult(request, [], {
                exitCode: 1,
                failed: true,
                stderr: 'INVALID_SESSION_ID: Session expired or invalid'
            });
        const runner = vi.fn(async (request: CommandRequest) => {
            if (command === 'plan') return authFailure(request);
            if (request.arguments?.[1] === 'display') {
                return commandResult(request, {
                    alias: 'scratch-org',
                    orgType: 'scratch',
                    connectedStatus: 'Connected'
                });
            }
            if (request.arguments?.[1] === 'installed') return commandResult(request, []);
            if (request.arguments?.[1] === 'version') {
                return commandResult(
                    request,
                    request.arguments[4] === '0Ho-keyless'
                        ? [released('keyless', '1.0.0.3', '04t-keyless')]
                        : [released('protected', '2.0.0.4', '04t-protected')]
                );
            }
            return authFailure(request);
        });

        const exitCode = await runCli(
            ['packages', command, '--project-dir', projectDirectory, '--target-org', 'scratch-org'],
            { stdout: () => undefined, stderr: () => undefined },
            { runCommand: runner, environment: {} }
        );

        expect(exitCode).toBe(4);
    });

    it.each([
        ['malformed JSON', (request: CommandRequest) => commandResult(request, [], { stdout: '{bad json' })],
        [
            'command failure',
            (request: CommandRequest) =>
                commandResult(request, [], { exitCode: 1, failed: true, stderr: 'query failed', error: 'query failed' })
        ]
    ])('fails cleanly for %s from Salesforce CLI', async (_name, installedResult) => {
        const projectDirectory = await createProject();
        const runner = vi.fn(async (request: CommandRequest) => installedResult(request));
        const stdout: string[] = [];
        const stderr: string[] = [];

        const exitCode = await runCli(
            ['packages', 'plan', '--project-dir', projectDirectory, '--target-org', 'scratch-org', '--json'],
            { stdout: (line) => stdout.push(line), stderr: (line) => stderr.push(line) },
            { runCommand: runner }
        );

        expect(exitCode).toBe(1);
        expect(stderr.join('\n')).toMatch(/malformed JSON|query failed/);
        expect(stdout.map((line) => JSON.parse(line))).toEqual(
            expect.arrayContaining([
                expect.objectContaining({ kind: 'step-failed', stepId: 'packages:plan' }),
                expect.objectContaining({ kind: 'package-summary', failed: 1 }),
                expect.objectContaining({ kind: 'operation-completed', operation: 'packages.plan', exitCode: 1 })
            ])
        );
    });
});
