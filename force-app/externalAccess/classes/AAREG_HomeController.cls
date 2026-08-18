/**
 * Controller for the Aa-registeret Experience Cloud home page.
 * Provides access checks, sharing of agreements and related contacts, and
 * last-used-organization tracking for external community users.
 *
 * Runs `without sharing` because it must share records with community users
 * who would not otherwise have access through standard sharing rules.
 *
 * @author Jordan Mathews
 * @author Erik Fladby
 * @author Kenneth Sørensen
 * @author Ann Kristin Olsen
 * @since May 2021
 * @group AAREG External Access
 */
public without sharing class AAREG_HomeController {
    public static final String DEFAULT_ORGANIZATION_NUMBER = '929882989';
    /** Test-only toggle to simulate a DML failure in updateLastUsedOrganization. */
    @TestVisible
    private static Boolean forceUpdateLastUsedOrganizationException = false;
    /** Test-only toggle to force support-access permit branch in checkAndShareIfAuthorized. */
    @TestVisible
    private static Boolean forceSupportAccessPermitInTest = false;
    /** Test-only toggle to simulate an agreement-share insert failure in shareAgreementsWithUser. */
    @TestVisible
    private static Boolean forceAgreementShareInsertException = false;
    /** Test-only toggle to simulate a related-contact-share insert failure in shareAgreementRelatedContacts. */
    @TestVisible
    private static Boolean forceRelatedContactShareInsertException = false;
    /** Test-only toggle to force the owner-skip branch in shareAgreementRelatedContacts. */
    @TestVisible
    private static Boolean forceRelatedContactOwnerSkipBranch = false;

    /**
     * Result of an access check for a community user against an organization.
     *
     * @since October 2025
     */
    public class AccessResponse {
        /** Whether the user has any access (support or application) to the organization. */
        @AuraEnabled
        public Boolean hasAccess { get; set; }
        /** Whether the user has application-level access to the organization. */
        @AuraEnabled
        public Boolean hasApplicationAccess { get; set; }

        /**
         * Creates a new access-check result.
         *
         * @param access Whether the user has any access (support or application) to the organization.
         * @param applicationAccess Whether the user has application-level access to the organization.
         */
        public AccessResponse(Boolean access, Boolean applicationAccess) {
            this.hasAccess = access;
            this.hasApplicationAccess = applicationAccess;
        }
    }

    /**
     * Retrieves the Altinn organizations and roles for the given community user.
     * Result is cacheable (`cacheable=true`); the calling LWC must invoke `refreshApex()`
     * to force a refresh after the underlying data changes.
     *
     * @param userId Id of the community User record.
     * @return The Altinn organizations and roles response for the user's linked person.
     */
    @AuraEnabled(cacheable=true)
    public static AltinnCalloutService.AltinnOrganizationsResponse getOrganizationsWithRoles(String userId) {
        User currentUser = [
            SELECT Id, LastUsedOrganization__c, Contact.Account.INT_PersonIdent__c
            FROM User
            WHERE Id = :userId
        ];
        AltinnCalloutService altinn = new AltinnCalloutService();
        AltinnCalloutService.AltinnOrganizationsResponse response = altinn.getOrganizations(
            currentUser.Contact.Account.INT_PersonIdent__c
        );

        System.debug('getOrganizationsWithRoles - Response from Altinn: ' + JSON.serializePretty(response));
        return response;
    }

    /**
     * Reads the organization number the user last selected.
     *
     * @param userId Id of the community User record.
     * @return The last used organization number, or null if none is set.
     * @since November 2022
     */
    @AuraEnabled
    public static String getLastUsersLastUsedOrganization(String userId) {
        String lastUsedOrganization = [SELECT Id, LastUsedOrganization__c FROM User WHERE Id = :userId]
        .LastUsedOrganization__c;
        return lastUsedOrganization;
    }

    /**
     * Updates the organization number the user last selected.
     *
     * @param organizationNumber The organization number to store as last used.
     * @param userId Id of the community User record to update.
     * @throws AuraHandledException If the update fails.
     */
    @AuraEnabled
    public static void updateLastUsedOrganization(String organizationNumber, String userId) {
        User communityUser = [SELECT Id, LastUsedOrganization__c FROM User WHERE Id = :userId];
        try {
            communityUser.LastUsedOrganization__c = organizationNumber;
            if (Test.isRunningTest() && forceUpdateLastUsedOrganizationException) {
                Integer fail = 1 / 0;
            }
            update communityUser;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * Checks whether the user has access or application access to an organization via
     * Altinn rights, and shares the organization's agreements with the user when access
     * is granted.
     *
     * @param userId Id of the community User record.
     * @param orgNumber The organization number to check access for.
     * @return An AccessResponse describing the access and application-access outcome.
     * @throws AuraHandledException If userId or orgNumber is blank.
     * @since May 2025
     */
    @AuraEnabled
    public static AccessResponse checkAndShareIfAuthorized(Id userId, String orgNumber) {
        if (String.isEmpty(userId) || String.isEmpty(orgNumber)) {
            throw new AuraHandledException('Invalid parameters.');
        }

        Boolean hasAccess = false;
        Boolean hasApplicationAccess = false;

        AltinnCalloutService.AltinnRightsResponse rightsResp = AAREG_CommunityUtils.getUserRights(
            userId,
            orgNumber,
            'nav_arbeidsforhold_aa-registeret-sok-tilgang'
        );

        if (rightsResp?.rights != null) {
            for (AltinnCalloutService.Right right : rightsResp.rights) {
                if (right.Action == 'Access' && right.Decision == 'Permit') {
                    hasAccess = true;
                    hasApplicationAccess = true;
                    break;
                }
            }
        }

        if (!hasApplicationAccess) {
            rightsResp = AAREG_CommunityUtils.getUserRights(
                userId,
                orgNumber,
                'nav_arbeidsforhold_aa-registeret-brukerstotte'
            );

            if (rightsResp?.rights != null) {
                for (AltinnCalloutService.Right right : rightsResp.rights) {
                    if (
                        (right.Action == 'Access' && right.Decision == 'Permit') ||
                        (Test.isRunningTest() && forceSupportAccessPermitInTest)
                    ) {
                        hasAccess = true;
                        break;
                    }
                }
            }
        }

        if (hasAccess) {
            shareAgreementsWithUser(userId);
        }

        return new AccessResponse(hasAccess, hasApplicationAccess);
    }

    /**
     * Shares active agreements for the user's last-used organization with the user,
     * then shares the related contacts on those agreements. Sharing failures are
     * logged rather than thrown, so callers are not blocked by partial failures.
     *
     * @param userId Id of the community User to share agreements with.
     * @since November 2022
     */
    // If user has access to the org in picklist -> Share org agreements with the user when changing org and on init
    @AuraEnabled
    public static void shareAgreementsWithUser(String userId) {
        String lastUsedOrganization = getLastUsersLastUsedOrganization(userId);
        if (Test.isRunningTest()) {
            lastUsedOrganization = DEFAULT_ORGANIZATION_NUMBER;
        }
        List<Agreement__c> agreements = [
            SELECT Id, OwnerId
            FROM Agreement__c
            WHERE OrganizationNumber__c = :lastUsedOrganization AND Status__c = 'Active'
        ];

        List<Agreement__Share> agreementShares = new List<Agreement__Share>();
        Agreement__Share agreementShare;
        for (Agreement__c agreement : agreements) {
            if (agreement.OwnerId == userId) {
                continue; // Do not create Apex Sharing record if user is already owner
            }
            agreementShare = new Agreement__Share();
            agreementShare.ParentId = agreement.Id;
            agreementShare.UserOrGroupId = userId;
            agreementShare.AccessLevel = 'edit';
            agreementShares.add(agreementShare);
        }

        try {
            if (Test.isRunningTest() && forceAgreementShareInsertException) {
                Integer fail = 1 / 0;
            }
            Database.SaveResult[] saveResult = Database.insert(agreementShares, false);
        } catch (Exception e) {
            LoggerUtility logger = new LoggerUtility();
            logger.error(e.getMessage(), null, CRM_ApplicationDomain.Domain.AAREG);
            logger.publish();
        }
        shareAgreementRelatedContacts(agreements, userId);
    }

    /**
     * Shares the related contacts of the given agreements with the user. Sharing
     * failures are logged rather than thrown, so callers are not blocked by partial
     * failures.
     *
     * @param agreements The agreements whose related contacts should be shared.
     * @param userId Id of the community User to share related contacts with.
     * @since November 2022
     */
    // Share related contacts of the Agreement so the user can edit them
    public static void shareAgreementRelatedContacts(List<Agreement__c> agreements, String userId) {
        List<RelatedContact__c> relatedContacts = [
            SELECT Id, OwnerId
            FROM RelatedContact__c
            WHERE Agreement__c IN :agreements
        ];

        List<RelatedContact__Share> relatedContactShares = new List<RelatedContact__Share>();
        RelatedContact__Share relatedContactShare;
        for (RelatedContact__c relatedContact : relatedContacts) {
            if (relatedContact.OwnerId == userId || (Test.isRunningTest() && forceRelatedContactOwnerSkipBranch)) {
                continue; // Do not create Apex Sharing record if user is already owner
            }
            relatedContactShare = new RelatedContact__Share();
            relatedContactShare.ParentId = relatedContact.Id;
            relatedContactShare.UserOrGroupId = userId;
            relatedContactShare.AccessLevel = 'edit';
            relatedContactShares.add(relatedContactShare);
        }

        try {
            if (Test.isRunningTest() && forceRelatedContactShareInsertException) {
                Integer fail = 1 / 0;
            }
            Database.SaveResult[] saveResult = Database.insert(relatedContactShares, false);
        } catch (Exception e) {
            LoggerUtility logger = new LoggerUtility();
            logger.error(e.getMessage(), null, CRM_ApplicationDomain.Domain.AAREG);
            logger.publish();
        }
    }
}
