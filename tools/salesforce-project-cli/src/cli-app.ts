/**
 * Composes CLI commands from application services and injectable runtime boundaries.
 * Command output is redacted before emission, and handlers return stable exit codes without terminating the process.
 */
import { randomUUID } from 'node:crypto';
import { Command, CommanderError } from 'commander';
import { ZodError } from 'zod';
import { clearDependencySources } from './application/clear-dependency-sources.js';
import { runDoctor } from './application/doctor.js';
import { recoverForceignoreTransaction } from './application/forceignore-transaction.js';
import { getOrgInfo, getOrgStatus, listOrgs, renderOrgInfo, renderOrgSummary } from './application/org-inspection.js';
import { isOrgMutationConfirmed, mutationConfirmationToken } from './domain/org-policy.js';
import { configureProject, createOrg, deleteOrg } from './application/org-workflow.js';
import { installPackages, planPackages, updatePackages } from './application/package-operations.js';
import { refreshDependencies, type CommandRunner } from './application/refresh-dependencies.js';
import { createWebServiceFacade } from './application/web-service-facade.js';
import { loadProjectConfiguration, type PostStep, type ProjectConfiguration } from './domain/config.js';
import { EXIT_CODES, type ExitCode, type OperationEvent } from './domain/events.js';
import { runCommand } from './infrastructure/command-runner.js';
import { createEventWriter } from './infrastructure/output.js';
import { createRedactingEventSink, createRedactor } from './infrastructure/redactor.js';
import { classifySalesforceFailure } from './infrastructure/salesforce-errors.js';
import { startWebServer, type StartWebServerOptions, type StartedWebServer } from './web/server.js';

/** Output channels used by the CLI instead of writing to process streams directly. */
export interface CliOutput {
    /** Receives normal command output, including human-readable text and JSON event lines. */
    stdout: (line: string) => void;
    /** Receives validation, prerequisite, and operation error messages. */
    stderr: (line: string) => void;
    /** Enables terminal styling when `true`; omitted or `false` produces unstyled output. */
    isTTY?: boolean;
}

interface ClearOptions {
    projectDir: string;
    dryRun: boolean;
    json: boolean;
}

interface RefreshOptions extends ClearOptions {
    targetOrg?: string;
}

interface PackageOptions extends RefreshOptions {
    installLatest: boolean;
    confirmMutation?: string;
}

interface OrgCreateOptions extends ClearOptions {
    alias?: string;
    targetOrg?: string;
    durationDays?: string;
    postSteps?: string;
    usePool?: boolean;
    poolTag?: string;
    poolDevhub?: string;
    fallbackToCreate?: boolean;
    clearDependencySources?: boolean;
    refreshDependencySources?: boolean;
    yes?: boolean;
}

interface OrgDeleteOptions extends ClearOptions {
    alias?: string;
    targetOrg?: string;
    yes?: boolean;
    confirmMutation?: string;
}

interface OrgReadOptions {
    projectDir: string;
    json: boolean;
    refresh?: boolean;
}

interface OrgInfoOptions extends OrgReadOptions {
    alias: string;
}

interface ProjectConfigureOptions extends ClearOptions {
    alias?: string;
    targetOrg?: string;
    postSteps?: string;
    refreshDependencySources?: boolean;
    confirmMutation?: string;
}

interface DoctorCliOptions {
    projectDir: string;
    json: boolean;
}

/** Replaceable runtime dependencies for embedding or testing the CLI without process-global side effects. */
export interface CliDependencies {
    /** Executes external commands; defaults to the production command runner and may spawn child processes. */
    runCommand?: CommandRunner;
    /** Supplies environment values, including package installation secrets; defaults to `process.env`. */
    environment?: Readonly<Record<string, string | undefined>>;
    /** Overrides the Node.js version inspected by `doctor`; defaults to the active runtime version. */
    nodeVersion?: string;
    /** Starts the loopback web server; injected implementations must honor the returned handle's lifecycle contract. */
    startWebServer?: (options: StartWebServerOptions) => Promise<StartedWebServer>;
}

const SENSITIVE_ARGUMENTS = new Set(['--alias', '--installation-key', '--target-org', '--targetdevhubusername']);

function renderSafeCommand(executable: string, commandArguments: readonly string[]): string {
    const safeArguments = commandArguments.map((argument, index) =>
        index > 0 && SENSITIVE_ARGUMENTS.has(commandArguments[index - 1] ?? '') ? '[REDACTED]' : argument
    );
    return [executable, ...safeArguments].join(' ');
}

function createEventCommandRunner(
    runner: CommandRunner,
    operationId: string,
    emit: (event: OperationEvent) => void,
    verbose: boolean
): CommandRunner {
    return async (request) => {
        if (verbose) {
            emit({
                kind: 'progress',
                operationId,
                timestamp: new Date().toISOString(),
                stepId: `command:${request.executable}`,
                step: 'Run command',
                message: renderSafeCommand(request.executable, request.arguments ?? []),
                diagnostic: true
            });
        }
        return runner(request);
    };
}

function requireAlias(options: { alias?: string; targetOrg?: string }, configuration: ProjectConfiguration): string {
    const alias = options.alias ?? options.targetOrg ?? configuration.defaultOrgAlias;
    if (alias === undefined) {
        throw new CommanderError(
            EXIT_CODES.INVALID_INPUT_OR_CONFIG,
            'sf-project.missingAlias',
            'An org alias is required through --alias, --target-org, or defaultOrgAlias'
        );
    }
    return alias;
}

async function assertMutationTarget(
    projectDirectory: string,
    alias: string | undefined,
    operation: string,
    confirmation: string | undefined,
    runCommand: CommandRunner
): Promise<void> {
    const inspected =
        alias === undefined
            ? await getOrgStatus({ projectDirectory, runCommand })
            : await getOrgInfo({ projectDirectory, alias, runCommand });
    const target = inspected.org.alias ?? inspected.org.username ?? alias;
    if (target === null || target === undefined) {
        throw new CommanderError(
            EXIT_CODES.INVALID_INPUT_OR_CONFIG,
            'sf-project.missingMutationTarget',
            'A resolvable target org is required for mutation'
        );
    }
    if (!isOrgMutationConfirmed(inspected.org.orgType, operation, target, confirmation)) {
        throw new CommanderError(
            EXIT_CODES.INVALID_INPUT_OR_CONFIG,
            'sf-project.mutationNotAllowed',
            `Mutation is restricted to scratch orgs. Override requires: ${mutationConfirmationToken(operation, target)}`
        );
    }
}

function parseDurationDays(value: string | undefined, configuration: ProjectConfiguration): number {
    const durationDays = value === undefined ? configuration.scratchDurationDays : Number(value);
    if (!Number.isInteger(durationDays) || durationDays < 1 || durationDays > 30) {
        throw new CommanderError(
            EXIT_CODES.INVALID_INPUT_OR_CONFIG,
            'sf-project.invalidDuration',
            '--duration-days must be an integer from 1 to 30'
        );
    }
    return durationDays;
}

function parsePort(value: string): number {
    const port = Number(value);
    if (!Number.isInteger(port) || port < 0 || port > 65_535) {
        throw new CommanderError(
            EXIT_CODES.INVALID_INPUT_OR_CONFIG,
            'sf-project.invalidPort',
            '--port must be an integer from 0 to 65535'
        );
    }
    return port;
}

function parsePostSteps(value: string | undefined, configuration: ProjectConfiguration): PostStep[] {
    if (value === undefined) {
        return configuration.postSteps;
    }
    if (value === 'all') {
        return ['deploy', 'permsets', 'data', 'community'];
    }
    if (value === 'none') {
        return [];
    }
    const postSteps = value.split(',').filter(Boolean);
    const validPostSteps: readonly string[] = ['deploy', 'permsets', 'data', 'community'];
    if (postSteps.some((postStep) => !validPostSteps.includes(postStep))) {
        throw new CommanderError(
            EXIT_CODES.INVALID_INPUT_OR_CONFIG,
            'sf-project.invalidPostSteps',
            '--post-steps accepts all, none, deploy, permsets, data, and community'
        );
    }
    return postSteps as PostStep[];
}

function emitPackageFailure(
    emit: (event: OperationEvent) => void,
    operationId: string,
    stepId: string,
    error: string,
    total: number
): void {
    const timestamp = new Date().toISOString();
    emit({
        kind: 'step-failed',
        operationId,
        timestamp,
        stepId,
        step: 'Resolve packages',
        exitCode: null,
        durationMs: 0,
        error
    });
    emit({
        kind: 'package-summary',
        operationId,
        timestamp,
        total,
        missing: 0,
        installed: 0,
        updated: 0,
        skipped: 0,
        higher: 0,
        failed: 1
    });
}

/**
 * Parses and executes one CLI invocation using caller-owned output channels and optional runtime dependencies.
 *
 * Command handlers may inspect or mutate the project, invoke external tools, or start a web server according to
 * the selected command. Expected user, configuration, prerequisite, and operation failures are converted to stable
 * numeric exit codes instead of being rethrown.
 *
 * @param argv - Command arguments without the Node.js executable or script path.
 * @param output - Destination channels for all user-visible output.
 * @param cliDependencies - Optional injected environment and side-effecting services.
 * @returns The process exit code for the completed invocation.
 */
export async function runCli(
    argv: string[],
    output: CliOutput,
    cliDependencies: CliDependencies = {}
): Promise<number> {
    const projectDirectoryIndex = argv.indexOf('--project-dir');
    const normalizedArgv =
        projectDirectoryIndex === 0 && argv[1] !== undefined ? [...argv.slice(2), '--project-dir', argv[1]] : argv;
    const program = new Command();
    let exitCode: ExitCode = EXIT_CODES.SUCCESS;
    program.exitOverride();
    program.configureOutput({
        writeOut: (value) => output.stdout(value.trimEnd()),
        writeErr: (value) => output.stderr(value.trimEnd())
    });
    program.name('sf-project');
    program
        .option('--no-color', 'Disable terminal styling')
        .option('--verbose', 'Include sanitized diagnostic details', false);
    const writeEvent = (event: OperationEvent, json: boolean): void => {
        const globalOptions = program.opts<{ color: boolean; verbose: boolean }>();
        createEventWriter({
            color: output.isTTY === true && globalOptions.color !== false,
            verbose: globalOptions.verbose,
            json,
            output
        })(event);
    };

    program
        .command('doctor')
        .option('--project-dir <path>', 'Salesforce project root', process.cwd())
        .option('--json', 'Emit newline-delimited JSON events', false)
        .action(async (options: DoctorCliOptions) => {
            const operationId = randomUUID();
            const operation = 'doctor';
            const startedAt = Date.now();
            const redactor = createRedactor();
            const emit = createRedactingEventSink(redactor, (event) => writeEvent(event, options.json));
            const verbose = program.opts<{ verbose: boolean }>().verbose;

            emit({
                kind: 'operation-started',
                operationId,
                operation,
                timestamp: new Date().toISOString(),
                dryRun: false
            });
            const doctorExitCode = await runDoctor({
                projectDirectory: options.projectDir,
                nodeVersion: cliDependencies.nodeVersion ?? process.versions.node,
                operationId,
                emit,
                runCommand: cliDependencies.runCommand ?? runCommand,
                verbose
            });
            exitCode = doctorExitCode;
            emit({
                kind: 'operation-completed',
                operationId,
                operation,
                timestamp: new Date().toISOString(),
                exitCode: doctorExitCode,
                durationMs: Date.now() - startedAt,
                dryRun: false
            });
        });

    const web = program.command('web');
    web.command('start')
        .option('--project-dir <path>', 'Salesforce project root', process.cwd())
        .option('--port <port>', 'Local HTTP port', '1717')
        .action(async (options: { projectDir: string; port: string }) => {
            const port = parsePort(options.port);
            const environment = cliDependencies.environment ?? process.env;
            const configuration = await loadProjectConfiguration(options.projectDir);
            const installationKey = environment[configuration.packageInstallKeyEnvironmentVariable];
            const started = await (cliDependencies.startWebServer ?? startWebServer)({
                facade: createWebServiceFacade({
                    projectDirectory: options.projectDir,
                    environment,
                    runCommand: cliDependencies.runCommand ?? runCommand
                }),
                host: '127.0.0.1',
                port,
                ...(installationKey === undefined ? {} : { redactionSecrets: [installationKey] })
            });
            output.stdout(`Web server listening at ${started.url}`);
        });

    const org = program.command('org');
    org.command('list')
        .option('--project-dir <path>', 'Salesforce project root', process.cwd())
        .option('--refresh', 'Refresh org details before displaying them', false)
        .option('--json', 'Emit normalized JSON output', false)
        .action(async (options: OrgReadOptions) => {
            const result = await listOrgs({
                projectDirectory: options.projectDir,
                runCommand: cliDependencies.runCommand ?? runCommand,
                refresh: options.refresh ?? false
            });
            output.stdout(options.json ? JSON.stringify(result) : result.orgs.map(renderOrgSummary).join('\n\n'));
        });

    org.command('status')
        .argument('[alias]', 'Org alias or username')
        .option('--project-dir <path>', 'Salesforce project root', process.cwd())
        .option('--refresh', 'Refresh org details before displaying them', false)
        .option('--json', 'Emit normalized JSON output', false)
        .action(async (alias: string | undefined, options: OrgReadOptions) => {
            const result = await getOrgStatus({
                projectDirectory: options.projectDir,
                ...(alias === undefined ? {} : { alias }),
                refresh: options.refresh ?? false,
                runCommand: cliDependencies.runCommand ?? runCommand
            });
            output.stdout(options.json ? JSON.stringify(result) : renderOrgSummary(result.org));
        });

    org.command('info')
        .argument('<alias>', 'Org alias or username')
        .option('--project-dir <path>', 'Salesforce project root', process.cwd())
        .option('--json', 'Emit normalized JSON output', false)
        .action(async (alias: string, options: OrgInfoOptions) => {
            const result = await getOrgInfo({
                projectDirectory: options.projectDir,
                alias,
                runCommand: cliDependencies.runCommand ?? runCommand
            });
            output.stdout(options.json ? JSON.stringify(result) : renderOrgInfo(result.org));
        });

    org.command('create')
        .option('--project-dir <path>', 'Salesforce project root', process.cwd())
        .option('--alias <alias>', 'Scratch org alias')
        .option('--target-org <alias>', 'Scratch org alias')
        .option('--duration-days <days>', 'Scratch org duration in days')
        .option('--use-pool', 'Fetch a scratch org from an sfp pool')
        .option('--pool-tag <tag>', 'sfp pool tag')
        .option('--pool-devhub <alias>', 'Dev Hub alias for sfp pool commands')
        .option('--fallback-to-create', 'Create a scratch org when the pool is empty')
        .option('--no-fallback-to-create', 'Fail when the pool is empty')
        .option('--post-steps <steps>', 'Comma-separated post steps')
        .option('--clear-dependency-sources', 'Clear dependency source directories before org acquisition')
        .option('--refresh-dependency-sources', 'Retrieve dependency sources after project setup')
        .option('--dry-run', 'Plan without mutating an org', false)
        .option('--json', 'Emit newline-delimited JSON events', false)
        .option('--yes', 'Confirm eligible destructive actions', false)
        .action(async (options: OrgCreateOptions) => {
            const operationId = randomUUID();
            const operation = 'org.create';
            const startedAt = Date.now();
            const configuration = await loadProjectConfiguration(options.projectDir);
            const alias = requireAlias(options, configuration);
            const durationDays = parseDurationDays(options.durationDays, configuration);
            const postSteps = parsePostSteps(options.postSteps, configuration);
            const emit = createRedactingEventSink(createRedactor(), (event) => writeEvent(event, options.json));
            emit({
                kind: 'operation-started',
                operationId,
                operation,
                timestamp: new Date().toISOString(),
                dryRun: options.dryRun
            });
            const orgExitCode = await createOrg({
                configuration,
                alias,
                durationDays,
                postSteps,
                usePool: options.usePool ?? configuration.pool.use,
                poolTag: options.poolTag ?? configuration.pool.tag,
                ...((options.poolDevhub ?? configuration.pool.devHub) === undefined
                    ? {}
                    : { poolDevHub: options.poolDevhub ?? configuration.pool.devHub }),
                fallbackToCreate: options.fallbackToCreate ?? configuration.pool.fallbackToCreate,
                clearDependencySources: options.clearDependencySources ?? false,
                refreshDependencySources: options.refreshDependencySources ?? false,
                dryRun: options.dryRun,
                environment: cliDependencies.environment ?? process.env,
                operationId,
                emit,
                runCommand: createEventCommandRunner(
                    cliDependencies.runCommand ?? runCommand,
                    operationId,
                    emit,
                    program.opts<{ verbose: boolean }>().verbose
                )
            });
            exitCode = orgExitCode;
            emit({
                kind: 'operation-completed',
                operationId,
                operation,
                timestamp: new Date().toISOString(),
                exitCode: orgExitCode,
                durationMs: Date.now() - startedAt,
                dryRun: options.dryRun
            });
        });

    org.command('delete')
        .option('--project-dir <path>', 'Salesforce project root', process.cwd())
        .option('--alias <alias>', 'Scratch org alias')
        .option('--target-org <alias>', 'Scratch org alias')
        .option('--dry-run', 'Plan without deleting an org', false)
        .option('--json', 'Emit newline-delimited JSON events', false)
        .option('--yes', 'Confirm scratch org deletion', false)
        .option('--confirm-mutation <text>', 'Override scratch-only policy with exact command and org text')
        .action(async (options: OrgDeleteOptions) => {
            const operationId = randomUUID();
            const operation = 'org.delete';
            const startedAt = Date.now();
            const configuration = await loadProjectConfiguration(options.projectDir);
            const alias = requireAlias(options, configuration);
            const emit = createRedactingEventSink(createRedactor(), (event) => writeEvent(event, options.json));
            emit({
                kind: 'operation-started',
                operationId,
                operation,
                timestamp: new Date().toISOString(),
                dryRun: options.dryRun
            });
            const eventCommandRunner = createEventCommandRunner(
                cliDependencies.runCommand ?? runCommand,
                operationId,
                emit,
                program.opts<{ verbose: boolean }>().verbose
            );
            let deleteExitCode: ExitCode;
            if (options.dryRun) {
                deleteExitCode = await deleteOrg({
                    configuration,
                    alias,
                    classification: 'scratch',
                    confirmed: options.yes ?? false,
                    dryRun: true,
                    operationId,
                    emit,
                    runCommand: eventCommandRunner
                });
            } else {
                const inspected = await getOrgInfo({
                    projectDirectory: options.projectDir,
                    alias,
                    runCommand: eventCommandRunner
                });
                deleteExitCode =
                    inspected.org.authStatus === 'unauthenticated' || inspected.org.authStatus === 'expired'
                        ? EXIT_CODES.AUTH_OR_AUTHORIZATION_FAILURE
                        : await deleteOrg({
                              configuration,
                              alias,
                              classification: inspected.org.orgType,
                              confirmed: options.yes ?? false,
                              ...(options.confirmMutation === undefined
                                  ? {}
                                  : { confirmation: options.confirmMutation }),
                              dryRun: false,
                              operationId,
                              emit,
                              runCommand: eventCommandRunner
                          });
            }
            exitCode = deleteExitCode;
            emit({
                kind: 'operation-completed',
                operationId,
                operation,
                timestamp: new Date().toISOString(),
                exitCode: deleteExitCode,
                durationMs: Date.now() - startedAt,
                dryRun: options.dryRun
            });
        });

    const project = program.command('project');
    project
        .command('configure')
        .option('--project-dir <path>', 'Salesforce project root', process.cwd())
        .option('--alias <alias>', 'Target org alias')
        .option('--target-org <alias>', 'Target org alias')
        .option('--post-steps <steps>', 'Comma-separated post steps')
        .option('--refresh-dependency-sources', 'Retrieve dependency sources after project setup')
        .option('--dry-run', 'Plan without mutating an org', false)
        .option('--json', 'Emit newline-delimited JSON events', false)
        .option('--confirm-mutation <text>', 'Override scratch-only policy with exact command and org text')
        .action(async (options: ProjectConfigureOptions) => {
            const operationId = randomUUID();
            const operation = 'project.configure';
            const startedAt = Date.now();
            const configuration = await loadProjectConfiguration(options.projectDir);
            const alias = requireAlias(options, configuration);
            const emit = createRedactingEventSink(createRedactor(), (event) => writeEvent(event, options.json));
            emit({
                kind: 'operation-started',
                operationId,
                operation,
                timestamp: new Date().toISOString(),
                dryRun: options.dryRun
            });
            if (!options.dryRun) {
                await assertMutationTarget(
                    options.projectDir,
                    alias,
                    'project.configure',
                    options.confirmMutation,
                    cliDependencies.runCommand ?? runCommand
                );
            }
            const configureExitCode = await configureProject({
                configuration,
                alias,
                postSteps: parsePostSteps(options.postSteps, configuration),
                refreshDependencySources: options.refreshDependencySources ?? false,
                dryRun: options.dryRun,
                environment: cliDependencies.environment ?? process.env,
                operationId,
                emit,
                runCommand: createEventCommandRunner(
                    cliDependencies.runCommand ?? runCommand,
                    operationId,
                    emit,
                    program.opts<{ verbose: boolean }>().verbose
                )
            });
            exitCode = configureExitCode;
            emit({
                kind: 'operation-completed',
                operationId,
                operation,
                timestamp: new Date().toISOString(),
                exitCode: configureExitCode,
                durationMs: Date.now() - startedAt,
                dryRun: options.dryRun
            });
        });

    const dependencies = program.command('dependencies');
    dependencies
        .command('clear')
        .option('--project-dir <path>', 'Salesforce project root', process.cwd())
        .option('--dry-run', 'Plan without changing files', false)
        .option('--json', 'Emit newline-delimited JSON events', false)
        .action(async (options: ClearOptions) => {
            const operationId = randomUUID();
            const operation = 'dependencies.clear';
            const startedAt = Date.now();
            const emit = (event: OperationEvent): void => writeEvent(event, options.json);

            emit({
                kind: 'operation-started',
                operationId,
                operation,
                timestamp: new Date().toISOString(),
                dryRun: options.dryRun
            });

            const configuration = await loadProjectConfiguration(options.projectDir);
            await clearDependencySources({
                configuration,
                dryRun: options.dryRun,
                operationId,
                emit
            });

            emit({
                kind: 'operation-completed',
                operationId,
                operation,
                timestamp: new Date().toISOString(),
                exitCode: EXIT_CODES.SUCCESS,
                durationMs: Date.now() - startedAt,
                dryRun: options.dryRun
            });
        });

    dependencies
        .command('recover')
        .option('--project-dir <path>', 'Salesforce project root', process.cwd())
        .option('--dry-run', 'Show the validated recovery plan without changing files', false)
        .option('--json', 'Emit newline-delimited JSON events', false)
        .action(async (options: ClearOptions) => {
            const operationId = randomUUID();
            const operation = 'dependencies.recover';
            const startedAt = Date.now();
            const emit = (event: OperationEvent): void => writeEvent(event, options.json);
            emit({
                kind: 'operation-started',
                operationId,
                operation,
                timestamp: new Date().toISOString(),
                dryRun: options.dryRun
            });
            const recoverExitCode = await recoverForceignoreTransaction({
                projectDirectory: options.projectDir,
                dryRun: options.dryRun,
                operationId,
                emit
            });
            exitCode = recoverExitCode;
            emit({
                kind: 'operation-completed',
                operationId,
                operation,
                timestamp: new Date().toISOString(),
                exitCode: recoverExitCode,
                durationMs: Date.now() - startedAt,
                dryRun: options.dryRun
            });
        });

    const packages = program.command('packages');
    packages
        .command('plan')
        .option('--project-dir <path>', 'Salesforce project root', process.cwd())
        .option('--target-org <alias-or-username>', 'Salesforce target org')
        .option('--install-latest', 'Select the latest released package version', false)
        .option('--dry-run', 'Plan without installing packages', false)
        .option('--json', 'Emit newline-delimited JSON events', false)
        .action(async (options: PackageOptions) => {
            const operationId = randomUUID();
            const operation = 'packages.plan';
            const startedAt = Date.now();
            const redactor = createRedactor();
            const emit = createRedactingEventSink(redactor, (event) => writeEvent(event, options.json));

            emit({
                kind: 'operation-started',
                operationId,
                operation,
                timestamp: new Date().toISOString(),
                dryRun: options.dryRun
            });
            const configuration = await loadProjectConfiguration(options.projectDir);
            let packageExitCode: ExitCode = EXIT_CODES.SUCCESS;
            try {
                await planPackages({
                    configuration,
                    ...(options.targetOrg === undefined ? {} : { targetOrg: options.targetOrg }),
                    installLatest: options.installLatest,
                    operationId,
                    emit,
                    runCommand: createEventCommandRunner(
                        cliDependencies.runCommand ?? runCommand,
                        operationId,
                        emit,
                        program.opts<{ verbose: boolean }>().verbose
                    )
                });
            } catch (error) {
                packageExitCode = classifySalesforceFailure(error, EXIT_CODES.OPERATION_FAILURE);
                const message = redactor.redactError(error);
                output.stderr(message);
                emitPackageFailure(
                    emit,
                    operationId,
                    'packages:plan',
                    message,
                    configuration.packageDependencies.length
                );
            }
            exitCode = packageExitCode;
            emit({
                kind: 'operation-completed',
                operationId,
                operation,
                timestamp: new Date().toISOString(),
                exitCode: packageExitCode,
                durationMs: Date.now() - startedAt,
                dryRun: options.dryRun
            });
        });

    const registerPackageMutation = (commandName: 'install' | 'update'): void => {
        packages
            .command(commandName)
            .option('--project-dir <path>', 'Salesforce project root', process.cwd())
            .option('--target-org <alias-or-username>', 'Salesforce target org')
            .option('--install-latest', 'Select the latest released package version', false)
            .option('--dry-run', 'Query and plan without installing packages', false)
            .option('--json', 'Emit newline-delimited JSON events', false)
            .option('--confirm-mutation <text>', 'Override scratch-only policy with exact command and org text')
            .action(async (options: PackageOptions) => {
                const operationId = randomUUID();
                const operation = `packages.${commandName}`;
                const startedAt = Date.now();
                const configuration = await loadProjectConfiguration(options.projectDir);
                const environment = cliDependencies.environment ?? process.env;
                const installationKey = environment[configuration.packageInstallKeyEnvironmentVariable];
                const redactor = createRedactor(installationKey === undefined ? [] : [installationKey]);
                const emit = createRedactingEventSink(redactor, (event) => writeEvent(event, options.json));

                emit({
                    kind: 'operation-started',
                    operationId,
                    operation,
                    timestamp: new Date().toISOString(),
                    dryRun: options.dryRun
                });
                if (!options.dryRun) {
                    await assertMutationTarget(
                        options.projectDir,
                        options.targetOrg,
                        `packages.${commandName}`,
                        options.confirmMutation,
                        cliDependencies.runCommand ?? runCommand
                    );
                }
                const mutate = commandName === 'install' ? installPackages : updatePackages;
                let packageExitCode: ExitCode;
                try {
                    packageExitCode = await mutate({
                        configuration,
                        ...(options.targetOrg === undefined ? {} : { targetOrg: options.targetOrg }),
                        installLatest: options.installLatest,
                        dryRun: options.dryRun,
                        environment,
                        operationId,
                        emit,
                        runCommand: createEventCommandRunner(
                            cliDependencies.runCommand ?? runCommand,
                            operationId,
                            emit,
                            program.opts<{ verbose: boolean }>().verbose
                        )
                    });
                } catch (error) {
                    packageExitCode = classifySalesforceFailure(error, EXIT_CODES.OPERATION_FAILURE);
                    const message = redactor.redactError(error);
                    output.stderr(message);
                    emitPackageFailure(
                        emit,
                        operationId,
                        `packages:${commandName}`,
                        message,
                        configuration.packageDependencies.length
                    );
                }
                exitCode = packageExitCode;
                emit({
                    kind: 'operation-completed',
                    operationId,
                    operation,
                    timestamp: new Date().toISOString(),
                    exitCode: packageExitCode,
                    durationMs: Date.now() - startedAt,
                    dryRun: options.dryRun
                });
            });
    };

    registerPackageMutation('install');
    registerPackageMutation('update');

    dependencies
        .command('refresh')
        .option('--project-dir <path>', 'Salesforce project root', process.cwd())
        .option('--target-org <alias-or-username>', 'Salesforce target org')
        .option('--dry-run', 'Plan without changing files or retrieving metadata', false)
        .option('--json', 'Emit newline-delimited JSON events', false)
        .action(async (options: RefreshOptions) => {
            const operationId = randomUUID();
            const operation = 'dependencies.refresh';
            const startedAt = Date.now();
            const emit = createRedactingEventSink(createRedactor(), (event) => writeEvent(event, options.json));

            emit({
                kind: 'operation-started',
                operationId,
                operation,
                timestamp: new Date().toISOString(),
                dryRun: options.dryRun
            });

            const configuration = await loadProjectConfiguration(options.projectDir);
            const refreshExitCode = await refreshDependencies({
                configuration,
                ...(options.targetOrg === undefined ? {} : { targetOrg: options.targetOrg }),
                dryRun: options.dryRun,
                operationId,
                emit,
                runCommand: createEventCommandRunner(
                    cliDependencies.runCommand ?? runCommand,
                    operationId,
                    emit,
                    program.opts<{ verbose: boolean }>().verbose
                )
            });
            exitCode = refreshExitCode;

            emit({
                kind: 'operation-completed',
                operationId,
                operation,
                timestamp: new Date().toISOString(),
                exitCode: refreshExitCode,
                durationMs: Date.now() - startedAt,
                dryRun: options.dryRun
            });
        });

    // Commander is configured to throw so embedders receive an exit code rather than a process exit.
    try {
        await program.parseAsync(normalizedArgv, { from: 'user' });
        return exitCode;
    } catch (error) {
        if (error instanceof CommanderError) {
            if (error.exitCode !== 0 && error.code.startsWith('sf-project.')) {
                output.stderr(error.message);
            }
            return error.exitCode === 0 ? EXIT_CODES.SUCCESS : EXIT_CODES.INVALID_INPUT_OR_CONFIG;
        }
        if (error instanceof SyntaxError || error instanceof ZodError) {
            output.stderr(error.message);
            return EXIT_CODES.INVALID_INPUT_OR_CONFIG;
        }
        if (error instanceof Error && 'code' in error && error.code === 'ENOENT') {
            output.stderr(error.message);
            return EXIT_CODES.MISSING_PREREQUISITE;
        }
        output.stderr(error instanceof Error ? error.message : String(error));
        return EXIT_CODES.OPERATION_FAILURE;
    }
}
