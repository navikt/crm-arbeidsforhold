/**
 * Verifies idempotent creation of asynchronous P360 archive jobs.
 *
 * @author Kenneth Sørensen
 * @since 2026-09
 * @group P360 Archive Job
 */
@IsTest
private class P360_ArchiveJobServiceTest {
    /**
     * Verifies that repeated application document requests reuse the same pending archive job.
     *
     * @since 2026-09
     */
    @IsTest
    static void shouldReuseApplicationDocumentJobForSameArchiveEvent() {
        User processingUser = createProcessingUser();

        System.runAs(processingUser) {
            Access_Request__c accessRequest = new Access_Request__c();
            insert accessRequest;
            Application__c application = new Application__c();
            insert application;

            System.Test.startTest();
            P360_Archive_Job__c firstJob = P360_ArchiveJobService.getOrCreateApplicationDocumentJob(
                accessRequest.Id,
                application.Id,
                'correlation-application-document'
            );
            P360_Archive_Job__c repeatedJob = P360_ArchiveJobService.getOrCreateApplicationDocumentJob(
                accessRequest.Id,
                application.Id,
                'different-correlation-id'
            );
            System.Test.stopTest();

            System.Assert.areEqual(firstJob.Id, repeatedJob.Id, 'Retry must reuse the existing archive job.');
            P360_Archive_Job__c savedJob = [
                SELECT
                    Access_Request__c,
                    Application__c,
                    Archive_Event_Type__c,
                    Attempt_Count__c,
                    Correlation_Id__c,
                    Idempotency_Key__c,
                    Queued_Date__c,
                    Status__c
                FROM P360_Archive_Job__c
                WHERE Id = :firstJob.Id
                LIMIT 1
            ];
            System.Assert.areEqual(accessRequest.Id, savedJob.Access_Request__c);
            System.Assert.areEqual(application.Id, savedJob.Application__c);
            System.Assert.areEqual('ApplicationDocument', savedJob.Archive_Event_Type__c);
            System.Assert.areEqual(0, savedJob.Attempt_Count__c);
            System.Assert.areEqual('correlation-application-document', savedJob.Correlation_Id__c);
            System.Assert.areEqual(
                P360_IdempotencyKey.forApplicationDocument(application.Id),
                savedJob.Idempotency_Key__c
            );
            System.Assert.isNotNull(savedJob.Queued_Date__c, 'A new archive job must record when it was queued.');
            System.Assert.areEqual('Pending', savedJob.Status__c);
            System.Assert.areEqual(
                1,
                [SELECT COUNT() FROM P360_Archive_Job__c WHERE Idempotency_Key__c = :savedJob.Idempotency_Key__c]
            );
        }
    }

    /**
     * Verifies that repeated application attachment requests reuse the same pending archive job.
     *
     * @since 2026-09
     */
    @IsTest
    static void shouldReuseApplicationAttachmentJobForSameArchiveEvent() {
        User processingUser = createProcessingUser();

        System.runAs(processingUser) {
            Access_Request__c accessRequest = new Access_Request__c();
            insert accessRequest;
            Application__c application = new Application__c();
            insert application;
            ContentVersion contentVersion = new ContentVersion(
                Title = 'attachment',
                PathOnClient = 'attachment.pdf',
                VersionData = Blob.valueOf('attachment content')
            );
            insert contentVersion;

            System.Test.startTest();
            P360_Archive_Job__c firstJob = P360_ArchiveJobService.getOrCreateApplicationAttachmentJob(
                accessRequest.Id,
                application.Id,
                contentVersion.Id,
                'correlation-application-attachment'
            );
            P360_Archive_Job__c repeatedJob = P360_ArchiveJobService.getOrCreateApplicationAttachmentJob(
                accessRequest.Id,
                application.Id,
                contentVersion.Id,
                'different-correlation-id'
            );
            System.Test.stopTest();

            System.Assert.areEqual(
                firstJob.Id,
                repeatedJob.Id,
                'Retry must reuse the existing attachment archive job.'
            );
            P360_Archive_Job__c savedJob = [
                SELECT
                    Access_Request__c,
                    Application__c,
                    Archive_Event_Type__c,
                    Attempt_Count__c,
                    Correlation_Id__c,
                    Idempotency_Key__c,
                    Queued_Date__c,
                    Status__c
                FROM P360_Archive_Job__c
                WHERE Id = :firstJob.Id
                LIMIT 1
            ];
            System.Assert.areEqual(accessRequest.Id, savedJob.Access_Request__c);
            System.Assert.areEqual(application.Id, savedJob.Application__c);
            System.Assert.areEqual('ApplicationAttachment', savedJob.Archive_Event_Type__c);
            System.Assert.areEqual(0, savedJob.Attempt_Count__c);
            System.Assert.areEqual('correlation-application-attachment', savedJob.Correlation_Id__c);
            System.Assert.areEqual(
                P360_IdempotencyKey.forApplicationAttachment(application.Id, contentVersion.Id),
                savedJob.Idempotency_Key__c
            );
            System.Assert.isNotNull(savedJob.Queued_Date__c, 'A new archive job must record when it was queued.');
            System.Assert.areEqual('Pending', savedJob.Status__c);
            System.Assert.areEqual(
                1,
                [SELECT COUNT() FROM P360_Archive_Job__c WHERE Idempotency_Key__c = :savedJob.Idempotency_Key__c]
            );
        }
    }

    /**
     * Verifies that repeated decision document requests reuse the same pending archive job.
     *
     * @since 2026-09
     */
    @IsTest
    static void shouldReuseDecisionDocumentJobForSameArchiveEvent() {
        User processingUser = createProcessingUser();

        System.runAs(processingUser) {
            Access_Request__c accessRequest = new Access_Request__c();
            insert accessRequest;
            Application_Decision__c decision = new Application_Decision__c();
            insert decision;

            System.Test.startTest();
            P360_Archive_Job__c firstJob = P360_ArchiveJobService.getOrCreateDecisionDocumentJob(
                accessRequest.Id,
                decision.Id,
                'correlation-decision-document'
            );
            P360_Archive_Job__c repeatedJob = P360_ArchiveJobService.getOrCreateDecisionDocumentJob(
                accessRequest.Id,
                decision.Id,
                'different-correlation-id'
            );
            System.Test.stopTest();

            System.Assert.areEqual(firstJob.Id, repeatedJob.Id);
            System.Assert.areEqual('DECISION_DOCUMENT:' + decision.Id, firstJob.Idempotency_Key__c);
            System.Assert.areEqual('DecisionDocument', firstJob.Archive_Event_Type__c);
            System.Assert.areEqual('Pending', firstJob.Status__c);
        }
    }

    /**
     * Verifies that repeated agreement document requests reuse the same pending archive job.
     *
     * @since 2026-09
     */
    @IsTest
    static void shouldReuseAgreementDocumentJobForSameArchiveEvent() {
        User processingUser = createProcessingUser();

        System.runAs(processingUser) {
            Access_Request__c accessRequest = new Access_Request__c();
            insert accessRequest;
            Agreement__c agreement = new Agreement__c();
            insert agreement;

            System.Test.startTest();
            P360_Archive_Job__c firstJob = P360_ArchiveJobService.getOrCreateAgreementDocumentJob(
                accessRequest.Id,
                agreement.Id,
                'correlation-agreement-document'
            );
            P360_Archive_Job__c repeatedJob = P360_ArchiveJobService.getOrCreateAgreementDocumentJob(
                accessRequest.Id,
                agreement.Id,
                'different-correlation-id'
            );
            System.Test.stopTest();

            System.Assert.areEqual(firstJob.Id, repeatedJob.Id);
            System.Assert.areEqual('AGREEMENT_DOCUMENT:' + agreement.Id, firstJob.Idempotency_Key__c);
            System.Assert.areEqual('AgreementDocument', firstJob.Archive_Event_Type__c);
            System.Assert.areEqual('Pending', firstJob.Status__c);
        }
    }

    /**
     * Verifies that required context is rejected before the service accesses archive-job data.
     *
     * @since 2026-09
     */
    @IsTest
    static void shouldRejectMissingApplicationDocumentContext() {
        User minimumAccessUser = P360_TestDataFactory.createMinimumAccessUser();

        System.runAs(minimumAccessUser) {
            try {
                P360_ArchiveJobService.getOrCreateApplicationDocumentJob(null, null, null);
                System.Assert.fail('Missing archive job context must be rejected.');
            } catch (P360_ContractException error) {
                System.Assert.isTrue(error.getMessage().contains('Access request id'));
            }
        }
    }

    private static User createProcessingUser() {
        User userRecord;
        User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        System.runAs(currentUser) {
            userRecord = P360_TestDataFactory.createMinimumAccessUser();
            AAREG_TestDataFactory.assignPermissionSet(userRecord.Id, 'AAREG_Arbeidsforhold_Saksbehandling');
            AAREG_TestDataFactory.assignPermissionSet(userRecord.Id, 'P360_Archive_Job_Processing');
        }
        return userRecord;
    }
}
