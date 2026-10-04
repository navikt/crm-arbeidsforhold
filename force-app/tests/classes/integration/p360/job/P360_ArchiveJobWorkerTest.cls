/**
 * Verifies that the archive job worker classifies P360 adapter outcomes into the correct job status.
 *
 * @author Kenneth Sørensen
 * @since 2026-09 R2
 * @group P360 Archive Job
 */
@IsTest
private class P360_ArchiveJobWorkerTest {
    /**
     * Verifies that a non-retryable adapter failure (the current controlled "not implemented" contract
     * error) moves the job straight to Manual Review, without waiting for retries.
     *
     * @since 2026-09
     */
    @IsTest
    static void nonRetryableFailureMovesJobToManualReview() {
        P360_TestDataFactory.setArchiveProcessingEnabled(true);
        User processingUser = createProcessingUser();

        System.runAs(processingUser) {
            Id jobId = claimedJobId('correlation-worker-1');

            System.Test.startTest();
            new P360_ArchiveJobWorker(new Set<Id>{ jobId }).execute(null);
            System.Test.stopTest();

            P360_Archive_Job__c job = [
                SELECT Status__c, Last_Error_Code__c, Last_Error_Message__c, Next_Attempt_Date__c
                FROM P360_Archive_Job__c
                WHERE Id = :jobId
            ];
            System.Assert.areEqual(
                'Manual Review',
                job.Status__c,
                'Expected a non-retryable error to require manual review.'
            );
            System.Assert.areEqual(
                'P360_ContractException',
                job.Last_Error_Code__c,
                'Expected the exception type name as the error code.'
            );
            System.Assert.isNotNull(job.Last_Error_Message__c, 'Expected the error message to be recorded.');
            System.Assert.isNull(job.Next_Attempt_Date__c, 'Manual review jobs are not automatically retried.');
        }
    }

    /**
     * Verifies that a worker failure persists bounded technical log context without the exception message.
     *
     * @since 2026-10
     */
    @IsTest
    static void failurePersistsOnlyBoundedTechnicalLog() {
        P360_TestDataFactory.setArchiveProcessingEnabled(true);
        User processingUser = createProcessingUser();
        String correlationId = '0123456789abcdef0123456789abcdef';

        System.runAs(processingUser) {
            Id jobId = claimedJobId(correlationId);

            System.Test.startTest();
            new P360_ArchiveJobWorker(new Set<Id>{ jobId }).execute(null);
            System.Test.stopTest();
        }

        Application_Log__c savedLog = [
            SELECT Category__c, Log_Message__c, Pay_Load__c
            FROM Application_Log__c
            WHERE Category__c = 'P360'
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        Map<String, Object> payload = (Map<String, Object>) JSON.deserializeUntyped(savedLog.Pay_Load__c);

        System.Assert.areEqual('P360', payload.get('systemName'));
        System.Assert.areEqual('ApplicationDocument', payload.get('operationName'));
        System.Assert.areEqual('ManualReview', payload.get('status'));
        System.Assert.areEqual(correlationId, payload.get('correlationId'));
        System.Assert.areEqual(4, payload.size());
        System.Assert.isFalse(savedLog.Log_Message__c.contains('not implemented yet'));
        System.Assert.isFalse(savedLog.Pay_Load__c.contains('not implemented yet'));
    }

    /**
     * Verifies that a retryable failure log identifies the archive type and scheduled retry outcome.
     *
     * @since 2026-10
     */
    @IsTest
    static void retryableFailureLogsArchiveTypeAndRetryStatus() {
        P360_TestDataFactory.setArchiveProcessingEnabled(true);
        User processingUser = createProcessingUser();
        String correlationId = 'abcdef0123456789abcdef0123456789';

        System.runAs(processingUser) {
            Access_Request__c accessRequest = new Access_Request__c();
            insert accessRequest;
            Application__c application = new Application__c(Access_Request__c = accessRequest.Id);
            insert application;
            ContentVersion attachment = new ContentVersion(
                Title = 'attachment',
                PathOnClient = 'attachment.pdf',
                VersionData = Blob.valueOf('attachment content')
            );
            insert attachment;

            P360_ArchiveJobService.getOrCreateApplicationAttachmentJob(
                accessRequest.Id,
                application.Id,
                attachment.Id,
                correlationId
            );
            Id jobId = P360_ArchiveJobClaimService.claimNextBatch(1)[0];
            P360_ArchiveJobWorker worker = new P360_ArchiveJobWorker(new Set<Id>{ jobId });
            worker.adapter = new P360_TestRetryableArchiveAdapter();

            System.Test.startTest();
            worker.execute(null);
            System.Test.stopTest();
        }

        Application_Log__c savedLog = [
            SELECT Pay_Load__c
            FROM Application_Log__c
            WHERE Category__c = 'P360'
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        Map<String, Object> payload = (Map<String, Object>) JSON.deserializeUntyped(savedLog.Pay_Load__c);

        System.Assert.areEqual('ApplicationAttachment', payload.get('operationName'));
        System.Assert.areEqual('RetryScheduled', payload.get('status'));
        System.Assert.areEqual(correlationId, payload.get('correlationId'));
        System.Assert.areEqual(4, payload.size());
    }

    /**
     * Verifies that a retryable adapter failure schedules the next attempt using the documented backoff.
     *
     * @since 2026-09
     */
    @IsTest
    static void retryableFailureSchedulesNextAttemptWithBackoff() {
        P360_TestDataFactory.setArchiveProcessingEnabled(true);
        User processingUser = createProcessingUser();

        System.runAs(processingUser) {
            Id jobId = claimedJobId('correlation-worker-2');

            P360_ArchiveJobWorker worker = new P360_ArchiveJobWorker(new Set<Id>{ jobId });
            worker.adapter = new P360_TestRetryableArchiveAdapter();

            System.Test.startTest();
            worker.execute(null);
            System.Test.stopTest();

            P360_Archive_Job__c job = [
                SELECT Status__c, Next_Attempt_Date__c, Last_Error_Code__c
                FROM P360_Archive_Job__c
                WHERE Id = :jobId
            ];
            System.Assert.areEqual('Failed', job.Status__c, 'Expected a retryable error to leave the job Failed.');
            System.Assert.isNotNull(job.Next_Attempt_Date__c, 'Expected the next attempt to be scheduled.');
            System.Assert.isTrue(
                job.Next_Attempt_Date__c > System.now(),
                'Expected the next attempt to be scheduled in the future.'
            );
        }
    }

    /**
     * Verifies that an oversized exception message is bounded to the archive job field length.
     *
     * @since 2026-10
     */
    @IsTest
    static void retryableFailureMessageIsBoundedToFieldLength() {
        P360_TestDataFactory.setArchiveProcessingEnabled(true);
        User processingUser = createProcessingUser();
        Integer maximumLength = P360_Archive_Job__c.Last_Error_Message__c.getDescribe().getLength();
        String failureMessage = 'x';
        while (failureMessage.length() <= maximumLength) {
            failureMessage += failureMessage;
        }
        failureMessage = failureMessage.substring(0, maximumLength + 1);

        System.runAs(processingUser) {
            Id jobId = claimedJobId('correlation-worker-long-error');
            P360_ArchiveJobWorker worker = new P360_ArchiveJobWorker(new Set<Id>{ jobId });
            worker.adapter = new P360_TestRetryableArchiveAdapter(failureMessage);

            System.Test.startTest();
            worker.execute(null);
            System.Test.stopTest();

            P360_Archive_Job__c job = [
                SELECT Status__c, Last_Error_Message__c
                FROM P360_Archive_Job__c
                WHERE Id = :jobId
                LIMIT 1
            ];
            System.Assert.areEqual('Failed', job.Status__c);
            System.Assert.areEqual(maximumLength, job.Last_Error_Message__c.length());
            System.Assert.areEqual(failureMessage.substring(0, maximumLength), job.Last_Error_Message__c);
        }
    }

    /**
     * Verifies that a retryable failure at the final attempt moves the job to Manual Review instead of retrying.
     *
     * @since 2026-09
     */
    @IsTest
    static void retryableFailureAtMaxAttemptsMovesToManualReview() {
        P360_TestDataFactory.setArchiveProcessingEnabled(true);
        User processingUser = createProcessingUser();

        System.runAs(processingUser) {
            Id jobId = claimedJobId('correlation-worker-3');
            update new P360_Archive_Job__c(Id = jobId, Attempt_Count__c = P360_ArchiveJobWorker.MAX_ATTEMPTS);

            P360_ArchiveJobWorker worker = new P360_ArchiveJobWorker(new Set<Id>{ jobId });
            worker.adapter = new P360_TestRetryableArchiveAdapter();

            System.Test.startTest();
            worker.execute(null);
            System.Test.stopTest();

            P360_Archive_Job__c job = [SELECT Status__c FROM P360_Archive_Job__c WHERE Id = :jobId];
            System.Assert.areEqual(
                'Manual Review',
                job.Status__c,
                'Expected the job to require manual review once attempts are exhausted.'
            );
        }
    }

    /**
     * Verifies that a successful adapter call marks the job Succeeded.
     *
     * @since 2026-09
     */
    @IsTest
    static void successfulArchiveMarksJobSucceeded() {
        P360_TestDataFactory.setArchiveProcessingEnabled(true);
        User processingUser = createProcessingUser();

        System.runAs(processingUser) {
            Id jobId = claimedJobId('correlation-worker-4');

            P360_ArchiveJobWorker worker = new P360_ArchiveJobWorker(new Set<Id>{ jobId });
            worker.adapter = new P360_StubArchiveAdapter();

            System.Test.startTest();
            worker.execute(null);
            System.Test.stopTest();

            P360_Archive_Job__c job = [SELECT Status__c FROM P360_Archive_Job__c WHERE Id = :jobId];
            System.Assert.areEqual(
                'Succeeded',
                job.Status__c,
                'Expected a successful archive to mark the job Succeeded.'
            );
        }
    }

    /**
     * Verifies that disabling processing before a worker runs restores its claim without consuming an attempt.
     *
     * @since 2026-10
     */
    @IsTest
    static void shouldRestoreClaimedJobWhenArchiveProcessingIsDisabled() {
        P360_TestDataFactory.setArchiveProcessingEnabled(true);
        User processingUser = createProcessingUser();
        Id jobId;

        System.runAs(processingUser) {
            jobId = claimedJobId('correlation-worker-disabled');
        }

        P360_TestDataFactory.setArchiveProcessingEnabled(false);
        System.runAs(processingUser) {
            P360_ArchiveJobWorker worker = new P360_ArchiveJobWorker(new Set<Id>{ jobId });
            worker.adapter = new P360_StubArchiveAdapter();

            System.Test.startTest();
            worker.execute(null);
            System.Test.stopTest();

            P360_Archive_Job__c job = [
                SELECT Status__c, Attempt_Count__c, Started_Date__c, Lease_Expires_Date__c
                FROM P360_Archive_Job__c
                WHERE Id = :jobId
                LIMIT 1
            ];
            System.Assert.areEqual('Pending', job.Status__c);
            System.Assert.areEqual(0, job.Attempt_Count__c);
            System.Assert.isNull(job.Started_Date__c);
            System.Assert.isNull(job.Lease_Expires_Date__c);
        }
    }

    private static Id claimedJobId(String correlationId) {
        Access_Request__c accessRequest = new Access_Request__c();
        insert accessRequest;
        Application__c application = new Application__c(Access_Request__c = accessRequest.Id);
        insert application;

        P360_Archive_Job__c job = P360_ArchiveJobService.getOrCreateApplicationDocumentJob(
            accessRequest.Id,
            application.Id,
            correlationId
        );
        List<Id> claimedIds = P360_ArchiveJobClaimService.claimNextBatch(1);
        return claimedIds[0];
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
