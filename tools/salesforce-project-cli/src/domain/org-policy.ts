/**
 * Centralizes Salesforce org classification and the fail-closed mutation policy.
 * Mutations are scratch-only by default. Other org categories require an explicit confirmation token.
 */
/** Safety classification used to decide whether an org may be mutated automatically. */
export type OrgClassification = 'scratch' | 'sandbox' | 'development' | 'dev-hub' | 'production' | 'unknown';

/**
 * Applies the fail-closed mutation policy for Salesforce org classifications.
 *
 * @param classification - Classification established by org inspection.
 * @returns `true` only for scratch orgs.
 */
export function isOrgMutationAllowed(classification: OrgClassification): boolean {
    return classification === 'scratch';
}

/**
 * Returns the exact confirmation text required to override the scratch-only mutation policy.
 *
 * @param operation - Stable command operation name, for example `packages.install`.
 * @param org - Alias or username selected for the mutation.
 * @returns A human-readable token that binds confirmation to both command and org.
 */
export function mutationConfirmationToken(operation: string, org: string): string {
    return `MUTATE ${operation} ${org}`;
}

/**
 * Checks the scratch-only policy and an optional explicit override token.
 *
 * @param classification - Inspected Salesforce org classification.
 * @param operation - Stable command operation name.
 * @param org - Alias or username selected for the mutation.
 * @param confirmation - User-provided override token.
 * @returns `true` when mutation is permitted.
 */
export function isOrgMutationConfirmed(
    classification: OrgClassification,
    operation: string,
    org: string,
    confirmation?: string
): boolean {
    return isOrgMutationAllowed(classification) || confirmation === mutationConfirmationToken(operation, org);
}
