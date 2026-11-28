/**
 * Chooses the contact and address for the application confirmation (K8, REQ-15).
 *
 * Called from the flow AAREG_createContactSendConfirmation. With every contact model flag off, or for submitters
 * outside the contact model, the flow keeps its legacy behaviour. With
 * {@link AAREG_ContactModelGate#LEGACY_MATCHING_OFF} on, the domain contact replaces the legacy contact per email.
 * With {@link AAREG_ContactModelGate#CONTEXT_ADDRESS} on, the address is the contact point for the application's
 * organization. There is never a fallback to the private address or another organization's address.
 *
 * @author Kenneth Sørensen
 * @since 2026-11
 * @group Contact Model
 * @see .github/specs/aareg-contact-model.md
 */
public with sharing class AAREG_ContactModelRecipient {
    /**
     * Application to resolve.
     */
    public class Request {
        /** Application that was submitted. */
        @InvocableVariable(label='Application Id' required=true)
        public Id applicationId;
    }

    /**
     * Recipient for one application.
     */
    public class Result {
        /** True when the flow must use contactId instead of matching or creating a contact per email. */
        @InvocableVariable(label='Use domain contact')
        public Boolean useDomainContact = false;
        /** Domain contact when useDomainContact is true. */
        @InvocableVariable(label='Contact Id')
        public Id contactId;
        /** Address for the confirmation. Null means the flow keeps the legacy recipient. */
        @InvocableVariable(label='To address')
        public String toAddress;
    }

    /**
     * Resolves the recipient for each application. Never throws; errors give the legacy behaviour and are logged.
     *
     * @param requests One request per application.
     * @return One result per request, in the same order.
     */
    @InvocableMethod(
        label='Aa-reg: Resolve confirmation recipient'
        description='Chooses contact and context address for the confirmation email in the contact model.'
        category='Aa-registeret'
    )
    public static List<Result> resolve(List<Request> requests) {
        List<Result> results = new List<Result>();
        Boolean legacyOff = AAREG_ContactModelGate.isEnabled(AAREG_ContactModelGate.LEGACY_MATCHING_OFF);
        Boolean contextAddress = AAREG_ContactModelGate.isEnabled(AAREG_ContactModelGate.CONTEXT_ADDRESS);
        for (Request request : requests) {
            results.add(new Result());
        }
        if (!legacyOff && !contextAddress) {
            return results;
        }
        Savepoint savepoint = Database.setSavepoint();
        try {
            fill(requests, results, legacyOff, contextAddress);
        } catch (Exception error) {
            Database.rollback(savepoint);
            log('Contact model recipient fell back to the legacy recipient: ' + error.getMessage());
            results.clear();
            for (Request request : requests) {
                results.add(new Result());
            }
        }
        return results;
    }

    private static void fill(List<Request> requests, List<Result> results, Boolean legacyOff, Boolean contextAddress) {
        Set<Id> applicationIds = new Set<Id>();
        for (Request request : requests) {
            applicationIds.add(request.applicationId);
        }
        Map<Id, Application__c> applications = new Map<Id, Application__c>(
            [
                SELECT Id, Account__c, Email__c, CreatedById, CreatedBy.ContactId
                FROM Application__c
                WHERE Id IN :applicationIds
                WITH SYSTEM_MODE
            ]
        );
        Map<Id, Id> submitterIdByApplicationId = new Map<Id, Id>();
        for (Application__c application : applications.values()) {
            if (application.CreatedBy?.ContactId != null) {
                submitterIdByApplicationId.put(application.Id, application.CreatedById);
            }
        }
        // A person shielded after their domain data was created must still get the legacy recipient (ADR-0008).
        Set<Id> shieldedUserIds = AAREG_ContactModelShielding.shieldedUserIds(
            new Set<Id>(submitterIdByApplicationId.values())
        );
        for (Id applicationId : new List<Id>(submitterIdByApplicationId.keySet())) {
            if (shieldedUserIds.contains(submitterIdByApplicationId.get(applicationId))) {
                submitterIdByApplicationId.remove(applicationId);
            }
        }
        // Idempotent: makes the domain contact, relation, contact point and participation exist before the email.
        AAREG_ContactModelService.recordSubmissions(submitterIdByApplicationId);

        for (Integer index = 0; index < requests.size(); index++) {
            Application__c application = applications.get(requests[index].applicationId);
            if (application == null || !submitterIdByApplicationId.containsKey(application.Id)) {
                continue;
            }
            Contact contact = AAREG_ContactModelService.findContactForUser(application.CreatedById);
            if (contact == null) {
                continue;
            }
            String address = contextAddress(contact.Id, application);
            Result result = results[index];
            if (legacyOff) {
                result.useDomainContact = true;
                result.contactId = contact.Id;
                result.toAddress = address;
            } else if (contextAddress) {
                result.toAddress = address;
            }
        }
    }

    private static String contextAddress(Id contactId, Application__c application) {
        if (application.Account__c != null) {
            AAREG_Contact_Point__c point = AAREG_ContactModelService.findContactPoint(
                contactId,
                application.Account__c
            );
            if (String.isNotBlank(point?.Email__c)) {
                return point.Email__c;
            }
        }
        // The address the applicant entered for this application belongs to the same context.
        return String.isBlank(application.Email__c) ? null : application.Email__c.trim();
    }

    private static void log(String message) {
        try {
            LoggerUtility logger = new LoggerUtility();
            logger.error(message, null, CRM_ApplicationDomain.Domain.AAREG);
            logger.publish();
        } catch (Exception error) {
            System.debug(LoggingLevel.ERROR, message);
        }
    }
}
