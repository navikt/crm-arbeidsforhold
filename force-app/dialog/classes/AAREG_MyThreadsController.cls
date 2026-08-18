/**
 * Provides the community user's message threads for the Aa-registeret dialog UI.
 *
 * @author Ann Kristin Olsen
 * @author Ashish Misra
 * @since July 2026
 * @group AAREG Dialog
 */
public with sharing class AAREG_MyThreadsController {
    /**
     * Retrieves the message threads for the account linked to the user's last-used
     * organization, ordered by most recent message first. Result is cacheable
     * (`cacheable=true`); the calling LWC must invoke `refreshApex()` to force a
     * refresh after the underlying data changes.
     *
     * @param userId Id of the community User record. Returns an empty list if blank.
     * @return The user's Thread__c records, or an empty list if the user, last-used
     * organization, or matching account cannot be resolved.
     * @throws AuraHandledException If retrieving the threads fails.
     */
    @AuraEnabled(cacheable=true)
    public static List<Thread__c> getUsersThreads(String userId) {
        // Returner tom liste hvis bruker-ID ikke er oppgitt.
        if (String.isBlank(userId)) {
            return new List<Thread__c>();
        }

        try {
            // Hent brukerens sist valgte organisasjonsnummer for å finne riktig konto.
            List<User> users = [
                SELECT LastUsedOrganization__c
                FROM User
                WHERE Id = :userId
                LIMIT 1
            ];

            String lastUsedOrganizationNumber = users.isEmpty() ? null : users[0].LastUsedOrganization__c;
            if (String.isBlank(lastUsedOrganizationNumber)) {
                return new List<Thread__c>();
            }

            // Slå opp konto basert på organisasjonsnummer.
            List<Account> accountIdList = AAREG_accountSelector.selectAccountByOrganizationNumber(
                lastUsedOrganizationNumber
            );
            if (accountIdList == null || accountIdList.isEmpty()) {
                return new List<Thread__c>();
            }

            Id accountId = accountIdList[0].Id;
            // Hent tråder for kontoen, sortert på siste meldingsdato.
            return [
                SELECT
                    Id,
                    Name,
                    CreatedDate,
                    CRM_Conversation_Summary__c,
                    CRM_Number_of_External_Messages__c,
                    CRM_Latest_Message_Datetime__c,
                    CRM_Number_of_unread_Messages__c,
                    CRM_Related_Object__c,
                    CRM_HenvendelseId__c,
                    AAREG_Thread_Subject__c,
                    CRM_isActive__c
                FROM Thread__c
                WHERE CRM_Account__c = :accountId
                ORDER BY CRM_Latest_Message_Datetime__c DESC
            ];
        } catch (Exception e) {
            // Logg teknisk feil og returner en kontrollert feil til klienten.
            LoggerUtility logger = new LoggerUtility();
            logger.error('Feil ved henting av brukertråder.', null, CRM_ApplicationDomain.Domain.AAREG);
            logger.publish();
            throw new AuraHandledException('Kunne ikke hente brukertråder.');
        }
    }
}
