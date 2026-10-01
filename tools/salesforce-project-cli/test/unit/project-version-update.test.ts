import { mkdtemp, readFile, rm, writeFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import path from 'node:path';
import { afterEach, describe, expect, it, vi } from 'vitest';
import { runCli } from '../../src/cli-app.js';
import { loadProjectConfiguration } from '../../src/domain/config.js';
import { updateProjectPackageVersions } from '../../src/application/project-version-update.js';
import type { CommandRequest, CommandResult } from '../../src/infrastructure/command-runner.js';

const temporaryDirectories: string[] = [];

afterEach(async () => {
    await Promise.all(
        temporaryDirectories.splice(0).map((directory) => rm(directory, { force: true, recursive: true }))
    );
});

function result(request: CommandRequest, stdout: string): CommandResult {
    return {
        executable: request.executable,
        arguments: [...(request.arguments ?? [])],
        exitCode: 0,
        failed: false,
        stdout,
        stderr: '',
        durationMs: 0,
        timedOut: false,
        canceled: false,
        attempts: 1,
        error: ''
    };
}

async function createProject(): Promise<{
    directory: string;
    configuration: Awaited<ReturnType<typeof loadProjectConfiguration>>;
    original: string;
}> {
    const directory = await mkdtemp(path.join(tmpdir(), 'sf-project-version-update-'));
    temporaryDirectories.push(directory);
    await writeFile(
        path.join(directory, 'sfdx-project.json'),
        JSON.stringify(
            {
                packageDirectories: [
                    {
                        path: 'force-app',
                        dependencies: [
                            { package: 'package-one', versionNumber: '1.2.0.LATEST' },
                            { package: 'package-two', versionNumber: '2.0.0.1' }
                        ]
                    },
                    {
                        path: 'package-one',
                        package: 'package-one',
                        dependencies: [{ package: 'package-one', versionNumber: '1.2.0.LATEST' }]
                    },
                    { path: 'package-two', package: 'package-two' }
                ],
                packageAliases: { 'package-one': '0Ho000000000001', 'package-two': '0Ho000000000002' }
            },
            null,
            4
        ) + '\n'
    );
    const original = await readFile(path.join(directory, 'sfdx-project.json'), 'utf8');
    return { directory, configuration: await loadProjectConfiguration(directory), original };
}

describe('project package version update', () => {
    it('previews latest released constraints without writing unless apply is explicit', async () => {
        const { directory, configuration, original } = await createProject();
        const runCommand = vi.fn(async (request: CommandRequest) => {
            const alias = request.arguments?.[request.arguments.indexOf('--packages') + 1];
            const version = alias === '0Ho000000000001' ? [1, 2, 3, 4] : [2, 1, 0, 2];
            return result(
                request,
                JSON.stringify({
                    status: 0,
                    result: [
                        {
                            MajorVersion: version[0],
                            MinorVersion: version[1],
                            PatchVersion: version[2],
                            BuildNumber: version[3],
                            SubscriberPackageVersionId: `04t${version.join('')}`
                        }
                    ]
                })
            );
        });

        const preview = await updateProjectPackageVersions({ configuration, runCommand, apply: false });

        expect(preview.changes).toEqual([
            { packageName: 'package-one', currentVersion: '1.2.0.LATEST', latestVersion: '1.2.3.LATEST' },
            { packageName: 'package-two', currentVersion: '2.0.0.1', latestVersion: '2.1.0.LATEST' }
        ]);
        expect(preview.applied).toBe(false);
        expect(await readFile(path.join(directory, 'sfdx-project.json'), 'utf8')).toBe(original);
        await expect(readFile(path.join(directory, 'sfdx-project.json.backup'), 'utf8')).rejects.toMatchObject({
            code: 'ENOENT'
        });
    });

    it('backs up the project and updates every matching dependency only when apply is true', async () => {
        const { directory, configuration } = await createProject();
        const runCommand = vi.fn(async (request: CommandRequest) => {
            const alias = request.arguments?.[request.arguments.indexOf('--packages') + 1];
            const version = alias === '0Ho000000000001' ? [1, 2, 3, 4] : [2, 1, 0, 2];
            return result(
                request,
                JSON.stringify({
                    status: 0,
                    result: [
                        {
                            MajorVersion: version[0],
                            MinorVersion: version[1],
                            PatchVersion: version[2],
                            BuildNumber: version[3],
                            SubscriberPackageVersionId: `04t${version.join('')}`
                        }
                    ]
                })
            );
        });

        const applied = await updateProjectPackageVersions({ configuration, runCommand, apply: true });
        const updated = JSON.parse(await readFile(path.join(directory, 'sfdx-project.json'), 'utf8'));
        const backup = JSON.parse(await readFile(path.join(directory, 'sfdx-project.json.backup'), 'utf8'));

        expect(applied.applied).toBe(true);
        expect(backup.packageDirectories[0].dependencies[0].versionNumber).toBe('1.2.0.LATEST');
        expect(updated.packageDirectories[0].dependencies[0].versionNumber).toBe('1.2.3.LATEST');
        expect(updated.packageDirectories[1].dependencies[0].versionNumber).toBe('1.2.3.LATEST');
        expect(updated.packageDirectories[0].dependencies[1].versionNumber).toBe('2.1.0.LATEST');
    });

    it('exposes preview and explicit apply through packages check-versions', async () => {
        const { directory, original } = await createProject();
        const runCommand = vi.fn(async (request: CommandRequest) => {
            const alias = request.arguments?.[request.arguments.indexOf('--packages') + 1];
            const version = alias === '0Ho000000000001' ? [1, 2, 3, 4] : [2, 1, 0, 2];
            return result(
                request,
                JSON.stringify({
                    status: 0,
                    result: [
                        {
                            MajorVersion: version[0],
                            MinorVersion: version[1],
                            PatchVersion: version[2],
                            BuildNumber: version[3],
                            SubscriberPackageVersionId: `04t${version.join('')}`
                        }
                    ]
                })
            );
        });
        const stdout: string[] = [];
        const stderr: string[] = [];

        await expect(
            runCli(
                ['packages', 'check-versions', '--project-dir', directory],
                { stdout: (line) => stdout.push(line), stderr: (line) => stderr.push(line) },
                { runCommand }
            )
        ).resolves.toBe(0);
        expect(await readFile(path.join(directory, 'sfdx-project.json'), 'utf8')).toBe(original);
        expect(stdout.join('\n')).toContain('1.2.3.LATEST');
        expect(stderr).toEqual([]);

        await expect(
            runCli(
                ['packages', 'check-versions', '--project-dir', directory, '--apply'],
                { stdout: (line) => stdout.push(line), stderr: (line) => stderr.push(line) },
                { runCommand }
            )
        ).resolves.toBe(0);
        expect(await readFile(path.join(directory, 'sfdx-project.json.backup'), 'utf8')).toBe(original);
    });
});
