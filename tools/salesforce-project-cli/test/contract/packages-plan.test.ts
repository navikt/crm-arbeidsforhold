import { mkdtemp, rm, writeFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import path from 'node:path';
import { afterEach, describe, expect, it, vi } from 'vitest';
import { runCli } from '../../src/cli-app.js';
import { getOrgPackageStatus } from '../../src/application/package-operations.js';
import type { ProjectConfiguration } from '../../src/domain/config.js';
import type { CommandRequest, CommandResult } from '../../src/infrastructure/command-runner.js';

const temporaryDirectories: string[] = [];

afterEach(async () => {
    await Promise.all(
        temporaryDirectories.splice(0).map((directory) => rm(directory, { force: true, recursive: true }))
    );
});

async function createProject(): Promise<string> {
    const projectDirectory = await mkdtemp(path.join(tmpdir(), 'sf-project-packages-plan-'));
    temporaryDirectories.push(projectDirectory);
    await writeFile(
        path.join(projectDirectory, 'sfdx-project.json'),
        JSON.stringify({
            packageDirectories: [
                {
                    path: 'force-app',
                    dependencies: [
                        { package: 'alpha', versionNumber: '1.0.0.LATEST' },
                        { package: 'beta', versionNumber: '2.0.0.3' }
                    ]
                },
                {
                    path: 'feature',
                    dependencies: [
                        { package: 'gamma', versionNumber: '3.0.0.NEXT' },
                        { package: 'delta', versionNumber: '4.0.0.LATEST' }
                    ]
                },
                { path: 'alpha' },
                { path: 'beta' },
                { path: 'gamma' },
                { path: 'delta' }
            ],
            packageAliases: {
                alpha: '0Ho-alpha',
                beta: '0Ho-beta',
                gamma: '0Ho-gamma',
                delta: '0Ho-delta'
            },
            packageKeyConfig: { alpha: false }
        })
    );
    return projectDirectory;
}

function result(request: CommandRequest, payload: unknown): CommandResult {
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

const releasedVersion = (packageName: string, versionNumber: string, id: string) => {
    const [MajorVersion, MinorVersion, PatchVersion, BuildNumber] = versionNumber.split('.').map(Number);
    return {
        PackageName: packageName,
        MajorVersion,
        MinorVersion,
        PatchVersion,
        BuildNumber,
        SubscriberPackageVersionId: id
    };
};

describe('packages plan', () => {
    it('reports selected-org package status and preserves unavailable values as unknown', async () => {
        const projectDirectory = await createProject();
        const versions = new Map([
            ['0Ho-alpha', [releasedVersion('alpha', '1.0.0.7', '04t-alpha')]],
            ['0Ho-beta', [releasedVersion('beta', '2.0.0.3', '04t-beta')]],
            ['0Ho-gamma', [releasedVersion('gamma', '3.0.0.8', '04t-gamma')]],
            ['0Ho-delta', [releasedVersion('delta', '4.0.0.2', '04t-delta')]]
        ]);
        const runner = vi.fn(async (request: CommandRequest) => {
            if (request.arguments?.[1] === 'installed') {
                return result(request, [
                    {
                        SubscriberPackageName: 'alpha',
                        SubscriberPackageVersionNumber: '1.0.0.7',
                        SubscriberPackageVersionId: '04t-alpha'
                    },
                    {
                        SubscriberPackageName: 'beta',
                        SubscriberPackageVersionNumber: '1.9.0.9',
                        SubscriberPackageVersionId: '04t-beta-old'
                    },
                    {
                        SubscriberPackageName: 'gamma',
                        SubscriberPackageVersionNumber: '3.1.0.1',
                        SubscriberPackageVersionId: '04t-gamma-newer'
                    }
                ]);
            }
            return result(request, versions.get(request.arguments?.[4] ?? '') ?? []);
        });
        const configuration = {
            projectDirectory,
            packageDependencies: [
                {
                    packageName: 'alpha',
                    packageAlias: '0Ho-alpha',
                    configuredVersion: '1.0.0.LATEST',
                    requiresInstallationKey: false
                },
                {
                    packageName: 'beta',
                    packageAlias: '0Ho-beta',
                    configuredVersion: '2.0.0.3',
                    requiresInstallationKey: false
                },
                {
                    packageName: 'gamma',
                    packageAlias: '0Ho-gamma',
                    configuredVersion: '3.0.0.NEXT',
                    requiresInstallationKey: false
                },
                {
                    packageName: 'delta',
                    packageAlias: '0Ho-delta',
                    configuredVersion: '4.0.0.LATEST',
                    requiresInstallationKey: false
                },
                { packageName: 'unconfigured', requiresInstallationKey: false }
            ]
        } as ProjectConfiguration;

        await expect(
            getOrgPackageStatus({ configuration, targetOrg: 'scratch-org', runCommand: runner })
        ).resolves.toEqual({
            targetOrg: 'scratch-org',
            packages: [
                {
                    packageName: 'alpha',
                    configuredVersion: '1.0.0.LATEST',
                    installedVersion: '1.0.0.7',
                    selectedVersion: '1.0.0.7',
                    status: 'current'
                },
                {
                    packageName: 'beta',
                    configuredVersion: '2.0.0.3',
                    installedVersion: '1.9.0.9',
                    selectedVersion: '2.0.0.3',
                    status: 'update-available'
                },
                {
                    packageName: 'gamma',
                    configuredVersion: '3.0.0.NEXT',
                    installedVersion: '3.1.0.1',
                    selectedVersion: '3.0.0.8',
                    status: 'higher'
                },
                {
                    packageName: 'delta',
                    configuredVersion: '4.0.0.LATEST',
                    installedVersion: null,
                    selectedVersion: '4.0.0.2',
                    status: 'missing'
                },
                {
                    packageName: 'unconfigured',
                    configuredVersion: null,
                    installedVersion: null,
                    selectedVersion: null,
                    status: 'unknown'
                }
            ],
            summary: { total: 5, current: 1, updateAvailable: 1, higher: 1, missing: 1, unknown: 1 }
        });
    });

    it('reports ordered skip, update, higher, and missing statuses using read-only queries', async () => {
        const projectDirectory = await createProject();
        const requests: CommandRequest[] = [];
        const versions = new Map([
            ['0Ho-alpha', [releasedVersion('alpha', '1.0.0.7', '04t-alpha')]],
            ['0Ho-beta', [releasedVersion('beta', '2.0.0.3', '04t-beta')]],
            ['0Ho-gamma', [releasedVersion('gamma', '3.0.0.8', '04t-gamma')]],
            ['0Ho-delta', [releasedVersion('delta', '4.0.0.2', '04t-delta')]]
        ]);
        const runner = vi.fn(async (request: CommandRequest) => {
            requests.push(request);
            if (request.arguments?.[1] === 'installed') {
                return result(request, [
                    {
                        SubscriberPackageName: 'alpha',
                        SubscriberPackageVersionNumber: '1.0.0.7',
                        SubscriberPackageVersionId: '04t-alpha'
                    },
                    {
                        SubscriberPackageName: 'beta',
                        SubscriberPackageVersionNumber: '1.9.0.9',
                        SubscriberPackageVersionId: '04t-beta-old'
                    },
                    {
                        SubscriberPackageName: 'gamma',
                        SubscriberPackageVersionNumber: '3.1.0.1',
                        SubscriberPackageVersionId: '04t-gamma-newer'
                    }
                ]);
            }
            return result(request, versions.get(request.arguments?.[4] ?? '') ?? []);
        });
        const stdout: string[] = [];
        const stderr: string[] = [];

        const exitCode = await runCli(
            ['packages', 'plan', '--project-dir', projectDirectory, '--target-org', 'scratch-org', '--json'],
            { stdout: (line) => stdout.push(line), stderr: (line) => stderr.push(line) },
            { runCommand: runner }
        );

        expect(exitCode).toBe(0);
        expect(stderr).toEqual([]);
        expect(requests.map((request) => request.arguments)).toEqual([
            ['package', 'installed', 'list', '--target-org', 'scratch-org', '--json'],
            [
                'package',
                'version',
                'list',
                '--packages',
                '0Ho-alpha',
                '--released',
                '--order-by',
                'CreatedDate',
                '--json'
            ],
            [
                'package',
                'version',
                'list',
                '--packages',
                '0Ho-beta',
                '--released',
                '--order-by',
                'CreatedDate',
                '--json'
            ],
            [
                'package',
                'version',
                'list',
                '--packages',
                '0Ho-gamma',
                '--released',
                '--order-by',
                'CreatedDate',
                '--json'
            ],
            [
                'package',
                'version',
                'list',
                '--packages',
                '0Ho-delta',
                '--released',
                '--order-by',
                'CreatedDate',
                '--json'
            ]
        ]);
        const events = stdout.map((line) => JSON.parse(line));
        expect(events.filter((event) => event.kind === 'package-result')).toEqual([
            expect.objectContaining({
                packageName: 'alpha',
                ordinal: 1,
                status: 'skip',
                selectedVersionId: '04t-alpha'
            }),
            expect.objectContaining({
                packageName: 'beta',
                ordinal: 2,
                status: 'update',
                selectedVersionId: '04t-beta'
            }),
            expect.objectContaining({
                packageName: 'gamma',
                ordinal: 3,
                status: 'higher',
                selectedVersionId: '04t-gamma'
            }),
            expect.objectContaining({
                packageName: 'delta',
                ordinal: 4,
                status: 'missing',
                selectedVersionId: '04t-delta'
            })
        ]);
        expect(events).toContainEqual(
            expect.objectContaining({
                kind: 'package-summary',
                total: 4,
                missing: 1,
                updated: 1,
                skipped: 1,
                higher: 1,
                failed: 0
            })
        );
    });
});
