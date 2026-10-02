import { comparePackageVersions, type PackageOperationSummary, type PackagePlanItem, type PackagePlanStatus, type PackageVersion } from '../domain/packages.js';

/** Compares an installed version with the selected target version. */
export function packagePlanStatus(installed: PackageVersion | undefined, selected: PackageVersion): PackagePlanStatus {
    if (installed === undefined) return 'missing';
    const comparison = comparePackageVersions(installed, selected);
    return comparison === 0 ? 'skip' : comparison < 0 ? 'update' : 'higher';
}

/** Aggregates the immutable plan statuses before any mutation begins. */
export function summarizePackagePlan(items: readonly PackagePlanItem[]): PackageOperationSummary {
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