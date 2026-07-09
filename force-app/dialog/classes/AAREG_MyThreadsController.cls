public with sharing class AAREG_MyThreadsController {
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
                WITH USER_MODE
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
                WITH USER_MODE
                ORDER BY CRM_Latest_Message_Datetime__c DESC
            ];
        } catch (Exception e) {
            // Logg teknisk feil og returner en kontrollert feil til klienten.
            LoggerUtility logger = new LoggerUtility();
            logger.error('Feil ved henting av brukertråder.', null);
            logger.publish();
            throw new AuraHandledException('Kunne ikke hente brukertråder.');
        }
    }
}
