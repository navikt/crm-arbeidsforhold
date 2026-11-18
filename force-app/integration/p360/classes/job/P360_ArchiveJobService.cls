/**
 * Creates and reuses P360 archive jobs at the internal orchestration boundary.
 *
 * @author Kenneth Sørensen
 * @since 2026-09
 * @group P360 Archive Job
 */
public with sharing class P360_ArchiveJobService {
    private static final String APPLICATION_DOCUMENT_EVENT = 'ApplicationDocument';
    private static final String APPLICATION_ATTACHMENT_EVENT = 'ApplicationAttachment';
    private static final String DECISION_DOCUMENT_EVENT = 'DecisionDocument';
    private static final String AGREEMENT_DOCUMENT_EVENT = 'AgreementDocument';
    private static final String PENDING_STATUS = 'Pending';
    private static final Set<String> OPEN_STATUSES = new Set<String>{ 'Pending', 'In Progress', 'Failed' };

    /**
     * Gets or creates the single archive job for an application document event.
     *
     * @param accessRequestId Related Access_Request__c identifier.
     * @param applicationId Source Application__c identifier.
     * @param correlationId Correlation identifier for the first queued attempt.
     * @return Existing or newly created P360 archive job.
     * @throws P360_ContractException When a required identifier is missing.
     */
    public static P360_Archive_Job__c getOrCreateApplicationDocumentJob(
        Id accessRequestId,
        Id applicationId,
        String correlationId
    ) {
        requireId(accessRequestId, 'Access request id');
        requireId(applicationId, 'Application id');
        if (String.isBlank(correlationId)) {
            throw new P360_ContractException('Correlation id is required for an archive job.');
        }

        String idempotencyKey = P360_IdempotencyKey.forApplicationDocument(applicationId);
        P360_Archive_Job__c existingJob = findByIdempotencyKey(idempotencyKey);
        if (existingJob != null) {
            return existingJob;
        }

        P360_Archive_Job__c archiveJob = new P360_Archive_Job__c(
            Access_Request__c = accessRequestId,
            Application__c = applicationId,
            Archive_Event_Type__c = APPLICATION_DOCUMENT_EVENT,
            Attempt_Count__c = 0,
            Correlation_Id__c = correlationId,
            Idempotency_Key__c = idempotencyKey,
            Queued_Date__c = System.now(),
            Status__c = PENDING_STATUS
        );

        try {
            insert archiveJob;
            return archiveJob;
        } catch (DmlException error) {
            if (error.getDmlType(0) == StatusCode.DUPLICATE_VALUE) {
                return findByIdempotencyKey(idempotencyKey);
            }
            throw error;
        }
    }

    /**
     * Gets or creates the single archive job for an application attachment event.
     *
     * @param accessRequestId Related Access_Request__c identifier.
     * @param applicationId Source Application__c identifier.
     * @param contentVersionId Source ContentVersion identifier.
     * @param correlationId Correlation identifier for the first queued attempt.
     * @return Existing or newly created attachment archive job.
     * @throws P360_ContractException When a required identifier is missing.
     */
    public static P360_Archive_Job__c getOrCreateApplicationAttachmentJob(
        Id accessRequestId,
        Id applicationId,
        Id contentVersionId,
        String correlationId
    ) {
        requireId(accessRequestId, 'Access request id');
        requireId(applicationId, 'Application id');
        requireId(contentVersionId, 'Content version id');
        if (String.isBlank(correlationId)) {
            throw new P360_ContractException('Correlation id is required for an archive job.');
        }

        String idempotencyKey = P360_IdempotencyKey.forApplicationAttachment(applicationId, contentVersionId);
        P360_Archive_Job__c existingJob = findByIdempotencyKey(idempotencyKey);
        if (existingJob != null) {
            return existingJob;
        }

        P360_Archive_Job__c archiveJob = new P360_Archive_Job__c(
            Access_Request__c = accessRequestId,
            Application__c = applicationId,
            Archive_Event_Type__c = APPLICATION_ATTACHMENT_EVENT,
            Attempt_Count__c = 0,
            Correlation_Id__c = correlationId,
            Idempotency_Key__c = idempotencyKey,
            Queued_Date__c = System.now(),
            Status__c = PENDING_STATUS
        );

        try {
            insert archiveJob;
            return archiveJob;
        } catch (DmlException error) {
            if (error.getDmlType(0) == StatusCode.DUPLICATE_VALUE) {
                return findByIdempotencyKey(idempotencyKey);
            }
            throw error;
        }
    }

    /**
     * Gets or creates the single archive job for a decision document event.
     *
     * @param accessRequestId Related Access_Request__c identifier.
     * @param applicationDecisionId Source Application_Decision__c identifier.
     * @param correlationId Correlation identifier for the first queued attempt.
     * @return Existing or newly created decision document archive job.
     * @throws P360_ContractException When a required identifier is missing.
     */
    public static P360_Archive_Job__c getOrCreateDecisionDocumentJob(
        Id accessRequestId,
        Id applicationDecisionId,
        String correlationId
    ) {
        requireId(accessRequestId, 'Access request id');
        requireId(applicationDecisionId, 'Application decision id');
        if (String.isBlank(correlationId)) {
            throw new P360_ContractException('Correlation id is required for an archive job.');
        }

        String idempotencyKey = P360_IdempotencyKey.forDecisionDocument(applicationDecisionId);
        P360_Archive_Job__c existingJob = findByIdempotencyKey(idempotencyKey);
        if (existingJob != null) {
            return existingJob;
        }

        P360_Archive_Job__c archiveJob = new P360_Archive_Job__c(
            Access_Request__c = accessRequestId,
            Application_Decision__c = applicationDecisionId,
            Archive_Event_Type__c = DECISION_DOCUMENT_EVENT,
            Attempt_Count__c = 0,
            Correlation_Id__c = correlationId,
            Idempotency_Key__c = idempotencyKey,
            Queued_Date__c = System.now(),
            Status__c = PENDING_STATUS
        );

        try {
            insert archiveJob;
            return archiveJob;
        } catch (DmlException error) {
            if (error.getDmlType(0) == StatusCode.DUPLICATE_VALUE) {
                return findByIdempotencyKey(idempotencyKey);
            }
            throw error;
        }
    }

    /**
     * Gets or creates the single archive job for an agreement document event.
     *
     * @param accessRequestId Related Access_Request__c identifier.
     * @param agreementId Source Agreement__c identifier.
     * @param correlationId Correlation identifier for the first queued attempt.
     * @return Existing or newly created agreement document archive job.
     * @throws P360_ContractException When a required identifier is missing.
     */
    public static P360_Archive_Job__c getOrCreateAgreementDocumentJob(
        Id accessRequestId,
        Id agreementId,
        String correlationId
    ) {
        requireId(accessRequestId, 'Access request id');
        requireId(agreementId, 'Agreement id');
        if (String.isBlank(correlationId)) {
            throw new P360_ContractException('Correlation id is required for an archive job.');
        }

        String idempotencyKey = P360_IdempotencyKey.forAgreementDocument(agreementId);
        P360_Archive_Job__c existingJob = findByIdempotencyKey(idempotencyKey);
        if (existingJob != null) {
            return existingJob;
        }

        P360_Archive_Job__c archiveJob = new P360_Archive_Job__c(
            Access_Request__c = accessRequestId,
            Agreement__c = agreementId,
            Archive_Event_Type__c = AGREEMENT_DOCUMENT_EVENT,
            Attempt_Count__c = 0,
            Correlation_Id__c = correlationId,
            Idempotency_Key__c = idempotencyKey,
            Queued_Date__c = System.now(),
            Status__c = PENDING_STATUS
        );

        try {
            insert archiveJob;
            return archiveJob;
        } catch (DmlException error) {
            if (error.getDmlType(0) == StatusCode.DUPLICATE_VALUE) {
                return findByIdempotencyKey(idempotencyKey);
            }
            throw error;
        }
    }

    /**
     * Queues the application document archive job when an application is submitted.
     * Does nothing while P360 archive processing is disabled. Failures are logged without detail and never
     * block the submission. A repeated submission reuses an open job (Pending, In Progress or Failed with a
     * scheduled retry); a resubmission after a completed job (Succeeded or Manual Review) queues a new job so
     * that a complete new document set is archived.
     *
     * @param accessRequestId Related Access_Request__c identifier.
     * @param applicationId Submitted Application__c identifier.
     * @since 2026-11
     */
    public static void requestApplicationArchiveOnSubmit(Id accessRequestId, Id applicationId) {
        String correlationId = APPLICATION_DOCUMENT_EVENT + ':' + applicationId;
        try {
            if (!P360_ArchiveProcessingGate.isEnabled()) {
                return;
            }
            requireId(accessRequestId, 'Access request id');
            requireId(applicationId, 'Application id');
            new SubmissionJobQueue().queue(accessRequestId, applicationId);
        } catch (Exception error) {
            try {
                IntegrationLogger.logFailure(
                    new IntegrationLogContext('P360', APPLICATION_DOCUMENT_EVENT, 'EnqueueFailed')
                        .withCorrelationId(correlationId)
                );
            } catch (Exception ignored) {
            }
        }
    }

    /**
     * Submissions run as the applicant, who cannot see archive jobs created for colleagues in the same
     * organisation. Job lookup therefore runs without sharing so that a resubmission never collides silently
     * with an invisible existing job. Applicants have no object or field access to archive jobs, so the lookup and
     * insert run in system mode. Only server-derived identifiers are used and no job data is returned.
     */
    private without sharing class SubmissionJobQueue {
        void queue(Id accessRequestId, Id applicationId) {
            List<P360_Archive_Job__c> existingJobs = [
                SELECT Id, Status__c
                FROM P360_Archive_Job__c
                WHERE Application__c = :applicationId AND Archive_Event_Type__c = :APPLICATION_DOCUMENT_EVENT
                WITH SYSTEM_MODE
            ];
            for (P360_Archive_Job__c existingJob : existingJobs) {
                if (OPEN_STATUSES.contains(existingJob.Status__c)) {
                    return;
                }
            }

            Integer submissionNumber = existingJobs.size() + 1;
            String idempotencyKey = P360_IdempotencyKey.forApplicationDocumentSubmission(
                applicationId,
                submissionNumber
            );
            String correlationId = APPLICATION_DOCUMENT_EVENT + ':' + applicationId;
            if (submissionNumber > 1) {
                correlationId += ':' + submissionNumber;
            }
            P360_Archive_Job__c archiveJob = new P360_Archive_Job__c(
                Access_Request__c = accessRequestId,
                Application__c = applicationId,
                Archive_Event_Type__c = APPLICATION_DOCUMENT_EVENT,
                Attempt_Count__c = 0,
                Correlation_Id__c = correlationId,
                Idempotency_Key__c = idempotencyKey,
                Queued_Date__c = System.now(),
                Status__c = PENDING_STATUS
            );
            Database.SaveResult result = Database.insert(archiveJob, false, AccessLevel.SYSTEM_MODE);
            if (!result.isSuccess() && !isDuplicate(result)) {
                throw new P360_ContractException('Application archive job could not be queued.');
            }
        }

        private Boolean isDuplicate(Database.SaveResult result) {
            for (Database.Error error : result.getErrors()) {
                if (error.getStatusCode() == StatusCode.DUPLICATE_VALUE) {
                    return true;
                }
            }
            return false;
        }
    }

    private static P360_Archive_Job__c findByIdempotencyKey(String idempotencyKey) {
        List<P360_Archive_Job__c> jobs = [
            SELECT
                Access_Request__c,
                Application__c,
                Archive_Event_Type__c,
                Attempt_Count__c,
                Correlation_Id__c,
                Idempotency_Key__c,
                Queued_Date__c,
                Status__c
            FROM P360_Archive_Job__c
            WHERE Idempotency_Key__c = :idempotencyKey
            LIMIT 1
        ];
        return jobs.isEmpty() ? null : jobs[0];
    }

    private static void requireId(Id value, String fieldName) {
        if (value == null) {
            throw new P360_ContractException(fieldName + ' is required for an archive job.');
        }
    }
}
