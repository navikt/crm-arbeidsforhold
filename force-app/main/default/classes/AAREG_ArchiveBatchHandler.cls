public class AAREG_ArchiveBatchHandler {
  private static final String NEW_APPLICATION = 'New';
  private static final String CLOSED_APPLICATION = 'Closed';

  public static void archive(Set<Id> recordIds) {
    List<Application__c> applicationsToArchive = new List<Application__c>();
    List<Application__c> decisionsToArchive = new List<Application__c>();

    for (Application__c application : getApplications(recordIds)) {
      if (application.Casehandler_Status__c == NEW_APPLICATION && !application.AA_ApplicationArchived__c) {
        applicationsToArchive.add(application);
      }
      if (application.Casehandler_Status__c == CLOSED_APPLICATION && !application.AA_DecisionArchived__c) {
        decisionsToArchive.add(application);
      }
    }
    if (!applicationsToArchive.isEmpty()) {
      Database.executeBatch(new AAREG_ApplicationArchiveBatch(applicationsToArchive), 20);
    }

    if (!decisionsToArchive.isEmpty()) {
      Database.executeBatch(new AAREG_DecisionArchiveBatch(decisionsToArchive), 40);
    }
  }

  private static List<Application__c> getApplications(Set<Id> recordIds) {
    return [
      SELECT
        Id,
        Name,
        Casehandler_Status__c,
        AA_register_application_text__c,
        AA_ApplicationArchived__c,
        AA_ApplicationArchivedDate__c,
        AA_DecisionArchived__c,
        AA_CaseHandlerNavIdent__c,
        AA_DecisionArchiveText__c
      FROM Application__c
      WHERE Id IN :recordIds
    ];
  }
}
