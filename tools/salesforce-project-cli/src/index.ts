/**
 * Defines the public package boundary for CLI-first Salesforce project tooling.
 *
 * The package exposes a shell-free Salesforce command adapter for embedding, but does not
 * guarantee validation against an authenticated Salesforce org.
 *
 * @packageDocumentation
 */
export { runCli } from './cli-app.js';
export type { CliDependencies, CliOutput } from './cli-app.js';
export { runDoctor } from './application/doctor.js';
export type { DoctorOptions } from './application/doctor.js';
export { recoverForceignoreTransaction } from './application/forceignore-transaction.js';
export type { RecoverForceignoreOptions } from './application/forceignore-transaction.js';
export { loadProjectConfiguration } from './domain/config.js';
export type { ProjectConfiguration, DependencySource, PoolConfiguration, PostStep } from './domain/config.js';
export { configureProject, createOrg, deleteOrg } from './application/org-workflow.js';
export type { ConfigureProjectOptions, CreateOrgOptions, DeleteOrgOptions } from './application/org-workflow.js';
export { getOrgInfo, getOrgStatus, listOrgs, renderOrgInfo, renderOrgSummary } from './application/org-inspection.js';
export type {
    AuthStatus,
    ConnectionStatus,
    GetOrgInfoOptions,
    GetOrgStatusOptions,
    InstanceUrlClassification,
    ListOrgsOptions,
    MutationPolicy,
    OrgCapabilities,
    OrgInfo,
    OrgListResult,
    OrgResult,
    OrgSummary
} from './application/org-inspection.js';
export {
    getOrgPackageStatus,
    installPackages,
    isRetryablePackageInstallFailure,
    planPackages,
    updatePackages
} from './application/package-operations.js';
export type { MutatePackagesOptions, PlanPackagesOptions } from './application/package-operations.js';
export { comparePackageVersions, normalizeConfiguredVersion, selectLatestPackageVersion } from './domain/packages.js';
export type {
    PackageDependency,
    OrgPackageStatusItem,
    OrgPackageStatusKind,
    OrgPackageStatusResult,
    PackageOperationSummary,
    PackagePlanItem,
    PackagePlanStatus,
    PackageVersion
} from './domain/packages.js';
export { EXIT_CODES } from './domain/events.js';
export type { EventBase, OperationEvent, EventSink, ExitCode } from './domain/events.js';
export { isOrgMutationAllowed, isOrgMutationConfirmed, mutationConfirmationToken } from './domain/org-policy.js';
export type { OrgClassification } from './domain/org-policy.js';
export { runCommand } from './infrastructure/command-runner.js';
export type { AsyncDelay, CommandRequest, CommandResult, RetryOptions } from './infrastructure/command-runner.js';
export { createRedactingEventSink, createRedactor } from './infrastructure/redactor.js';
export type { Redactor } from './infrastructure/redactor.js';
export { createWebServiceFacade } from './application/web-service-facade.js';
export type { CreateWebServiceFacadeOptions, WebApplicationServices } from './application/web-service-facade.js';
export type { ClearDependencySourcesOptions } from './application/clear-dependency-sources.js';
export type { CommandRunner, RefreshDependenciesOptions } from './application/refresh-dependencies.js';
export { startWebServer } from './web/server.js';
export type {
    StartedWebServer,
    StartWebServerOptions,
    WebOperationCommand,
    WebOperationRequest,
    WebServiceFacade
} from './web/server.js';
