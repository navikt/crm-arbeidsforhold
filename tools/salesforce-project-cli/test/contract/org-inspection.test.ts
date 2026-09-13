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
    const projectDirectory = await mkdtemp(path.join(tmpdir(), 'sf-project-org-inspection-'));
    temporaryDirectories.push(projectDirectory);
    await writeFile(
        path.join(projectDirectory, 'sfdx-project.json'),
        JSON.stringify({
            packageDirectories: [{ path: 'force-app' }]
        })
    );
    return projectDirectory;
}

function successfulResult(request: CommandRequest, result: unknown): CommandResult {
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

function failedResult(request: CommandRequest, message: string): CommandResult {
    return {
        ...successfulResult(request, {}),
        exitCode: 1,
        stdout: JSON.stringify({ status: 1, message }),
        stderr: message,
        failed: true,
        error: message
    };
}

describe('org inspection', () => {
    it('lists normalized org summaries using only the injected runner', async () => {
        const projectDirectory = await createProject();
        const requests: CommandRequest[] = [];
        const runner = vi.fn(async (request: CommandRequest) => {
            requests.push(request);
            return successfulResult(request, {
                scratchOrgs: [
                    {
                        alias: 'scratch-org',
                        username: 'scratch@example.test',
                        orgId: '00D000000000001',
                        status: 'Active',
                        connectedStatus: 'Connected',
                        instanceUrl: 'https://example.scratch.my.salesforce.com',
                        expirationDate: '2026-09-20',
                        isDefaultUsername: true,
                        tracksSource: true,
                        accessToken: '00D000000000001!secret'
                    }
                ],
                nonScratchOrgs: []
            });
        });
        const stdout: string[] = [];

        const exitCode = await runCli(
            ['org', 'list', '--project-dir', projectDirectory, '--json'],
            { stdout: (line) => stdout.push(line), stderr: () => undefined },
            { runCommand: runner }
        );

        expect(exitCode).toBe(0);
        expect(requests).toEqual([
            {
                executable: 'sf',
                arguments: ['org', 'list', '--json'],
                cwd: projectDirectory
            }
        ]);
        expect(stdout).toHaveLength(1);
        expect(JSON.parse(stdout[0] ?? '')).toEqual({
            orgs: [
                expect.objectContaining({
                    alias: 'scratch-org',
                    username: 'scratch@example.test',
                    orgId: '00D000000000001',
                    orgType: 'scratch',
                    connectionStatus: 'connected',
                    authStatus: 'authenticated',
                    instanceUrlClassification: 'scratch',
                    expirationDate: '2026-09-20',
                    isDefaultOrg: true,
                    isDefaultDevHub: false,
                    sourceTracking: true,
                    capabilities: expect.objectContaining({ mutationPolicy: 'allowed' })
                })
            ]
        });
        expect(stdout.join('\n')).not.toContain('accessToken');
        expect(stdout.join('\n')).not.toContain('secret');
    });

    it('classifies every org type and preserves unknowns from noisy incomplete JSON', async () => {
        const projectDirectory = await createProject();
        const runner = vi.fn(async (request: CommandRequest) => ({
            ...successfulResult(request, {}),
            stdout: `Update available\n${JSON.stringify(
                {
                    status: 0,
                    result: {
                        scratchOrgs: [{ alias: 'expired', status: 'Expired', expirationDate: '2020-01-01' }],
                        nonScratchOrgs: [
                            {
                                alias: 'sandbox',
                                instanceUrl: 'https://team.sandbox.my.salesforce.com',
                                connectedStatus: 'Connected'
                            },
                            { alias: 'development', edition: 'Developer Edition', connectedStatus: 'Connected' },
                            { alias: 'production', orgType: 'Production', connectedStatus: 'Connected' },
                            { alias: 'unknown' },
                            {
                                alias: 'dev-hub',
                                isDevHub: true,
                                isDefaultDevHubUsername: true,
                                connectedStatus: 'Connected'
                            }
                        ]
                    }
                },
                null,
                2
            )}`
        }));
        const stdout: string[] = [];

        const exitCode = await runCli(
            ['org', 'list', '--project-dir', projectDirectory, '--json'],
            { stdout: (line) => stdout.push(line), stderr: () => undefined },
            { runCommand: runner }
        );

        expect(exitCode).toBe(0);
        const orgs = JSON.parse(stdout[0] ?? '').orgs as Array<Record<string, unknown>>;
        expect(Object.fromEntries(orgs.map((org) => [org.alias, org.orgType]))).toEqual({
            expired: 'scratch',
            sandbox: 'sandbox',
            development: 'development',
            production: 'production',
            unknown: 'unknown',
            'dev-hub': 'dev-hub'
        });
        expect(orgs.find((org) => org.alias === 'expired')).toEqual(
            expect.objectContaining({
                authStatus: 'expired',
                connectionStatus: 'unknown',
                remainingLifetimeDays: expect.any(Number)
            })
        );
        expect(orgs.find((org) => org.alias === 'unknown')).toEqual(
            expect.objectContaining({
                username: null,
                orgId: null,
                authStatus: 'unknown',
                instanceUrlClassification: 'unknown',
                expirationDate: null,
                remainingLifetimeDays: null,
                sourceTracking: null,
                capabilities: { sourceTracking: null, mutationPolicy: 'read-only' }
            })
        );
        expect(orgs.find((org) => org.alias === 'dev-hub')).toEqual(
            expect.objectContaining({
                isDefaultDevHub: true,
                capabilities: expect.objectContaining({ mutationPolicy: 'read-only' })
            })
        );
    });

    it('deduplicates orgs repeated across Salesforce CLI source groups', async () => {
        const projectDirectory = await createProject();
        const runner = vi.fn(async (request: CommandRequest) =>
            successfulResult(request, {
                nonScratchOrgs: [
                    {
                        alias: 'SIT2',
                        username: 'sit2@example.test',
                        orgId: '00D000000000010',
                        connectedStatus: 'Connected'
                    },
                    {
                        alias: 'NAV DevHub',
                        username: 'devhub@example.test',
                        orgId: '00D000000000011',
                        connectedStatus: 'Connected'
                    }
                ],
                sandboxes: [
                    {
                        alias: 'SIT2',
                        username: 'sit2@example.test',
                        orgId: '00D000000000010',
                        connectedStatus: 'Connected'
                    }
                ],
                devHubs: [
                    {
                        alias: 'NAV DevHub',
                        username: 'devhub@example.test',
                        orgId: '00D000000000011',
                        connectedStatus: 'Connected',
                        isDefaultDevHubUsername: true
                    }
                ]
            })
        );
        const stdout: string[] = [];

        const exitCode = await runCli(
            ['org', 'list', '--project-dir', projectDirectory, '--json'],
            { stdout: (line) => stdout.push(line), stderr: () => undefined },
            { runCommand: runner }
        );

        expect(exitCode).toBe(0);
        expect(JSON.parse(stdout[0] ?? '').orgs).toEqual([
            expect.objectContaining({ alias: 'SIT2', orgType: 'sandbox' }),
            expect.objectContaining({ alias: 'NAV DevHub', orgType: 'dev-hub', isDefaultDevHub: true })
        ]);
    });

    it('refreshes list entries through org display and merges source tracking details', async () => {
        const projectDirectory = await createProject();
        const requests: CommandRequest[] = [];
        const runner = vi.fn(async (request: CommandRequest) => {
            requests.push(request);
            if (request.arguments?.[1] === 'list') {
                return successfulResult(request, {
                    scratchOrgs: [{ alias: 'scratch-org', orgId: '00D000000000001' }],
                    nonScratchOrgs: []
                });
            }
            return successfulResult(request, {
                alias: 'scratch-org',
                id: '00D000000000001',
                connectedStatus: 'Connected',
                tracksSource: true,
                instanceUrl: 'https://example.scratch.my.salesforce.com'
            });
        });
        const stdout: string[] = [];

        const exitCode = await runCli(
            ['org', 'list', '--project-dir', projectDirectory, '--refresh', '--json'],
            { stdout: (line) => stdout.push(line), stderr: () => undefined },
            { runCommand: runner }
        );

        expect(exitCode).toBe(0);
        expect(requests.map((request) => request.arguments)).toEqual([
            ['org', 'list', '--json'],
            ['org', 'display', '--target-org', 'scratch-org', '--json']
        ]);
        expect(JSON.parse(stdout[0] ?? '').orgs[0]).toEqual(
            expect.objectContaining({
                orgType: 'scratch',
                authStatus: 'authenticated',
                sourceTracking: true,
                lastRefreshTimestamp: expect.any(String)
            })
        );
    });

    it('resolves the default target for status and returns a normalized summary', async () => {
        const projectDirectory = await createProject();
        const requests: CommandRequest[] = [];
        const runner = vi.fn(async (request: CommandRequest) => {
            requests.push(request);
            if (request.arguments?.[0] === 'config') {
                return successfulResult(request, [{ key: 'target-org', value: 'default-org', location: 'Local' }]);
            }
            return successfulResult(request, {
                scratchOrgs: [],
                nonScratchOrgs: [{ alias: 'default-org', orgId: '00D000000000002', orgType: 'Production' }]
            });
        });
        const stdout: string[] = [];

        const exitCode = await runCli(
            ['org', 'status', '--project-dir', projectDirectory, '--json'],
            { stdout: (line) => stdout.push(line), stderr: () => undefined },
            { runCommand: runner }
        );

        expect(exitCode).toBe(0);
        expect(requests.map((request) => request.arguments)).toEqual([
            ['config', 'get', 'target-org', '--json'],
            ['org', 'list', '--json']
        ]);
        expect(JSON.parse(stdout[0] ?? '')).toEqual({
            org: expect.objectContaining({
                alias: 'default-org',
                isDefaultOrg: true,
                orgType: 'production',
                capabilities: expect.objectContaining({ mutationPolicy: 'read-only' })
            })
        });
    });

    it('reports unauthenticated refresh failures without exposing auth material', async () => {
        const projectDirectory = await createProject();
        const secret = '00D000000000003!sensitive-token';
        const authUrl = `force://client:${secret}@login.salesforce.com`;
        const runner = vi.fn(async (request: CommandRequest) => {
            if (request.arguments?.[1] === 'list') {
                return successfulResult(request, {
                    scratchOrgs: [],
                    nonScratchOrgs: [{ alias: 'logged-out', orgId: '00D000000000003' }]
                });
            }
            return failedResult(request, `No authorization information found for ${authUrl}`);
        });
        const stdout: string[] = [];
        const stderr: string[] = [];

        const exitCode = await runCli(
            ['org', 'status', 'logged-out', '--project-dir', projectDirectory, '--refresh', '--json'],
            { stdout: (line) => stdout.push(line), stderr: (line) => stderr.push(line) },
            { runCommand: runner }
        );

        expect(exitCode).toBe(0);
        expect(JSON.parse(stdout[0] ?? '').org).toEqual(
            expect.objectContaining({
                alias: 'logged-out',
                authStatus: 'unauthenticated',
                connectionStatus: 'disconnected'
            })
        );
        expect(`${stdout.join('\n')}\n${stderr.join('\n')}`).not.toContain(secret);
        expect(`${stdout.join('\n')}\n${stderr.join('\n')}`).not.toContain('force://');
    });

    it('returns normalized org info and distinguishes inaccessible orgs', async () => {
        const projectDirectory = await createProject();
        const requests: CommandRequest[] = [];
        const runner = vi.fn(async (request: CommandRequest) => {
            requests.push(request);
            if (request.arguments?.[0] === 'config') {
                return successfulResult(request, [{ key: 'target-org', value: 'other-org' }]);
            }
            return failedResult(request, 'The org endpoint could not be reached');
        });
        const stdout: string[] = [];

        const exitCode = await runCli(
            ['org', 'info', 'unreachable', '--project-dir', projectDirectory, '--json'],
            { stdout: (line) => stdout.push(line), stderr: () => undefined },
            { runCommand: runner }
        );

        expect(exitCode).toBe(0);
        expect(requests.map((request) => request.arguments)).toEqual([
            ['org', 'display', '--target-org', 'unreachable', '--json'],
            ['config', 'get', 'target-org', '--json']
        ]);
        expect(JSON.parse(stdout[0] ?? '')).toEqual({
            org: expect.objectContaining({
                alias: 'unreachable',
                username: null,
                orgId: null,
                orgType: 'unknown',
                authStatus: 'inaccessible',
                apiVersion: null,
                edition: null,
                createdDate: null,
                devHubUsername: null,
                capabilities: { sourceTracking: null, mutationPolicy: 'read-only' }
            })
        });
    });

    it('renders human info from the same normalized fields as JSON', async () => {
        const projectDirectory = await createProject();
        const runner = vi.fn(async (request: CommandRequest) =>
            request.arguments?.[0] === 'config'
                ? successfulResult(request, [])
                : successfulResult(request, {
                    alias: 'developer-org',
                    username: 'developer@example.test',
                    id: '00D000000000004',
                    edition: 'Developer Edition',
                    connectedStatus: 'Connected',
                    apiVersion: '65.0',
                    tracksSource: true,
                    sfdxAuthUrl: 'force://must-not-appear'
                })
        );
        const humanOutput: string[] = [];

        const exitCode = await runCli(
            ['org', 'info', 'developer-org', '--project-dir', projectDirectory],
            { stdout: (line) => humanOutput.push(line), stderr: () => undefined },
            { runCommand: runner }
        );

        expect(exitCode).toBe(0);
        expect(humanOutput.join('\n')).toContain('Alias: developer-org');
        expect(humanOutput.join('\n')).toContain('Org type: development');
        expect(humanOutput.join('\n')).toContain('API version: 65.0');
        expect(humanOutput.join('\n')).toContain('Mutation policy: read-only');
        expect(humanOutput.join('\n')).not.toContain('sfdxAuthUrl');
        expect(humanOutput.join('\n')).not.toContain('force://');
    });
});
