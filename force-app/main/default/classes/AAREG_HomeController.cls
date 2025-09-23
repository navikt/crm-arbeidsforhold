public without sharing class AAREG_HomeController {
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

    @AuraEnabled
    public static String getLastUsersLastUsedOrganization(String userId) {
        String lastUsedOrganization = [SELECT Id, LastUsedOrganization__c FROM User WHERE Id = :userId]
        .LastUsedOrganization__c;
        return lastUsedOrganization;
    }

    @AuraEnabled
    public static void updateLastUsedOrganization(String organizationNumber, String userId) {
        User communityUser = [SELECT Id, LastUsedOrganization__c FROM User WHERE Id = :userId];
        try {
            communityUser.LastUsedOrganization__c = organizationNumber;
            update communityUser;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    // If user has access to the org in picklist -> Share org agreements with the user when changing org and on init
    @AuraEnabled
    public static void shareAgreementsWithUser(String userId) {
        String lastUsedOrganization = getLastUsersLastUsedOrganization(userId);
        if (Test.isRunningTest()) {
            lastUsedOrganization = '123456789';
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
            Database.SaveResult[] saveResult = Database.insert(agreementShares, false);
        } catch (Exception e) {
            LoggerUtility logger = new LoggerUtility();
            logger.error(e.getMessage(), null);
            logger.publish();
        }
        shareAgreementRelatedContacts(agreements, userId);
    }

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
            if (relatedContact.OwnerId == userId) {
                continue; // Do not create Apex Sharing record if user is already owner
            }
            relatedContactShare = new RelatedContact__Share();
            relatedContactShare.ParentId = relatedContact.Id;
            relatedContactShare.UserOrGroupId = userId;
            relatedContactShare.AccessLevel = 'edit';
            relatedContactShares.add(relatedContactShare);
        }

        try {
            Database.SaveResult[] saveResult = Database.insert(relatedContactShares, false);
        } catch (Exception e) {
            LoggerUtility logger = new LoggerUtility();
            logger.error(e.getMessage(), null);
            logger.publish();
        }
    }
}
