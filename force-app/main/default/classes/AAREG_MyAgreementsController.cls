public with sharing class AAREG_MyAgreementsController {
  @AuraEnabled(cacheable=true)
  public static List<Agreement__c> getUsersAgreements(String userId) {
    String lastUsedOrganization = [SELECT Id, lastUsedOrganization__c FROM User WHERE ID = :userid]
    ?.LastUsedOrganization__c;

    if (lastUsedOrganization != null) {
      return getAgreements(lastUsedOrganization);
    } else {
      return new List<Agreement__c>();
    }
  }

  private static List<Agreement__c> getAgreements(String lastUsedOrganization) {
    List<Agreement__c> applications = new List<Agreement__c>(
      [SELECT Id, Name, Status__c FROM Agreement__c WHERE OrganizationNumber__c = :lastUsedOrganization]
    );
    return applications;
  }
}
