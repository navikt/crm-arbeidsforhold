/**
 * Models package plans and status while providing deterministic Salesforce version selection.
 * Versions compare numerically, with subscriber package version IDs used only as stable tie-breakers.
 */
/** Identifies a released package version and its installable subscriber version. */
export interface PackageVersion {
    /** Four-part Salesforce package version number. */
    versionNumber: string;
    /** Subscriber package version ID used for installation and deterministic tie-breaking. */
    subscriberPackageVersionId: string;
}

/** Planned relationship between an org's installed version and the selected release. */
export type PackagePlanStatus = 'missing' | 'update' | 'skip' | 'higher';

/** Package dependency configuration required to plan installation or update work. */
export interface PackageDependency {
    /** Human-readable package name used in plans and output. */
    packageName: string;
    /** Optional alias that resolves the package in Salesforce project configuration. */
    packageAlias?: string;
    /** Version constraint from project configuration, when one is declared. */
    configuredVersion?: string;
    /** Whether installation must be supplied with a package installation key. */
    requiresInstallationKey: boolean;
}

/** A dependency's immutable position and selected action within a package plan. */
export interface PackagePlanItem {
    /** One-based display position in the complete plan. */
    ordinal: number;
    /** Dependency configuration that produced this item. */
    dependency: PackageDependency;
    /** Released version selected as the desired target. */
    selectedVersion: PackageVersion;
    /** Version currently installed in the target org, if present. */
    installedVersion?: PackageVersion;
    /** Action implied by comparing the installed and selected versions. */
    status: PackagePlanStatus;
}

/** Aggregate package outcomes for one operation. */
export interface PackageOperationSummary {
    /** Number of dependencies considered. */
    total: number;
    /** Number not installed when the operation began. */
    missing: number;
    /** Number installed by the operation. */
    installed: number;
    /** Number upgraded by the operation. */
    updated: number;
    /** Number intentionally left unchanged. */
    skipped: number;
    /** Number already newer than the selected release. */
    higher: number;
    /** Number that could not be processed successfully. */
    failed: number;
}

/** Comparison state reported while inspecting an org's package inventory. */
export type OrgPackageStatusKind = 'missing' | 'current' | 'update-available' | 'higher' | 'unknown';

/** Inspection result for one configured package in an org. */
export interface OrgPackageStatusItem {
    /** Human-readable package name. */
    packageName: string;
    /** Normalized configured version, or `null` when no version is configured. */
    configuredVersion: string | null;
    /** Installed version, or `null` when the package is absent or could not be resolved. */
    installedVersion: string | null;
    /** Latest eligible released version, or `null` when selection was not possible. */
    selectedVersion: string | null;
    /** Comparison outcome for the configured, installed, and selected versions. */
    status: OrgPackageStatusKind;
}

/** Complete package inspection result for a target org. */
export interface OrgPackageStatusResult {
    /** Alias or username identifying the inspected org. */
    targetOrg: string;
    /** Per-package inspection results in reporting order. */
    packages: OrgPackageStatusItem[];
    /** Counts partitioning all package results by status. */
    summary: {
        /** Number of packages inspected. */
        total: number;
        /** Number matching the selected release. */
        current: number;
        /** Number with a newer eligible release. */
        updateAvailable: number;
        /** Number newer than the selected release. */
        higher: number;
        /** Number not installed in the org. */
        missing: number;
        /** Number whose status could not be determined. */
        unknown: number;
    };
}

interface VersionComponents {
    /** Salesforce package major version. */
    major: number;
    /** Salesforce package minor version. */
    minor: number;
    /** Salesforce package patch version. */
    patch: number;
    /** Numeric build version; symbolic `LATEST` and `NEXT` normalize to zero. */
    build: number;
}

const CONFIGURED_VERSION_PATTERN = /^(\d+)\.(\d+)\.(\d+)(?:\.(\d+|LATEST|NEXT))?$/;

function parseVersion(versionNumber: string): VersionComponents {
    const match = CONFIGURED_VERSION_PATTERN.exec(versionNumber);
    if (!match) {
        throw new Error(`Invalid package version: ${versionNumber}`);
    }

    return {
        major: Number(match[1]),
        minor: Number(match[2]),
        patch: Number(match[3]),
        build: match[4] === undefined || match[4] === 'LATEST' || match[4] === 'NEXT' ? 0 : Number(match[4])
    };
}

/**
 * Converts configured package versions to the representation used for release matching.
 *
 * Three-part versions and `.LATEST` or `.NEXT` selectors normalize to `major.minor.patch`;
 * an explicit numeric build remains four-part.
 *
 * @param versionNumber - Configured Salesforce package version.
 * @returns The normalized version used for comparisons and release queries.
 * @throws `Error` If the version does not follow the supported Salesforce format.
 */
export function normalizeConfiguredVersion(versionNumber: string): string {
    const parsed = parseVersion(versionNumber);
    if (versionNumber.endsWith('.LATEST') || versionNumber.endsWith('.NEXT') || versionNumber.split('.').length === 3) {
        return `${parsed.major}.${parsed.minor}.${parsed.patch}`;
    }
    return `${parsed.major}.${parsed.minor}.${parsed.patch}.${parsed.build}`;
}

/**
 * Orders package versions by numeric components with subscriber ID as a stable tie-breaker.
 *
 * @param left - First package version.
 * @param right - Second package version.
 * @returns A negative value when `left` precedes `right`, zero when equal, otherwise a positive value.
 * @throws `Error` If either version number is invalid.
 */
export function comparePackageVersions(left: PackageVersion, right: PackageVersion): number {
    const leftVersion = parseVersion(left.versionNumber);
    const rightVersion = parseVersion(right.versionNumber);
    const componentComparison = (['major', 'minor', 'patch', 'build'] as const)
        .map((component) => leftVersion[component] - rightVersion[component])
        .find((comparison) => comparison !== 0);

    return componentComparison ?? left.subscriberPackageVersionId.localeCompare(right.subscriberPackageVersionId);
}

/**
 * Selects the greatest released package version without mutating the input collection.
 *
 * @param versions - Released versions eligible for selection.
 * @returns The latest version according to {@link comparePackageVersions}.
 * @throws `Error` If no released versions are supplied or a version number is invalid.
 */
export function selectLatestPackageVersion(versions: readonly PackageVersion[]): PackageVersion {
    if (versions.length === 0) {
        throw new Error('No released package versions were returned');
    }

    return [...versions].sort(comparePackageVersions).at(-1) as PackageVersion;
}
