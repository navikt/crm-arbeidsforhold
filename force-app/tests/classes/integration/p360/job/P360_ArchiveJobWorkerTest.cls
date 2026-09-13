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
        User processingUser = createProcessingUser();

        System.runAs(processingUser) {
            Id jobId = claimedJobId('correlation-worker-1');

            Test.startTest();
            new P360_ArchiveJobWorker(new Set<Id>{ jobId }).execute(null);
            Test.stopTest();

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
     * Verifies that a retryable adapter failure schedules the next attempt using the documented backoff.
     *
     * @since 2026-09
     */
    @IsTest
    static void retryableFailureSchedulesNextAttemptWithBackoff() {
        User processingUser = createProcessingUser();

        System.runAs(processingUser) {
            Id jobId = claimedJobId('correlation-worker-2');

            P360_ArchiveJobWorker worker = new P360_ArchiveJobWorker(new Set<Id>{ jobId });
            worker.adapter = new P360_TestRetryableArchiveAdapter();

            Test.startTest();
            worker.execute(null);
            Test.stopTest();

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
     * Verifies that a retryable failure at the final attempt moves the job to Manual Review instead of retrying.
     *
     * @since 2026-09
     */
    @IsTest
    static void retryableFailureAtMaxAttemptsMovesToManualReview() {
        User processingUser = createProcessingUser();

        System.runAs(processingUser) {
            Id jobId = claimedJobId('correlation-worker-3');
            update new P360_Archive_Job__c(Id = jobId, Attempt_Count__c = P360_ArchiveJobWorker.MAX_ATTEMPTS);

            P360_ArchiveJobWorker worker = new P360_ArchiveJobWorker(new Set<Id>{ jobId });
            worker.adapter = new P360_TestRetryableArchiveAdapter();

            Test.startTest();
            worker.execute(null);
            Test.stopTest();

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
        User processingUser = createProcessingUser();

        System.runAs(processingUser) {
            Id jobId = claimedJobId('correlation-worker-4');

            P360_ArchiveJobWorker worker = new P360_ArchiveJobWorker(new Set<Id>{ jobId });
            worker.adapter = new P360_StubArchiveAdapter();

            Test.startTest();
            worker.execute(null);
            Test.stopTest();

            P360_Archive_Job__c job = [SELECT Status__c FROM P360_Archive_Job__c WHERE Id = :jobId];
            System.Assert.areEqual(
                'Succeeded',
                job.Status__c,
                'Expected a successful archive to mark the job Succeeded.'
            );
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
