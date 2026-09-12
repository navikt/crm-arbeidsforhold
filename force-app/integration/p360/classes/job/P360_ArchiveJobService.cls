/**
 * Creates and reuses P360 archive jobs at the internal orchestration boundary.
 *
 * @author Kenneth Sørensen
 * @since 2026-09
 * @group P360 Archive Job
 */
public with sharing class P360_ArchiveJobService {
    private static final String APPLICATION_DOCUMENT_EVENT = 'ApplicationDocument';
    private static final String PENDING_STATUS = 'Pending';

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
