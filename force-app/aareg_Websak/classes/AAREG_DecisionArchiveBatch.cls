public class AAREG_DecisionArchiveBatch implements Database.Batchable<sObject>, Database.AllowsCallouts {
  List<Application__c> applications;

  public AAREG_DecisionArchiveBatch(List<Application__c> applications) {
    this.applications = applications;
  }

  public List<Application__c> start(Database.BatchableContext context) {
    return applications;
  }

  public void execute(Database.BatchableContext context, List<Application__c> applications) {
    AAREG_ArchiveService archive = new AAREG_ArchiveService();
    archive.archiveDecisions(applications);
  }

  public void finish(Database.BatchableContext context) {
    return;
  }
}
