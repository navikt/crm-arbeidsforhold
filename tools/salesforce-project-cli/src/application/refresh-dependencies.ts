/**
 * Coordinates transactional `.forceignore` handling, source cleanup, and sequential dependency retrieval.
 * Dry runs invoke no commands, and active transactions restore `.forceignore` even when retrieval fails.
 */
import type { ProjectConfiguration } from '../domain/config.js';
import { EXIT_CODES, type EventSink, type ExitCode } from '../domain/events.js';
import type { CommandRequest, CommandResult } from '../infrastructure/command-runner.js';
import { classifySalesforceFailure } from '../infrastructure/salesforce-errors.js';
import { clearDependencySources } from './clear-dependency-sources.js';
import { disableForceignore, recoverForceignoreTransaction, type ForceignoreLease } from './forceignore-transaction.js';

/** Injectable executor for external commands issued by application services. */
export type CommandRunner = (request: CommandRequest) => Promise<CommandResult>;

/** Inputs and injected dependencies for refreshing local dependency metadata. */
export interface RefreshDependenciesOptions {
    /** Validated project configuration containing dependency sources and project paths. */
    configuration: ProjectConfiguration;
    /** Optional org alias or username passed to each retrieve command. */
    targetOrg?: string;
    /** When `true`, emits cleanup and retrieval intent without changing files or running commands. */
    dryRun: boolean;
    /** Correlation identifier copied to all emitted workflow events. */
    operationId: string;
    /** Event sink receiving recovery, cleanup, retrieval, and failure events. */
    emit: EventSink;
    /** Injected command runner used only for non-dry-run dependency retrieval. */
    runCommand: CommandRunner;
}

function errorMessage(error: unknown): string {
    return error instanceof Error ? error.message : String(error);
}

/**
 * Recovers any interrupted `.forceignore` transaction, clears dependency source roots,
 * and retrieves each configured dependency in declaration order.
 *
 * A dry run validates pending recovery and cleanup paths, emits planned retrievals, and never
 * disables `.forceignore` or invokes the command runner. During execution, `.forceignore` is
 * restored in a `finally` stage even when cleanup, retrieval, or event emission fails.
 * Expected recovery/setup/command failures are returned as stable exit codes; a failure after
 * at least one successful retrieval returns `EXIT_CODES.PARTIAL_COMPLETION` unless failure
 * classification yields a more specific code.
 *
 * @param options - Configuration, target org, dry-run state, event sink, and command runner.
 * @returns The workflow exit code after recovery, cleanup, retrieval, and restoration.
 * @throws `Error` When cleanup or final restoration fails, or an injected dependency throws
 * outside a stage that is translated to an exit code.
 */
export async function refreshDependencies(options: RefreshDependenciesOptions): Promise<ExitCode> {
    // Recovery is always the first stage so a prior interrupted transaction cannot be overwritten.
    const recoveryExitCode = await recoverForceignoreTransaction({
        projectDirectory: options.configuration.projectDirectory,
        dryRun: options.dryRun,
        operationId: options.operationId,
        emit: options.emit
    });
    if (recoveryExitCode !== EXIT_CODES.SUCCESS) {
        return recoveryExitCode;
    }

    if (options.dryRun) {
        await clearDependencySources(options);
        for (const dependency of options.configuration.dependencySources) {
            options.emit({
                kind: 'progress',
                operationId: options.operationId,
                timestamp: new Date().toISOString(),
                stepId: `retrieve:${dependency.packageName}`,
                step: 'Retrieve dependency',
                message: `Would retrieve ${dependency.packageName}`,
                packageName: dependency.packageName,
                dryRun: true
            });
        }
        return EXIT_CODES.SUCCESS;
    }

    let lease: ForceignoreLease;
    try {
        lease = await disableForceignore(options.configuration.projectDirectory, options.operationId);
    } catch (error) {
        options.emit({
            kind: 'step-failed',
            operationId: options.operationId,
            timestamp: new Date().toISOString(),
            stepId: 'disable-forceignore',
            step: 'Disable .forceignore',
            exitCode: null,
            durationMs: 0,
            error: errorMessage(error)
        });
        return EXIT_CODES.OPERATION_FAILURE;
    }

    try {
        // Cleanup and retrieval share one lease; restoration must complete regardless of either result.
        await clearDependencySources(options);
        return await retrieveDependencies(options);
    } finally {
        await lease.restore();
    }
}

async function retrieveDependencies(options: RefreshDependenciesOptions): Promise<ExitCode> {
    let completedDependencies = 0;
    for (const dependency of options.configuration.dependencySources) {
        const stepId = `retrieve:${dependency.packageName}`;
        const startedAt = Date.now();
        options.emit({
            kind: 'step-started',
            operationId: options.operationId,
            timestamp: new Date().toISOString(),
            stepId,
            step: 'Retrieve dependency',
            attempt: 1
        });
        options.emit({
            kind: 'progress',
            operationId: options.operationId,
            timestamp: new Date().toISOString(),
            stepId,
            step: 'Retrieve dependency',
            message: `Retrieving ${dependency.packageName}`,
            packageName: dependency.packageName,
            dryRun: false
        });

        const commandArguments = ['project', 'retrieve', 'start'];
        if (options.targetOrg !== undefined) {
            commandArguments.push('--target-org', options.targetOrg);
        }
        commandArguments.push('-n', dependency.packageName);

        const result = await options.runCommand({
            executable: 'sf',
            arguments: commandArguments,
            cwd: options.configuration.projectDirectory
        });

        if (result.failed || result.exitCode !== 0) {
            options.emit({
                kind: 'step-failed',
                operationId: options.operationId,
                timestamp: new Date().toISOString(),
                stepId,
                step: 'Retrieve dependency',
                exitCode: result.exitCode,
                durationMs: Date.now() - startedAt,
                error: result.error ?? result.stderr ?? 'Dependency retrieval failed'
            });
            return classifySalesforceFailure(
                result,
                completedDependencies > 0 ? EXIT_CODES.PARTIAL_COMPLETION : EXIT_CODES.OPERATION_FAILURE
            );
        }

        completedDependencies += 1;
        options.emit({
            kind: 'step-completed',
            operationId: options.operationId,
            timestamp: new Date().toISOString(),
            stepId,
            step: 'Retrieve dependency',
            exitCode: result.exitCode,
            durationMs: Date.now() - startedAt
        });
    }
    return EXIT_CODES.SUCCESS;
}
