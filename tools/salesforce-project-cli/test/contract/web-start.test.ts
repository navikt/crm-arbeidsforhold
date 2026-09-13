import { mkdtemp, writeFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import path from 'node:path';
import { afterEach, describe, expect, it, vi } from 'vitest';
import { runCli } from '../../src/cli-app.js';
import type { StartedWebServer } from '../../src/web/server.js';

const temporaryDirectories: string[] = [];

afterEach(async () => {
    const { rm } = await import('node:fs/promises');
    await Promise.all(
        temporaryDirectories.splice(0).map((directory) => rm(directory, { force: true, recursive: true }))
    );
});

describe('web start', () => {
    it('starts on the configured loopback port without logging the session token', async () => {
        const projectDirectory = await mkdtemp(path.join(tmpdir(), 'sf-project-web-'));
        temporaryDirectories.push(projectDirectory);
        await writeFile(
            path.join(projectDirectory, 'sfdx-project.json'),
            JSON.stringify({ packageDirectories: [{ path: 'force-app' }] })
        );
        const sessionToken = 'a'.repeat(64);
        const start = vi.fn(
            async (): Promise<StartedWebServer> => ({
                server: {} as never,
                sessionToken,
                url: 'http://127.0.0.1:4310',
                subscriberCount: () => 0,
                close: async () => undefined
            })
        );
        const stdout: string[] = [];
        const stderr: string[] = [];

        const exitCode = await runCli(
            ['web', 'start', '--project-dir', projectDirectory, '--port', '4310'],
            {
                stdout: (line) => stdout.push(line),
                stderr: (line) => stderr.push(line)
            },
            { startWebServer: start }
        );

        expect(exitCode).toBe(0);
        expect(start).toHaveBeenCalledWith(
            expect.objectContaining({ host: '127.0.0.1', port: 4310, facade: expect.any(Object) })
        );
        expect(stdout).toEqual(['Web server listening at http://127.0.0.1:4310']);
        expect(JSON.stringify({ stdout, stderr })).not.toContain(sessionToken);
    });

    it('rejects an invalid port before starting the server', async () => {
        const start = vi.fn();
        const stderr: string[] = [];

        const exitCode = await runCli(
            ['web', 'start', '--port', '70000'],
            { stdout: () => undefined, stderr: (line) => stderr.push(line) },
            { startWebServer: start }
        );

        expect(exitCode).toBe(2);
        expect(start).not.toHaveBeenCalled();
        expect(stderr.join('\n')).toContain('--port');
    });
});
