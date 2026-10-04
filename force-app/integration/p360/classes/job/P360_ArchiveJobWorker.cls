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
     * @since 2026-10
     */
    public void execute(QueueableContext context) {
        if (!P360_ArchiveProcessingGate.isEnabled()) {
            restoreClaimedJobs();
            return;
        }

        if (adapter == null) {
            adapter = new P360_AdapterFactory().createArchiveAdapter();
        }

        List<P360_Archive_Job__c> jobs = [
            SELECT Id, Idempotency_Key__c, Attempt_Count__c, Correlation_Id__c, Archive_Event_Type__c
            FROM P360_Archive_Job__c
            WHERE Id IN :jobIds
        ];

        List<P360_Archive_Job__c> toUpdate = new List<P360_Archive_Job__c>();
        for (P360_Archive_Job__c job : jobs) {
            toUpdate.add(processJob(job));
        }
        update toUpdate;
    }

    private void restoreClaimedJobs() {
        List<P360_Archive_Job__c> claimedJobs = [
            SELECT Id, Status__c, Attempt_Count__c
            FROM P360_Archive_Job__c
            WHERE Id IN :jobIds
        ];

        List<P360_Archive_Job__c> jobsToRestore = new List<P360_Archive_Job__c>();
        for (P360_Archive_Job__c job : claimedJobs) {
            if (job.Status__c != 'In Progress') {
                continue;
            }

            Decimal attempts = job.Attempt_Count__c == null ? 0 : job.Attempt_Count__c;
            jobsToRestore.add(
                new P360_Archive_Job__c(
                    Id = job.Id,
                    Status__c = 'Pending',
                    Attempt_Count__c = attempts > 0 ? attempts - 1 : 0,
                    Started_Date__c = null,
                    Lease_Expires_Date__c = null,
                    Next_Attempt_Date__c = null
                )
            );
        }

        if (!jobsToRestore.isEmpty()) {
            update jobsToRestore;
        }
    }

    private P360_Archive_Job__c processJob(P360_Archive_Job__c job) {
        P360_ArchiveRequestDto request = new P360_ArchiveRequestDto();
        request.externalId = job.Idempotency_Key__c;

        try {
            adapter.archive(request);
            return new P360_Archive_Job__c(Id = job.Id, Status__c = 'Succeeded');
        } catch (P360_IntegrationException error) {
            P360_Archive_Job__c failure = classifyFailure(job, error);
            String logStatus = failure.Status__c == 'Failed' ? 'RetryScheduled' : 'ManualReview';
            logFailureSafely(job, logStatus);
            return failure;
        }
    }

    private void logFailureSafely(P360_Archive_Job__c job, String status) {
        try {
            IntegrationLogger.logFailure(
                new IntegrationLogContext('P360', job.Archive_Event_Type__c, status)
                    .withCorrelationId(job.Correlation_Id__c)
            );
        } catch (Exception ignored) {
        }
    }

    private P360_Archive_Job__c classifyFailure(P360_Archive_Job__c job, P360_IntegrationException error) {
        Integer attempts = job.Attempt_Count__c == null ? 1 : job.Attempt_Count__c.intValue();
        String errorCode = error.getTypeName();
        String errorMessage = limitErrorMessage(error.getMessage());

        if (error.isRetryable && attempts < MAX_ATTEMPTS) {
            Integer backoffIndex = Math.min(attempts - 1, BACKOFF_MINUTES_SCHEDULE.size() - 1);
            return new P360_Archive_Job__c(
                Id = job.Id,
                Status__c = 'Failed',
                Last_Error_Code__c = errorCode,
                Last_Error_Message__c = errorMessage,
                Next_Attempt_Date__c = System.now().addMinutes(BACKOFF_MINUTES_SCHEDULE[backoffIndex])
            );
        }

        return new P360_Archive_Job__c(
            Id = job.Id,
            Status__c = 'Manual Review',
            Last_Error_Code__c = errorCode,
            Last_Error_Message__c = errorMessage
        );
    }

    private static String limitErrorMessage(String errorMessage) {
        Integer maximumLength = P360_Archive_Job__c.Last_Error_Message__c.getDescribe().getLength();
        return errorMessage != null &&
            errorMessage.length() > maximumLength
            ? errorMessage.substring(0, maximumLength)
            : errorMessage;
    }
}
