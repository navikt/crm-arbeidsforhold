/**
 * Writes the contact model after a submission without affecting the submission itself.
 *
 * @author Kenneth Sørensen
 * @since 2026-11
 * @group Contact Model
 * @see AAREG_ContactModelService
 */
public without sharing class AAREG_ContactModelShadowWriteJob implements Queueable {
    private final Map<Id, Id> submitterIdByApplicationId;

    /**
     * Creates a job for the given submissions.
     *
     * @param submitterIdByApplicationId Submitting user Id per application Id.
     */
    public AAREG_ContactModelShadowWriteJob(Map<Id, Id> submitterIdByApplicationId) {
        this.submitterIdByApplicationId = submitterIdByApplicationId;
    }

    /**
     * Enqueues shadow writing for an application the running user has just submitted, when the flag is on.
     * Never throws.
     *
     * @param applicationId Submitted application.
     * @return True when a job was enqueued.
     */
    public static Boolean enqueueForCurrentUser(Id applicationId) {
        try {
            if (applicationId == null || !AAREG_ContactModelGate.isEnabled(AAREG_ContactModelGate.SHADOW_WRITE)) {
                return false;
            }
            if (Limits.getQueueableJobs() >= Limits.getLimitQueueableJobs()) {
                log('Contact model shadow write skipped: queueable limit reached for application ' + applicationId);
                return false;
            }
            System.enqueueJob(
                new AAREG_ContactModelShadowWriteJob(new Map<Id, Id>{ applicationId => UserInfo.getUserId() })
            );
            return true;
        } catch (Exception error) {
            log('Contact model shadow write could not be enqueued: ' + error.getMessage());
            return false;
        }
    }

    /**
     * Writes the contact model. Errors are logged and not rethrown.
     *
     * @param context Queueable context.
     */
    public void execute(QueueableContext context) {
        try {
            AAREG_ContactModelService.recordSubmissions(submitterIdByApplicationId);
        } catch (Exception error) {
            log(
                'Contact model shadow write failed for applications ' +
                    submitterIdByApplicationId.keySet() +
                    ': ' +
                    error.getMessage()
            );
        }
    }

    private static void log(String message) {
        try {
            LoggerUtility logger = new LoggerUtility();
            logger.error(message, null, CRM_ApplicationDomain.Domain.AAREG);
            logger.publish();
        } catch (Exception loggingError) {
            System.debug(LoggingLevel.ERROR, message);
        }
    }
}
