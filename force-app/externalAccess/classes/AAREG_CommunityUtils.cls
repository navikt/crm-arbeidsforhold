/**
 * Utility class for community-related operations in the AAREG system.
 * This class is defined with "without sharing" to ensure that it does not enforce the sharing rules
 * of the user context under which it executes.
 *
 * Note: Add specific details about the purpose and functionality of this class.
 *
 * @author [Your Name]
 * @date [Date]
 */
public without sharing class AAREG_CommunityUtils {
    /**
     * Retrieves the user rights from the Altinn service.
     * Only the signed-in user may be targeted, despite the legacy system-mode identity lookup.
     *
     * @param userId Id of the signed-in community user.
     * @param organizationNumber Organization whose rights are requested.
     * @param resourceName Altinn resource whose rights are requested.
     * @return AltinnCalloutService.AltinnRightsResponse - The response containing the user rights information.
     * @throws AuraHandledException If the requested user is not the signed-in user.
     */
    @AuraEnabled
    public static AltinnCalloutService.AltinnRightsResponse getUserRights(
        String userId,
        String organizationNumber,
        String resourceName
    ) {
        if (String.isBlank(userId) || userId != UserInfo.getUserId()) {
            throw new AuraHandledException('Invalid user for rights lookup.');
        }
        User currentUser = [SELECT Id, Contact.Account.INT_PersonIdent__c FROM User WHERE Id = :userId];
        AltinnCalloutService altinn = AAREG_AltinnServiceFactory.createService(
            currentUser.Id,
            currentUser.Contact.Account.INT_PersonIdent__c
        );

        AltinnCalloutService.AltinnRightsResponse response = altinn.getRights(
            currentUser.Contact.Account.INT_PersonIdent__c,
            organizationNumber,
            resourceName
        );

        return response;
    }
}
