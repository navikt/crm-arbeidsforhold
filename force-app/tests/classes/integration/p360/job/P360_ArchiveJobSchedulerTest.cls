/**
 * Verifies scheduled claiming and dispatch of P360 archive jobs.
 *
 * @author Kenneth Sørensen
 * @since 2026-09
 * @group P360 Archive Job
 */
@IsTest
private class P360_ArchiveJobSchedulerTest {
    /**
     * A scheduled run should claim a pending job before dispatching the worker.
     *
     * @since 2026-09
     */
    @IsTest
    static void shouldClaimPendingJobsAndDispatchWorker() {
        User processingUser = createProcessingUser();

        System.runAs(processingUser) {
            Access_Request__c accessRequest = new Access_Request__c();
            insert accessRequest;
            Application__c application = new Application__c();
            insert application;
            P360_Archive_Job__c job = P360_ArchiveJobService.getOrCreateApplicationDocumentJob(
                accessRequest.Id,
                application.Id,
                'correlation-scheduled-archive'
            );

            System.Test.startTest();
            new P360_ArchiveJobScheduler().execute(null);
            P360_Archive_Job__c claimedJob = [
                SELECT Status__c, Attempt_Count__c, Lease_Expires_Date__c
                FROM P360_Archive_Job__c
                WHERE Id = :job.Id
                LIMIT 1
            ];
            System.Test.stopTest();

            System.Assert.areEqual('In Progress', claimedJob.Status__c);
            System.Assert.areEqual(1, claimedJob.Attempt_Count__c);
            System.Assert.isNotNull(claimedJob.Lease_Expires_Date__c);
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
