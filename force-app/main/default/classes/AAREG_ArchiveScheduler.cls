global class AAREG_ArchiveScheduler implements Schedulable {
  global void execute(SchedulableContext ctx) {
    Map<Id, Application__c> applications = new Map<Id, Application__c>(
      [SELECT Id FROM Application__c WHERE AA_ApplicationArchived__c = FALSE OR AA_DecisionArchived__c = FALSE]
    );

    if (!applications.isEmpty()) {
      AAREG_ArchiveBatchHandler.archive(applications.keySet());
    }
  }
}
