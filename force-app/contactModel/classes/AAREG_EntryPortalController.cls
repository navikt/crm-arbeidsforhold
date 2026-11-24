/**
 * Portal endpoints for the entry portal on the home page and the role pages.
 *
 * Every decision is made by AAREG_RoleAccessService for the signed-in user. Values from the URL are only treated as
 * a request for a role and context, never as proof of access. While the existing sub-pages still read
 * LastUsedOrganization__c, a granted organization decision stores the organization there and shares its agreements,
 * exactly as the current home page does.
 *
 * @author Kenneth Sørensen
 * @since 2026-11
 * @group Contact Model
 * @see docs/architecture/kontaktmodell/inngangsportal.md
 */
public with sharing class AAREG_EntryPortalController {
    /**
     * Returns whether the entry portal is on and which roles the user can choose.
     *
     * @return Portal state; disabled when the flag is off, the person is shielded or the check fails.
     */
    @AuraEnabled
    public static Portal getPortal() {
        Portal portal = new Portal();
        try {
            portal.enabled = AAREG_RoleAccessService.isPortalEnabled();
            if (portal.enabled) {
                for (AAREG_PortalRole__mdt role : AAREG_RoleAccessService.availableRoles()) {
                    portal.roles.add(new RoleOption(role));
                }
            }
        } catch (Exception error) {
            portal.enabled = false;
            portal.roles.clear();
        }
        return portal;
    }

    /**
     * Decides access for a role and context and, when an organization role is granted, keeps the existing sub-pages
     * working by storing the organization as last used and sharing its agreements.
     *
     * @param roleKey Role set on the Experience Cloud page.
     * @param organizationNumber Organization chosen or given in a direct link; blank for person roles.
     * @return The decision. Never throws.
     */
    @AuraEnabled
    public static AAREG_RoleAccessService.Decision decide(String roleKey, String organizationNumber) {
        AAREG_RoleAccessService.Decision decision = AAREG_RoleAccessService.decide(roleKey, organizationNumber);
        if (
            decision.outcome == AAREG_RoleAccessService.GRANTED &&
            decision.contextType == AAREG_RoleAccessService.CONTEXT_ORGANIZATION
        ) {
            try {
                AAREG_HomeController.updateLastUsedOrganization(decision.organizationNumber, UserInfo.getUserId());
                if (decision.capabilities.contains('AGREEMENTS')) {
                    AAREG_HomeController.shareAgreementsWithUser(UserInfo.getUserId());
                }
            } catch (Exception error) {
                decision.outcome = AAREG_RoleAccessService.TECHNICAL_ERROR;
                decision.capabilities.clear();
            }
        }
        return decision;
    }

    /**
     * Returns the organizations the user can choose for an organization role.
     *
     * @param roleKey Role set on the Experience Cloud page.
     * @return Organizations from Altinn, sorted by name.
     * @throws AuraHandledException When the role is not available or is not an organization role, or Altinn fails.
     */
    @AuraEnabled
    public static List<AAREG_ContactModelPortalController.OrganizationOption> getOrganizations(String roleKey) {
        Boolean organizationRole = false;
        for (AAREG_PortalRole__mdt role : AAREG_RoleAccessService.availableRoles()) {
            if (role.DeveloperName == roleKey && role.ContextType__c == AAREG_RoleAccessService.CONTEXT_ORGANIZATION) {
                organizationRole = true;
            }
        }
        if (!organizationRole) {
            AuraHandledException error = new AuraHandledException('Rollen er ikke tilgjengelig.');
            error.setMessage('Rollen er ikke tilgjengelig.');
            throw error;
        }
        return AAREG_ContactModelPortalController.listOrganizations();
    }

    /**
     * Entry portal state for the signed-in user.
     */
    public class Portal {
        /** Whether the entry portal replaces the current home page. */
        @AuraEnabled
        public Boolean enabled = false;
        /** Roles the user can choose, in portal order. */
        @AuraEnabled
        public List<RoleOption> roles = new List<RoleOption>();
    }

    /**
     * Role shown in the entry portal. User-facing texts live in the LWC.
     */
    public class RoleOption {
        /** Developer name of the role. */
        @AuraEnabled
        public String roleKey;
        /** Organization or Person. */
        @AuraEnabled
        public String contextType;
        /** API name of the role's Experience Cloud page. */
        @AuraEnabled
        public String pageApiName;

        private RoleOption(AAREG_PortalRole__mdt role) {
            this.roleKey = role.DeveloperName;
            this.contextType = role.ContextType__c;
            this.pageApiName = role.PageApiName__c;
        }
    }
}
