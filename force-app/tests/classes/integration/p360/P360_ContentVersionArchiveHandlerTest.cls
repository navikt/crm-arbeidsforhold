/**
 * Verifies P360 attachment job creation for application-linked ContentVersion records.
 *
 * @author Kenneth Sørensen
 * @since 2026-09
 * @group P360 Archive Job
 */
@IsTest
private class P360_ContentVersionArchiveHandlerTest {
    /**
     * A ContentVersion published to an application should create one pending attachment job.
     *
     * @since 2026-09
     */
    @IsTest
    static void shouldCreateAttachmentJobForApplicationContentVersion() {
        User processingUser = createProcessingUser();

        System.runAs(processingUser) {
            Access_Request__c accessRequest = new Access_Request__c();
            insert accessRequest;
            Application__c application = new Application__c(Access_Request__c = accessRequest.Id);
            insert application;

            System.Test.startTest();
            ContentVersion version = new ContentVersion(
                Title = 'application-attachment',
                PathOnClient = 'application-attachment.pdf',
                VersionData = Blob.valueOf('attachment'),
                FirstPublishLocationId = application.Id
            );
            insert version;
            System.Test.stopTest();

            P360_Archive_Job__c job = [
                SELECT Application__c, Access_Request__c, Archive_Event_Type__c, Status__c
                FROM P360_Archive_Job__c
                WHERE Application__c = :application.Id
                LIMIT 1
            ];
            System.Assert.areEqual(application.Id, job.Application__c);
            System.Assert.areEqual(accessRequest.Id, job.Access_Request__c);
            System.Assert.areEqual('ApplicationAttachment', job.Archive_Event_Type__c);
            System.Assert.areEqual('Pending', job.Status__c);
        }
    }

    private static User createProcessingUser() {
        User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        User processingUser;
        System.runAs(currentUser) {
            processingUser = P360_TestDataFactory.createMinimumAccessUser();
            AAREG_TestDataFactory.assignPermissionSet(processingUser.Id, 'AAREG_Arbeidsforhold_Saksbehandling');
            AAREG_TestDataFactory.assignPermissionSet(processingUser.Id, 'P360_Archive_Job_Processing');
        }
        return processingUser;
    }
}
