/**
 * Verifies that eligible P360 archive jobs are claimed with a lease before processing.
 *
 * @author Kenneth Sørensen
 * @since 2026-09 R2
 * @group P360 Archive Job
 */
@IsTest
private class P360_ArchiveJobClaimServiceTest {
    /**
     * Verifies that a Pending job is claimed into In Progress with a lease and an incremented attempt count.
     *
     * @since 2026-09
     */
    @IsTest
    static void claimsPendingJobIntoInProgressWithLease() {
        User processingUser = createProcessingUser();

        System.runAs(processingUser) {
            Id accessRequestId = insertAccessRequest();
            Id applicationId = insertApplication(accessRequestId);
            P360_Archive_Job__c job = P360_ArchiveJobService.getOrCreateApplicationDocumentJob(
                accessRequestId,
                applicationId,
                'correlation-claim-1'
            );

            Test.startTest();
            List<Id> claimedIds = P360_ArchiveJobClaimService.claimNextBatch(10);
            Test.stopTest();

            System.Assert.areEqual(1, claimedIds.size(), 'Expected exactly one job to be claimed.');

            P360_Archive_Job__c claimed = [
                SELECT Status__c, Attempt_Count__c, Started_Date__c, Lease_Expires_Date__c
                FROM P360_Archive_Job__c
                WHERE Id = :job.Id
            ];
            System.Assert.areEqual('In Progress', claimed.Status__c, 'Expected the job to move to In Progress.');
            System.Assert.areEqual(1, claimed.Attempt_Count__c.intValue(), 'Expected the attempt count to increment.');
            System.Assert.isNotNull(claimed.Started_Date__c, 'Expected a started timestamp.');
            System.Assert.isNotNull(claimed.Lease_Expires_Date__c, 'Expected a lease expiry.');
        }
    }

    /**
     * Verifies that a Failed job whose next attempt is not yet due is not claimed.
     *
     * @since 2026-09
     */
    @IsTest
    static void doesNotClaimFailedJobBeforeNextAttemptIsDue() {
        User processingUser = createProcessingUser();

        System.runAs(processingUser) {
            Id accessRequestId = insertAccessRequest();
            Id applicationId = insertApplication(accessRequestId);
            P360_Archive_Job__c job = P360_ArchiveJobService.getOrCreateApplicationDocumentJob(
                accessRequestId,
                applicationId,
                'correlation-claim-2'
            );
            update new P360_Archive_Job__c(
                Id = job.Id,
                Status__c = 'Failed',
                Next_Attempt_Date__c = System.now().addMinutes(30)
            );

            Test.startTest();
            List<Id> claimedIds = P360_ArchiveJobClaimService.claimNextBatch(10);
            Test.stopTest();

            System.Assert.isTrue(claimedIds.isEmpty(), 'Expected no job to be claimed before it is due.');
        }
    }

    /**
     * Verifies that a Failed job whose next attempt is due gets reclaimed into In Progress.
     *
     * @since 2026-09
     */
    @IsTest
    static void claimsFailedJobOnceNextAttemptIsDue() {
        User processingUser = createProcessingUser();

        System.runAs(processingUser) {
            Id accessRequestId = insertAccessRequest();
            Id applicationId = insertApplication(accessRequestId);
            P360_Archive_Job__c job = P360_ArchiveJobService.getOrCreateApplicationDocumentJob(
                accessRequestId,
                applicationId,
                'correlation-claim-3'
            );
            update new P360_Archive_Job__c(
                Id = job.Id,
                Status__c = 'Failed',
                Attempt_Count__c = 1,
                Next_Attempt_Date__c = System.now().addMinutes(-1)
            );

            Test.startTest();
            List<Id> claimedIds = P360_ArchiveJobClaimService.claimNextBatch(10);
            Test.stopTest();

            System.Assert.areEqual(1, claimedIds.size(), 'Expected the due job to be reclaimed.');

            P360_Archive_Job__c reclaimed = [
                SELECT Status__c, Attempt_Count__c
                FROM P360_Archive_Job__c
                WHERE Id = :job.Id
            ];
            System.Assert.areEqual('In Progress', reclaimed.Status__c, 'Expected the job to move to In Progress.');
            System.Assert.areEqual(
                2,
                reclaimed.Attempt_Count__c.intValue(),
                'Expected the attempt count to increment.'
            );
        }
    }

    /**
     * Verifies that jobs already Succeeded or in Manual Review are never claimed.
     *
     * @since 2026-09
     */
    @IsTest
    static void doesNotClaimSucceededOrManualReviewJobs() {
        User processingUser = createProcessingUser();

        System.runAs(processingUser) {
            Id accessRequestId = insertAccessRequest();
            Id applicationId = insertApplication(accessRequestId);
            P360_Archive_Job__c succeededJob = P360_ArchiveJobService.getOrCreateApplicationDocumentJob(
                accessRequestId,
                applicationId,
                'correlation-claim-4'
            );
            update new P360_Archive_Job__c(Id = succeededJob.Id, Status__c = 'Succeeded');

            Test.startTest();
            List<Id> claimedIds = P360_ArchiveJobClaimService.claimNextBatch(10);
            Test.stopTest();

            System.Assert.isTrue(claimedIds.isEmpty(), 'Expected no completed job to be claimed.');
        }
    }

    private static Id insertAccessRequest() {
        Access_Request__c accessRequest = new Access_Request__c();
        insert accessRequest;
        return accessRequest.Id;
    }

    private static Id insertApplication(Id accessRequestId) {
        Application__c application = new Application__c(Access_Request__c = accessRequestId);
        insert application;
        return application.Id;
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
