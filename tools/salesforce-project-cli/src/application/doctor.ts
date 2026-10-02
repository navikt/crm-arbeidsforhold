/**
 * Runs read-only prerequisite diagnostics for the runtime, project, Salesforce CLI, authentication, and pool tooling.
 * Individual failures become deterministic check events and aggregate exit codes rather than aborting the sequence.
 */
import type { ProjectConfiguration } from '../domain/config.js';
import { loadProjectConfiguration } from '../domain/config.js';
import { EXIT_CODES, type EventSink, type ExitCode } from '../domain/events.js';
import type { CommandRequest, CommandResult } from '../infrastructure/command-runner.js';

/** Inputs and injected dependencies for project prerequisite diagnostics. */
export interface DoctorOptions {
    /** Project working directory used for configuration loading and command execution. */
    projectDirectory: string;
    /** Node.js version string to validate; normally the current process version without a leading `v`. */
    nodeVersion: string;
    /** Correlation identifier copied to all diagnostic events. */
    operationId: string;
    /** Event sink receiving optional command diagnostics, individual checks, and the final summary. */
    emit: EventSink;
    /** Injected command runner used for all Salesforce CLI and `sfp` availability checks. */
    runCommand: (request: CommandRequest) => Promise<CommandResult>;
    /** Whether attempted command lines are emitted as diagnostic progress events. */
    verbose: boolean;
}

type CheckName = 'node' | 'sf' | 'project' | 'auth' | 'sfp';
type CheckStatus = 'pass' | 'fail' | 'skip';

interface CheckResult {
    /** Stable machine-facing prerequisite identifier. */
    check: CheckName;
    /** Human-readable prerequisite name. */
    label: string;
    /** Outcome used to render and aggregate the prerequisite check. */
    status: CheckStatus;
    /** Elapsed check duration in milliseconds. */
    durationMs: number;
    /** Sanitized result detail suitable for terminal and event output. */
    message: string;
    /** Action the operator can take to resolve a failed prerequisite. */
    nextAction?: string;
    /** Stable process exit category contributed by a failed check. */
    exitCode?: ExitCode;
}

function nodeCheck(nodeVersion: string): CheckResult {
    const startedAt = Date.now();
    const majorVersion = Number(nodeVersion.split('.')[0]);
    const supported = Number.isInteger(majorVersion) && majorVersion >= 22;
    return {
        check: 'node',
        label: 'Node.js >=22',
        status: supported ? 'pass' : 'fail',
        durationMs: Date.now() - startedAt,
        message: supported ? `Node.js ${nodeVersion}` : `Node.js ${nodeVersion} is unsupported`,
        ...(supported
            ? {}
            : {
                nextAction: 'Install Node.js 22 or newer and rerun sf-project doctor.',
                exitCode: EXIT_CODES.MISSING_PREREQUISITE
            })
    };
}

async function runCheck(
    check: CheckName,
    label: string,
    request: CommandRequest,
    options: DoctorOptions,
    failure: { message: string; nextAction: string; exitCode: ExitCode }
): Promise<CheckResult> {
    const startedAt = Date.now();
    const failedResult = (): CheckResult => ({
        check,
        label,
        status: 'fail',
        durationMs: Date.now() - startedAt,
        message: failure.message,
        nextAction: failure.nextAction,
        exitCode: failure.exitCode
    });
    if (options.verbose) {
        options.emit({
            kind: 'progress',
            operationId: options.operationId,
            timestamp: new Date().toISOString(),
            stepId: `doctor:${check}`,
            step: label,
            message: [request.executable, ...(request.arguments ?? [])].join(' '),
            diagnostic: true
        });
    }

    try {
        const result = await options.runCommand(request);
        if (!result.failed && result.exitCode === 0) {
            return {
                check,
                label,
                status: 'pass',
                durationMs: Date.now() - startedAt,
                message: 'Available'
            };
        }
    } catch {
        return failedResult();
    }

    return failedResult();
}

function skippedCheck(check: CheckName, label: string, message: string): CheckResult {
    return { check, label, status: 'skip', durationMs: 0, message };
}

function emitCheck(result: CheckResult, options: DoctorOptions): void {
    options.emit({
        kind: 'doctor-check',
        operationId: options.operationId,
        timestamp: new Date().toISOString(),
        check: result.check,
        label: result.label,
        status: result.status,
        durationMs: result.durationMs,
        message: result.message,
        ...(result.nextAction === undefined ? {} : { nextAction: result.nextAction })
    });
}

function selectExitCode(results: CheckResult[]): ExitCode {
    // Keep this precedence stable so prerequisite/config/auth failures map deterministically across interfaces.
    const failedCodes = results.flatMap((result) => (result.exitCode === undefined ? [] : [result.exitCode]));
    if (failedCodes.includes(EXIT_CODES.MISSING_PREREQUISITE)) return EXIT_CODES.MISSING_PREREQUISITE;
    if (failedCodes.includes(EXIT_CODES.INVALID_INPUT_OR_CONFIG)) return EXIT_CODES.INVALID_INPUT_OR_CONFIG;
    if (failedCodes.includes(EXIT_CODES.AUTH_OR_AUTHORIZATION_FAILURE)) return EXIT_CODES.AUTH_OR_AUTHORIZATION_FAILURE;
    return failedCodes[0] ?? EXIT_CODES.SUCCESS;
}

/**
 * Checks the local runtime, Salesforce tooling, project configuration, authentication,
 * and optional pool tooling, then emits a result for every check and one summary.
 *
 * Command failures are converted to check failures rather than thrown. The returned code
 * uses stable precedence: missing prerequisite, invalid configuration, authentication or
 * authorization failure, then the first remaining failure. This operation is read-only,
 * although the injected runner may invoke external executables.
 *
 * @param options - Diagnostic inputs, event sink, verbosity, and injected command runner.
 * @returns The stable aggregate exit code for all checks.
 * @throws `Error` Only when event emission or an unexpected dependency outside the
 * guarded command/configuration checks fails.
 */
export async function runDoctor(options: DoctorOptions): Promise<ExitCode> {
    const results: CheckResult[] = [nodeCheck(options.nodeVersion)];
    const sfCheck = await runCheck(
        'sf',
        'Salesforce CLI',
        { executable: 'sf', arguments: ['--version', '--json'], cwd: options.projectDirectory },
        options,
        {
            message: 'Salesforce CLI is unavailable',
            nextAction: 'Install Salesforce CLI and rerun sf-project doctor.',
            exitCode: EXIT_CODES.MISSING_PREREQUISITE
        }
    );
    results.push(sfCheck);

    let configuration: ProjectConfiguration | undefined;
    const projectStartedAt = Date.now();
    try {
        configuration = await loadProjectConfiguration(options.projectDirectory);
        results.push({
            check: 'project',
            label: 'Salesforce project configuration',
            status: 'pass',
            durationMs: Date.now() - projectStartedAt,
            message: 'Valid'
        });
    } catch {
        results.push({
            check: 'project',
            label: 'Salesforce project configuration',
            status: 'fail',
            durationMs: Date.now() - projectStartedAt,
            message: 'Configuration could not be loaded or validated',
            nextAction: 'Correct sfdx-project.json or sf-project.config.json and rerun sf-project doctor.',
            exitCode: EXIT_CODES.INVALID_INPUT_OR_CONFIG
        });
    }

    if (sfCheck.status === 'pass') {
        results.push(
            await runCheck(
                'auth',
                'Salesforce authentication and org read access',
                { executable: 'sf', arguments: ['org', 'list', '--json'], cwd: options.projectDirectory },
                options,
                {
                    message: 'No authenticated org could be read',
                    nextAction: 'Run sf org login web, then rerun sf-project doctor.',
                    exitCode: EXIT_CODES.AUTH_OR_AUTHORIZATION_FAILURE
                }
            )
        );
    } else {
        results.push(
            skippedCheck('auth', 'Salesforce authentication and org read access', 'Salesforce CLI is unavailable')
        );
    }

    if (configuration?.pool.use) {
        results.push(
            await runCheck(
                'sfp',
                'sfp pool support',
                { executable: 'sfp', arguments: ['--version'], cwd: options.projectDirectory },
                options,
                {
                    message: 'sfp is required by the configured pool support',
                    nextAction: 'Install sfp or disable pool support, then rerun sf-project doctor.',
                    exitCode: EXIT_CODES.MISSING_PREREQUISITE
                }
            )
        );
    } else {
        results.push(skippedCheck('sfp', 'sfp pool support', 'Pool support is not configured'));
    }

    results.forEach((result) => emitCheck(result, options));
    const exitCode = selectExitCode(results);
    options.emit({
        kind: 'doctor-summary',
        operationId: options.operationId,
        timestamp: new Date().toISOString(),
        passed: results.filter((result) => result.status === 'pass').length,
        failed: results.filter((result) => result.status === 'fail').length,
        skipped: results.filter((result) => result.status === 'skip').length,
        exitCode
    });
    return exitCode;
}
