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

    private static final String APPLICATION_DOCUMENT_EVENT = 'ApplicationDocument';

    private final Set<Id> jobIds;
    private final Map<Id, String> createdCaseNumbers = new Map<Id, String>();
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
     * Records the adapter attempt start time with the persisted outcome, without DML before callouts.
     * Disabled processing restores claims without changing the last actual attempt timestamp.
     * Application document jobs are built from the submitted application; other event types are sent with
     * only their identity and are rejected by the adapter until their document content is implemented.
     * A P360 case created for an access request is saved on that access request after all callouts, also when the
     * document step then fails, so the next submission or retry reuses the case instead of creating a duplicate.
     *
     * @param context Queueable context supplied by the platform.
     * @since 2026-10
     */
    public void execute(QueueableContext context) {
        if (!P360_ArchiveProcessingGate.isEnabled()) {
            restoreClaimedJobs();
            return;
        }

        List<P360_Archive_Job__c> jobs = [
            SELECT
                Id,
                Idempotency_Key__c,
                Attempt_Count__c,
                Correlation_Id__c,
                Archive_Event_Type__c,
                Application__c,
                Access_Request__c
            FROM P360_Archive_Job__c
            WHERE Id IN :jobIds
        ];

        List<P360_Archive_Job__c> toUpdate = new List<P360_Archive_Job__c>();
        for (P360_Archive_Job__c job : jobs) {
            DateTime attemptedAt = System.now();
            P360_Archive_Job__c outcome = processJob(job);
            outcome.Last_Attempt_Date__c = attemptedAt;
            toUpdate.add(outcome);
        }
        update toUpdate;
        new CreatedCaseWriter().save(createdCaseNumbers);
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
        P360_ArchiveRequestDto request;
        try {
            if (adapter == null) {
                adapter = new P360_AdapterFactory().createArchiveAdapter();
            }
            request = buildRequest(job);
            P360_ArchiveResponseDto response = adapter.archive(request);
            if (response == null || response.success != true) {
                throw new P360_ContractException('P360 adapter did not confirm a successful archive.');
            }
            return new P360_Archive_Job__c(Id = job.Id, Status__c = 'Succeeded');
        } catch (P360_IntegrationException error) {
            P360_Archive_Job__c failure = classifyFailure(job, error);
            String logStatus = failure.Status__c == 'Failed' ? 'RetryScheduled' : 'ManualReview';
            logFailureSafely(job, logStatus);
            return failure;
        } finally {
            rememberCreatedCase(job, request);
        }
    }

    // The adapter sets CreateDocument's case number from the CreateCase result.
    private void rememberCreatedCase(P360_Archive_Job__c job, P360_ArchiveRequestDto request) {
        if (
            job.Access_Request__c != null &&
            request?.createCase != null &&
            String.isNotBlank(request.createDocument?.caseNumber)
        ) {
            createdCaseNumbers.put(job.Access_Request__c, request.createDocument.caseNumber);
        }
    }

    private static P360_ArchiveRequestDto buildRequest(P360_Archive_Job__c job) {
        if (job.Archive_Event_Type__c == APPLICATION_DOCUMENT_EVENT) {
            return new AAREG_ApplicationArchiveRequestBuilder().build(job);
        }
        P360_ArchiveRequestDto request = new P360_ArchiveRequestDto();
        request.correlationId = job.Correlation_Id__c;
        request.externalId = job.Idempotency_Key__c;
        return request;
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

    /**
     * Saves P360 case numbers on access requests that have none. Runs in system mode because the processing
     * user has no access to access requests; it writes only the case number of access requests in the batch.
     */
    private without sharing class CreatedCaseWriter {
        void save(Map<Id, String> caseNumberByAccessRequest) {
            if (caseNumberByAccessRequest.isEmpty()) {
                return;
            }
            List<Access_Request__c> updates = new List<Access_Request__c>();
            for (Access_Request__c accessRequest : [
                SELECT Id
                FROM Access_Request__c
                WHERE Id IN :caseNumberByAccessRequest.keySet() AND P360_Case_Number__c = NULL
                WITH SYSTEM_MODE
            ]) {
                updates.add(
                    new Access_Request__c(
                        Id = accessRequest.Id,
                        P360_Case_Number__c = caseNumberByAccessRequest.get(accessRequest.Id)
                    )
                );
            }
            update as system updates;
        }
    }

    private static String limitErrorMessage(String errorMessage) {
        Integer maximumLength = P360_Archive_Job__c.Last_Error_Message__c.getDescribe().getLength();
        return errorMessage != null &&
            errorMessage.length() > maximumLength
            ? errorMessage.substring(0, maximumLength)
            : errorMessage;
    }
}
