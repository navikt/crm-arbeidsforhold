import { createHash } from 'node:crypto';
import { EventEmitter } from 'node:events';
import { access, mkdtemp, mkdir, readFile, readdir, realpath, rm, writeFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import path from 'node:path';
import { afterEach, describe, expect, it, vi } from 'vitest';
import { runCli } from '../../src/cli-app.js';
import { disableForceignore } from '../../src/application/forceignore-transaction.js';
import type { CommandRequest, CommandResult } from '../../src/infrastructure/command-runner.js';

const temporaryDirectories: string[] = [];

afterEach(async () => {
    await Promise.all(
        temporaryDirectories.splice(0).map((directory) => rm(directory, { force: true, recursive: true }))
    );
});

async function createProject(options: { forceignore?: string } = {}): Promise<string> {
    const projectDirectory = await mkdtemp(path.join(tmpdir(), 'sf-project-refresh-'));
    temporaryDirectories.push(projectDirectory);

    for (const packageName of ['shared-one', 'shared-two']) {
        const dependencyDirectory = path.join(projectDirectory, packageName);
        await mkdir(path.join(dependencyDirectory, 'main'), { recursive: true });
        await writeFile(path.join(dependencyDirectory, 'README.md'), `keep ${packageName}`);
        await writeFile(path.join(dependencyDirectory, 'main', 'stale.xml'), `remove ${packageName}`);
    }

    await writeFile(
        path.join(projectDirectory, 'sfdx-project.json'),
        JSON.stringify({
            packageDirectories: [
                {
                    path: 'force-app',
                    dependencies: [{ package: 'shared-one' }, { package: 'shared-two' }]
                },
                { path: 'shared-one' },
                { path: 'shared-two' }
            ]
        })
    );

    if (options.forceignore !== undefined) {
        await writeFile(path.join(projectDirectory, '.forceignore'), options.forceignore);
    }

    return projectDirectory;
}

async function createInterruptedForceignoreTransaction(projectDirectory: string, original: string): Promise<void> {
    const transactionId = 'interrupted-transaction';
    const backupFile = `.forceignore.sf-project-${transactionId}.backup`;
    const originalBytes = Buffer.from(original);
    await writeFile(path.join(projectDirectory, backupFile), originalBytes);
    await writeFile(
        path.join(projectDirectory, '.forceignore.sf-project.lock'),
        JSON.stringify({
            version: 1,
            transactionId,
            projectRealPath: await realpath(projectDirectory),
            forceignoreFile: '.forceignore',
            backupFile,
            originalContentBase64: originalBytes.toString('base64'),
            originalSha256: createHash('sha256').update(originalBytes).digest('hex'),
            originalByteLength: originalBytes.byteLength,
            createdAt: '2026-09-13T10:00:00.000Z'
        })
    );
}

function successfulResult(request: CommandRequest): CommandResult {
    return {
        executable: request.executable,
        arguments: [...(request.arguments ?? [])],
        exitCode: 0,
        stdout: '',
        stderr: '',
        durationMs: 1,
        failed: false,
        timedOut: false,
        canceled: false,
        attempts: 1
    };
}

describe('dependencies refresh', () => {
    it('automatically recovers an unambiguous interrupted transaction before refreshing', async () => {
        const projectDirectory = await createProject();
        await createInterruptedForceignoreTransaction(projectDirectory, 'original ignore\n');
        const runner = vi.fn(async (request: CommandRequest) => successfulResult(request));

        const exitCode = await runCli(
            ['dependencies', 'refresh', '--project-dir', projectDirectory],
            { stdout: () => undefined, stderr: () => undefined },
            { runCommand: runner }
        );

        expect(exitCode).toBe(0);
        expect(runner).toHaveBeenCalledTimes(2);
        await expect(readFile(path.join(projectDirectory, '.forceignore'), 'utf8')).resolves.toBe('original ignore\n');
        expect((await readdir(projectDirectory)).filter((entry) => entry.includes('.forceignore.'))).toEqual([]);
    });

    it('clears and retrieves every dependency sequentially while restoring forceignore', async () => {
        const originalForceignore = '**/*.secret\n';
        const projectDirectory = await createProject({ forceignore: originalForceignore });
        const preexistingBackup = path.join(projectDirectory, '.forceignore.sf-project-existing.backup');
        await writeFile(preexistingBackup, 'existing backup');
        const requests: CommandRequest[] = [];
        const runner = vi.fn(async (request: CommandRequest) => {
            requests.push(request);
            await expect(access(path.join(projectDirectory, '.forceignore'))).rejects.toThrow();
            return successfulResult(request);
        });
        const stdout: string[] = [];
        const stderr: string[] = [];

        const exitCode = await runCli(
            ['dependencies', 'refresh', '--project-dir', projectDirectory, '--target-org', 'scratch-org', '--json'],
            { stdout: (line) => stdout.push(line), stderr: (line) => stderr.push(line) },
            { runCommand: runner }
        );

        expect(exitCode).toBe(0);
        expect(stderr).toEqual([]);
        expect(requests.map((request) => ({ executable: request.executable, arguments: request.arguments }))).toEqual([
            {
                executable: 'sf',
                arguments: ['project', 'retrieve', 'start', '--target-org', 'scratch-org', '-n', 'shared-one']
            },
            {
                executable: 'sf',
                arguments: ['project', 'retrieve', 'start', '--target-org', 'scratch-org', '-n', 'shared-two']
            }
        ]);
        expect(stdout.map((line) => JSON.parse(line))).toEqual(
            expect.arrayContaining([
                expect.objectContaining({ kind: 'operation-started', operation: 'dependencies.refresh' }),
                expect.objectContaining({ kind: 'step-completed', stepId: 'retrieve:shared-one' }),
                expect.objectContaining({ kind: 'step-completed', stepId: 'retrieve:shared-two' }),
                expect.objectContaining({ kind: 'operation-completed', exitCode: 0 })
            ])
        );
        await expect(readFile(path.join(projectDirectory, '.forceignore'), 'utf8')).resolves.toBe(originalForceignore);
        await expect(access(path.join(projectDirectory, 'shared-one', 'main'))).rejects.toThrow();
        await expect(access(path.join(projectDirectory, 'shared-two', 'main'))).rejects.toThrow();
        await expect(readFile(preexistingBackup, 'utf8')).resolves.toBe('existing backup');
        expect((await readdir(projectDirectory)).filter((entry) => entry.includes('.forceignore.'))).toEqual([
            '.forceignore.sf-project-existing.backup'
        ]);
    });

    it('reports the plan without clearing, changing forceignore, or invoking the runner in dry-run mode', async () => {
        const originalForceignore = 'force-app/test/**\n';
        const projectDirectory = await createProject({ forceignore: originalForceignore });
        const runner = vi.fn(async (request: CommandRequest) => successfulResult(request));
        const stdout: string[] = [];

        const exitCode = await runCli(
            ['dependencies', 'refresh', '--project-dir', projectDirectory, '--dry-run', '--json'],
            { stdout: (line) => stdout.push(line), stderr: () => undefined },
            { runCommand: runner }
        );

        expect(exitCode).toBe(0);
        expect(runner).not.toHaveBeenCalled();
        await expect(readFile(path.join(projectDirectory, '.forceignore'), 'utf8')).resolves.toBe(originalForceignore);
        await expect(readFile(path.join(projectDirectory, 'shared-one', 'main', 'stale.xml'), 'utf8')).resolves.toBe(
            'remove shared-one'
        );
        expect((await readdir(projectDirectory)).filter((entry) => entry.includes('.forceignore.'))).toEqual([]);
        expect(stdout.map((line) => JSON.parse(line))).toEqual(
            expect.arrayContaining([
                expect.objectContaining({ kind: 'progress', message: 'Would clear shared-one', dryRun: true }),
                expect.objectContaining({ kind: 'progress', message: 'Would retrieve shared-one', dryRun: true }),
                expect.objectContaining({ kind: 'operation-completed', exitCode: 0, dryRun: true })
            ])
        );
    });

    it('restores forceignore and reports partial completion when a later retrieve fails', async () => {
        const originalForceignore = '**/*.private\n';
        const projectDirectory = await createProject({ forceignore: originalForceignore });
        const accessToken = '00D000000000001!AQ0AQJx_access-token-value';
        const runner = vi
            .fn<(request: CommandRequest) => Promise<CommandResult>>()
            .mockImplementationOnce(async (request) => successfulResult(request))
            .mockImplementationOnce(async (request) => ({
                ...successfulResult(request),
                exitCode: 7,
                stderr: `Authorization failed for ${accessToken}`,
                failed: true,
                error: `Command failed for ${accessToken}`
            }));
        const stdout: string[] = [];

        const exitCode = await runCli(
            ['dependencies', 'refresh', '--project-dir', projectDirectory, '--json'],
            { stdout: (line) => stdout.push(line), stderr: () => undefined },
            { runCommand: runner }
        );

        expect(exitCode).toBe(4);
        expect(runner).toHaveBeenCalledTimes(2);
        await expect(readFile(path.join(projectDirectory, '.forceignore'), 'utf8')).resolves.toBe(originalForceignore);
        const serializedEvents = stdout.join('\n');
        expect(serializedEvents).not.toContain(accessToken);
        expect(stdout.map((line) => JSON.parse(line))).toEqual(
            expect.arrayContaining([
                expect.objectContaining({ kind: 'step-failed', stepId: 'retrieve:shared-two', exitCode: 7 }),
                expect.objectContaining({ kind: 'operation-completed', exitCode: 4 })
            ])
        );
    });

    it('restores forceignore when retrieval is canceled', async () => {
        const originalForceignore = 'cancel-safe\n';
        const projectDirectory = await createProject({ forceignore: originalForceignore });
        const runner = vi.fn(
            async (request: CommandRequest): Promise<CommandResult> => ({
                ...successfulResult(request),
                exitCode: null,
                failed: true,
                canceled: true,
                error: 'Command was canceled'
            })
        );

        const exitCode = await runCli(
            ['dependencies', 'refresh', '--project-dir', projectDirectory],
            { stdout: () => undefined, stderr: () => undefined },
            { runCommand: runner }
        );

        expect(exitCode).toBe(1);
        await expect(readFile(path.join(projectDirectory, '.forceignore'), 'utf8')).resolves.toBe(originalForceignore);
    });

    it('retrieves successfully when forceignore is absent without creating it', async () => {
        const projectDirectory = await createProject();
        const runner = vi.fn(async (request: CommandRequest) => successfulResult(request));

        const exitCode = await runCli(
            ['dependencies', 'refresh', '--project-dir', projectDirectory],
            { stdout: () => undefined, stderr: () => undefined },
            { runCommand: runner }
        );

        expect(exitCode).toBe(0);
        expect(runner).toHaveBeenCalledTimes(2);
        await expect(access(path.join(projectDirectory, '.forceignore'))).rejects.toThrow();
        expect((await readdir(projectDirectory)).filter((entry) => entry.includes('.forceignore.'))).toEqual([]);
    });

    it('does not overwrite a preexisting lock or backup and performs no destructive work', async () => {
        const originalForceignore = 'locked\n';
        const projectDirectory = await createProject({ forceignore: originalForceignore });
        const lockPath = path.join(projectDirectory, '.forceignore.sf-project.lock');
        const backupPath = path.join(projectDirectory, '.forceignore.sf-project-existing.backup');
        await writeFile(lockPath, 'other operation');
        await writeFile(backupPath, 'other backup');
        const runner = vi.fn(async (request: CommandRequest) => successfulResult(request));
        const stdout: string[] = [];

        const exitCode = await runCli(
            ['dependencies', 'refresh', '--project-dir', projectDirectory, '--json'],
            { stdout: (line) => stdout.push(line), stderr: () => undefined },
            { runCommand: runner }
        );

        expect(exitCode).toBe(1);
        expect(runner).not.toHaveBeenCalled();
        await expect(readFile(lockPath, 'utf8')).resolves.toBe('other operation');
        await expect(readFile(backupPath, 'utf8')).resolves.toBe('other backup');
        await expect(readFile(path.join(projectDirectory, '.forceignore'), 'utf8')).resolves.toBe(originalForceignore);
        await expect(readFile(path.join(projectDirectory, 'shared-one', 'main', 'stale.xml'), 'utf8')).resolves.toBe(
            'remove shared-one'
        );
        expect(stdout.map((line) => JSON.parse(line))).toEqual(
            expect.arrayContaining([
                expect.objectContaining({ kind: 'step-failed', stepId: 'recover-forceignore' }),
                expect.objectContaining({ kind: 'operation-completed', exitCode: 1 })
            ])
        );
    });

    it('registers scoped signal cleanup and removes both listeners after cooperative recovery', async () => {
        const projectDirectory = await createProject({ forceignore: 'signal-safe\n' });
        const signalTarget = new EventEmitter();
        const lease = await disableForceignore(projectDirectory, 'signal-transaction', signalTarget);

        expect(signalTarget.listenerCount('SIGINT')).toBe(1);
        expect(signalTarget.listenerCount('SIGTERM')).toBe(1);
        signalTarget.emit('SIGINT');

        await vi.waitFor(async () => {
            await expect(readFile(path.join(projectDirectory, '.forceignore'), 'utf8')).resolves.toBe('signal-safe\n');
        });
        expect(signalTarget.listenerCount('SIGINT')).toBe(0);
        expect(signalTarget.listenerCount('SIGTERM')).toBe(0);
        await lease.restore();
    });
});

describe('dependencies recover', () => {
    it('reports a recovery plan without changing an interrupted transaction in dry-run mode', async () => {
        const projectDirectory = await createProject();
        await createInterruptedForceignoreTransaction(projectDirectory, 'recover me\n');
        const stdout: string[] = [];

        const exitCode = await runCli(
            ['dependencies', 'recover', '--project-dir', projectDirectory, '--dry-run', '--json'],
            { stdout: (line) => stdout.push(line), stderr: () => undefined }
        );

        expect(exitCode).toBe(0);
        await expect(access(path.join(projectDirectory, '.forceignore'))).rejects.toThrow();
        await expect(access(path.join(projectDirectory, '.forceignore.sf-project.lock'))).resolves.toBeUndefined();
        expect(stdout.map((line) => JSON.parse(line))).toEqual(
            expect.arrayContaining([
                expect.objectContaining({
                    kind: 'progress',
                    stepId: 'recover-forceignore',
                    message: 'Would restore .forceignore from the validated interrupted transaction',
                    dryRun: true
                }),
                expect.objectContaining({ kind: 'operation-completed', operation: 'dependencies.recover', exitCode: 0 })
            ])
        );
    });

    it('restores the validated original and removes its marker and backup', async () => {
        const projectDirectory = await createProject();
        await createInterruptedForceignoreTransaction(projectDirectory, 'recover me\n');

        const exitCode = await runCli(['dependencies', 'recover', '--project-dir', projectDirectory, '--json'], {
            stdout: () => undefined,
            stderr: () => undefined
        });

        expect(exitCode).toBe(0);
        await expect(readFile(path.join(projectDirectory, '.forceignore'), 'utf8')).resolves.toBe('recover me\n');
        expect((await readdir(projectDirectory)).filter((entry) => entry.includes('.forceignore.'))).toEqual([]);
    });

    it('fails closed without overwriting an active forceignore that differs from the transaction', async () => {
        const projectDirectory = await createProject({ forceignore: 'current active ignore\n' });
        await createInterruptedForceignoreTransaction(projectDirectory, 'stale original\n');
        const stdout: string[] = [];

        const exitCode = await runCli(['dependencies', 'recover', '--project-dir', projectDirectory, '--json'], {
            stdout: (line) => stdout.push(line),
            stderr: () => undefined
        });

        expect(exitCode).toBe(1);
        await expect(readFile(path.join(projectDirectory, '.forceignore'), 'utf8')).resolves.toBe(
            'current active ignore\n'
        );
        await expect(access(path.join(projectDirectory, '.forceignore.sf-project.lock'))).resolves.toBeUndefined();
        expect(stdout.map((line) => JSON.parse(line))).toEqual(
            expect.arrayContaining([
                expect.objectContaining({
                    kind: 'step-failed',
                    stepId: 'recover-forceignore',
                    nextAction: expect.stringContaining('Resolve the active .forceignore conflict')
                })
            ])
        );
    });

    it('fails closed for an invalid marker and leaves unrelated backups untouched', async () => {
        const projectDirectory = await createProject();
        const unrelatedBackup = path.join(projectDirectory, '.forceignore.sf-project-unrelated.backup');
        await writeFile(unrelatedBackup, 'do not use');
        await writeFile(
            path.join(projectDirectory, '.forceignore.sf-project.lock'),
            '{"version":1,"backupFile":"../outside"}'
        );

        const exitCode = await runCli(['dependencies', 'recover', '--project-dir', projectDirectory], {
            stdout: () => undefined,
            stderr: () => undefined
        });

        expect(exitCode).toBe(1);
        await expect(access(path.join(projectDirectory, '.forceignore'))).rejects.toThrow();
        await expect(readFile(unrelatedBackup, 'utf8')).resolves.toBe('do not use');
        await expect(access(path.join(projectDirectory, '.forceignore.sf-project.lock'))).resolves.toBeUndefined();
    });

    it('fails closed when the named backup does not match the marker', async () => {
        const projectDirectory = await createProject();
        await createInterruptedForceignoreTransaction(projectDirectory, 'expected original\n');
        const backupPath = path.join(projectDirectory, '.forceignore.sf-project-interrupted-transaction.backup');
        await writeFile(backupPath, 'tampered backup\n');
        const stdout: string[] = [];

        const exitCode = await runCli(['dependencies', 'recover', '--project-dir', projectDirectory, '--json'], {
            stdout: (line) => stdout.push(line),
            stderr: () => undefined
        });

        expect(exitCode).toBe(1);
        await expect(access(path.join(projectDirectory, '.forceignore'))).rejects.toThrow();
        await expect(readFile(backupPath, 'utf8')).resolves.toBe('tampered backup\n');
        expect(stdout.map((line) => JSON.parse(line))).toEqual(
            expect.arrayContaining([
                expect.objectContaining({
                    kind: 'step-failed',
                    stepId: 'recover-forceignore',
                    error: expect.stringContaining('does not match'),
                    nextAction: expect.stringContaining('Inspect .forceignore.sf-project.lock')
                })
            ])
        );
    });
});
