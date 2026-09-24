import { describe, expect, it, vi } from 'vitest';
import { runDependencyRetrieval } from '../../src/application/dependency-retrieval-runner.js';
import type { ProjectConfiguration } from '../../src/domain/config.js';
import type { CommandRequest, CommandResult } from '../../src/infrastructure/command-runner.js';

const configuration = {
    projectDirectory: '/project'
} as ProjectConfiguration;

function result(request: CommandRequest, overrides: Partial<CommandResult> = {}): CommandResult {
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
        attempts: 1,
        ...overrides
    };
}

describe('dependency retrieval runner', () => {
    it('builds the retrieve command and forwards the target org', async () => {
        const runCommand = vi.fn(async (request: CommandRequest) => result(request));
        const emit = vi.fn();

        await expect(
            runDependencyRetrieval({
                configuration,
                dependencyName: 'shared-one',
                targetOrg: 'scratch-org',
                operationId: 'operation-1',
                stepId: 'retrieve:shared-one',
                emit,
                runCommand,
            })
        ).resolves.toMatchObject({ exitCode: 0, failed: false });

        expect(runCommand).toHaveBeenCalledWith(
            expect.objectContaining({
                executable: 'sf',
                arguments: ['project', 'retrieve', 'start', '--target-org', 'scratch-org', '-n', 'shared-one'],
                cwd: '/project',
                retry: expect.objectContaining({ maxAttempts: 3, delayMs: 5_000 })
            })
        );
    });

    it('forwards transient retry events through the injected event sink', async () => {
        const runCommand = vi.fn(async (request: CommandRequest) => {
            request.retry?.onRetry?.(result(request, { failed: true, stderr: 'ECONNRESET' }), 2, 5_000);
            return result(request, { attempts: 2 });
        });
        const emit = vi.fn();

        await runDependencyRetrieval({
            configuration,
            dependencyName: 'shared-one',
            operationId: 'operation-1',
            stepId: 'retrieve:shared-one',
            emit,
            runCommand,
        });

        expect(emit).toHaveBeenCalledWith(expect.objectContaining({ kind: 'retrying', nextAttempt: 2 }));
    });
});