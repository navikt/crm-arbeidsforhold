import { describe, expect, it } from 'vitest';
import {
    isOrgMutationAllowed,
    isOrgMutationConfirmed,
    mutationConfirmationToken
} from '../../src/domain/org-policy.js';

describe('org mutation policy', () => {
    it('keeps production, unknown, and Dev Hub orgs read-only by default', () => {
        expect(isOrgMutationAllowed('scratch')).toBe(true);
        expect(isOrgMutationAllowed('sandbox')).toBe(false);
        expect(isOrgMutationAllowed('development')).toBe(false);
        expect(isOrgMutationAllowed('production')).toBe(false);
        expect(isOrgMutationAllowed('unknown')).toBe(false);
        expect(isOrgMutationAllowed('dev-hub')).toBe(false);
    });

    it('requires an exact operation and org token to override the scratch-only policy', () => {
        expect(mutationConfirmationToken('packages.install', 'production-org')).toBe(
            'MUTATE packages.install production-org'
        );
        expect(isOrgMutationConfirmed('production', 'packages.install', 'production-org')).toBe(false);
        expect(
            isOrgMutationConfirmed(
                'production',
                'packages.install',
                'production-org',
                'MUTATE packages.install other-org'
            )
        ).toBe(false);
        expect(
            isOrgMutationConfirmed(
                'production',
                'packages.install',
                'production-org',
                'MUTATE packages.install production-org'
            )
        ).toBe(true);
        expect(isOrgMutationConfirmed('scratch', 'packages.install', 'scratch-org')).toBe(true);
    });
});
