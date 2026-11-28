/**
 * Server-side access decision for the roles in the Aa-register entry portal.
 *
 * A role comes from AAREG_PortalRole__mdt and its capabilities from AAREG_RoleCapability__mdt. The policy is chosen
 * with an explicit switch on the role's context type. The identity is always the signed-in user. The decision is
 * fail-closed: an unknown, inactive or switched-off role, a shielded person and an invalid context are denied, and a
 * failing access source gives TECHNICAL_ERROR instead of DENIED.
 *
 * @author Kenneth Sørensen
 * @since 2026-11
 * @group Contact Model
 * @see docs/architecture/kontaktmodell/inngangsportal.md
 */
public with sharing class AAREG_RoleAccessService {
    /** Access granted; capabilities lists what the user may do. */
    public static final String GRANTED = 'GRANTED';
    /** Access denied; reason tells the portal which fixed message to show. */
    public static final String DENIED = 'DENIED';
    /** The access source failed; the user may try again. */
    public static final String TECHNICAL_ERROR = 'TECHNICAL_ERROR';

    /** The role exists but the source did not grant any capability for the context. */
    public static final String REASON_NO_ACCESS = 'no-access';
    /** The role is inactive, switched off or unavailable for the person. */
    public static final String REASON_ROLE_NOT_ACTIVE = 'role-not-active';
    /** The role key is unknown. */
    public static final String REASON_UNKNOWN_ROLE = 'unknown-role';
    /** The organization or person context is missing or invalid. */
    public static final String REASON_INVALID_CONTEXT = 'invalid-context';

    /** Context type for roles that act on behalf of an organization. */
    public static final String CONTEXT_ORGANIZATION = 'Organization';
    /** Context type for roles where the signed-in person acts on their own behalf. */
    public static final String CONTEXT_PERSON = 'Person';

    private static final Pattern ORGANIZATION_NUMBER_PATTERN = Pattern.compile('^\\d{9}$');

    @TestVisible
    private static AltinnCalloutService altinnOverride;
    @TestVisible
    private static Map<String, AAREG_PortalRole__mdt> rolesOverride;

    /**
     * Thrown by require when the signed-in user may not use a capability.
     */
    public class AccessDeniedException extends Exception {
    }

    /**
     * Decides whether the signed-in user may use a role in a context.
     *
     * @param roleKey Developer name of the AAREG_PortalRole__mdt record.
     * @param contextKey Organization number for organization roles; blank for person roles.
     * @return The decision. Never null and never throws.
     */
    public static Decision decide(String roleKey, String contextKey) {
        AAREG_PortalRole__mdt role = String.isBlank(roleKey) ? null : roles().get(roleKey);
        if (role == null) {
            return denied(roleKey, null, REASON_UNKNOWN_ROLE);
        }
        if (!isAvailable(role)) {
            return denied(roleKey, role.ContextType__c, REASON_ROLE_NOT_ACTIVE);
        }
        try {
            switch on role.ContextType__c {
                when 'Organization' {
                    return decideForOrganization(role, contextKey);
                }
                when 'Person' {
                    return decideForPerson(role, contextKey);
                }
                when else {
                    return denied(roleKey, role.ContextType__c, REASON_ROLE_NOT_ACTIVE);
                }
            }
        } catch (Exception error) {
            return technicalError(roleKey, role.ContextType__c);
        }
    }

    /**
     * Requires a capability for a role and context. Use in every server method that acts in a role.
     *
     * @param roleKey Developer name of the AAREG_PortalRole__mdt record.
     * @param contextKey Organization number for organization roles; blank for person roles.
     * @param capability Capability the call needs, for example SUPPORT.
     * @return The granted decision.
     * @throws AccessDeniedException When the decision is not GRANTED or lacks the capability.
     */
    public static Decision require(String roleKey, String contextKey, String capability) {
        Decision decision = decide(roleKey, contextKey);
        if (decision.outcome != GRANTED || !decision.capabilities.contains(capability)) {
            throw new AccessDeniedException(
                decision.outcome == TECHNICAL_ERROR ? TECHNICAL_ERROR : DENIED + ':' + decision.reason
            );
        }
        return decision;
    }

    /**
     * Returns the roles that are active and switched on for the signed-in user, sorted for the portal.
     *
     * @return Available roles; empty for shielded persons.
     */
    public static List<AAREG_PortalRole__mdt> availableRoles() {
        List<AAREG_PortalRole__mdt> available = new List<AAREG_PortalRole__mdt>();
        for (AAREG_PortalRole__mdt role : roles().values()) {
            if (isAvailable(role)) {
                available.add(role);
            }
        }
        available.sort(new RoleOrder());
        return available;
    }

    /**
     * Returns whether the entry portal is on for the signed-in user. Off for shielded persons (ADR-0008).
     *
     * @return True when the portal should replace the current home page.
     */
    public static Boolean isPortalEnabled() {
        return AAREG_ContactModelGate.isEnabled(AAREG_ContactModelGate.ENTRY_PORTAL) &&
            !AAREG_ContactModelShielding.isShieldedUser(UserInfo.getUserId());
    }

    /**
     * Normalizes an organization number by removing whitespace.
     *
     * @param value Raw organization number.
     * @return Nine digits, or null when the value is not a valid organization number.
     */
    public static String normalizeOrganizationNumber(String value) {
        String normalized = (value ?? '').deleteWhitespace();
        return ORGANIZATION_NUMBER_PATTERN.matcher(normalized).matches() ? normalized : null;
    }

    private static Boolean isAvailable(AAREG_PortalRole__mdt role) {
        return role.IsActive__c == true &&
            String.isNotBlank(role.FeatureFlag__c) &&
            isPortalEnabled() &&
            AAREG_ContactModelGate.isEnabled(role.FeatureFlag__c);
    }

    private static Decision decideForOrganization(AAREG_PortalRole__mdt role, String contextKey) {
        String organizationNumber = normalizeOrganizationNumber(contextKey);
        if (organizationNumber == null) {
            return denied(role.DeveloperName, CONTEXT_ORGANIZATION, REASON_INVALID_CONTEXT);
        }
        Map<String, Set<String>> capabilitiesByResource = new Map<String, Set<String>>();
        for (AAREG_RoleCapability__mdt row : capabilities(role.DeveloperName)) {
            if (String.isBlank(row.AltinnResource__c)) {
                continue;
            }
            if (!capabilitiesByResource.containsKey(row.AltinnResource__c)) {
                capabilitiesByResource.put(row.AltinnResource__c, new Set<String>());
            }
            capabilitiesByResource.get(row.AltinnResource__c).add(row.Capability__c);
        }

        String personIdent = personIdent();
        AltinnCalloutService altinn = altinn(personIdent);
        Set<String> grantedCapabilities = new Set<String>();
        for (String resource : capabilitiesByResource.keySet()) {
            if (grantedCapabilities.containsAll(capabilitiesByResource.get(resource))) {
                continue;
            }
            AltinnCalloutService.AltinnRightsResponse response = altinn.getRights(
                personIdent,
                organizationNumber,
                resource
            );
            if (isTechnicalFailure(response)) {
                return technicalError(role.DeveloperName, CONTEXT_ORGANIZATION);
            }
            if (isPermitted(response)) {
                grantedCapabilities.addAll(capabilitiesByResource.get(resource));
            }
        }
        if (grantedCapabilities.isEmpty()) {
            return denied(role.DeveloperName, CONTEXT_ORGANIZATION, REASON_NO_ACCESS);
        }
        Decision decision = granted(role.DeveloperName, CONTEXT_ORGANIZATION, grantedCapabilities);
        decision.organizationNumber = organizationNumber;
        return decision;
    }

    private static Decision decideForPerson(AAREG_PortalRole__mdt role, String contextKey) {
        if (String.isNotBlank(contextKey) || personIdent() == null) {
            return denied(role.DeveloperName, CONTEXT_PERSON, REASON_INVALID_CONTEXT);
        }
        Set<String> grantedCapabilities = new Set<String>();
        for (AAREG_RoleCapability__mdt row : capabilities(role.DeveloperName)) {
            if (String.isBlank(row.AltinnResource__c)) {
                grantedCapabilities.add(row.Capability__c);
            }
        }
        return granted(role.DeveloperName, CONTEXT_PERSON, grantedCapabilities);
    }

    private static Boolean isTechnicalFailure(AltinnCalloutService.AltinnRightsResponse response) {
        return response == null ||
            (response.success == false &&
            String.isNotBlank(response.errorMessage) &&
            (response.rights == null || response.rights.isEmpty()));
    }

    private static Boolean isPermitted(AltinnCalloutService.AltinnRightsResponse response) {
        for (AltinnCalloutService.Right right : response.rights ?? new List<AltinnCalloutService.Right>()) {
            if (right.Action == 'Access' && right.Decision == 'Permit') {
                return true;
            }
        }
        return false;
    }

    private static Map<String, AAREG_PortalRole__mdt> roles() {
        return rolesOverride ?? AAREG_PortalRole__mdt.getAll();
    }

    private static List<AAREG_RoleCapability__mdt> capabilities(String roleKey) {
        List<AAREG_RoleCapability__mdt> rows = new List<AAREG_RoleCapability__mdt>();
        for (AAREG_RoleCapability__mdt row : AAREG_RoleCapability__mdt.getAll().values()) {
            if (row.Role__c == roleKey) {
                rows.add(row);
            }
        }
        return rows;
    }

    private static String personIdent() {
        List<User> users = [
            SELECT Contact.Account.INT_PersonIdent__c
            FROM User
            WHERE Id = :UserInfo.getUserId()
            WITH SYSTEM_MODE
        ];
        return users.isEmpty() ? null : users[0].Contact?.Account?.INT_PersonIdent__c;
    }

    private static AltinnCalloutService altinn(String personIdent) {
        if (altinnOverride != null) {
            return altinnOverride;
        }
        return AAREG_AltinnServiceFactory.createService(UserInfo.getUserId(), personIdent);
    }

    private class RoleOrder implements Comparator<AAREG_PortalRole__mdt> {
        public Integer compare(AAREG_PortalRole__mdt left, AAREG_PortalRole__mdt right) {
            Decimal leftOrder = left.SortOrder__c ?? 999;
            Decimal rightOrder = right.SortOrder__c ?? 999;
            return leftOrder == rightOrder ? 0 : (leftOrder < rightOrder ? -1 : 1);
        }
    }

    /**
     * Outcome of an access decision. Contains no personal data.
     */
    public class Decision {
        /** GRANTED, DENIED or TECHNICAL_ERROR. */
        @AuraEnabled
        public String outcome;
        /** Fixed status code for DENIED, for example no-access. */
        @AuraEnabled
        public String reason;
        /** Role key the decision applies to. */
        @AuraEnabled
        public String roleKey;
        /** Organization or Person. */
        @AuraEnabled
        public String contextType;
        /** Verified organization number for organization roles. */
        @AuraEnabled
        public String organizationNumber;
        /** Capabilities granted by the server, sorted. */
        @AuraEnabled
        public List<String> capabilities = new List<String>();

        private Decision(String outcome, String roleKey, String contextType) {
            this.outcome = outcome;
            this.roleKey = roleKey;
            this.contextType = contextType;
        }
    }

    private static Decision denied(String roleKey, String contextType, String reason) {
        Decision decision = new Decision(DENIED, roleKey, contextType);
        decision.reason = reason;
        return decision;
    }

    private static Decision technicalError(String roleKey, String contextType) {
        return new Decision(TECHNICAL_ERROR, roleKey, contextType);
    }

    private static Decision granted(String roleKey, String contextType, Set<String> capabilities) {
        Decision decision = new Decision(GRANTED, roleKey, contextType);
        decision.capabilities = new List<String>(capabilities);
        decision.capabilities.sort();
        return decision;
    }
}
