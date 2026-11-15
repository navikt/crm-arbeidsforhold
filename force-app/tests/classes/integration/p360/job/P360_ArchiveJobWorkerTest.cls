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
     * Verifies that the processing user can persist the timestamp required by the worker.
     *
     * @since 2026-11
     */
    @IsTest
    static void shouldAllowProcessingUserToRecordLastAttemptDate() {
        User processingUser = createProcessingUser();

        System.runAs(processingUser) {
            Schema.DescribeFieldResult lastAttempt = P360_Archive_Job__c.Last_Attempt_Date__c.getDescribe();
            System.Assert.isTrue(
                lastAttempt.isAccessible(),
                'The processing user must be able to read Last Attempt Date.'
            );
            System.Assert.isTrue(
                lastAttempt.isUpdateable(),
                'The processing user must be able to update Last Attempt Date.'
            );
        }
    }

    /**
     * Verifies that a non-retryable failure (the default HTTP transport is not implemented yet)
     * moves the job straight to Manual Review, without waiting for retries.
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
            DateTime beforeAttempt = DateTime.newInstance((System.now().getTime() / 1000) * 1000);
            new P360_ArchiveJobWorker(new Set<Id>{ jobId }).execute(null);
            DateTime afterAttempt = System.now();
            System.Test.stopTest();

            P360_Archive_Job__c job = [
                SELECT Status__c, Last_Error_Code__c, Last_Error_Message__c, Next_Attempt_Date__c, Last_Attempt_Date__c
                FROM P360_Archive_Job__c
                WHERE Id = :jobId
            ];
            System.Assert.areEqual(
                'Manual Review',
                job.Status__c,
                'Expected a non-retryable error to require manual review.'
            );
            System.Assert.areEqual(
                'P360_TransportException',
                job.Last_Error_Code__c,
                'Expected the exception type name as the error code.'
            );
            System.Assert.isNotNull(job.Last_Error_Message__c, 'Expected the error message to be recorded.');
            System.Assert.isNull(job.Next_Attempt_Date__c, 'Manual review jobs are not automatically retried.');
            System.Assert.isNotNull(job.Last_Attempt_Date__c, 'Expected the failed attempt timestamp to be recorded.');
            System.Assert.isTrue(job.Last_Attempt_Date__c >= beforeAttempt && job.Last_Attempt_Date__c <= afterAttempt);
        }
    }

    /**
     * Verifies the runnable submission path: submitting an application queues one archive job, and the worker
     * sends the generated application summary and the submitted attachment through the configured RPC client.
     *
     * @since 2026-11
     */
    @IsTest
    static void submittedApplicationIsArchivedThroughConfiguredRpcClient() {
        P360_TestDataFactory.setArchiveProcessingEnabled(true);
        insert new P360_Integration_Setting__c(
            SetupOwnerId = UserInfo.getOrganizationId(),
            Rpc_Client_Class__c = 'P360_CapturingRpcClient',
            External_System__c = 'Scratch P360'
        );
        Account account = AAREG_TestDataFactory.getAccountCounty();
        insert account;
        String attachmentBase64 = EncodingUtil.base64Encode(Blob.valueOf('synthetic attachment'));

        User processingUser = createProcessingUser();

        System.Test.startTest();
        Id applicationId = AAREG_ApplicationController.processApplication(
            new Application__c(Account__c = account.Id, IsConfirmationEmailSent__c = true),
            new List<ApplicationBasisCode__c>(),
            new List<RelatedContact__c>(),
            attachmentBase64,
            'vedlegg.pdf'
        );
        List<Id> claimedIds;
        System.runAs(processingUser) {
            claimedIds = P360_ArchiveJobClaimService.claimNextBatch(10);
            new P360_ArchiveJobWorker(new Set<Id>(claimedIds)).execute(null);
        }
        System.Test.stopTest();

        P360_Archive_Job__c job = [
            SELECT Status__c, Last_Error_Message__c, Access_Request__c
            FROM P360_Archive_Job__c
            WHERE Application__c = :applicationId AND Archive_Event_Type__c = 'ApplicationDocument'
        ];
        System.Assert.areEqual(1, claimedIds.size(), 'Submission must queue exactly one archive job.');
        System.Assert.areEqual('Succeeded', job.Status__c, 'Archive job failed: ' + job.Last_Error_Message__c);
        System.Assert.areEqual(2, P360_CapturingRpcClient.requests.size(), 'Expected CreateCase then CreateDocument.');

        Map<String, Object> caseParameter = P360_CapturingRpcClient.parameter(0);
        System.Assert.areEqual(
            new Map<String, Object>{ 'Id' => 'ACCESS_REQUEST:' + job.Access_Request__c, 'Type' => 'Scratch P360' },
            caseParameter.get('ExternalId')
        );
        Map<String, Object> documentParameter = P360_CapturingRpcClient.parameter(1);
        System.Assert.areEqual(
            new Map<String, Object>{ 'Id' => 'APPLICATION_DOCUMENT:' + applicationId, 'Type' => 'Scratch P360' },
            documentParameter.get('ExternalId')
        );
        System.Assert.areEqual('26/00001', documentParameter.get('CaseNumber'));
        List<Object> files = (List<Object>) documentParameter.get('Files');
        System.Assert.areEqual(2, files.size(), 'Expected the application summary and the attachment.');
        Map<String, Object> summary = (Map<String, Object>) files[0];
        System.Assert.areEqual('txt', summary.get('Format'));
        System.Assert.isTrue(
            EncodingUtil.base64Decode((String) summary.get('Base64Data')).toString().contains(applicationId),
            'The summary must identify the submitted application.'
        );
        Map<String, Object> attachment = (Map<String, Object>) files[1];
        System.Assert.areEqual('vedlegg.pdf', attachment.get('Title'));
        System.Assert.areEqual(attachmentBase64, attachment.get('Base64Data'));
    }

    /**
     * Verifies that an unsuccessful adapter response cannot mark an archive job Succeeded.
     *
     * @since 2026-10
     */
    @IsTest
    static void unsuccessfulAdapterResponseMovesJobToManualReview() {
        P360_TestDataFactory.setArchiveProcessingEnabled(true);
        User processingUser = createProcessingUser();

        System.runAs(processingUser) {
            Id jobId = claimedJobId('correlation-worker-unsuccessful-response');
            P360_ArchiveJobWorker worker = new P360_ArchiveJobWorker(new Set<Id>{ jobId });
            worker.adapter = new UnsuccessfulArchiveAdapter();

            System.Test.startTest();
            worker.execute(null);
            System.Test.stopTest();

            P360_Archive_Job__c job = [
                SELECT Status__c, Last_Error_Code__c, Last_Error_Message__c, Next_Attempt_Date__c
                FROM P360_Archive_Job__c
                WHERE Id = :jobId
                LIMIT 1
            ];
            System.Assert.areEqual('Manual Review', job.Status__c);
            System.Assert.areEqual('P360_ContractException', job.Last_Error_Code__c);
            System.Assert.areEqual('P360 adapter did not confirm a successful archive.', job.Last_Error_Message__c);
            System.Assert.isNull(job.Next_Attempt_Date__c);
            System.Assert.isFalse(job.Last_Error_Message__c.contains('untrusted response detail'));
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
            DateTime beforeAttempt = DateTime.newInstance((System.now().getTime() / 1000) * 1000);
            worker.execute(null);
            DateTime afterAttempt = System.now();
            System.Test.stopTest();

            P360_Archive_Job__c job = [
                SELECT Status__c, Next_Attempt_Date__c, Last_Error_Code__c, Last_Attempt_Date__c
                FROM P360_Archive_Job__c
                WHERE Id = :jobId
            ];
            System.Assert.areEqual('Failed', job.Status__c, 'Expected a retryable error to leave the job Failed.');
            System.Assert.isNotNull(job.Next_Attempt_Date__c, 'Expected the next attempt to be scheduled.');
            System.Assert.isTrue(
                job.Next_Attempt_Date__c > System.now(),
                'Expected the next attempt to be scheduled in the future.'
            );
            System.Assert.isNotNull(
                job.Last_Attempt_Date__c,
                'Expected the retryable attempt timestamp to be recorded.'
            );
            System.Assert.isTrue(job.Last_Attempt_Date__c >= beforeAttempt && job.Last_Attempt_Date__c <= afterAttempt);
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
            DateTime beforeAttempt = DateTime.newInstance((System.now().getTime() / 1000) * 1000);
            worker.execute(null);
            DateTime afterAttempt = System.now();
            System.Test.stopTest();

            P360_Archive_Job__c job = [
                SELECT Status__c, Last_Attempt_Date__c
                FROM P360_Archive_Job__c
                WHERE Id = :jobId
            ];
            System.Assert.areEqual(
                'Succeeded',
                job.Status__c,
                'Expected a successful archive to mark the job Succeeded.'
            );
            System.Assert.isNotNull(
                job.Last_Attempt_Date__c,
                'Expected the successful attempt timestamp to be recorded.'
            );
            System.Assert.isTrue(job.Last_Attempt_Date__c >= beforeAttempt && job.Last_Attempt_Date__c <= afterAttempt);
        }
    }

    /**
     * Verifies that retry processing replaces the previous attempt timestamp, but claiming alone does not.
     *
     * @since 2026-11
     */
    @IsTest
    static void shouldRefreshLastAttemptDateOnlyWhenRetryIsProcessed() {
        P360_TestDataFactory.setArchiveProcessingEnabled(true);
        User processingUser = createProcessingUser();

        System.runAs(processingUser) {
            Id jobId = claimedJobId('correlation-worker-retry-date');
            DateTime previousAttempt = System.now().addDays(-1);
            update new P360_Archive_Job__c(
                Id = jobId,
                Status__c = 'Failed',
                Last_Attempt_Date__c = previousAttempt,
                Next_Attempt_Date__c = System.now().addMinutes(-1)
            );

            System.Test.startTest();
            List<Id> claimedIds = P360_ArchiveJobClaimService.claimNextBatch(1);
            System.Assert.areEqual(new List<Id>{ jobId }, claimedIds);
            P360_Archive_Job__c claimed = [
                SELECT Last_Attempt_Date__c
                FROM P360_Archive_Job__c
                WHERE Id = :jobId
            ];
            System.Assert.areEqual(previousAttempt, claimed.Last_Attempt_Date__c);

            P360_ArchiveJobWorker worker = new P360_ArchiveJobWorker(new Set<Id>{ jobId });
            worker.adapter = new P360_StubArchiveAdapter();
            DateTime beforeAttempt = DateTime.newInstance((System.now().getTime() / 1000) * 1000);
            worker.execute(null);
            DateTime afterAttempt = System.now();
            System.Test.stopTest();

            P360_Archive_Job__c retried = [
                SELECT Status__c, Attempt_Count__c, Last_Attempt_Date__c
                FROM P360_Archive_Job__c
                WHERE Id = :jobId
            ];
            System.Assert.areEqual('Succeeded', retried.Status__c);
            System.Assert.areEqual(2, retried.Attempt_Count__c);
            System.Assert.isNotNull(retried.Last_Attempt_Date__c);
            System.Assert.isTrue(
                retried.Last_Attempt_Date__c >= beforeAttempt && retried.Last_Attempt_Date__c <= afterAttempt,
                'Expected the retry to replace the previous attempt timestamp.'
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
                SELECT Status__c, Attempt_Count__c, Started_Date__c, Lease_Expires_Date__c, Last_Attempt_Date__c
                FROM P360_Archive_Job__c
                WHERE Id = :jobId
                LIMIT 1
            ];
            System.Assert.areEqual('Pending', job.Status__c);
            System.Assert.areEqual(0, job.Attempt_Count__c);
            System.Assert.isNull(job.Started_Date__c);
            System.Assert.isNull(job.Lease_Expires_Date__c);
            System.Assert.isNull(job.Last_Attempt_Date__c, 'A cancelled claim must not record an archive attempt.');
        }
    }

    /**
     * Verifies that a disabled worker preserves a previous attempt timestamp without calling the adapter.
     *
     * @since 2026-11
     */
    @IsTest
    static void shouldPreserveLastAttemptDateWhenRetryIsCancelled() {
        P360_TestDataFactory.setArchiveProcessingEnabled(true);
        User processingUser = createProcessingUser();
        DateTime previousAttempt = System.now().addDays(-1);
        Id jobId;

        System.runAs(processingUser) {
            jobId = claimedJobId('correlation-worker-cancelled-retry');
            update new P360_Archive_Job__c(Id = jobId, Attempt_Count__c = 2, Last_Attempt_Date__c = previousAttempt);
        }

        P360_TestDataFactory.setArchiveProcessingEnabled(false);
        System.runAs(processingUser) {
            P360_ArchiveJobWorker worker = new P360_ArchiveJobWorker(new Set<Id>{ jobId });
            worker.adapter = new P360_StubArchiveAdapter();

            System.Test.startTest();
            worker.execute(null);
            System.Test.stopTest();

            P360_Archive_Job__c restored = [
                SELECT Status__c, Attempt_Count__c, Last_Attempt_Date__c
                FROM P360_Archive_Job__c
                WHERE Id = :jobId
            ];
            System.Assert.areEqual('Pending', restored.Status__c);
            System.Assert.areEqual(1, restored.Attempt_Count__c);
            System.Assert.areEqual(previousAttempt, restored.Last_Attempt_Date__c);
        }
    }

    /**
     * Verifies that application files over the inline limit are rejected from their stored size, before the
     * worker reads and Base64-encodes their content.
     *
     * @since 2026-11
     */
    @IsTest
    static void oversizedApplicationFilesMoveJobToManualReviewBeforeEncoding() {
        P360_TestDataFactory.setArchiveProcessingEnabled(true);
        User processingUser = createProcessingUser();

        System.runAs(processingUser) {
            Access_Request__c accessRequest = new Access_Request__c();
            insert accessRequest;
            Application__c application = new Application__c(Access_Request__c = accessRequest.Id);
            insert application;
            for (Integer i = 0; i < 4; i++) {
                insertAttachment(application.Id, 1500000);
            }
            Id jobId = P360_ArchiveJobService.getOrCreateApplicationDocumentJob(
                    accessRequest.Id,
                    application.Id,
                    'correlation-worker-oversized'
                )
                .Id;
            System.Assert.isTrue(
                new Set<Id>(P360_ArchiveJobClaimService.claimNextBatch(10)).contains(jobId),
                'The application document job must be claimed.'
            );

            System.Test.startTest();
            new P360_ArchiveJobWorker(new Set<Id>{ jobId }).execute(null);
            System.Test.stopTest();

            P360_Archive_Job__c job = [
                SELECT Status__c, Last_Error_Code__c, Last_Error_Message__c
                FROM P360_Archive_Job__c
                WHERE Id = :jobId
            ];
            System.Assert.areEqual('Manual Review', job.Status__c);
            System.Assert.areEqual('P360_ContractException', job.Last_Error_Code__c);
            System.Assert.areEqual('Application files exceed the inline P360 upload limit.', job.Last_Error_Message__c);
        }
    }

    private static void insertAttachment(Id applicationId, Integer sizeInBytes) {
        insert new ContentVersion(
            Title = 'large attachment',
            PathOnClient = 'large.pdf',
            FirstPublishLocationId = applicationId,
            VersionData = Blob.valueOf('a'.repeat(sizeInBytes))
        );
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

    /**
     * Returns a controlled unsuccessful response containing detail the worker must not trust.
     */
    private class UnsuccessfulArchiveAdapter implements P360_IArchiveAdapter {
        public P360_ArchiveResponseDto archive(P360_ArchiveRequestDto request) {
            P360_ArchiveResponseDto response = new P360_ArchiveResponseDto();
            response.success = false;
            response.message = 'untrusted response detail';
            return response;
        }
    }

    private static User createProcessingUser() {
        User userRecord;
        User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        System.runAs(currentUser) {
            userRecord = P360_TestDataFactory.createMinimumAccessUser();
            AAREG_TestDataFactory.assignPermissionSet(userRecord.Id, 'AAREG_Arbeidsforhold_Saksbehandling');
            AAREG_TestDataFactory.assignPermissionSet(userRecord.Id, 'P360_Archive_Job_Processing');
            AAREG_TestDataFactory.assignPermissionSet(userRecord.Id, 'P360_Code_Table_Access');
        }
        return userRecord;
    }
}
