/**
 * Builds deterministic keys for P360 archive events without depending on transport contracts.
 *
 * @author Kenneth Sørensen
 * @since 2026-09
 * @group P360 Archive Job
 */
public with sharing class P360_IdempotencyKey {
    private static final String APPLICATION_DOCUMENT_PREFIX = 'APPLICATION_DOCUMENT:';
    private static final String APPLICATION_ATTACHMENT_PREFIX = 'APPLICATION_ATTACHMENT:';
    private static final String DECISION_DOCUMENT_PREFIX = 'DECISION_DOCUMENT:';
    private static final String AGREEMENT_DOCUMENT_PREFIX = 'AGREEMENT_DOCUMENT:';

    /**
     * Builds the key for an application document archive event.
     *
     * @param applicationId Source Application__c identifier.
     * @return Stable application document idempotency key.
     */
    public static String forApplicationDocument(Id applicationId) {
        requireId(applicationId, 'Application id');
        return APPLICATION_DOCUMENT_PREFIX + applicationId;
    }

    /**
     * Builds the key for the application document archive of one submission.
     * The first submission keeps the original application document key so existing jobs stay valid.
     *
     * @param applicationId Source Application__c identifier.
     * @param submissionNumber One-based submission sequence for the application.
     * @return Stable idempotency key for that submission.
     * @throws P360_ContractException When the identifier or sequence is missing or invalid.
     * @since 2026-11
     */
    public static String forApplicationDocumentSubmission(Id applicationId, Integer submissionNumber) {
        if (submissionNumber == null || submissionNumber < 1) {
            throw new P360_ContractException('Submission number must be one or greater for an idempotency key.');
        }
        String firstSubmissionKey = forApplicationDocument(applicationId);
        return submissionNumber == 1 ? firstSubmissionKey : firstSubmissionKey + ':SUBMISSION:' + submissionNumber;
    }

    /**
     * Builds the key for an application attachment archive event.
     *
     * @param applicationId Source Application__c identifier.
     * @param contentVersionId Source ContentVersion identifier.
     * @return Stable application attachment idempotency key.
     */
    public static String forApplicationAttachment(Id applicationId, Id contentVersionId) {
        requireId(applicationId, 'Application id');
        requireId(contentVersionId, 'Content version id');
        return APPLICATION_ATTACHMENT_PREFIX + applicationId + ':' + contentVersionId;
    }

    /**
     * Builds the key for a decision document archive event.
     *
     * @param applicationDecisionId Source Application_Decision__c identifier.
     * @return Stable decision document idempotency key.
     */
    public static String forDecisionDocument(Id applicationDecisionId) {
        requireId(applicationDecisionId, 'Application decision id');
        return DECISION_DOCUMENT_PREFIX + applicationDecisionId;
    }

    /**
     * Builds the key for an agreement document archive event.
     *
     * @param agreementId Source Agreement__c identifier.
     * @return Stable agreement document idempotency key.
     */
    public static String forAgreementDocument(Id agreementId) {
        requireId(agreementId, 'Agreement id');
        return AGREEMENT_DOCUMENT_PREFIX + agreementId;
    }

    private static void requireId(Id value, String fieldName) {
        if (value == null) {
            throw new P360_ContractException(fieldName + ' is required for an idempotency key.');
        }
    }
}
