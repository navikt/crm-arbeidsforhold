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
    List<Application__c> applications = new List<Application__c>();
    List<Application__c> applicationstemp = new List<Application__c>(
      [
        SELECT Id, Name, CreatedDate, Casehandler_Status__c,Status__c, ApplicationSubmittedDate__c,ApplicationDeadlineForReply__c, AA_CasehandlerDecisionTemplate__c
        FROM Application__c
        WHERE OrganizationNumber__c = :lastUsedOrganization
        ORDER BY ApplicationSubmittedDate__c DESC NULLS LAST
      ]
    );
    for (Application__c app : applicationstemp) {
      app.Status__c = translateStatus(app.Status__c);
      applications.add(app);
    }
    return applications;
  }

  private static String translateStatus(String status) {
    Map<String, String> statusLabels = new Map<String, String>{
      'In Progress' => 'Under behandling',
      'Draft' => 'Utkast',
      'New' => 'Ny',
      'Additional Information Required' => 'Venter på svar',
      'Approved' => 'Innvilget',
      'Approved Partially' => 'Delvis innvilget',
      'Declined' => 'Avslag',
      'Suspension' => 'Trukket tilbake'
    };
    return statusLabels.containsKey(status) ? statusLabels.get(status) : 'Ukjent status';
  }
}