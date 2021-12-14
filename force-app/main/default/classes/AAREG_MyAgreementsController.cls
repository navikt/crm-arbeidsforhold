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
    List<Agreement__c> agreements = new List<Agreement__c>();

    agreements = [
      SELECT Id, Name, toLabel(Status__c)
      FROM Agreement__c
      WHERE OrganizationNumber__c = :lastUsedOrganization AND Status__c = 'Active'
    ];

    return agreements;
  }
}
