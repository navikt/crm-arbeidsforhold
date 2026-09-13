import { mkdtemp, readFile, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import path from 'node:path';
import { afterEach, describe, expect, it, vi } from 'vitest';
import { runCommand } from '../../src/infrastructure/command-runner.js';

const temporaryDirectories: string[] = [];

afterEach(async () => {
    await Promise.all(
        temporaryDirectories.splice(0).map((directory) => rm(directory, { force: true, recursive: true }))
    );
});

describe('runCommand', () => {
    it('passes arguments literally while capturing and streaming output lines', async () => {
        const stdoutLines: string[] = [];
        const stderrLines: string[] = [];
        const literalArgument = 'value with spaces; $(echo unsafe)';

        const result = await runCommand({
            executable: process.execPath,
            arguments: ['-e', "console.log(process.argv[1]); console.error('first\\nsecond')", literalArgument],
            onStdoutLine: (line) => stdoutLines.push(line),
            onStderrLine: (line) => stderrLines.push(line)
        });

        expect(result).toMatchObject({
            executable: process.execPath,
            arguments: expect.arrayContaining([literalArgument]),
            exitCode: 0,
            stdout: literalArgument,
            stderr: 'first\nsecond',
            timedOut: false,
            canceled: false,
            attempts: 1
        });
        expect(result.durationMs).toBeGreaterThanOrEqual(0);
        expect(stdoutLines).toEqual([literalArgument]);
        expect(stderrLines).toEqual(['first', 'second']);
    });

    it('returns structured timeout data', async () => {
        const result = await runCommand({
            executable: process.execPath,
            arguments: ['-e', 'setTimeout(() => undefined, 1_000)'],
            timeoutMs: 20
        });

        expect(result).toMatchObject({
            exitCode: null,
            failed: true,
            timedOut: true,
            canceled: false,
            attempts: 1
        });
    });

    it('cancels a running command through AbortSignal', async () => {
        const controller = new AbortController();

        const result = await runCommand({
            executable: process.execPath,
            arguments: ['-e', "console.log('ready'); setTimeout(() => undefined, 1_000)"],
            signal: controller.signal,
            onStdoutLine: (line) => {
                if (line === 'ready') {
                    controller.abort();
                }
            }
        });

        expect(result).toMatchObject({
            exitCode: null,
            failed: true,
            timedOut: false,
            canceled: true,
            attempts: 1
        });
    });

    it('retries failed commands using the injected async delay', async () => {
        const directory = await mkdtemp(path.join(tmpdir(), 'command-runner-retry-'));
        temporaryDirectories.push(directory);
        const attemptFile = path.join(directory, 'attempt.txt');
        const delay = vi.fn(async () => undefined);
        const onRetry = vi.fn();

        const result = await runCommand({
            executable: process.execPath,
            arguments: [
                '-e',
                "const fs = require('node:fs'); const file = process.argv[1]; const attempt = fs.existsSync(file) ? Number(fs.readFileSync(file, 'utf8')) + 1 : 1; fs.writeFileSync(file, String(attempt)); process.exit(attempt < 2 ? 9 : 0)",
                attemptFile
            ],
            retry: { maxAttempts: 2, delayMs: 25, onRetry },
            delay
        });

        expect(result).toMatchObject({ exitCode: 0, failed: false, attempts: 2 });
        expect(delay).toHaveBeenCalledOnce();
        expect(delay).toHaveBeenCalledWith(25, undefined);
        expect(onRetry).toHaveBeenCalledOnce();
        expect(onRetry).toHaveBeenCalledWith(expect.objectContaining({ exitCode: 9, attempts: 1 }), 2, 25);
        await expect(readFile(attemptFile, 'utf8')).resolves.toBe('2');
    });

    it('redacts secrets and Salesforce access tokens from all returned and streamed text', async () => {
        const stdoutLines: string[] = [];
        const stderrLines: string[] = [];
        const secret = 'literal-secret';
        const accessToken = '00D000000000001!AQ0AQJx_access-token-value';

        const result = await runCommand({
            executable: process.execPath,
            arguments: [
                '-e',
                'console.log(process.argv[1]); console.error(process.argv[2]); process.exit(7)',
                secret,
                accessToken
            ],
            secretValues: [secret],
            onStdoutLine: (line) => stdoutLines.push(line),
            onStderrLine: (line) => stderrLines.push(line)
        });

        expect(result.arguments).toEqual(['-e', expect.any(String), '[REDACTED]', '[REDACTED]']);
        expect(result).toMatchObject({ exitCode: 7, failed: true, attempts: 1 });
        expect(result.stdout).toBe('[REDACTED]');
        expect(result.stderr).toBe('[REDACTED]');
        expect(result.error).not.toContain(secret);
        expect(result.error).not.toContain(accessToken);
        expect(stdoutLines).toEqual(['[REDACTED]']);
        expect(stderrLines).toEqual(['[REDACTED]']);
    });

    it('does not retry failures rejected by the retry classifier', async () => {
        const delay = vi.fn(async () => undefined);
        const shouldRetry = vi.fn(() => false);

        const result = await runCommand({
            executable: process.execPath,
            arguments: ['-e', 'process.exit(8)'],
            retry: { maxAttempts: 3, shouldRetry },
            delay
        });

        expect(result).toMatchObject({ exitCode: 8, failed: true, attempts: 1 });
        expect(shouldRetry).toHaveBeenCalledOnce();
        expect(delay).not.toHaveBeenCalled();
    });
});
