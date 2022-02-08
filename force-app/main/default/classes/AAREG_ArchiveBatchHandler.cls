public class AAREG_ArchiveBatchHandler {
  private static final String IN_PROGRESS = 'In Progress';
  private static final String CLOSED_APPLICATION = 'Closed';
  private static final String SUSPENDED_APPLICATION ='Suspension';

  public static void archive(Set<Id> recordIds) {
    List<Application__c> applicationsToArchive = new List<Application__c>();
    List<Application__c> decisionsToArchive = new List<Application__c>();
	
    for (Application__c application : getApplications(recordIds)) {
      /*Commented out for now 08.02.2022 
        if (isApplicationArchivable(application)) {
        applicationsToArchive.add(application);
      }
      if (isDecisionArchivable(application)) {
        decisionsToArchive.add(application);
      }*/
    }
    if (!applicationsToArchive.isEmpty()) {
      Database.executeBatch(new AAREG_ApplicationArchiveBatch(applicationsToArchive), 10);
    }

    if (!decisionsToArchive.isEmpty()) {
      Database.executeBatch(new AAREG_DecisionArchiveBatch(decisionsToArchive), 10);
    }
  }

  private static Boolean isApplicationArchivable(Application__c application) {
    return (application.Casehandler_Status__c == IN_PROGRESS ||
      application.Casehandler_Status__c == CLOSED_APPLICATION) &&
      !application.AA_ApplicationArchived__c &&
      String.isNotBlank(application.AA_register_application_text__c);
  }

  private static Boolean isDecisionArchivable(Application__c application) {
    return application.Casehandler_Status__c == CLOSED_APPLICATION &&
      application.Status__c != SUSPENDED_APPLICATION &&
      !application.AA_DecisionArchived__c &&
      application.AA_ApplicationArchived__c == true &&
      application.DecisionDate__c != null &&
      String.isNotBlank(application.AA_DecisionArchiveText__c);
  }

  private static List<Application__c> getApplications(Set<Id> recordIds) {
    return [
      SELECT
        Id,
        Name,
        Status__c,
        Casehandler_Status__c,
        AA_register_application_text__c,
        AA_ApplicationArchived__c,
        AA_ApplicationArchivedDate__c,
        AA_DecisionArchived__c,
        AA_DecisionArchivedDate__c,
        AA_CaseHandlerNavIdent__c,
        CaseHandlerOwner__c,
        AA_DecisionArchiveText__c,
        AccountName__c,
        OrganizationNumber__c,
        MailingAddress__c,
        MailingCity__c,
        MailingPostalCode__c,
        ApplicationSubmittedDate__c,
        DecisionDate__c
      FROM Application__c
      WHERE Id IN :recordIds AND AA_CaseHandlerNavIdent__c != NULL
    ];
  }
}