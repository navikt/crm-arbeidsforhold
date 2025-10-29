public without sharing class AAREG_CommunityUtils {
    @AuraEnabled
    public static AltinnCalloutService.AltinnRightsResponse getUserRights(
        String userId,
        String organizationNumber,
        String resourceName
    ) {
        User currentUser = [SELECT Id, Contact.Account.INT_PersonIdent__c FROM User WHERE Id = :userId];
        AltinnCalloutService altinn = new AltinnCalloutService();

        AltinnCalloutService.AltinnRightsResponse response = altinn.getRights(
            currentUser.Contact.Account.INT_PersonIdent__c,
            organizationNumber,
            resourceName
        );

        return response;
    }
}
