/**
 * Writes the Aa-register contact model: one domain contact per portal user, one managed
 * AccountContactRelation per organization, one contact point per context and one participation per
 * application and role. Addresses are stored only on AAREG_Contact_Point__c (ADR-0007).
 *
 * Runs in system mode because portal users cannot write Contact or AccountContactRelation. Callers must pass
 * only server-derived Ids: the submitting user and the application that user has just submitted.
 *
 * @author Kenneth Sørensen
 * @since 2026-11
 * @group Contact Model
 * @see .github/specs/aareg-contact-model.md
 */
public without sharing class AAREG_ContactModelService {
    /** Role for the person who submitted the application. */
    public static final String ROLE_SUBMITTER = 'Submitter';
    /** Context for an address used on behalf of an organization. */
    public static final String CONTEXT_ORGANIZATION = 'Organization';
    /** Context for the private address. */
    public static final String CONTEXT_PRIVATE = 'Private';
    /** Name of the technical primary account for domain contacts. */
    public static final String PRIMARY_ACCOUNT_NAME = 'Aa-registeret kontaktmodell';

    private static final Integer NAME_LENGTH = 80;

    /**
     * Thrown when the contact model cannot be written.
     */
    public class ContactModelException extends Exception {
    }

    /**
     * Records the submitter of each application in the contact model. Idempotent for resubmissions.
     *
     * @param submitterIdByApplicationId Submitting user Id per application Id.
     * @throws ContactModelException When the primary account is not set up or a domain contact cannot be created.
     */
    public static void recordSubmissions(Map<Id, Id> submitterIdByApplicationId) {
        if (submitterIdByApplicationId == null || submitterIdByApplicationId.isEmpty()) {
            return;
        }
        Id primaryAccountId = requirePrimaryAccountId();
        List<Application__c> applications = [
            SELECT Id, Account__c, Email__c
            FROM Application__c
            WHERE Id IN :submitterIdByApplicationId.keySet()
            WITH SYSTEM_MODE
        ];
        Map<Id, Contact> contactByUserId = ensureContacts(
            new Set<Id>(submitterIdByApplicationId.values()),
            primaryAccountId
        );

        List<Submission> submissions = new List<Submission>();
        for (Application__c application : applications) {
            Contact contact = contactByUserId.get(submitterIdByApplicationId.get(application.Id));
            submissions.add(new Submission(application, contact));
        }
        ensureRelations(submissions, primaryAccountId);
        ensureOrganizationContactPoints(submissions, primaryAccountId);
        upsertParticipations(submissions);
    }

    /**
     * Returns the Id of the technical primary account, creating the account and setting when missing.
     *
     * @return Id of the primary account.
     * @throws ContactModelException When the AAREG Default Settings org defaults are not configured.
     */
    public static Id setUpPrimaryAccount() {
        AAREG_Default_Settings__c settings = AAREG_Default_Settings__c.getOrgDefaults();
        if (settings?.Id == null) {
            throw new ContactModelException('AAREG Default Settings org defaults must be configured first.');
        }
        Id existingId = findPrimaryAccountId(settings);
        if (existingId != null) {
            return existingId;
        }
        Account account = new Account(Name = PRIMARY_ACCOUNT_NAME);
        insert as system account;
        settings.Contact_Model_Account_Id__c = account.Id;
        upsert as system settings;
        return account.Id;
    }

    /**
     * Returns the Id of the technical primary account when it is set up.
     *
     * @return Primary account Id, or null when the setting is blank or the account no longer exists.
     */
    public static Id getPrimaryAccountId() {
        return findPrimaryAccountId(AAREG_Default_Settings__c.getOrgDefaults());
    }

    /**
     * Builds the key that allows one contact point per context.
     *
     * @param contactId Domain contact Id.
     * @param organizationId Organization account Id, or null for the private context.
     * @return Key in the form contact:organization or contact:PRIVATE.
     */
    public static String contextKey(Id contactId, Id organizationId) {
        return String.valueOf(contactId) + ':' + (organizationId == null ? 'PRIVATE' : String.valueOf(organizationId));
    }

    /**
     * Builds the participation key that prevents duplicate participations.
     *
     * @param contextId Application or agreement Id.
     * @param contactId Domain contact Id.
     * @param role Participation role.
     * @return Key in the form context:contact:role.
     */
    public static String participationKey(Id contextId, Id contactId, String role) {
        return String.valueOf(contextId) + ':' + String.valueOf(contactId) + ':' + role;
    }

    /**
     * Returns the domain contact for a portal user, creating it when missing.
     *
     * @param userId Portal user Id, derived on the server.
     * @return Domain contact.
     * @throws ContactModelException When the primary account is not set up or the contact cannot be created.
     */
    public static Contact ensureContactForUser(Id userId) {
        return ensureContacts(new Set<Id>{ userId }, requirePrimaryAccountId()).get(userId);
    }

    /**
     * Returns the domain contact for a portal user without creating it.
     *
     * @param userId Portal user Id.
     * @return Domain contact, or null.
     */
    public static Contact findContactForUser(Id userId) {
        return queryContacts(new Set<Id>{ userId }).get(userId);
    }

    /**
     * Saves the address for one context. Organization addresses also ensure a managed ACR, private addresses never do.
     * Other contexts are never changed.
     *
     * @param contactId Domain contact.
     * @param organizationId Organization account, or null for the private context.
     * @param email Address for the context.
     * @param phone Phone for the context.
     * @return Saved contact point.
     */
    public static AAREG_Contact_Point__c saveContactPoint(Id contactId, Id organizationId, String email, String phone) {
        if (organizationId != null) {
            List<AccountContactRelation> relations = [
                SELECT Id
                FROM AccountContactRelation
                WHERE ContactId = :contactId AND AccountId = :organizationId
                WITH SYSTEM_MODE
            ];
            if (relations.isEmpty()) {
                insert as system new AccountContactRelation(
                    AccountId = organizationId,
                    ContactId = contactId,
                    IsActive = true,
                    AAREG_Managed__c = true
                );
            }
        }
        AAREG_Contact_Point__c point = new AAREG_Contact_Point__c(
            Context_Key__c = contextKey(contactId, organizationId),
            Contact__c = contactId,
            Organization__c = organizationId,
            Context__c = organizationId == null ? CONTEXT_PRIVATE : CONTEXT_ORGANIZATION,
            Email__c = String.isBlank(email) ? null : email.trim(),
            Phone__c = String.isBlank(phone) ? null : phone.trim()
        );
        Database.upsert(point, AAREG_Contact_Point__c.Context_Key__c, true, AccessLevel.SYSTEM_MODE);
        return point;
    }

    /**
     * Returns the address for one context without fallback to another context.
     *
     * @param contactId Domain contact.
     * @param organizationId Organization account, or null for the private context.
     * @return Contact point, or null when the context has no address.
     */
    public static AAREG_Contact_Point__c findContactPoint(Id contactId, Id organizationId) {
        if (contactId == null) {
            return null;
        }
        String key = contextKey(contactId, organizationId);
        List<AAREG_Contact_Point__c> points = [
            SELECT Id, Context__c, Organization__c, Email__c, Phone__c, LastModifiedDate
            FROM AAREG_Contact_Point__c
            WHERE Context_Key__c = :key
            WITH SYSTEM_MODE
        ];
        return points.isEmpty() ? null : points[0];
    }

    private static Id requirePrimaryAccountId() {
        Id primaryAccountId = getPrimaryAccountId();
        if (primaryAccountId == null) {
            throw new ContactModelException('Contact model primary account is not set up.');
        }
        return primaryAccountId;
    }

    private static Id findPrimaryAccountId(AAREG_Default_Settings__c settings) {
        String configuredId = settings?.Contact_Model_Account_Id__c;
        if (String.isBlank(configuredId)) {
            return null;
        }
        Id accountId;
        try {
            accountId = Id.valueOf(configuredId);
        } catch (StringException error) {
            return null;
        }
        List<Account> accounts = [SELECT Id FROM Account WHERE Id = :accountId WITH SYSTEM_MODE LIMIT 1];
        return accounts.isEmpty() ? null : accounts[0].Id;
    }

    private static Map<Id, Contact> ensureContacts(Set<Id> userIds, Id primaryAccountId) {
        Map<Id, Contact> contactByUserId = queryContacts(userIds);
        Set<Id> missingUserIds = new Set<Id>(userIds);
        missingUserIds.removeAll(contactByUserId.keySet());
        if (missingUserIds.isEmpty()) {
            return contactByUserId;
        }

        Account primaryAccount = [SELECT OwnerId FROM Account WHERE Id = :primaryAccountId WITH SYSTEM_MODE];
        List<Contact> newContacts = new List<Contact>();
        for (User user : [SELECT Id, FirstName, LastName FROM User WHERE Id IN :missingUserIds WITH SYSTEM_MODE]) {
            newContacts.add(
                new Contact(
                    AccountId = primaryAccountId,
                    OwnerId = primaryAccount.OwnerId,
                    FirstName = user.FirstName,
                    LastName = user.LastName,
                    AAREG_Identity_Key__c = user.Id
                )
            );
        }
        Database.DMLOptions options = new Database.DMLOptions();
        options.DuplicateRuleHeader.allowSave = true;
        options.optAllOrNone = false;
        // A concurrent submission may have created the contact; the unique key rejects the duplicate.
        Database.insert(newContacts, options, AccessLevel.SYSTEM_MODE);

        contactByUserId = queryContacts(userIds);
        if (!contactByUserId.keySet().containsAll(userIds)) {
            throw new ContactModelException('Could not create the Aa-register domain contact.');
        }
        return contactByUserId;
    }

    private static Map<Id, Contact> queryContacts(Set<Id> userIds) {
        Set<String> identityKeys = new Set<String>();
        for (Id userId : userIds) {
            identityKeys.add(userId);
        }
        Map<Id, Contact> contactByUserId = new Map<Id, Contact>();
        for (Contact contact : [
            SELECT Id, FirstName, LastName, AAREG_Identity_Key__c
            FROM Contact
            WHERE AAREG_Identity_Key__c IN :identityKeys
            WITH SYSTEM_MODE
        ]) {
            contactByUserId.put(Id.valueOf(contact.AAREG_Identity_Key__c), contact);
        }
        return contactByUserId;
    }

    private static void ensureRelations(List<Submission> submissions, Id primaryAccountId) {
        Set<Id> accountIds = new Set<Id>();
        Set<Id> contactIds = new Set<Id>();
        for (Submission submission : submissions) {
            if (submission.hasOrganization(primaryAccountId)) {
                accountIds.add(submission.application.Account__c);
                contactIds.add(submission.contact.Id);
            }
        }
        if (accountIds.isEmpty()) {
            return;
        }

        Set<String> existingKeys = new Set<String>();
        for (AccountContactRelation relation : [
            SELECT AccountId, ContactId
            FROM AccountContactRelation
            WHERE AccountId IN :accountIds AND ContactId IN :contactIds
            WITH SYSTEM_MODE
        ]) {
            existingKeys.add(contextKey(relation.ContactId, relation.AccountId));
        }

        Map<String, AccountContactRelation> newByKey = new Map<String, AccountContactRelation>();
        for (Submission submission : submissions) {
            String key = contextKey(submission.contact.Id, submission.application.Account__c);
            if (submission.hasOrganization(primaryAccountId) && !existingKeys.contains(key)) {
                newByKey.put(
                    key,
                    new AccountContactRelation(
                        AccountId = submission.application.Account__c,
                        ContactId = submission.contact.Id,
                        IsActive = true,
                        AAREG_Managed__c = true
                    )
                );
            }
        }
        insert as system newByKey.values();
    }

    private static void ensureOrganizationContactPoints(List<Submission> submissions, Id primaryAccountId) {
        Set<String> keys = new Set<String>();
        for (Submission submission : submissions) {
            if (submission.hasOrganization(primaryAccountId)) {
                keys.add(contextKey(submission.contact.Id, submission.application.Account__c));
            }
        }
        if (keys.isEmpty()) {
            return;
        }
        Map<String, AAREG_Contact_Point__c> pointByKey = new Map<String, AAREG_Contact_Point__c>();
        for (AAREG_Contact_Point__c point : [
            SELECT Id, Context_Key__c, Email__c
            FROM AAREG_Contact_Point__c
            WHERE Context_Key__c IN :keys
            WITH SYSTEM_MODE
        ]) {
            pointByKey.put(point.Context_Key__c, point);
        }

        Map<String, AAREG_Contact_Point__c> changedByKey = new Map<String, AAREG_Contact_Point__c>();
        for (Submission submission : submissions) {
            if (!submission.hasOrganization(primaryAccountId)) {
                continue;
            }
            String key = contextKey(submission.contact.Id, submission.application.Account__c);
            String email = submission.application.Email__c;
            AAREG_Contact_Point__c point = pointByKey.get(key);
            if (point == null) {
                point = new AAREG_Contact_Point__c(
                    Context_Key__c = key,
                    Contact__c = submission.contact.Id,
                    Organization__c = submission.application.Account__c,
                    Context__c = CONTEXT_ORGANIZATION,
                    Email__c = email
                );
                pointByKey.put(key, point);
                changedByKey.put(key, point);
            } else if (String.isNotBlank(email) && point.Email__c != email) {
                point.Email__c = email;
                changedByKey.put(key, point);
            }
            submission.contactPoint = point;
        }
        Database.upsert(changedByKey.values(), AAREG_Contact_Point__c.Context_Key__c, true, AccessLevel.SYSTEM_MODE);
    }

    private static void upsertParticipations(List<Submission> submissions) {
        Map<String, RelatedContact__c> participationByKey = new Map<String, RelatedContact__c>();
        for (Submission submission : submissions) {
            String key = participationKey(submission.application.Id, submission.contact.Id, ROLE_SUBMITTER);
            participationByKey.put(
                key,
                new RelatedContact__c(
                    Participation_Key__c = key,
                    Name = displayName(submission.contact),
                    Application__c = submission.application.Id,
                    Contact__c = submission.contact.Id,
                    Role__c = ROLE_SUBMITTER,
                    Email__c = submission.application.Email__c,
                    Contact_Point__c = submission.contactPoint?.Id
                )
            );
        }
        Database.upsert(
            participationByKey.values(),
            RelatedContact__c.Participation_Key__c,
            true,
            AccessLevel.SYSTEM_MODE
        );
    }

    private static String displayName(Contact contact) {
        String name = String.join(new List<String>{ contact.FirstName ?? '', contact.LastName ?? '' }, ' ').trim();
        return name.abbreviate(NAME_LENGTH);
    }

    private class Submission {
        private final Application__c application;
        private final Contact contact;
        private AAREG_Contact_Point__c contactPoint;

        private Submission(Application__c application, Contact contact) {
            this.application = application;
            this.contact = contact;
        }

        private Boolean hasOrganization(Id primaryAccountId) {
            return application.Account__c != null && application.Account__c != primaryAccountId;
        }
    }
}
