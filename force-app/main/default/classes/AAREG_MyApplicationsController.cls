public with sharing class AAREG_MyApplicationsController {
  @AuraEnabled(cacheable=true)
  public static List<Application__c> getUsersApplications(String userId) {
    String lastUsedOrganization = [SELECT Id, lastUsedOrganization__c FROM User WHERE ID = :userid]
    ?.LastUsedOrganization__c;

    if (lastUsedOrganization != null) {
      return getApplications(lastUsedOrganization);
    } else {
      return new List<Application__c>();
    }
  }

  private static List<Application__c> getApplications(String lastUsedOrganization) {
    List<Application__c> applications = new List<Application__c>(
      [
        SELECT Id, Name, Casehandler_Status__c, toLabel(Status__c), ApplicationSubmittedDate__c
        FROM Application__c
        WHERE OrganizationNumber__c = :lastUsedOrganization
        ORDER BY ApplicationSubmittedDate__c DESC
      ]
    );
    return applications;
  }
}
