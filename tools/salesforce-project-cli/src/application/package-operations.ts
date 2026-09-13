/**
 * Plans and executes package installation or update work from released and installed versions.
 * Dependency order is preserved, dry runs avoid mutation, and outcomes are emitted as stable events and exit codes.
 */
import type { ProjectConfiguration } from '../domain/config.js';
import { EXIT_CODES, type EventSink, type ExitCode } from '../domain/events.js';
import {
    comparePackageVersions,
    normalizeConfiguredVersion,
    selectLatestPackageVersion,
    type OrgPackageStatusItem,
    type OrgPackageStatusResult,
    type PackageDependency,
    type PackageOperationSummary,
    type PackagePlanItem,
    type PackagePlanStatus,
    type PackageVersion
} from '../domain/packages.js';
import type { CommandRunner } from './refresh-dependencies.js';
import { classifySalesforceFailure } from '../infrastructure/salesforce-errors.js';

/** Inputs and injected dependencies for resolving a package plan. */
export interface PlanPackagesOptions {
    /** Validated configuration containing package dependencies in installation order. */
    configuration: ProjectConfiguration;
    /** Optional target org; falls back to the configured default and may remain unspecified. */
    targetOrg?: string;
    /** Whether each dependency selects its latest released version instead of the configured version. */
    installLatest: boolean;
    /** Correlation identifier copied to emitted package events. */
    operationId: string;
    /** Event sink receiving one result per dependency and an aggregate summary. */
    emit: EventSink;
    /** Injected runner used for all read-only and mutating Salesforce CLI commands. */
    runCommand: CommandRunner;
}

/** Inputs for package installation or update workflows. */
export interface MutatePackagesOptions extends PlanPackagesOptions {
    /** When `true`, resolves and emits the plan but never runs package installation commands. */
    dryRun: boolean;
    /** Environment used to resolve required package installation keys. */
    environment: Readonly<Record<string, string | undefined>>;
}

interface SalesforceVersionRecord {
    MajorVersion?: unknown;
    MinorVersion?: unknown;
    PatchVersion?: unknown;
    BuildNumber?: unknown;
    SubscriberPackageVersionId?: unknown;
}

interface InstalledPackageRecord {
    SubscriberPackageName?: unknown;
    PackageName?: unknown;
    Name?: unknown;
    SubscriberPackageVersionNumber?: unknown;
    VersionNumber?: unknown;
    Version?: unknown;
    SubscriberPackageVersionId?: unknown;
    SubscriberPackageVersionID?: unknown;
}

function parseResult(stdout: string, command: string): unknown[] {
    let payload: unknown;
    try {
        payload = JSON.parse(stdout);
    } catch {
        throw new Error(`${command} returned malformed JSON`);
    }
    if (payload === null || typeof payload !== 'object' || !Array.isArray((payload as { result?: unknown }).result)) {
        throw new Error(`${command} returned an invalid result`);
    }
    return (payload as { result: unknown[] }).result;
}

function releasedVersion(record: unknown): PackageVersion {
    const value = record as SalesforceVersionRecord;
    const components = [value.MajorVersion, value.MinorVersion, value.PatchVersion, value.BuildNumber];
    if (
        !components.every((component) => Number.isInteger(component)) ||
        typeof value.SubscriberPackageVersionId !== 'string'
    ) {
        throw new Error('Package version list returned an invalid version record');
    }
    return {
        versionNumber: components.join('.'),
        subscriberPackageVersionId: value.SubscriberPackageVersionId
    };
}

function installedVersion(record: InstalledPackageRecord): PackageVersion | undefined {
    const versionNumber = record.SubscriberPackageVersionNumber ?? record.VersionNumber ?? record.Version;
    const subscriberPackageVersionId = record.SubscriberPackageVersionId ?? record.SubscriberPackageVersionID;
    if (typeof versionNumber !== 'string' || typeof subscriberPackageVersionId !== 'string') {
        return undefined;
    }
    return { versionNumber, subscriberPackageVersionId };
}

function installedPackageName(record: InstalledPackageRecord): string | undefined {
    const packageName = record.SubscriberPackageName ?? record.PackageName ?? record.Name;
    return typeof packageName === 'string' ? packageName : undefined;
}

function selectConfiguredVersion(versions: readonly PackageVersion[], configuredVersion: string): PackageVersion {
    const normalized = normalizeConfiguredVersion(configuredVersion);
    const hasBuild = normalized.split('.').length === 4;
    const matches = versions.filter((version) =>
        hasBuild ? version.versionNumber === normalized : version.versionNumber.startsWith(`${normalized}.`)
    );
    if (matches.length === 0) {
        throw new Error(`No released package version matches ${configuredVersion}`);
    }
    return selectLatestPackageVersion(matches);
}

async function querySelectedVersion(
    options: PlanPackagesOptions,
    dependency: PackageDependency
): Promise<PackageVersion> {
    // Select from released versions only, preserving configured major/minor/patch intent unless latest is requested.
    if (dependency.packageAlias === undefined) {
        throw new Error(`Package alias is not declared: ${dependency.packageName}`);
    }
    if (dependency.configuredVersion === undefined) {
        throw new Error(`Package version is not declared: ${dependency.packageName}`);
    }
    const result = await options.runCommand({
        executable: 'sf',
        arguments: [
            'package',
            'version',
            'list',
            '--packages',
            dependency.packageAlias,
            '--released',
            '--order-by',
            'CreatedDate',
            '--json'
        ],
        cwd: options.configuration.projectDirectory
    });
    if (result.failed || result.exitCode !== 0) {
        throw new Error(result.error ?? result.stderr ?? `Failed to query ${dependency.packageName} versions`);
    }
    const versions = parseResult(result.stdout, 'sf package version list').map(releasedVersion);
    return options.installLatest
        ? selectLatestPackageVersion(versions)
        : selectConfiguredVersion(versions, dependency.configuredVersion);
}

function statusFor(installed: PackageVersion | undefined, selected: PackageVersion): PackagePlanStatus {
    if (installed === undefined) {
        return 'missing';
    }
    const comparison = comparePackageVersions(installed, selected);
    return comparison === 0 ? 'skip' : comparison < 0 ? 'update' : 'higher';
}

function createSummary(items: readonly PackagePlanItem[]): PackageOperationSummary {
    return items.reduce<PackageOperationSummary>(
        (summary, item) => ({
            ...summary,
            missing: summary.missing + Number(item.status === 'missing'),
            updated: summary.updated + Number(item.status === 'update'),
            skipped: summary.skipped + Number(item.status === 'skip'),
            higher: summary.higher + Number(item.status === 'higher')
        }),
        { total: items.length, missing: 0, installed: 0, updated: 0, skipped: 0, higher: 0, failed: 0 }
    );
}

function emitPlanItem(options: PlanPackagesOptions, item: PackagePlanItem, total: number): void {
    options.emit({
        kind: 'package-result',
        operationId: options.operationId,
        timestamp: new Date().toISOString(),
        packageName: item.dependency.packageName,
        ordinal: item.ordinal,
        total,
        attempt: 1,
        status: item.status,
        selectedVersion: item.selectedVersion.versionNumber,
        selectedVersionId: item.selectedVersion.subscriberPackageVersionId,
        ...(item.installedVersion === undefined ? {} : { installedVersion: item.installedVersion.versionNumber }),
        message: `${item.dependency.packageName}: ${item.status}`
    });
}

function emitSummary(options: PlanPackagesOptions, summary: PackageOperationSummary): void {
    options.emit({
        kind: 'package-summary',
        operationId: options.operationId,
        timestamp: new Date().toISOString(),
        ...summary
    });
}

async function queryInstalledPackages(options: PlanPackagesOptions): Promise<Map<string, PackageVersion>> {
    const arguments_ = ['package', 'installed', 'list'];
    const targetOrg = options.targetOrg ?? options.configuration.defaultOrgAlias;
    if (targetOrg !== undefined) {
        arguments_.push('--target-org', targetOrg);
    }
    arguments_.push('--json');
    const result = await options.runCommand({
        executable: 'sf',
        arguments: arguments_,
        cwd: options.configuration.projectDirectory
    });
    if (result.failed || result.exitCode !== 0) {
        throw new Error(result.error ?? result.stderr ?? 'Failed to query installed packages');
    }
    return new Map(
        parseResult(result.stdout, 'sf package installed list').flatMap((record) => {
            const packageName = installedPackageName(record as InstalledPackageRecord);
            const version = installedVersion(record as InstalledPackageRecord);
            return packageName === undefined || version === undefined ? [] : [[packageName, version] as const];
        })
    );
}

async function resolvePackagePlan(options: PlanPackagesOptions): Promise<PackagePlanItem[]> {
    // Resolve sequentially so emitted ordinals and later mutation order match dependency declaration order.
    const installedPackages = await queryInstalledPackages(options);
    const items: PackagePlanItem[] = [];

    for (const [index, dependency] of options.configuration.packageDependencies.entries()) {
        const selectedVersion = await querySelectedVersion(options, dependency);
        const installed = installedPackages.get(dependency.packageName);
        const status = statusFor(installed, selectedVersion);
        const item: PackagePlanItem = {
            ordinal: index + 1,
            dependency,
            selectedVersion,
            ...(installed === undefined ? {} : { installedVersion: installed }),
            status
        };
        items.push(item);
    }

    return items;
}

/**
 * Reports configured dependencies against versions installed in one target org.
 *
 * Dependencies missing alias/version metadata are returned with `unknown` status without a
 * version-list query. Other dependencies select the configured released version and are compared
 * with the installed version. The operation is read-only but invokes Salesforce CLI queries.
 *
 * @param options - Configuration, required target org, and injected command runner.
 * @returns Per-package status and aggregate counts for the target org.
 * @throws `Error` When a query fails, JSON is malformed, released records are invalid, or
 * no released version matches a configured dependency.
 */
export async function getOrgPackageStatus(
    options: Omit<PlanPackagesOptions, 'installLatest' | 'operationId' | 'emit'> & { targetOrg: string }
): Promise<OrgPackageStatusResult> {
    const planOptions: PlanPackagesOptions = {
        ...options,
        installLatest: false,
        operationId: 'package-status',
        emit: () => undefined
    };
    const installedPackages = await queryInstalledPackages(planOptions);
    const packages: OrgPackageStatusItem[] = [];

    for (const dependency of options.configuration.packageDependencies) {
        const installed = installedPackages.get(dependency.packageName);
        if (dependency.packageAlias === undefined || dependency.configuredVersion === undefined) {
            packages.push({
                packageName: dependency.packageName,
                configuredVersion: dependency.configuredVersion ?? null,
                installedVersion: installed?.versionNumber ?? null,
                selectedVersion: null,
                status: 'unknown'
            });
            continue;
        }
        const selected = await querySelectedVersion(planOptions, dependency);
        const planStatus = statusFor(installed, selected);
        packages.push({
            packageName: dependency.packageName,
            configuredVersion: dependency.configuredVersion,
            installedVersion: installed?.versionNumber ?? null,
            selectedVersion: selected.versionNumber,
            status: planStatus === 'skip' ? 'current' : planStatus === 'update' ? 'update-available' : planStatus
        });
    }

    return {
        targetOrg: options.targetOrg,
        packages,
        summary: packages.reduce(
            (summary, item) => ({
                ...summary,
                [item.status === 'update-available' ? 'updateAvailable' : item.status]:
                    summary[item.status === 'update-available' ? 'updateAvailable' : item.status] + 1
            }),
            { total: packages.length, current: 0, updateAvailable: 0, higher: 0, missing: 0, unknown: 0 }
        )
    };
}

/**
 * Resolves and emits the package installation/update plan without mutating an org.
 *
 * @param options - Configuration, target selection, version-selection policy, events, and runner.
 * @returns Plan items in configured dependency order.
 * @throws `Error` When package metadata is incomplete, a query fails, Salesforce returns
 * malformed data, or a configured released version cannot be selected.
 */
export async function planPackages(options: PlanPackagesOptions): Promise<PackagePlanItem[]> {
    const items = await resolvePackagePlan(options);
    items.forEach((item) => emitPlanItem(options, item, items.length));
    emitSummary(options, createSummary(items));
    return items;
}

const TRANSIENT_PACKAGE_INSTALL_SIGNATURES = [
    'TypeError: terminated',
    'ECONNRESET',
    'socket hang up',
    'ETIMEDOUT',
    'ENOTFOUND',
    'UND_ERR_'
] as const;

/**
 * Identifies package-install failures eligible for the bounded transport retry policy.
 *
 * @param result - Captured command output and optional normalized error text.
 * @returns `true` only when output contains a recognized transient network signature.
 */
export function isRetryablePackageInstallFailure(result: { stdout: string; stderr: string; error?: string }): boolean {
    const output = `${result.stdout}\n${result.stderr}\n${result.error ?? ''}`;
    return TRANSIENT_PACKAGE_INSTALL_SIGNATURES.some((signature) => output.includes(signature));
}

async function mutatePackages(options: MutatePackagesOptions): Promise<ExitCode> {
    const items = await resolvePackagePlan(options);
    const summary: PackageOperationSummary = {
        total: items.length,
        missing: 0,
        installed: 0,
        updated: 0,
        skipped: 0,
        higher: 0,
        failed: 0
    };
    let completedInstalls = 0;

    for (const item of items) {
        if (item.status === 'skip' || item.status === 'higher' || options.dryRun) {
            if (item.status === 'skip') summary.skipped += 1;
            if (item.status === 'higher') summary.higher += 1;
            if (options.dryRun && item.status === 'missing') summary.missing += 1;
            if (options.dryRun && item.status === 'update') summary.updated += 1;
            emitPlanItem(options, item, items.length);
            continue;
        }

        const installationKey = item.dependency.requiresInstallationKey
            ? options.environment[options.configuration.packageInstallKeyEnvironmentVariable]
            : undefined;
        if (item.dependency.requiresInstallationKey && installationKey === undefined) {
            throw new Error(
                `Package ${item.dependency.packageName} requires ${options.configuration.packageInstallKeyEnvironmentVariable}`
            );
        }

        const arguments_ = ['package', 'install', '--package', item.selectedVersion.subscriberPackageVersionId];
        if (installationKey !== undefined) {
            arguments_.push('--installation-key', installationKey);
        }
        const targetOrg = options.targetOrg ?? options.configuration.defaultOrgAlias;
        if (targetOrg !== undefined) {
            arguments_.push('--target-org', targetOrg);
        }
        arguments_.push('--json');
        const stepId = `install:${item.dependency.packageName}`;
        const result = await options.runCommand({
            executable: 'sf',
            arguments: arguments_,
            cwd: options.configuration.projectDirectory,
            ...(installationKey === undefined ? {} : { secretValues: [installationKey] }),
            // Retry only recognized transport failures; package or authorization failures remain single-attempt.
            retry: {
                maxAttempts: 3,
                delayMs: 5_000,
                shouldRetry: isRetryablePackageInstallFailure,
                onRetry: (failure, nextAttempt, delayMs) =>
                    options.emit({
                        kind: 'retrying',
                        operationId: options.operationId,
                        timestamp: new Date().toISOString(),
                        stepId,
                        step: 'Install package',
                        attempt: nextAttempt - 1,
                        nextAttempt,
                        maxAttempts: 3,
                        delayMs,
                        message: `Retrying ${item.dependency.packageName}`,
                        error: failure.error ?? failure.stderr
                    })
            }
        });

        if (result.failed || result.exitCode !== 0) {
            summary.failed += 1;
            options.emit({
                kind: 'package-result',
                operationId: options.operationId,
                timestamp: new Date().toISOString(),
                packageName: item.dependency.packageName,
                ordinal: item.ordinal,
                total: items.length,
                attempt: result.attempts,
                status: 'failed',
                selectedVersion: item.selectedVersion.versionNumber,
                selectedVersionId: item.selectedVersion.subscriberPackageVersionId,
                ...(item.installedVersion === undefined
                    ? {}
                    : { installedVersion: item.installedVersion.versionNumber }),
                message: result.error ?? result.stderr ?? `Failed to install ${item.dependency.packageName}`
            });
            emitSummary(options, summary);
            return classifySalesforceFailure(
                result,
                completedInstalls > 0 ? EXIT_CODES.PARTIAL_COMPLETION : EXIT_CODES.OPERATION_FAILURE
            );
        }

        completedInstalls += 1;
        const status = item.status === 'missing' ? 'installed' : 'updated';
        summary[status] += 1;
        options.emit({
            kind: 'package-result',
            operationId: options.operationId,
            timestamp: new Date().toISOString(),
            packageName: item.dependency.packageName,
            ordinal: item.ordinal,
            total: items.length,
            attempt: result.attempts,
            status,
            selectedVersion: item.selectedVersion.versionNumber,
            selectedVersionId: item.selectedVersion.subscriberPackageVersionId,
            ...(item.installedVersion === undefined ? {} : { installedVersion: item.installedVersion.versionNumber }),
            message: `${item.dependency.packageName}: ${status}`
        });
    }

    emitSummary(options, summary);
    return EXIT_CODES.SUCCESS;
}

/**
 * Installs missing packages and updates older packages in configured dependency order.
 *
 * Dry-run mode still performs read-only installed/version queries, but it never reads installation
 * keys or issues install commands. Current and higher versions are never mutated. Install commands
 * retry recognized transient transport failures up to three attempts. A failed command returns a
 * classified stable exit code, using `EXIT_CODES.PARTIAL_COMPLETION` as the fallback after any
 * prior successful install.
 *
 * @param options - Plan inputs plus dry-run state and the environment containing installation keys.
 * @returns Success or the classified first installation failure.
 * @throws `Error` When planning fails, a required installation key is absent, or an injected
 * dependency throws instead of returning a command result.
 */
export async function installPackages(options: MutatePackagesOptions): Promise<ExitCode> {
    return mutatePackages(options);
}

/**
 * Updates older packages and installs missing packages using the same ordered mutation contract
 * as {@link installPackages}.
 *
 * Dry-run mode performs only read-only planning queries. Recognized transient install failures are
 * retried up to three attempts; terminal command failures are returned as stable classified codes.
 *
 * @param options - Plan inputs plus dry-run state and the environment containing installation keys.
 * @returns Success or the classified first installation failure, including partial completion.
 * @throws `Error` When planning fails, a required installation key is absent, or an injected
 * dependency throws instead of returning a command result.
 */
export async function updatePackages(options: MutatePackagesOptions): Promise<ExitCode> {
    return mutatePackages(options);
}
