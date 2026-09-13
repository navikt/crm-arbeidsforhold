/**
 * Processes claimed P360 archive jobs: calls the archive adapter and classifies the outcome.
 *
 * @author Kenneth Sørensen
 * @since 2026-09 R2
 * @group P360 Archive Job
 */
public with sharing class P360_ArchiveJobWorker implements Queueable, Database.AllowsCallouts {
    @TestVisible
    private static final Integer MAX_ATTEMPTS = 5;
    @TestVisible
    private static final List<Integer> BACKOFF_MINUTES_SCHEDULE = new List<Integer>{ 1, 5, 15, 60, 360 };

    private final Set<Id> jobIds;
    @TestVisible
    private P360_IArchiveAdapter adapter;

    /**
     * Creates a worker for a batch of already-claimed job ids.
     *
     * @param jobIds Ids of jobs claimed by `P360_ArchiveJobClaimService`.
     */
    public P360_ArchiveJobWorker(Set<Id> jobIds) {
        this.jobIds = jobIds;
    }

    /**
     * Processes each claimed job and updates it to Succeeded, Failed (with a scheduled retry), or Manual Review.
     *
     * @param context Queueable context supplied by the platform.
     */
    public void execute(QueueableContext context) {
        if (adapter == null) {
            adapter = new P360_AdapterFactory().createArchiveAdapter();
        }

        List<P360_Archive_Job__c> jobs = [
            SELECT Id, Idempotency_Key__c, Attempt_Count__c
            FROM P360_Archive_Job__c
            WHERE Id IN :jobIds
        ];

        List<P360_Archive_Job__c> toUpdate = new List<P360_Archive_Job__c>();
        for (P360_Archive_Job__c job : jobs) {
            toUpdate.add(processJob(job));
        }
        update toUpdate;
    }

    private P360_Archive_Job__c processJob(P360_Archive_Job__c job) {
        P360_ArchiveRequestDto request = new P360_ArchiveRequestDto();
        request.externalId = job.Idempotency_Key__c;

        try {
            adapter.archive(request);
            return new P360_Archive_Job__c(Id = job.Id, Status__c = 'Succeeded');
        } catch (P360_IntegrationException error) {
            return classifyFailure(job, error);
        }
    }

    private P360_Archive_Job__c classifyFailure(P360_Archive_Job__c job, P360_IntegrationException error) {
        Integer attempts = job.Attempt_Count__c == null ? 1 : job.Attempt_Count__c.intValue();
        String errorCode = error.getTypeName();

        if (error.isRetryable && attempts < MAX_ATTEMPTS) {
            Integer backoffIndex = Math.min(attempts - 1, BACKOFF_MINUTES_SCHEDULE.size() - 1);
            return new P360_Archive_Job__c(
                Id = job.Id,
                Status__c = 'Failed',
                Last_Error_Code__c = errorCode,
                Last_Error_Message__c = error.getMessage(),
                Next_Attempt_Date__c = System.now().addMinutes(BACKOFF_MINUTES_SCHEDULE[backoffIndex])
            );
        }

        return new P360_Archive_Job__c(
            Id = job.Id,
            Status__c = 'Manual Review',
            Last_Error_Code__c = errorCode,
            Last_Error_Message__c = error.getMessage()
        );
    }
}
