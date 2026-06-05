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
     * 
     * @return AltinnCalloutService.AltinnRightsResponse - The response containing the user rights information.
     */
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
