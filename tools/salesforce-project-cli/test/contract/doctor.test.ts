import { mkdtemp, rm, writeFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import path from 'node:path';
import { afterEach, describe, expect, it, vi } from 'vitest';
import { runCli } from '../../src/cli-app.js';
import { EXIT_CODES } from '../../src/domain/events.js';
import type { CommandRequest, CommandResult } from '../../src/infrastructure/command-runner.js';

const temporaryDirectories: string[] = [];

afterEach(async () => {
    await Promise.all(
        temporaryDirectories.splice(0).map((directory) => rm(directory, { force: true, recursive: true }))
    );
});

async function createProject(pool = false): Promise<string> {
    const projectDirectory = await mkdtemp(path.join(tmpdir(), 'sf-project-doctor-'));
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
            pool: { use: pool, tag: 'dev', fallbackToCreate: true }
        })
    );
    return projectDirectory;
}

function commandResult(request: CommandRequest, overrides: Partial<CommandResult> = {}): CommandResult {
    return {
        executable: request.executable,
        arguments: [...(request.arguments ?? [])],
        exitCode: 0,
        stdout: '{}',
        stderr: '',
        durationMs: 2,
        failed: false,
        timedOut: false,
        canceled: false,
        attempts: 1,
        ...overrides
    };
}

describe('doctor command', () => {
    it('reports pass and skip checks as NDJSON with one final result', async () => {
        const projectDirectory = await createProject();
        const runner = vi.fn(async (request: CommandRequest) => commandResult(request));
        const stdout: string[] = [];
        const stderr: string[] = [];

        const exitCode = await runCli(
            ['doctor', '--project-dir', projectDirectory, '--json'],
            { stdout: (line) => stdout.push(line), stderr: (line) => stderr.push(line) },
            { runCommand: runner, nodeVersion: '22.11.0' }
        );

        const events = stdout.map((line) => JSON.parse(line) as Record<string, unknown>);
        expect(stderr).toEqual([]);
        expect(exitCode).toBe(EXIT_CODES.SUCCESS);
        expect(
            events.filter((event) => event.kind === 'doctor-check').map((event) => [event.check, event.status])
        ).toEqual([
            ['node', 'pass'],
            ['sf', 'pass'],
            ['project', 'pass'],
            ['auth', 'pass'],
            ['sfp', 'skip']
        ]);
        expect(events.at(-2)).toMatchObject({
            kind: 'doctor-summary',
            passed: 4,
            failed: 0,
            skipped: 1,
            exitCode: EXIT_CODES.SUCCESS
        });
        expect(events.at(-1)).toMatchObject({ kind: 'operation-completed', operation: 'doctor', exitCode: 0 });
        expect(runner.mock.calls.map(([request]) => [request.executable, ...(request.arguments ?? [])])).toEqual([
            ['sf', '--version', '--json'],
            ['sf', 'org', 'list', '--json']
        ]);
    });

    it('checks sfp only when pool support is configured', async () => {
        const projectDirectory = await createProject(true);
        const runner = vi.fn(async (request: CommandRequest) => commandResult(request));

        const exitCode = await runCli(
            ['doctor', '--project-dir', projectDirectory, '--json'],
            { stdout: () => undefined, stderr: () => undefined },
            { runCommand: runner, nodeVersion: '22.0.0' }
        );

        expect(exitCode).toBe(EXIT_CODES.SUCCESS);
        expect(runner.mock.calls.map(([request]) => [request.executable, ...(request.arguments ?? [])])).toContainEqual(
            ['sfp', '--version']
        );
    });

    it('returns the stable prerequisite exit code when Node or sf is unavailable', async () => {
        const projectDirectory = await createProject();
        const runner = vi.fn(async (request: CommandRequest) =>
            commandResult(
                request,
                request.executable === 'sf' ? { exitCode: null, failed: true, error: 'spawn sf ENOENT' } : {}
            )
        );
        const stdout: string[] = [];

        const exitCode = await runCli(
            ['doctor', '--project-dir', projectDirectory, '--json'],
            { stdout: (line) => stdout.push(line), stderr: () => undefined },
            { runCommand: runner, nodeVersion: '20.18.0' }
        );

        const events = stdout.map((line) => JSON.parse(line) as Record<string, unknown>);
        expect(exitCode).toBe(EXIT_CODES.MISSING_PREREQUISITE);
        expect(events).toEqual(
            expect.arrayContaining([
                expect.objectContaining({ kind: 'doctor-check', check: 'node', status: 'fail' }),
                expect.objectContaining({ kind: 'doctor-check', check: 'sf', status: 'fail' }),
                expect.objectContaining({ kind: 'doctor-check', check: 'auth', status: 'skip' })
            ])
        );
    });

    it('returns the auth exit code and keeps verbose output secret-safe', async () => {
        const projectDirectory = await createProject();
        const secret = '00D000000000001!AQ0AQJx_secret-access-token';
        const runner = vi.fn(async (request: CommandRequest) => {
            if (request.arguments?.[0] === 'org') {
                return commandResult(request, {
                    exitCode: 1,
                    failed: true,
                    stderr: `Authorization failed for ${secret}`,
                    error: `Authorization failed for ${secret}`
                });
            }
            return commandResult(request);
        });
        const stdout: string[] = [];

        const exitCode = await runCli(
            ['--no-color', '--verbose', 'doctor', '--project-dir', projectDirectory],
            { stdout: (line) => stdout.push(line), stderr: () => undefined, isTTY: true },
            { runCommand: runner, nodeVersion: '22.0.0' }
        );

        expect(exitCode).toBe(EXIT_CODES.AUTH_OR_AUTHORIZATION_FAILURE);
        expect(stdout.join('\n')).toContain('FAILED Salesforce authentication and org read access');
        expect(stdout.join('\n')).toContain('Next action: Run sf org login web, then rerun sf-project doctor.');
        expect(stdout.join('\n')).toContain('sf org list --json');
        expect(stdout.join('\n')).not.toContain(secret);
        expect(stdout.join('\n')).not.toContain('\u001b[');
    });
});
