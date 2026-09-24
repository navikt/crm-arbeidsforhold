import { describe, expect, it } from 'vitest';
import { packagePlanStatus, summarizePackagePlan } from '../../src/application/package-plan-logic.js';
import type { PackagePlanItem, PackageVersion } from '../../src/domain/packages.js';

const selected: PackageVersion = { versionNumber: '1.0.0.2', subscriberPackageVersionId: '04t-selected' };
const item = (status: PackagePlanItem['status']): PackagePlanItem => ({
    ordinal: 1,
    dependency: { packageName: 'shared', requiresInstallationKey: false },
    selectedVersion: selected,
    status
});

describe('package plan logic', () => {
    it.each([
        [undefined, 'missing'],
        [{ versionNumber: '1.0.0.1', subscriberPackageVersionId: '04t-old' }, 'update'],
        [selected, 'skip'],
        [{ versionNumber: '1.0.0.3', subscriberPackageVersionId: '04t-new' }, 'higher']
    ] as const)('classifies installed package status as %s', (installed, expected) => {
        expect(packagePlanStatus(installed, selected)).toBe(expected);
    });

    it('summarizes plan statuses without mutation concerns', () => {
        expect(summarizePackagePlan([item('missing'), item('update'), item('skip'), item('higher')])).toEqual({
            total: 4,
            missing: 1,
            installed: 0,
            updated: 1,
            skipped: 1,
            higher: 1,
            failed: 0
        });
    });
});