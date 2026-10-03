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
        P360_TestDataFactory.setArchiveProcessingEnabled(true);
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

    /**
     * An Application-linked ContentVersion should not create a P360 job when archive processing is disabled.
     *
     * @since 2026-10
     */
    @IsTest
    static void shouldNotCreateAttachmentJobWhenArchiveProcessingIsDisabled() {
        User processingUser = createProcessingUser();

        System.runAs(processingUser) {
            Access_Request__c accessRequest = new Access_Request__c();
            insert accessRequest;
            Application__c application = new Application__c(Access_Request__c = accessRequest.Id);
            insert application;

            System.Test.startTest();
            ContentVersion version = new ContentVersion(
                Title = 'application-attachment-disabled',
                PathOnClient = 'application-attachment-disabled.pdf',
                VersionData = Blob.valueOf('attachment'),
                FirstPublishLocationId = application.Id
            );
            insert version;
            System.Test.stopTest();

            Integer jobCount = [SELECT COUNT() FROM P360_Archive_Job__c WHERE Application__c = :application.Id];
            System.Assert.areEqual(0, jobCount);
        }
    }

    /**
     * A false org-default archive-processing setting should not create an attachment job.
     *
     * @since 2026-10
     */
    @IsTest
    static void shouldNotCreateAttachmentJobWhenArchiveProcessingIsExplicitlyFalse() {
        P360_TestDataFactory.setArchiveProcessingEnabled(false);
        User processingUser = createProcessingUser();

        System.runAs(processingUser) {
            Access_Request__c accessRequest = new Access_Request__c();
            insert accessRequest;
            Application__c application = new Application__c(Access_Request__c = accessRequest.Id);
            insert application;

            System.Test.startTest();
            insert new ContentVersion(
                Title = 'application-attachment-explicitly-disabled',
                PathOnClient = 'application-attachment-explicitly-disabled.pdf',
                VersionData = Blob.valueOf('attachment'),
                FirstPublishLocationId = application.Id
            );
            System.Test.stopTest();

            Integer jobCount = [SELECT COUNT() FROM P360_Archive_Job__c WHERE Application__c = :application.Id];
            System.Assert.areEqual(0, jobCount);
        }
    }

    /**
     * Missing settings and unset checkbox values should fail closed.
     *
     * @since 2026-10
     */
    @IsTest
    static void shouldFailClosedWhenSettingOrCheckboxIsNull() {
        P360_Integration_Setting__c unsetSetting = new P360_Integration_Setting__c();
        System.Assert.isFalse(P360_ArchiveProcessingGate.isExplicitlyEnabled(null));
        System.Assert.isFalse(P360_ArchiveProcessingGate.isExplicitlyEnabled(unsetSetting));
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
