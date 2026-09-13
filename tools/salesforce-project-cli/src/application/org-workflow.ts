/**
 * Orchestrates org acquisition, configuration, post-steps, and deletion across application services.
 * Mutation requires an allowed org classification, and real deletion additionally requires explicit confirmation.
 */
import type { PostStep, ProjectConfiguration } from '../domain/config.js';
import { EXIT_CODES, type EventSink, type ExitCode } from '../domain/events.js';
import { isOrgMutationConfirmed, type OrgClassification } from '../domain/org-policy.js';
import type { CommandResult } from '../infrastructure/command-runner.js';
import { classifySalesforceFailure } from '../infrastructure/salesforce-errors.js';
import { clearDependencySources } from './clear-dependency-sources.js';
import { installPackages } from './package-operations.js';
import { refreshDependencies, type CommandRunner } from './refresh-dependencies.js';

const POST_STEP_ORDER: readonly PostStep[] = ['deploy', 'permsets', 'data', 'community'];

/** Shared inputs and injected dependencies for configuring an existing org. */
export interface ConfigureProjectOptions {
    /** Validated project configuration used by package, post-step, and refresh operations. */
    configuration: ProjectConfiguration;
    /** Target org alias; falls back to `configuration.defaultOrgAlias` when omitted. */
    alias?: string;
    /** Exact command-and-org token required to configure a non-scratch org. */
    confirmation?: string;
    /** Selected post-steps; execution always follows the service-defined canonical order. */
    postSteps: PostStep[];
    /** Whether dependency sources are refreshed after successful project configuration. */
    refreshDependencySources: boolean;
    /** When `true`, emits planned work without installing packages or invoking post-step commands. */
    dryRun: boolean;
    /** Environment used to resolve package installation keys without reading globals directly. */
    environment: Readonly<Record<string, string | undefined>>;
    /** Correlation identifier copied to emitted workflow events. */
    operationId: string;
    /** Event sink receiving package, step, workflow, and org summary events. */
    emit: EventSink;
    /** Injected runner used for every external command in the composed workflow. */
    runCommand: CommandRunner;
}

type ResolvedConfigureProjectOptions = ConfigureProjectOptions & { alias: string };

/** Inputs for acquiring a scratch org and then configuring it. */
export interface CreateOrgOptions extends Omit<ConfigureProjectOptions, 'alias'> {
    /** Alias assigned to the acquired or created scratch org. */
    alias: string;
    /** Requested scratch-org lifetime in days. */
    durationDays: number;
    /** Whether acquisition should use the configured `sfp` pool before direct creation. */
    usePool: boolean;
    /** Pool tag passed to `sfp` list and fetch commands. */
    poolTag: string;
    /** Dev Hub alias or username required for pool operations. */
    poolDevHub?: string;
    /** Whether an unavailable or empty pool may fall back to direct scratch-org creation. */
    fallbackToCreate: boolean;
    /** Whether dependency source directories are cleared before acquisition. */
    clearDependencySources: boolean;
}

/** Inputs and injected dependencies for deleting a scratch org. */
export interface DeleteOrgOptions {
    /** Validated project configuration providing the command working directory. */
    configuration: ProjectConfiguration;
    /** Alias of the org to delete. */
    alias: string;
    /** Previously inspected org classification used to enforce mutation policy. */
    classification: OrgClassification;
    /** Explicit confirmation required for a real deletion. */
    confirmed: boolean;
    /** Exact command-and-org token required to delete a non-scratch org. */
    confirmation?: string;
    /** When `true`, reports an allowed deletion without invoking the command runner. */
    dryRun: boolean;
    /** Correlation identifier copied to emitted events. */
    operationId: string;
    /** Event sink receiving command and org summary events. */
    emit: EventSink;
    /** Injected runner used for the delete command. */
    runCommand: CommandRunner;
}

function failed(result: CommandResult): boolean {
    return result.failed || result.exitCode !== 0;
}

function emitOrgSummary(
    options: Pick<ResolvedConfigureProjectOptions, 'alias' | 'dryRun' | 'emit' | 'operationId'>,
    acquisition: 'create' | 'pool' | 'delete' | 'configure',
    status: 'run' | 'failed' = 'run'
): void {
    options.emit({
        kind: 'org-summary',
        operationId: options.operationId,
        timestamp: new Date().toISOString(),
        alias: options.alias,
        acquisition,
        status,
        dryRun: options.dryRun
    });
}

async function runStep(
    options: Pick<ConfigureProjectOptions, 'configuration' | 'emit' | 'operationId' | 'runCommand'>,
    stepId: string,
    step: string,
    executable: string,
    commandArguments: string[]
): Promise<ExitCode> {
    const startedAt = Date.now();
    options.emit({
        kind: 'step-started',
        operationId: options.operationId,
        timestamp: new Date().toISOString(),
        stepId,
        step,
        attempt: 1
    });
    const result = await options.runCommand({
        executable,
        arguments: commandArguments,
        cwd: options.configuration.projectDirectory
    });
    if (failed(result)) {
        options.emit({
            kind: 'step-failed',
            operationId: options.operationId,
            timestamp: new Date().toISOString(),
            stepId,
            step,
            exitCode: result.exitCode,
            durationMs: Date.now() - startedAt,
            error: result.error ?? result.stderr ?? `${step} failed`
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

function postStepCommand(configuration: ProjectConfiguration, alias: string, postStep: PostStep): string[] | undefined {
    switch (postStep) {
        case 'deploy':
            return ['project', 'deploy', 'start', '--target-org', alias];
        case 'permsets':
            return configuration.permissionSets.length === 0
                ? undefined
                : [
                    'org',
                    'assign',
                    'permset',
                    '--target-org',
                    alias,
                    ...configuration.permissionSets.flatMap((permissionSet) => ['--name', permissionSet])
                ];
        case 'data':
            return configuration.dummyDataPlan === null
                ? undefined
                : ['data', 'import', 'tree', '--target-org', alias, '--plan', configuration.dummyDataPlan];
        case 'community':
            return configuration.communityName === null
                ? undefined
                : ['community', 'publish', '--target-org', alias, '--name', configuration.communityName];
    }
}

function postStepLabel(postStep: PostStep): string {
    return {
        deploy: 'Deploy metadata',
        permsets: 'Assign permission sets',
        data: 'Import dummy data',
        community: 'Publish community'
    }[postStep];
}

function emitPostStepResult(
    options: ResolvedConfigureProjectOptions,
    postStep: PostStep,
    status: 'run' | 'skipped' | 'warning' | 'failure',
    message: string
): void {
    options.emit({
        kind: 'post-step-result',
        operationId: options.operationId,
        timestamp: new Date().toISOString(),
        postStep,
        status,
        message,
        dryRun: options.dryRun
    });
}

async function runPostSteps(options: ResolvedConfigureProjectOptions): Promise<ExitCode> {
    let run = 0;
    let skipped = 0;
    let warnings = 0;

    for (const postStep of POST_STEP_ORDER) {
        if (!options.postSteps.includes(postStep)) {
            skipped += 1;
            emitPostStepResult(options, postStep, 'skipped', `${postStep} was not selected`);
            continue;
        }
        const commandArguments = postStepCommand(options.configuration, options.alias, postStep);
        if (commandArguments === undefined) {
            warnings += 1;
            emitPostStepResult(options, postStep, 'warning', `${postStep} has no configured value`);
            continue;
        }
        if (options.dryRun) {
            run += 1;
            emitPostStepResult(options, postStep, 'run', `Would run ${postStep}`);
            continue;
        }
        const stepExitCode = await runStep(
            options,
            `post-step:${postStep}`,
            postStepLabel(postStep),
            'sf',
            commandArguments
        );
        if (stepExitCode !== EXIT_CODES.SUCCESS) {
            emitPostStepResult(options, postStep, 'failure', `${postStep} failed`);
            options.emit({
                kind: 'workflow-summary',
                operationId: options.operationId,
                timestamp: new Date().toISOString(),
                run,
                skipped,
                warnings,
                failed: 1,
                dryRun: false
            });
            return stepExitCode;
        }
        run += 1;
        emitPostStepResult(options, postStep, 'run', `${postStep} completed`);
    }

    options.emit({
        kind: 'workflow-summary',
        operationId: options.operationId,
        timestamp: new Date().toISOString(),
        run,
        skipped,
        warnings,
        failed: 0,
        dryRun: options.dryRun
    });
    return EXIT_CODES.SUCCESS;
}

async function configureResolvedProject(options: ResolvedConfigureProjectOptions): Promise<ExitCode> {
    // Compose packages, canonical post-steps, and optional dependency refresh; stop at the first failed stage.
    emitOrgSummary(options, 'configure');
    if (!options.dryRun) {
        let packageExitCode: ExitCode;
        try {
            packageExitCode = await installPackages({
                configuration: options.configuration,
                targetOrg: options.alias,
                installLatest: false,
                dryRun: false,
                environment: options.environment,
                operationId: options.operationId,
                emit: options.emit,
                runCommand: options.runCommand
            });
        } catch (error) {
            options.emit({
                kind: 'step-failed',
                operationId: options.operationId,
                timestamp: new Date().toISOString(),
                stepId: 'packages:install',
                step: 'Install packages',
                exitCode: null,
                durationMs: 0,
                error: error instanceof Error ? error.message : String(error)
            });
            packageExitCode = EXIT_CODES.OPERATION_FAILURE;
        }
        if (packageExitCode !== EXIT_CODES.SUCCESS) {
            return packageExitCode;
        }
    } else {
        options.emit({
            kind: 'progress',
            operationId: options.operationId,
            timestamp: new Date().toISOString(),
            stepId: 'packages:install',
            step: 'Install packages',
            message: 'Would resolve and install packages',
            dryRun: true
        });
    }

    const postStepExitCode = await runPostSteps(options);
    if (postStepExitCode !== EXIT_CODES.SUCCESS) {
        return postStepExitCode;
    }
    if (options.refreshDependencySources) {
        return refreshDependencies({
            configuration: options.configuration,
            targetOrg: options.alias,
            dryRun: options.dryRun,
            operationId: options.operationId,
            emit: options.emit,
            runCommand: options.runCommand
        });
    }
    return EXIT_CODES.SUCCESS;
}

/**
 * Configures a target org by installing packages, running selected post-steps in canonical
 * order, and optionally refreshing dependency sources.
 *
 * Dry-run mode emits package and post-step intent and delegates refresh in dry-run mode; it does
 * not invoke package installation or post-step commands. Expected failures are returned as stable
 * exit codes. A missing explicit and default alias returns
 * `EXIT_CODES.INVALID_INPUT_OR_CONFIG`.
 *
 * @param options - Configuration workflow inputs, event sink, environment, and command runner.
 * @returns Success or the first package, post-step, or dependency-refresh exit code.
 * @throws `Error` When an injected dependency or event sink throws outside the guarded
 * package-install stage.
 */
export async function configureProject(options: ConfigureProjectOptions): Promise<ExitCode> {
    const alias = options.alias ?? options.configuration.defaultOrgAlias;
    if (alias === undefined) {
        options.emit({
            kind: 'step-failed',
            operationId: options.operationId,
            timestamp: new Date().toISOString(),
            stepId: 'configure:target',
            step: 'Resolve target org',
            exitCode: null,
            durationMs: 0,
            error: 'An org alias is required through alias or defaultOrgAlias'
        });
        return EXIT_CODES.INVALID_INPUT_OR_CONFIG;
    }
    return configureResolvedProject({ ...options, alias });
}

function parseUnusedPoolOrgCount(stdout: string): number | undefined {
    const match = stdout.match(/Unused Scratch Orgs in the Pool\s*:\s*(\d+)/i);
    return match?.[1] === undefined ? undefined : Number(match[1]);
}

async function resolvePoolDevHub(options: CreateOrgOptions): Promise<string | undefined> {
    if (options.poolDevHub !== undefined) return options.poolDevHub;
    const result = await options.runCommand({
        executable: 'sf',
        arguments: ['config', 'get', 'target-dev-hub', '--json'],
        cwd: options.configuration.projectDirectory
    });
    if (failed(result)) return undefined;
    try {
        const payload = JSON.parse(result.stdout) as { result?: Array<Record<string, unknown>> };
        const setting = payload.result?.find(
            (item) => item.name === 'target-dev-hub' || item.key === 'target-dev-hub'
        );
        return typeof setting?.value === 'string' && setting.value.length > 0 ? setting.value : undefined;
    } catch {
        return undefined;
    }
}

async function acquireFromPool(options: CreateOrgOptions): Promise<'acquired' | 'fallback' | ExitCode> {
    const poolDevHub = await resolvePoolDevHub(options);
    if (poolDevHub === undefined) {
        options.emit({
            kind: 'step-failed',
            operationId: options.operationId,
            timestamp: new Date().toISOString(),
            stepId: 'pool-list',
            step: 'List scratch org pool',
            exitCode: null,
            durationMs: 0,
            error: 'Pool use requires --pool-devhub, pool.devHub, or Salesforce target-dev-hub configuration'
        });
        return EXIT_CODES.INVALID_INPUT_OR_CONFIG;
    }
    const listResult = await options.runCommand({
        executable: 'sfp',
        arguments: ['pool', 'list', '--tag', options.poolTag, '-a', '--targetdevhubusername', poolDevHub],
        cwd: options.configuration.projectDirectory
    });
    if (failed(listResult)) {
        options.emit({
            kind: 'step-failed',
            operationId: options.operationId,
            timestamp: new Date().toISOString(),
            stepId: 'pool-list',
            step: 'List scratch org pool',
            exitCode: listResult.exitCode,
            durationMs: listResult.durationMs,
            error: listResult.error ?? listResult.stderr ?? 'Could not list scratch org pool'
        });
        return classifySalesforceFailure(listResult, EXIT_CODES.OPERATION_FAILURE);
    }
    const unusedCount = parseUnusedPoolOrgCount(listResult.stdout);
    if (unusedCount === undefined || unusedCount === 0) {
        options.emit({
            kind: 'warning',
            operationId: options.operationId,
            timestamp: new Date().toISOString(),
            stepId: 'pool-list',
            step: 'List scratch org pool',
            message:
                unusedCount === 0 ? 'No unused scratch orgs are available' : 'Could not determine pool availability',
            code: 'POOL_UNAVAILABLE'
        });
        return options.fallbackToCreate ? 'fallback' : EXIT_CODES.OPERATION_FAILURE;
    }
    const fetched = await runStep(options, 'pool-fetch', 'Fetch scratch org from pool', 'sfp', [
        'pool',
        'fetch',
        '--tag',
        options.poolTag,
        '--targetdevhubusername',
        poolDevHub,
        '--alias',
        options.alias,
        '--setdefaultusername'
    ]);
    return fetched === EXIT_CODES.SUCCESS ? 'acquired' : fetched;
}

async function acquireByCreation(options: CreateOrgOptions): Promise<ExitCode> {
    const deleteResult = await options.runCommand({
        executable: 'sf',
        arguments: ['org', 'delete', 'scratch', '--no-prompt', '--target-org', options.alias],
        cwd: options.configuration.projectDirectory
    });
    if (failed(deleteResult)) {
        options.emit({
            kind: 'warning',
            operationId: options.operationId,
            timestamp: new Date().toISOString(),
            stepId: 'org-delete-existing',
            step: 'Delete existing scratch org',
            message: `Could not delete existing scratch org ${options.alias}; continuing`,
            code: 'ORG_NOT_FOUND_OR_DELETE_FAILED'
        });
    }
    return runStep(options, 'org-create', 'Create scratch org', 'sf', [
        'org',
        'create',
        'scratch',
        '--set-default',
        '--definition-file',
        options.configuration.scratchDefinition,
        '--duration-days',
        String(options.durationDays),
        '--alias',
        options.alias
    ]);
}

/**
 * Acquires a scratch org from a pool or direct creation and composes project configuration.
 *
 * Pool configuration is validated before any cleanup. In dry-run mode no acquisition command is
 * executed, though configured dependency cleanup is delegated in dry-run mode and the complete
 * configuration plan is emitted. After successful acquisition, configuration failures become
 * `EXIT_CODES.PARTIAL_COMPLETION`, except authentication/authorization failures retain their
 * specific code because user action can resume the workflow.
 *
 * @param options - Scratch-org acquisition, configuration, dry-run, and injected service inputs.
 * @returns A stable exit code describing validation, acquisition, configuration, or partial completion.
 * @throws `Error` When dependency cleanup or another injected dependency throws outside a
 * command-failure translation boundary.
 */
export async function createOrg(options: CreateOrgOptions): Promise<ExitCode> {
    const resolvedPoolDevHub = options.usePool ? await resolvePoolDevHub(options) : options.poolDevHub;
    const resolvedOptions =
        resolvedPoolDevHub === undefined ? options : { ...options, poolDevHub: resolvedPoolDevHub };
    if (resolvedOptions.usePool && resolvedOptions.poolDevHub === undefined) {
        options.emit({
            kind: 'step-failed',
            operationId: options.operationId,
            timestamp: new Date().toISOString(),
            stepId: 'pool-configuration',
            step: 'Validate scratch org pool',
            exitCode: null,
            durationMs: 0,
            error: 'Pool use requires --pool-devhub, pool.devHub, or Salesforce target-dev-hub configuration'
        });
        return EXIT_CODES.INVALID_INPUT_OR_CONFIG;
    }
    if (resolvedOptions.clearDependencySources) {
        await clearDependencySources(resolvedOptions);
    }
    if (resolvedOptions.dryRun) {
        emitOrgSummary(resolvedOptions, resolvedOptions.usePool ? 'pool' : 'create');
        return configureProject(resolvedOptions);
    }

    let acquisition: 'create' | 'pool' = 'create';
    if (resolvedOptions.usePool) {
        const poolResult = await acquireFromPool(resolvedOptions);
        if (typeof poolResult === 'number') {
            emitOrgSummary(resolvedOptions, 'pool', 'failed');
            return poolResult;
        }
        if (poolResult === 'acquired') {
            acquisition = 'pool';
        } else {
            const createExitCode = await acquireByCreation(resolvedOptions);
            if (createExitCode !== EXIT_CODES.SUCCESS) {
                emitOrgSummary(resolvedOptions, 'create', 'failed');
                return createExitCode;
            }
        }
    } else {
        const createExitCode = await acquireByCreation(resolvedOptions);
        if (createExitCode !== EXIT_CODES.SUCCESS) {
            emitOrgSummary(resolvedOptions, 'create', 'failed');
            return createExitCode;
        }
    }
    emitOrgSummary(resolvedOptions, acquisition);

    const configureExitCode = await configureProject(resolvedOptions);
    if (configureExitCode === EXIT_CODES.SUCCESS || configureExitCode === EXIT_CODES.AUTH_OR_AUTHORIZATION_FAILURE) {
        return configureExitCode;
    }
    return EXIT_CODES.PARTIAL_COMPLETION;
}

/**
 * Deletes a confirmed scratch org when local mutation policy permits it.
 *
 * Real deletion requires both explicit confirmation and scratch classification. Dry-run still
 * enforces classification policy but does not require confirmation or invoke the command runner.
 * Policy rejection returns `EXIT_CODES.INVALID_INPUT_OR_CONFIG`; command failures are
 * classified into stable exit codes.
 *
 * @param options - Inspected classification, confirmation, dry-run state, and injected dependencies.
 * @returns Success, invalid input/configuration, or the classified command failure code.
 * @throws `Error` When the injected command runner or event sink throws.
 */
export async function deleteOrg(options: DeleteOrgOptions): Promise<ExitCode> {
    if (!options.confirmed && options.confirmation === undefined && !options.dryRun) {
        return EXIT_CODES.INVALID_INPUT_OR_CONFIG;
    }
    if (!isOrgMutationConfirmed(options.classification, 'org.delete', options.alias, options.confirmation)) {
        return EXIT_CODES.INVALID_INPUT_OR_CONFIG;
    }
    if (options.dryRun) {
        emitOrgSummary(options, 'delete');
        return EXIT_CODES.SUCCESS;
    }
    const deleteExitCode = await runStep(options, 'org-delete', 'Delete scratch org', 'sf', [
        'org',
        'delete',
        'scratch',
        '--no-prompt',
        '--target-org',
        options.alias
    ]);
    emitOrgSummary(options, 'delete', deleteExitCode === EXIT_CODES.SUCCESS ? 'run' : 'failed');
    return deleteExitCode;
}
