import { describe, expect, it } from 'vitest';
import {
    comparePackageVersions,
    normalizeConfiguredVersion,
    selectLatestPackageVersion,
    type PackageVersion
} from '../../src/domain/packages.js';

const version = (versionNumber: string, subscriberPackageVersionId: string): PackageVersion => ({
    versionNumber,
    subscriberPackageVersionId
});

describe('package versions', () => {
    it.each([
        ['1.2.3.4', '1.2.3.4'],
        ['1.2.3.LATEST', '1.2.3'],
        ['1.2.3.NEXT', '1.2.3']
    ])('normalizes configured version %s', (configured, expected) => {
        expect(normalizeConfiguredVersion(configured)).toBe(expected);
    });

    it('compares major, minor, patch, build, and 04t deterministically', () => {
        expect(
            comparePackageVersions(version('2.0.0.1', '04t000000000001'), version('1.99.99.99', '04t999999999999'))
        ).toBeGreaterThan(0);
        expect(
            comparePackageVersions(version('1.3.0.1', '04t000000000001'), version('1.2.99.99', '04t999999999999'))
        ).toBeGreaterThan(0);
        expect(
            comparePackageVersions(version('1.2.4.1', '04t000000000001'), version('1.2.3.99', '04t999999999999'))
        ).toBeGreaterThan(0);
        expect(
            comparePackageVersions(version('1.2.3.5', '04t000000000001'), version('1.2.3.4', '04t999999999999'))
        ).toBeGreaterThan(0);
        expect(
            comparePackageVersions(version('1.2.3.4', '04t000000000002'), version('1.2.3.4', '04t000000000001'))
        ).toBeGreaterThan(0);
    });

    it('selects the latest release independent of input order', () => {
        expect(
            selectLatestPackageVersion([
                version('1.2.3.5', '04t000000000005'),
                version('2.0.0.1', '04t000000000001'),
                version('1.9.9.9', '04t000000000009')
            ])
        ).toEqual(version('2.0.0.1', '04t000000000001'));
    });
});
