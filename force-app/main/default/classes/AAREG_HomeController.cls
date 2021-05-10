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

    return response;
  }

  @AuraEnabled
  public static String getLastUsersLastUsedOrganiation(String userId) {
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
}
