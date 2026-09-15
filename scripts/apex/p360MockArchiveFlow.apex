// P360 mock smoke flow for the approved default scratch org: crm-arbeidsforhold.
// Prerequisite: the running user has P360_Archive_Job_Processing.
// This script never performs a live P360 call. It enables the explicit mock transport,
// creates an application and attachment, creates the document job, and dispatches the
// scheduler. Query P360_Archive_Job__c after the async worker finishes.

P360_Integration_Setting__c settings = P360_Integration_Setting__c.getOrgDefaults();
if (settings == null) {
    settings = new P360_Integration_Setting__c();
}
settings.Use_Mock_Transport__c = true;
upsert settings;

Access_Request__c accessRequest = new Access_Request__c();
insert accessRequest;

Application__c application = new Application__c(Access_Request__c = accessRequest.Id);
insert application;

ContentVersion attachment = new ContentVersion(
    Title = 'p360-mock-attachment',
    PathOnClient = 'p360-mock-attachment.txt',
    VersionData = Blob.valueOf('P360 mock attachment'),
    FirstPublishLocationId = application.Id
);
insert attachment;

P360_Archive_Job__c documentJob = P360_ArchiveJobService.getOrCreateApplicationDocumentJob(
    accessRequest.Id,
    application.Id,
    'mock-script-document-' + application.Id
);

new P360_ArchiveJobScheduler().execute(null);

System.debug('P360 mock application: ' + application.Id);
System.debug('P360 mock attachment: ' + attachment.Id);
System.debug('P360 mock document job: ' + documentJob.Id);
System.debug('P360 mock flow dispatched scheduler; query P360_Archive_Job__c after async processing.');
