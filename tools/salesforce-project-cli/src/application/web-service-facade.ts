/**
 * Adapts validated web operation requests to the shared application-service contracts.
 * The facade captures injected dependencies once while delegated services retain side-effect and policy ownership.
 */
import { clearDependencySources } from './clear-dependency-sources.js';
import { getOrgInfo, getOrgStatus, listOrgs } from './org-inspection.js';
import { configureProject, createOrg, deleteOrg } from './org-workflow.js';
import { getOrgPackageStatus, installPackages, planPackages, updatePackages } from './package-operations.js';
import { refreshDependencies, type CommandRunner } from './refresh-dependencies.js';
import { loadProjectConfiguration, DEFAULT_COMMAND_TIMEOUTS, type PostStep } from '../domain/config.js';
import { EXIT_CODES } from '../domain/events.js';
import { runCommand as defaultRunCommand, withDefaultTimeout, type CommandRequest } from '../infrastructure/command-runner.js';
import { createRedactor } from '../infrastructure/redactor.js';
import { createMockCommandRunner, type MockScenario } from '../infrastructure/mock-command-runner.js';
import type { ProjectInfo, WebOperationRequest, WebServiceFacade } from '../web/server.js';
import { existsSync, readFileSync } from 'node:fs';

async function getGitProjectInfo(projectDirectory: string): Promise<ProjectInfo> {
    const gitDir = `${projectDirectory}/.git`;
    if (!existsSync(gitDir)) {
        return {
            projectDirectory,
            repositoryName: null,
            repositoryUrl: null,
            branch: null,
            status: 'unknown',
            statusSummary: 'Ikke et Git-prosjekt',
            isGitRepository: false
        };
    }

    const branchResult = await defaultRunCommand({
        executable: 'git',
        arguments: ['rev-parse', '--abbrev-ref', 'HEAD'],
        cwd: projectDirectory,
        retry: { maxAttempts: 1 }
    });
    const statusResult = await defaultRunCommand({
        executable: 'git',
        arguments: ['status', '--short'],
        cwd: projectDirectory,
        retry: { maxAttempts: 1 }
    });
    const remoteResult = await defaultRunCommand({
        executable: 'git',
        arguments: ['remote', 'get-url', 'origin'],
        cwd: projectDirectory,
        retry: { maxAttempts: 1 }
    });

    const branch = branchResult.exitCode === 0 ? branchResult.stdout.trim() || null : null;
    const isDirty = statusResult.exitCode === 0 && statusResult.stdout.trim().length > 0;
    const repoUrl = remoteResult.exitCode === 0 ? remoteResult.stdout.trim() || null : null;
    const repositoryName = repoUrl ? repoUrl.split('/').pop()?.replace(/\.git$/, '') ?? null : null;

    return {
        projectDirectory,
        repositoryName,
        repositoryUrl: repoUrl,
        branch,
        status: isDirty ? 'dirty' : 'clean',
        statusSummary: isDirty ? 'Endringer i arbeidskatalogen' : 'Ingen endringer',
        isGitRepository: true
    };
}

/** Injectable application-service set used by the web transport adapter. */
export interface WebApplicationServices {
    /** Dependency source cleanup implementation. */
    clearDependencySources: typeof clearDependencySources;
    /** Dependency refresh implementation. */
    refreshDependencies: typeof refreshDependencies;
    /** Package planning implementation. */
    planPackages: typeof planPackages;
    /** Package installation implementation. */
    installPackages: typeof installPackages;
    /** Package update implementation. */
    updatePackages: typeof updatePackages;
    /** Scratch-org acquisition and configuration implementation. */
    createOrg: typeof createOrg;
    /** Scratch-org deletion implementation. */
    deleteOrg: typeof deleteOrg;
    /** Existing-org project configuration implementation. */
    configureProject: typeof configureProject;
    /** Org listing implementation. */
    listOrgs: typeof listOrgs;
    /** Detailed org inspection implementation. */
    getOrgInfo: typeof getOrgInfo;
    /** Org status implementation. */
    getOrgStatus: typeof getOrgStatus;
    /** Org package-status implementation. */
    getOrgPackageStatus: typeof getOrgPackageStatus;
    /** Project configuration loader used before configuration-dependent operations. */
    loadProjectConfiguration: typeof loadProjectConfiguration;
}

/** Construction options and dependency-injection seams for the web facade. */
export interface CreateWebServiceFacadeOptions {
    /** Project root bound to every facade operation. */
    projectDirectory: string;
    /** Environment forwarded to package mutation workflows; defaults to `process.env`. */
    environment?: Readonly<Record<string, string | undefined>>;
    /** Command runner forwarded to application services; defaults to the process command runner. */
    runCommand?: CommandRunner;
    /** Partial service overrides merged over production implementations for embedding or tests. */
    services?: Partial<WebApplicationServices>;
}

const defaultServices: WebApplicationServices = {
    clearDependencySources,
    refreshDependencies,
    planPackages,
    installPackages,
    updatePackages,
    createOrg,
    deleteOrg,
    configureProject,
    listOrgs,
    getOrgInfo,
    getOrgStatus,
    getOrgPackageStatus,
    loadProjectConfiguration
};

function booleanValue(request: WebOperationRequest, key: string, fallback = false): boolean {
    const value = request.payload[key];
    return typeof value === 'boolean' ? value : fallback;
}

function stringValue(request: WebOperationRequest, key: string): string {
    return String(request.payload[key]);
}

function optionalStringValue(request: WebOperationRequest, key: string): string | undefined {
    const value = request.payload[key];
    return typeof value === 'string' ? value : undefined;
}

function postSteps(request: WebOperationRequest, fallback: PostStep[]): PostStep[] {
    const value = request.payload.postSteps;
    return Array.isArray(value) ? (value as PostStep[]) : fallback;
}

function createOperationCommandRunner(
    commandRunner: CommandRunner,
    operationId: string,
    emit: WebServiceFacade['execute'] extends (...args: infer Arguments) => unknown
        ? Arguments[1]
        : never,
    secretValues: readonly string[]
): CommandRunner {
    let commandNumber = 0;
    return async (request: CommandRequest) => {
        commandNumber += 1;
        const redactor = createRedactor([...secretValues, ...(request.secretValues ?? [])]);
        const command = redactor.redact([request.executable, ...(request.arguments ?? [])].join(' '));
        const stepId = `external-command:${commandNumber}`;
        const report = (message: string): void => {
            emit({
                kind: 'progress',
                operationId,
                timestamp: new Date().toISOString(),
                stepId,
                step: 'External command',
                message: redactor.redact(message),
                diagnostic: true
            });
        };
        const hasOutputCallbacks = request.onStdoutLine !== undefined || request.onStderrLine !== undefined;
        report(`Running: ${command}`);
        const result = await commandRunner({
            ...request,
            onStdoutLine: (line) => {
                request.onStdoutLine?.(line);
                if (!hasOutputCallbacks) report(`[stdout] ${line}`);
            },
            onStderrLine: (line) => {
                request.onStderrLine?.(line);
                if (!hasOutputCallbacks) report(`[stderr] ${line}`);
            }
        });
        report(`Finished: ${redactor.redact(request.executable)} (exit code ${result.exitCode ?? 'unknown'}, ${result.durationMs} ms)`);
        return result;
    };
}

/**
 * Creates the web transport adapter over application services for one project directory.
 *
 * The facade loads configuration per configuration-dependent request, maps validated web request
 * fields to service options, and forwards emitted operation events unchanged. Dry-run guarantees,
 * stable exit codes, mutations, retries, and command side effects are owned by the delegated
 * application service. Service and command-runner injection is captured when the facade is created.
 *
 * @param options - Bound project path plus optional environment, command runner, and service overrides.
 * @returns A facade implementing org queries and operation execution for the web server.
 * @throws `Error` From configuration loading, injected services, or delegated application
 * operations; expected command failures are returned when the delegated service uses exit codes.
 */
export function createWebServiceFacade(options: CreateWebServiceFacadeOptions): WebServiceFacade {
    // Capture one composed dependency set so every endpoint in this facade uses the same injected boundary.
    const services: WebApplicationServices = { ...defaultServices, ...options.services };
    const commandRunner = options.runCommand ?? defaultRunCommand;
    // Read-only endpoints run before configuration is loaded, so they use the built-in default rather
    // than a per-project override; mutating operations apply the project's configured timeout below.
    const readCommandRunner = withDefaultTimeout(commandRunner, DEFAULT_COMMAND_TIMEOUTS.readMs);
    const environment = options.environment ?? process.env;

    return {
        getProjectInfo: async () => getGitProjectInfo(options.projectDirectory),
        listOrgs: () =>
            services.listOrgs({
                projectDirectory: options.projectDirectory,
                runCommand: readCommandRunner
            }),
        getOrg: (alias) =>
            services.getOrgInfo({
                projectDirectory: options.projectDirectory,
                alias,
                runCommand: readCommandRunner
            }),
        getOrgStatus: (alias) =>
            services.getOrgStatus({
                projectDirectory: options.projectDirectory,
                ...(alias === undefined ? {} : { alias }),
                runCommand: readCommandRunner
            }),
        getOrgPackages: async (alias) =>
            services.getOrgPackageStatus({
                configuration: await services.loadProjectConfiguration(options.projectDirectory),
                targetOrg: alias,
                runCommand: readCommandRunner
            }),
        execute: async (request, emit) => {
            const configuration = await services.loadProjectConfiguration(options.projectDirectory);
            const mock = request.payload.mock === true;
            const selectedCommandRunner = mock
                ? createMockCommandRunner(configuration, (request.payload.mockScenario as MockScenario | undefined) ?? 'success')
                : commandRunner;
            const operationCommandRunner = createOperationCommandRunner(
                withDefaultTimeout(selectedCommandRunner, configuration.commandTimeouts.mutationMs),
                request.operationId,
                emit,
                [environment[configuration.packageInstallKeyEnvironmentVariable] ?? '']
            );
            const common = {
                configuration,
                operationId: request.operationId,
                emit,
                ...(request.signal === undefined ? {} : { signal: request.signal })
            };
            switch (request.command) {
                case 'dependencies.clear':
                    await services.clearDependencySources({
                        ...common,
                        dryRun: booleanValue(request, 'dryRun')
                    });
                    return EXIT_CODES.SUCCESS;
                case 'dependencies.refresh': {
                    const refreshTargetOrg = optionalStringValue(request, 'targetOrg');
                    return services.refreshDependencies({
                        ...common,
                        ...(refreshTargetOrg === undefined ? {} : { targetOrg: refreshTargetOrg }),
                        dryRun: booleanValue(request, 'dryRun'),
                        runCommand: operationCommandRunner
                    });
                }
                case 'packages.plan': {
                    const targetOrg = optionalStringValue(request, 'targetOrg');
                    const planOptions = {
                        ...common,
                        installLatest: booleanValue(request, 'installLatest'),
                        runCommand: operationCommandRunner
                    };
                    await services.planPackages(targetOrg === undefined ? planOptions : { ...planOptions, targetOrg });
                    return EXIT_CODES.SUCCESS;
                }
                case 'packages.install':
                case 'packages.update': {
                    const mutate =
                        request.command === 'packages.install' ? services.installPackages : services.updatePackages;
                    const targetOrg = optionalStringValue(request, 'targetOrg');
                    return mutate({
                        ...common,
                        ...(targetOrg === undefined ? {} : { targetOrg }),
                        installLatest: booleanValue(request, 'installLatest'),
                        dryRun: booleanValue(request, 'dryRun'),
                        environment,
                        runCommand: operationCommandRunner
                    });
                }
                case 'org.create': {
                    const poolDevHub = optionalStringValue(request, 'poolDevHub') ?? configuration.pool.devHub;
                    return services.createOrg({
                        ...common,
                        alias: stringValue(request, 'alias'),
                        durationDays:
                            typeof request.payload.durationDays === 'number'
                                ? request.payload.durationDays
                                : configuration.scratchDurationDays,
                        postSteps: postSteps(request, configuration.postSteps),
                        usePool: booleanValue(request, 'usePool', configuration.pool.use),
                        poolTag: optionalStringValue(request, 'poolTag') ?? configuration.pool.tag,
                        ...(poolDevHub === undefined ? {} : { poolDevHub }),
                        fallbackToCreate: booleanValue(
                            request,
                            'fallbackToCreate',
                            configuration.pool.fallbackToCreate
                        ),
                        clearDependencySources: booleanValue(request, 'clearDependencySources'),
                        refreshDependencySources: booleanValue(request, 'refreshDependencySources'),
                        dryRun: booleanValue(request, 'dryRun'),
                        environment,
                        runCommand: operationCommandRunner
                    });
                }
                case 'org.delete': {
                    const alias = stringValue(request, 'alias');
                    const confirmation = optionalStringValue(request, 'confirmMutation');
                    const org = await services.getOrgInfo({
                        projectDirectory: options.projectDirectory,
                        alias,
                        runCommand: operationCommandRunner
                    });
                    return services.deleteOrg({
                        ...common,
                        alias,
                        classification: org.org.orgType,
                        confirmed: booleanValue(request, 'confirmed'),
                        ...(confirmation === undefined ? {} : { confirmation }),
                        dryRun: booleanValue(request, 'dryRun'),
                        runCommand: operationCommandRunner
                    });
                }
                case 'project.configure': {
                    const alias = optionalStringValue(request, 'alias');
                    const confirmation = optionalStringValue(request, 'confirmMutation');
                    return services.configureProject({
                        ...common,
                        ...(alias === undefined ? {} : { alias }),
                        postSteps: postSteps(request, configuration.postSteps),
                        skipPackages: booleanValue(request, 'skipPackages'),
                        refreshDependencySources: booleanValue(request, 'refreshDependencySources'),
                        ...(confirmation === undefined ? {} : { confirmation }),
                        dryRun: booleanValue(request, 'dryRun'),
                        environment,
                        runCommand: operationCommandRunner
                    });
                }
            }
        }
    };
}
