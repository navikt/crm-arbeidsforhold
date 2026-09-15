/**
 * Claims eligible P360 archive jobs and dispatches the queueable worker.
 *
 * @author Kenneth Sørensen
 * @since 2026-09
 * @group P360 Archive Job
 */
public with sharing class P360_ArchiveJobScheduler implements Schedulable {
    @TestVisible
    private static final Integer DEFAULT_BATCH_SIZE = 10;

    /**
     * Claims eligible archive jobs and queues one worker for the claimed batch.
     *
     * @param context Scheduler context supplied by the platform.
     */
    public void execute(SchedulableContext context) {
        List<Id> claimedJobIds = P360_ArchiveJobClaimService.claimNextBatch(DEFAULT_BATCH_SIZE);
        if (!claimedJobIds.isEmpty()) {
            System.enqueueJob(new P360_ArchiveJobWorker(new Set<Id>(claimedJobIds)));
        }
    }
}
