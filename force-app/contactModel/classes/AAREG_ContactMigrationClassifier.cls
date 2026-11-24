/**
 * Classifies submitted applications into contact model migration classes A to E.
 *
 * Only class A is linked automatically. The classifier reads data in system mode and never writes.
 *
 * @author Kenneth Sørensen
 * @since 2026-11
 * @group Contact Model
 * @see .github/specs/aareg-contact-model.md
 */
public with sharing class AAREG_ContactMigrationClassifier {
    /** Safe to link automatically. */
    public static final String CLASS_A = 'A';
    /** No reliable portal user. */
    public static final String CLASS_B = 'B';
    /** Email shared by several portal users. */
    public static final String CLASS_C = 'C';
    /** Shielded person. */
    public static final String CLASS_D = 'D';
    /** Conflicting existing link. */
    public static final String CLASS_E = 'E';

    /**
     * Class and reason for one application.
     */
    public class Result {
        /** Application Id. */
        public Id applicationId;
        /** Portal user who created the application, when reliable. */
        public Id submitterUserId;
        /** Migration class A to E. */
        public String migrationClass;
        /** Reason without personal data. */
        public String reason;

        Result(Id applicationId, Id submitterUserId, String migrationClass, String reason) {
            this.applicationId = applicationId;
            this.submitterUserId = submitterUserId;
            this.migrationClass = migrationClass;
            this.reason = reason;
        }
    }

    /**
     * Classifies applications.
     *
     * @param applications Applications with Id, Account__c, Email__c, CreatedById and CreatedBy.ContactId.
     * @return One result per application, keyed by application Id.
     */
    public static Map<Id, Result> classify(List<Application__c> applications) {
        Map<Id, Result> results = new Map<Id, Result>();
        if (applications == null || applications.isEmpty()) {
            return results;
        }
        Id primaryAccountId = AAREG_ContactModelService.getPrimaryAccountId();
        Map<String, Set<Id>> usersByEmail = usersByEmail(applications);
        Set<Id> shieldedUserIds = shieldedUserIds(applications);
        Map<Id, Set<Id>> linkedContactIdsByApplication = linkedSubmitterContacts(applications);
        Map<Id, Id> contactIdByIdentityKey = domainContactIds(applications);

        for (Application__c application : applications) {
            Id userId = application.CreatedBy?.ContactId == null ? null : application.CreatedById;
            String email = normalize(application.Email__c);
            if (application.Account__c == null || application.Account__c == primaryAccountId) {
                results.put(
                    application.Id,
                    new Result(application.Id, userId, CLASS_B, 'Søknaden manglar organisasjon.')
                );
            } else if (userId == null) {
                results.put(
                    application.Id,
                    new Result(application.Id, null, CLASS_B, 'Søknaden er ikkje oppretta av ein portalbrukar.')
                );
            } else if (shieldedUserIds.contains(userId)) {
                results.put(
                    application.Id,
                    new Result(application.Id, userId, CLASS_D, 'Skjerma person. Krev eiga avklaring.')
                );
            } else if (email != null && usersByEmail.get(email).size() > 1) {
                results.put(
                    application.Id,
                    new Result(application.Id, userId, CLASS_C, 'E-postadressa er brukt av fleire portalbrukarar.')
                );
            } else if (hasConflict(application.Id, contactIdByIdentityKey.get(userId), linkedContactIdsByApplication)) {
                results.put(
                    application.Id,
                    new Result(application.Id, userId, CLASS_E, 'Søknaden er allereie kopla til ein annan kontakt.')
                );
            } else {
                results.put(application.Id, new Result(application.Id, userId, CLASS_A, 'Sikker portalbrukar.'));
            }
        }
        return results;
    }

    private static Boolean hasConflict(Id applicationId, Id domainContactId, Map<Id, Set<Id>> linkedByApplication) {
        Set<Id> linked = linkedByApplication.get(applicationId);
        if (linked == null || linked.isEmpty()) {
            return false;
        }
        return domainContactId == null || !linked.contains(domainContactId) || linked.size() > 1;
    }

    private static Map<String, Set<Id>> usersByEmail(List<Application__c> applications) {
        Set<String> emails = new Set<String>();
        for (Application__c application : applications) {
            String email = normalize(application.Email__c);
            if (email != null) {
                emails.add(email);
            }
        }
        Map<String, Set<Id>> result = new Map<String, Set<Id>>();
        for (String email : emails) {
            result.put(email, new Set<Id>());
        }
        if (emails.isEmpty()) {
            return result;
        }
        for (Application__c application : [
            SELECT Email__c, CreatedById
            FROM Application__c
            WHERE Email__c IN :emails AND CreatedBy.ContactId != NULL
            WITH SYSTEM_MODE
        ]) {
            String email = normalize(application.Email__c);
            if (result.containsKey(email)) {
                result.get(email).add(application.CreatedById);
            }
        }
        return result;
    }

    private static Set<Id> shieldedUserIds(List<Application__c> applications) {
        Set<Id> userIds = new Set<Id>();
        for (Application__c application : applications) {
            if (application.CreatedBy?.ContactId != null) {
                userIds.add(application.CreatedById);
            }
        }
        return AAREG_ContactModelShielding.shieldedUserIds(userIds);
    }

    private static Map<Id, Set<Id>> linkedSubmitterContacts(List<Application__c> applications) {
        Map<Id, Set<Id>> result = new Map<Id, Set<Id>>();
        for (RelatedContact__c participation : [
            SELECT Application__c, Contact__c
            FROM RelatedContact__c
            WHERE
                Application__c IN :applications
                AND Role__c = :AAREG_ContactModelService.ROLE_SUBMITTER
                AND Contact__c != NULL
            WITH SYSTEM_MODE
        ]) {
            if (!result.containsKey(participation.Application__c)) {
                result.put(participation.Application__c, new Set<Id>());
            }
            result.get(participation.Application__c).add(participation.Contact__c);
        }
        return result;
    }

    private static Map<Id, Id> domainContactIds(List<Application__c> applications) {
        Set<String> keys = new Set<String>();
        for (Application__c application : applications) {
            if (application.CreatedBy?.ContactId != null) {
                keys.add(application.CreatedById);
            }
        }
        Map<Id, Id> result = new Map<Id, Id>();
        if (keys.isEmpty()) {
            return result;
        }
        for (Contact contact : [
            SELECT Id, AAREG_Identity_Key__c
            FROM Contact
            WHERE AAREG_Identity_Key__c IN :keys
            WITH SYSTEM_MODE
        ]) {
            result.put(Id.valueOf(contact.AAREG_Identity_Key__c), contact.Id);
        }
        return result;
    }

    private static String normalize(String email) {
        return String.isBlank(email) ? null : email.trim().toLowerCase();
    }
}
