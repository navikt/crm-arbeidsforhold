import type { ProjectConfiguration } from '../domain/config.js';
import { EXIT_CODES, type EventSink, type ExitCode } from '../domain/events.js';
import type { CommandRequest, CommandResult } from '../infrastructure/command-runner.js';
import { withProgressHeartbeat } from '../infrastructure/progress-heartbeat.js';
import { classifySalesforceFailure, describeCommandFailure, isTransientCommandFailure } from '../infrastructure/salesforce-errors.js';
import type { CommandRunner } from './refresh-dependencies.js';

export interface CommandStepRunnerOptions {
    configuration: ProjectConfiguration;
    emit: EventSink;
    operationId: string;
    runCommand: CommandRunner;
    signal?: AbortSignal;
}

export function withCommandOutput(
    options: Pick<CommandStepRunnerOptions, 'emit' | 'operationId' | 'signal'>,
    stepId: string,
    step: string,
    request: CommandRequest
): CommandRequest {
    const emitOutput = (stream: 'stdout' | 'stderr', line: string): void => {
        if (line.length === 0) return;
        options.emit({
            kind: 'progress',
            operationId: options.operationId,
            timestamp: new Date().toISOString(),
            stepId,
            step,
            message: `[${stream}] ${line}`,
            diagnostic: true
        });
    };
    return {
        ...request,
        ...(options.signal === undefined ? {} : { signal: options.signal }),
        onStdoutLine: (line) => {
            request.onStdoutLine?.(line);
            emitOutput('stdout', line);
        },
        onStderrLine: (line) => {
            request.onStderrLine?.(line);
            emitOutput('stderr', line);
        }
    };
}

export async function runCommandStep(
    options: CommandStepRunnerOptions,
    stepId: string,
    step: string,
    executable: string,
    commandArguments: string[]
): Promise<ExitCode> {
    const startedAt = Date.now();
    let currentAttempt = 1;
    options.emit({
        kind: 'step-started',
        operationId: options.operationId,
        timestamp: new Date().toISOString(),
        stepId,
        step,
        attempt: 1
    });
    const result = await withProgressHeartbeat(
        {
            emit: options.emit,
            operationId: options.operationId,
            stepId,
            step,
            message: (elapsedSeconds) => `${step} is still running (${elapsedSeconds}s, attempt ${currentAttempt}/3)`
        },
        () =>
            options.runCommand(
                withCommandOutput(options, stepId, step, {
                    executable,
                    arguments: commandArguments,
                    cwd: options.configuration.projectDirectory,
                    retry: {
                        maxAttempts: 3,
                        delayMs: 5_000,
                        shouldRetry: isTransientCommandFailure,
                        onRetry: (failure, nextAttempt, delayMs) => {
                            currentAttempt = nextAttempt;
                            options.emit({
                                kind: 'retrying',
                                operationId: options.operationId,
                                timestamp: new Date().toISOString(),
                                stepId,
                                step,
                                attempt: nextAttempt - 1,
                                nextAttempt,
                                maxAttempts: 3,
                                delayMs,
                                message: `Retrying ${step}`,
                                error: failure.error ?? failure.stderr
                            });
                        }
                    }
                })
            )
    );
    if (result.failed || result.exitCode !== 0) {
        options.emit({
            kind: 'step-failed',
            operationId: options.operationId,
            timestamp: new Date().toISOString(),
            stepId,
            step,
            exitCode: result.exitCode,
            durationMs: Date.now() - startedAt,
            error: describeCommandFailure(result, `${step} failed`)
        });
        return classifySalesforceFailure(result, EXIT_CODES.OPERATION_FAILURE);
    }
    options.emit({
        kind: 'step-completed',
        operationId: options.operationId,
        timestamp: new Date().toISOString(),
        stepId,
        step,
        exitCode: result.exitCode ?? 0,
        durationMs: Date.now() - startedAt
    });
    return EXIT_CODES.SUCCESS;
}

export type CommandStepResult = CommandResult;