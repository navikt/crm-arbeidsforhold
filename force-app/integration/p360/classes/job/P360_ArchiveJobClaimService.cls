/**
 * Claims eligible P360 archive jobs into In Progress with a lease, ready for a worker to process.
 *
 * @author Kenneth Sørensen
 * @since 2026-09 R2
 * @group P360 Archive Job
 */
public with sharing class P360_ArchiveJobClaimService {
    @TestVisible
    private static final Integer LEASE_MINUTES = 10;

    /**
     * Claims up to `batchSize` eligible jobs (new Pending jobs, or Failed jobs whose next attempt is due)
     * into In Progress with a fresh lease, and increments their attempt count.
     *
     * @param batchSize Maximum number of jobs to claim in this call.
     * @return Ids of the jobs that were claimed, in claim order.
     */
    public static List<Id> claimNextBatch(Integer batchSize) {
        DateTime now = System.now();

        List<P360_Archive_Job__c> claimable = [
            SELECT Id, Attempt_Count__c
            FROM P360_Archive_Job__c
            WHERE Status__c = 'Pending' OR (Status__c = 'Failed' AND Next_Attempt_Date__c <= :now)
            ORDER BY Queued_Date__c ASC
            LIMIT :batchSize
        ];

        if (claimable.isEmpty()) {
            return new List<Id>();
        }

        List<P360_Archive_Job__c> toUpdate = new List<P360_Archive_Job__c>();
        for (P360_Archive_Job__c job : claimable) {
            Decimal currentAttempts = job.Attempt_Count__c == null ? 0 : job.Attempt_Count__c;
            toUpdate.add(
                new P360_Archive_Job__c(
                    Id = job.Id,
                    Status__c = 'In Progress',
                    Started_Date__c = now,
                    Lease_Expires_Date__c = now.addMinutes(LEASE_MINUTES),
                    Attempt_Count__c = currentAttempts + 1
                )
            );
        }
        update toUpdate;

        List<Id> claimedIds = new List<Id>();
        for (P360_Archive_Job__c job : toUpdate) {
            claimedIds.add(job.Id);
        }
        return claimedIds;
    }
}
