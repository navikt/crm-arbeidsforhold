import { renameSync, symlinkSync } from 'node:fs';
import { access, mkdtemp, mkdir, readFile, rm, symlink, writeFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import path from 'node:path';
import { afterEach, describe, expect, it } from 'vitest';
import { clearDependencySources } from '../../src/application/clear-dependency-sources.js';
import { runCli } from '../../src/cli-app.js';
import { loadProjectConfiguration } from '../../src/domain/config.js';

const temporaryDirectories: string[] = [];

afterEach(async () => {
    const { rm } = await import('node:fs/promises');
    await Promise.all(
        temporaryDirectories.splice(0).map((directory) => rm(directory, { force: true, recursive: true }))
    );
});

describe('dependencies clear', () => {
    it('reports the cleanup plan as NDJSON without changing files in dry-run mode', async () => {
        const projectDirectory = await mkdtemp(path.join(tmpdir(), 'sf-project-clear-'));
        temporaryDirectories.push(projectDirectory);

        const dependencyDirectory = path.join(projectDirectory, 'shared-package');
        await mkdir(path.join(dependencyDirectory, 'main'), { recursive: true });
        await writeFile(path.join(dependencyDirectory, 'README.md'), 'keep me');
        await writeFile(path.join(dependencyDirectory, 'main', 'metadata.xml'), 'keep during dry-run');
        await writeFile(
            path.join(projectDirectory, 'sfdx-project.json'),
            JSON.stringify({
                packageDirectories: [
                    {
                        path: 'force-app',
                        package: 'host-package',
                        dependencies: [{ package: 'shared-package', versionNumber: '1.0.0.LATEST' }]
                    },
                    { path: 'shared-package' }
                ]
            })
        );

        const stdout: string[] = [];
        const stderr: string[] = [];
        const exitCode = await runCli(
            ['dependencies', 'clear', '--project-dir', projectDirectory, '--dry-run', '--json'],
            {
                stdout: (line) => stdout.push(line),
                stderr: (line) => stderr.push(line)
            }
        );

        expect(exitCode).toBe(0);
        expect(stderr).toEqual([]);
        expect(stdout.length).toBeGreaterThan(1);
        expect(stdout.every((line) => JSON.parse(line))).toBeTruthy();
        expect(stdout.map((line) => JSON.parse(line))).toEqual(
            expect.arrayContaining([
                expect.objectContaining({ kind: 'operation-started', operation: 'dependencies.clear' }),
                expect.objectContaining({
                    kind: 'progress',
                    packageName: 'shared-package',
                    directory: dependencyDirectory,
                    preservedFiles: ['README.md'],
                    dryRun: true
                }),
                expect.objectContaining({ kind: 'operation-completed', exitCode: 0 })
            ])
        );
        await expect(readFile(path.join(dependencyDirectory, 'README.md'), 'utf8')).resolves.toBe('keep me');
        await expect(readFile(path.join(dependencyDirectory, 'main', 'metadata.xml'), 'utf8')).resolves.toBe(
            'keep during dry-run'
        );
    });

    it('deletes dependency contents except configured root files', async () => {
        const projectDirectory = await mkdtemp(path.join(tmpdir(), 'sf-project-clear-'));
        temporaryDirectories.push(projectDirectory);

        const dependencyDirectory = path.join(projectDirectory, 'shared-package');
        await mkdir(path.join(dependencyDirectory, 'main'), { recursive: true });
        await writeFile(path.join(dependencyDirectory, 'README.md'), 'keep readme');
        await writeFile(path.join(dependencyDirectory, '.gitkeep'), 'keep marker');
        await writeFile(path.join(dependencyDirectory, 'main', 'metadata.xml'), 'delete me');
        await writeFile(
            path.join(projectDirectory, 'sfdx-project.json'),
            JSON.stringify({
                packageDirectories: [
                    {
                        path: 'force-app',
                        dependencies: [{ package: 'shared-package' }]
                    },
                    { path: 'shared-package' }
                ]
            })
        );
        await writeFile(
            path.join(projectDirectory, 'sf-project.config.json'),
            JSON.stringify({
                schemaVersion: 1,
                dependencySourcePolicy: { preserveRootFiles: ['README.md', '.gitkeep'] }
            })
        );

        const exitCode = await runCli(['dependencies', 'clear', '--project-dir', projectDirectory], {
            stdout: () => undefined,
            stderr: () => undefined
        });

        expect(exitCode).toBe(0);
        await expect(readFile(path.join(dependencyDirectory, 'README.md'), 'utf8')).resolves.toBe('keep readme');
        await expect(readFile(path.join(dependencyDirectory, '.gitkeep'), 'utf8')).resolves.toBe('keep marker');
        await expect(access(path.join(dependencyDirectory, 'main'))).rejects.toThrow();
    });

    it('rejects a declared dependency directory outside the project root', async () => {
        const parentDirectory = await mkdtemp(path.join(tmpdir(), 'sf-project-clear-'));
        temporaryDirectories.push(parentDirectory);
        const projectDirectory = path.join(parentDirectory, 'project');
        const outsideDirectory = path.join(parentDirectory, 'outside-package');
        await mkdir(projectDirectory);
        await mkdir(outsideDirectory);
        await writeFile(path.join(outsideDirectory, 'metadata.xml'), 'must survive');
        await writeFile(
            path.join(projectDirectory, 'sfdx-project.json'),
            JSON.stringify({
                packageDirectories: [
                    {
                        path: 'force-app',
                        dependencies: [{ package: 'outside-package' }]
                    },
                    { path: '../outside-package' }
                ]
            })
        );

        const stderr: string[] = [];
        const exitCode = await runCli(['dependencies', 'clear', '--project-dir', projectDirectory], {
            stdout: () => undefined,
            stderr: (line) => stderr.push(line)
        });

        expect(exitCode).toBe(1);
        expect(stderr).toEqual([expect.stringContaining('outside the project root')]);
        await expect(readFile(path.join(outsideDirectory, 'metadata.xml'), 'utf8')).resolves.toBe('must survive');
    });

    it('rejects a symlink dependency root and preserves its outside target', async () => {
        const parentDirectory = await mkdtemp(path.join(tmpdir(), 'sf-project-clear-'));
        temporaryDirectories.push(parentDirectory);
        const projectDirectory = path.join(parentDirectory, 'project');
        const outsideDirectory = path.join(parentDirectory, 'outside-package');
        await mkdir(projectDirectory);
        await mkdir(outsideDirectory);
        await writeFile(path.join(outsideDirectory, 'metadata.xml'), 'must survive');
        await symlink(outsideDirectory, path.join(projectDirectory, 'shared-package'));
        await writeFile(
            path.join(projectDirectory, 'sfdx-project.json'),
            JSON.stringify({
                packageDirectories: [
                    { path: 'force-app', dependencies: [{ package: 'shared-package' }] },
                    { path: 'shared-package' }
                ]
            })
        );

        const exitCode = await runCli(['dependencies', 'clear', '--project-dir', projectDirectory], {
            stdout: () => undefined,
            stderr: () => undefined
        });

        expect(exitCode).toBe(1);
        await expect(readFile(path.join(outsideDirectory, 'metadata.xml'), 'utf8')).resolves.toBe('must survive');
    });

    it('fails if the dependency root is replaced after planning and preserves the outside target', async () => {
        const parentDirectory = await mkdtemp(path.join(tmpdir(), 'sf-project-clear-'));
        temporaryDirectories.push(parentDirectory);
        const projectDirectory = path.join(parentDirectory, 'project');
        const dependencyDirectory = path.join(projectDirectory, 'shared-package');
        const movedDependencyDirectory = path.join(projectDirectory, 'shared-package-original');
        const outsideDirectory = path.join(parentDirectory, 'outside-package');
        await mkdir(dependencyDirectory, { recursive: true });
        await mkdir(outsideDirectory);
        await writeFile(path.join(dependencyDirectory, 'metadata.xml'), 'original');
        await writeFile(path.join(outsideDirectory, 'metadata.xml'), 'must survive');
        await writeFile(
            path.join(projectDirectory, 'sfdx-project.json'),
            JSON.stringify({
                packageDirectories: [
                    { path: 'force-app', dependencies: [{ package: 'shared-package' }] },
                    { path: 'shared-package' }
                ]
            })
        );
        const configuration = await loadProjectConfiguration(projectDirectory);
        let replaced = false;

        await expect(
            clearDependencySources({
                configuration,
                dryRun: false,
                operationId: 'replace-root',
                emit: () => {
                    if (!replaced) {
                        replaced = true;
                        renameSync(dependencyDirectory, movedDependencyDirectory);
                        symlinkSync(outsideDirectory, dependencyDirectory);
                    }
                }
            })
        ).rejects.toThrow(/symbolic link|changed during cleanup/);
        await expect(readFile(path.join(outsideDirectory, 'metadata.xml'), 'utf8')).resolves.toBe('must survive');
        await rm(dependencyDirectory);
    });
});
