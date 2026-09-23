import type { ProjectConfiguration } from '../domain/config.js';
import type { EventSink } from '../domain/events.js';
import { withProgressHeartbeat } from '../infrastructure/progress-heartbeat.js';
import { isTransientCommandFailure } from '../infrastructure/salesforce-errors.js';
import type { CommandResult } from '../infrastructure/command-runner.js';
import type { CommandRunner } from './refresh-dependencies.js';

export interface RetrieveDependencyCommandOptions {
    configuration: ProjectConfiguration;
    dependencyName: string;
    targetOrg?: string;
    operationId: string;
    stepId: string;
    emit: EventSink;
    runCommand: CommandRunner;
    signal?: AbortSignal;
}

export async function runDependencyRetrieval(options: RetrieveDependencyCommandOptions): Promise<CommandResult> {
    let currentAttempt = 1;
    const commandArguments = ['project', 'retrieve', 'start'];
    if (options.targetOrg !== undefined) commandArguments.push('--target-org', options.targetOrg);
    commandArguments.push('-n', options.dependencyName);

    return withProgressHeartbeat(
        {
            emit: options.emit,
            operationId: options.operationId,
            stepId: options.stepId,
            step: 'Retrieve dependency',
            message: (elapsedSeconds) =>
                `Retrieving ${options.dependencyName} (${elapsedSeconds}s, attempt ${currentAttempt}/3)`
        },
        () =>
            options.runCommand({
                executable: 'sf',
                arguments: commandArguments,
                cwd: options.configuration.projectDirectory,
                ...(options.signal === undefined ? {} : { signal: options.signal }),
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
                            stepId: options.stepId,
                            step: 'Retrieve dependency',
                            attempt: nextAttempt - 1,
                            nextAttempt,
                            maxAttempts: 3,
                            delayMs,
                            message: `Retrying ${options.dependencyName}`,
                            error: failure.error ?? failure.stderr
                        });
                    }
                }
            })
    );
}