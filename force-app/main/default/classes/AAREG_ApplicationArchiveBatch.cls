public class AAREG_ApplicationArchiveBatch implements Database.Batchable<sObject>, Database.AllowsCallouts {
  List<Application__c> applications;

  public AAREG_ApplicationArchiveBatch(List<Application__c> applications) {
    this.applications = applications;
  }

  public List<Application__c> start(Database.BatchableContext context) {
    return applications;
  }

  public void execute(Database.BatchableContext context, List<Application__c> applications) {
    new AAREG_ArchiveService().archiveApplications(applications);
  }

  public void finish(Database.BatchableContext context) {
    return;
  }
}
