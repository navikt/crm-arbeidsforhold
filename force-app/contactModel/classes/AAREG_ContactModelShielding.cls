/**
 * Finds shielded persons: strictly confidential or confidential address (kode 6/7) and Nav employees.
 *
 * The contact model never creates or shows contact model data for shielded persons (ADR-0008). The source is the
 * person record linked to the portal user's own person account; nothing is copied to the contact model.
 *
 * @author Kenneth Sørensen
 * @since 2026-11
 * @group Contact Model
 * @see docs/adr/0008-skjerming-i-kontaktmodellen.md
 */
public without sharing class AAREG_ContactModelShielding {
    /** Confidentiality values that shield a person. */
    public static final Set<String> SHIELDED_CONFIDENTIALITY = new Set<String>{
        'STRENGT_FORTROLIG',
        'STRENGT_FORTROLIG_UTLAND',
        'FORTROLIG'
    };

    /**
     * Returns the portal users whose person is shielded. Users without a person record are not shielded.
     *
     * @param userIds Portal user Ids.
     * @return Shielded user Ids.
     */
    public static Set<Id> shieldedUserIds(Set<Id> userIds) {
        Set<Id> shielded = new Set<Id>();
        if (userIds == null || userIds.isEmpty()) {
            return shielded;
        }
        for (User user : [
            SELECT
                Id,
                Contact.Account.CRM_Person__r.INT_Confidential__c,
                Contact.Account.CRM_Person__r.INT_IsNavEmployee__c
            FROM User
            WHERE Id IN :userIds AND ContactId != NULL
            WITH SYSTEM_MODE
        ]) {
            if (isShielded(user.Contact?.Account?.CRM_Person__r)) {
                shielded.add(user.Id);
            }
        }
        return shielded;
    }

    /**
     * Returns whether one portal user is shielded.
     *
     * @param userId Portal user Id.
     * @return True when shielded.
     */
    public static Boolean isShieldedUser(Id userId) {
        return userId != null && shieldedUserIds(new Set<Id>{ userId }).contains(userId);
    }

    /**
     * Returns the domain contacts whose portal user is shielded. Contacts without an identity key are not domain
     * contacts and are not checked here.
     *
     * @param contactIds Contact Ids.
     * @return Shielded domain contact Ids.
     */
    public static Set<Id> shieldedContactIds(Set<Id> contactIds) {
        Set<Id> shielded = new Set<Id>();
        if (contactIds == null || contactIds.isEmpty()) {
            return shielded;
        }
        Map<Id, Id> contactIdByUserId = new Map<Id, Id>();
        for (Contact contact : [
            SELECT Id, AAREG_Identity_Key__c
            FROM Contact
            WHERE Id IN :contactIds AND AAREG_Identity_Key__c != NULL
            WITH SYSTEM_MODE
        ]) {
            contactIdByUserId.put(Id.valueOf(contact.AAREG_Identity_Key__c), contact.Id);
        }
        for (Id userId : shieldedUserIds(contactIdByUserId.keySet())) {
            shielded.add(contactIdByUserId.get(userId));
        }
        return shielded;
    }

    private static Boolean isShielded(Person__c person) {
        return person != null &&
            (person.INT_IsNavEmployee__c == true || SHIELDED_CONFIDENTIALITY.contains(person.INT_Confidential__c));
    }
}
