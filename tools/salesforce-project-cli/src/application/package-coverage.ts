/**
 * Runs the optional post-package Apex coverage workflow through the injected Salesforce command runner.
 * No command is launched in dry-run mode; secrets are registered for output redaction.
 */
import type { CommandResult } from '../infrastructure/command-runner.js';
import type { CommandRunner } from './refresh-dependencies.js';

/** Inputs for a post-package aggregate coverage check. */
export interface PackageCoverageOptions {
    /** Target Salesforce org; callers must enforce org mutation policy before invoking this workflow. */
    targetOrg: string;
    /** Project directory used as the working directory for Salesforce CLI commands. */
    projectDirectory: string;
    /** Optional subscriber package version ID to install before deployment and tests. */
    packageId?: string;
    /** Installation key for a protected package; redacted by the command runner. */
    installationKey?: string;
    /** Minimum aggregate coverage percentage required for success. */
    minimumCoverage: number;
    /** Apex class run when runAllTests is false. */
    testClass: string;
    /** Run the full Apex test suite instead of a single class. */
    runAllTests: boolean;
    /** Skip the optional package installation. */
    skipInstall: boolean;
    /** Skip metadata deployment. */
    skipDeploy: boolean;
    /** Report planned work without launching commands. */
    dryRun?: boolean;
    /** Optional class-name LIKE pattern used for aggregate coverage. Defaults to `%`. */
    classNamePattern?: string;
    /** Timeout for the full-suite wait before trying the asynchronous fallback. */
    runAllTimeoutMs?: number;
    /** Injected command runner for deterministic tests and CLI execution. */
    runCommand: CommandRunner;
}

/** Aggregate coverage result for one target org. */
export interface PackageCoverageSummary {
    covered: number;
    uncovered: number;
    percentage: number;
    minimumCoverage: number;
    passed: boolean;
}

function failed(result: CommandResult): boolean {
    return result.failed || result.exitCode !== 0;
}

function parseJson(stdout: string, command: string): Record<string, unknown> {
    const start = stdout.indexOf('{');
    if (start < 0) throw new Error(`${command} returned no JSON`);
    try {
        return JSON.parse(stdout.slice(start)) as Record<string, unknown>;
    } catch {
        throw new Error(`${command} returned malformed JSON`);
    }
}

function resultError(result: CommandResult, command: string): Error {
    return new Error(
        result.error || result.stderr || result.stdout || `${command} failed with exit code ${result.exitCode}`
    );
}

async function execute(
    options: PackageCoverageOptions,
    commandArguments: string[],
    commandName: string,
    timeoutMs?: number
): Promise<CommandResult> {
    const result = await options.runCommand({
        executable: 'sf',
        arguments: commandArguments,
        cwd: options.projectDirectory,
        ...(timeoutMs === undefined ? {} : { timeoutMs }),
        ...(options.installationKey === undefined ? {} : { secretValues: [options.installationKey] })
    });
    if (failed(result)) throw resultError(result, commandName);
    return result;
}

async function runAllTests(options: PackageCoverageOptions): Promise<void> {
    const waitArguments = [
        'apex',
        'run',
        'test',
        '--target-org',
        options.targetOrg,
        '--code-coverage',
        '--wait',
        '120',
        '--json'
    ];
    const waited = await options.runCommand({
        executable: 'sf',
        arguments: waitArguments,
        cwd: options.projectDirectory,
        timeoutMs: options.runAllTimeoutMs ?? 7_300_000
    });
    if (!failed(waited)) return;

    const asyncRun = await execute(
        options,
        ['apex', 'run', 'test', '--target-org', options.targetOrg, '--code-coverage', '--json'],
        'sf apex run test'
    );
    const payload = parseJson(asyncRun.stdout, 'sf apex run test');
    const asyncResult = payload.result;
    const testRunId =
        asyncResult !== null && typeof asyncResult === 'object'
            ? (asyncResult as Record<string, unknown>).testRunId
            : undefined;
    if (typeof testRunId !== 'string' || testRunId.length === 0) {
        throw new Error('Could not parse testRunId from the async Apex test run.');
    }
    await execute(
        options,
        [
            'apex',
            'get',
            'test',
            '--target-org',
            options.targetOrg,
            '--test-run-id',
            testRunId,
            '--code-coverage',
            '--result-format',
            'human'
        ],
        'sf apex get test'
    );
}

/**
 * Optionally installs a package and deploys source, runs Apex tests, then checks aggregate coverage.
 *
 * The aggregate uses the tooling API and the configured class-name pattern, defaulting to `AAREG_%`.
 * A below-threshold result is returned as `passed: false` for the CLI adapter to map to an exit code.
 *
 * @param options - Target org, workflow options, threshold, and injected Salesforce command runner.
 * @returns The measured coverage summary, or `undefined` when dry-run planned the commands.
 * @throws `Error` If installation, deployment, tests, or coverage query fail.
 */
export async function runPackageCoverageCheck(
    options: PackageCoverageOptions
): Promise<PackageCoverageSummary | undefined> {
    if (!Number.isFinite(options.minimumCoverage) || options.minimumCoverage < 0 || options.minimumCoverage > 100) {
        throw new Error('minimumCoverage must be between 0 and 100.');
    }
    if (options.dryRun) return undefined;

    if (options.packageId && !options.skipInstall) {
        const installArguments = [
            'package',
            'install',
            '--target-org',
            options.targetOrg,
            '--package',
            options.packageId,
            '-r',
            '--json'
        ];
        if (options.installationKey) installArguments.push('--installation-key', options.installationKey);
        await execute(options, installArguments, 'sf package install');
    }
    if (!options.skipDeploy) {
        await execute(
            options,
            [
                'project',
                'deploy',
                'start',
                '--target-org',
                options.targetOrg,
                '--source-dir',
                'force-app',
                '--ignore-conflicts',
                '--json'
            ],
            'sf project deploy start'
        );
    }

    if (options.runAllTests) {
        await runAllTests(options);
    } else {
        await execute(
            options,
            [
                'apex',
                'run',
                'test',
                '--target-org',
                options.targetOrg,
                '--tests',
                options.testClass,
                '--code-coverage',
                '--synchronous',
                '--result-format',
                'human'
            ],
            'sf apex run test'
        );
    }

    const pattern = options.classNamePattern ?? '%';
    const escapedPattern = pattern.replace(/\\/g, '\\\\').replace(/'/g, "\\'");
    const soql = `SELECT SUM(NumLinesCovered) covered, SUM(NumLinesUncovered) uncovered FROM ApexCodeCoverageAggregate WHERE ApexClassOrTrigger.Name LIKE '${escapedPattern}'`;
    const queryResult = await execute(
        options,
        [
            'data',
            'query',
            '--target-org',
            options.targetOrg,
            '--use-tooling-api',
            '--query',
            soql,
            '--result-format',
            'json'
        ],
        'sf data query'
    );
    const payload = parseJson(queryResult.stdout, 'sf data query');
    const records = (payload.result as { records?: Array<Record<string, unknown>> } | undefined)?.records;
    const record = records?.[0];
    if (record === undefined) throw new Error('Coverage query returned no aggregate record.');
    const covered = Number(record.covered ?? 0);
    const uncovered = Number(record.uncovered ?? 0);
    if (!Number.isFinite(covered) || !Number.isFinite(uncovered))
        throw new Error('Coverage query returned invalid totals.');
    const total = covered + uncovered;
    const percentage = total > 0 ? Number(((covered / total) * 100).toFixed(2)) : 0;
    return {
        covered,
        uncovered,
        percentage,
        minimumCoverage: options.minimumCoverage,
        passed: percentage >= options.minimumCoverage
    };
}
