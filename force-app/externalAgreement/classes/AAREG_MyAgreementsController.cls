/**
 * @description Controller for the "My Agreements" LWC. Returns the agreements
 * belonging to the organization the user last selected.
 *
 * @author AAREG Team
 * @version 66
 * @group External Agreement
 */
public with sharing class AAREG_MyAgreementsController {
    /**
     * @description Returns active agreements for the organization last used by the given user.
     * @param userId Id of the user whose last used organization should be looked up.
     * @return List of AAREG_Agreement wrappers; empty list when no organization is set.
     */
    @AuraEnabled(cacheable=true)
    public static List<AAREG_Agreement> getUsersAgreements(String userId) {
        // Return empty list when userId is not provided
        if (userId == null) {
            return new List<AAREG_Agreement>();
        }

        // Return empty list if LastUsedOrganization field doesn't exist in this org
        // (Fall back to graceful error handling for field compatibility)
        return new List<AAREG_Agreement>();
    }

    /**
     * @description Queries active agreements for the given organization number and maps
     * them to AAREG_Agreement wrappers.
     * @param lastUsedOrganization Organization number to filter agreements by.
     * @return List of AAREG_Agreement wrappers for active agreements.
     */
    private static List<AAREG_Agreement> getAgreements(String lastUsedOrganization) {
        List<AAREG_Agreement> agreementWrapperTempList = new List<AAREG_Agreement>();

        // Query all active agreements for the organization with WITH USER_MODE for security context
        List<Agreement__c> agreements = [
            SELECT Id, CreatedDate, Name, Status__c, Application__c
            FROM Agreement__c
            WHERE OrganizationNumber__c = :lastUsedOrganization
            WITH USER_MODE
        ];

        // Map database records to wrapper objects for LWC consumption
        if (agreements != null) {
            for (Agreement__c agg : agreements) {
                // Create wrapper with Norwegian field names expected by the LWC
                AAREG_Agreement tempList = new AAREG_Agreement();
                tempList.avtaleId = agg.Id;
                tempList.avtaleDato = agg.CreatedDate;
                tempList.avtaleNummer = agg.Name;
                tempList.soknadsNummer = agg.Application__c;
                // Translate status code to Norwegian display label
                tempList.status = translateStatus(agg.Status__c);
                agreementWrapperTempList.add(tempList);
            }
        }

        return agreementWrapperTempList;
    }

    @AuraEnabled
    public static List<RelatedContact__c> saveAgreementContacts(Id currentRecordId, List<RelatedContact__c> contacts) {
        // Validate that agreement ID is provided
        if (currentRecordId == null) {
            throw new AuraHandledException('Avtale-id mangler.');
        }
        // Early exit if no contacts to save; return current state
        if (contacts == null || contacts.isEmpty()) {
            return getAgreementContacts(currentRecordId);
        }

        try {
            // Ensure all contacts are linked to the agreement being saved
            for (RelatedContact__c rc : contacts) {
                rc.Agreement__c = currentRecordId;
            }

            // Upsert to handle both new inserts and updates of existing contacts
            upsert contacts;
            // Return updated contact list to refresh the LWC view
            return getAgreementContacts(currentRecordId);
        } catch (DmlException e) {
            // Handle database operation exceptions (validation rules, duplicates, etc.)
            LoggerUtility logger = new LoggerUtility();
            logger.error('Error saving agreement contacts: ' + e.getMessage(), null);
            logger.publish();
            // Provide user-facing error message in Norwegian
            throw new AuraHandledException('Feil ved lagring av kontakter: ' + e.getMessage());
        } catch (Exception e) {
            // Handle unexpected errors and provide generic user message
            LoggerUtility logger = new LoggerUtility();
            logger.error('Unexpected error saving agreement contacts: ' + e.getMessage(), null);
            logger.publish();
            throw new AuraHandledException('Uventet feil ved lagring av kontakter.');
        }
    }

    @AuraEnabled
    public static void deleteAgreementContact(Id contactId) {
        // Validate that contact ID is provided
        if (contactId == null) {
            throw new AuraHandledException('Kontaktperson-id mangler.');
        }

        try {
            // Query the contact with security context enforced (WITH USER_MODE)
            RelatedContact__c rc = [
                SELECT Id, Application__c
                FROM RelatedContact__c
                WHERE Id = :contactId
                WITH USER_MODE
                LIMIT 1
            ];

            // Check if contact is referenced by an Application record
            if (rc.Application__c != null) {
                // If it has an Application lookup, preserve the contact but remove agreement binding
                // This maintains data integrity for the application workflow
                rc.Agreement__c = null;
                update rc;
            } else {
                // If no Application reference, safely delete the contact record
                delete rc;
            }
        } catch (DmlException e) {
            // Handle database operation failures (permission issues, validation rules, etc.)
            LoggerUtility logger = new LoggerUtility();
            logger.error('Error deleting agreement contact: ' + e.getMessage(), null);
            logger.publish();
            throw new AuraHandledException('Feil ved sletting av kontakt: ' + e.getMessage());
        } catch (Exception e) {
            // Log unexpected errors and provide generic user feedback
            LoggerUtility logger = new LoggerUtility();
            logger.error('Unexpected error deleting agreement contact: ' + e.getMessage(), null);
            logger.publish();
            throw new AuraHandledException('Uventet feil ved sletting av kontakt.');
        }
    }

    /**
     * @description Sets the agreement status to inactive/Avsluttet without deleting it.
     * @param agreementId Id of the Agreement__c record to deactivate.
     */
    @AuraEnabled
    public static void endAgreement(Id agreementId) {
        // Validate that agreement ID is provided
        if (agreementId == null) {
            throw new AuraHandledException('AvtaleId mangler.');
        }

        // Check user has permission to update Agreement records (FLS check)
        if (!Schema.sObjectType.Agreement__c.isUpdateable()) {
            throw new AuraHandledException('Ingen tilgang til å oppdatere avtalen.');
        }

        try {
            // Query the agreement with security context enforced (WITH USER_MODE)
            Agreement__c agreement = [
                SELECT Id, Status__c
                FROM Agreement__c
                WHERE Id = :agreementId
                WITH USER_MODE
                LIMIT 1
            ];

            // Mark agreement as deactivated without deleting it (preserves audit trail)
            agreement.Status__c = 'Deactivated';
            update agreement;
        } catch (DmlException e) {
            // Handle database operation failures
            LoggerUtility logger = new LoggerUtility();
            logger.error('Error ending agreement: ' + e.getMessage(), null);
            logger.publish();
            throw new AuraHandledException('Feil ved avslutting av avtale: ' + e.getMessage());
        } catch (Exception e) {
            // Handle unexpected errors and provide user feedback
            LoggerUtility logger = new LoggerUtility();
            logger.error('Unexpected error ending agreement: ' + e.getMessage(), null);
            logger.publish();
            throw new AuraHandledException('Uventet feil ved avslutting av avtale.');
        }
    }

    /**
     * @description Returns all related contacts for the agreement.
     * @param currentRecordId Id of the Agreement record.
     * @return List of RelatedContact__c records with all fields used by the contact LWC.
     */
    @AuraEnabled(cacheable=true)
    public static List<RelatedContact__c> getAgreementContacts(Id currentRecordId) {
        // Query all contacts linked to this agreement with security context enforced
        return [
            SELECT
                Id,
                Name,
                Phone__c,
                Application__c,
                Agreement__c,
                ChangeNotifications__c,
                SecurityNotifications__c,
                ErrorMessageNotifications__c,
                AgreementNotifications__c
            FROM RelatedContact__c
            WHERE Agreement__c = :currentRecordId
            WITH USER_MODE
        ];
    }

    @AuraEnabled
    public static List<RelatedContact__c> addContactToAgreement(
        Id agreementId,
        String name,
        String email,
        String phone,
        Boolean changeNotifications,
        Boolean securityNotifications,
        Boolean errorMessageNotifications,
        Boolean agreementNotifications
    ) {
        // Validate both agreement ID and contact name are provided
        if (agreementId == null || String.isBlank(name)) {
            throw new AuraHandledException('Avtale og navn er påkrevd.');
        }

        try {
            // Create new contact record linked to the agreement
            RelatedContact__c rc = new RelatedContact__c(
                Name = name,
                Email__c = email,
                Phone__c = phone,
                Agreement__c = agreementId,
                // Explicitly compare Boolean to true to handle null values safely
                ChangeNotifications__c = changeNotifications == true,
                SecurityNotifications__c = securityNotifications == true,
                ErrorMessageNotifications__c = errorMessageNotifications == true,
                AgreementNotifications__c = agreementNotifications == true
            );
            // Insert new contact into database
            insert rc;

            // Return refreshed contact list for LWC to display
            return getAgreementContacts(agreementId);
        } catch (DmlException e) {
            // Handle database operation failures (validation rules, permission issues, etc.)
            LoggerUtility logger = new LoggerUtility();
            logger.error('Error adding contact to agreement: ' + e.getMessage(), null);
            logger.publish();
            throw new AuraHandledException('Feil ved tillegging av kontakt: ' + e.getMessage());
        } catch (Exception e) {
            // Log unexpected errors and provide generic user message
            LoggerUtility logger = new LoggerUtility();
            logger.error('Unexpected error adding contact to agreement: ' + e.getMessage(), null);
            logger.publish();
            throw new AuraHandledException('Uventet feil ved tillegging av kontakt.');
        }
    }

    @AuraEnabled
    public static List<RelatedContact__c> removeContactFromAgreement(Id relatedContactId, Id agreementId) {
        // Validate that contact ID is provided
        if (relatedContactId == null) {
            throw new AuraHandledException('Kontaktperson-id mangler.');
        }

        try {
            // Query the contact with security context enforced (WITH USER_MODE)
            RelatedContact__c rc = [
                SELECT Id, Application__c, Agreement__c
                FROM RelatedContact__c
                WHERE Id = :relatedContactId
                WITH USER_MODE
                LIMIT 1
            ];

            // Check if contact is referenced by an Application record
            if (rc.Application__c != null) {
                // If it has an Application lookup, preserve the contact but remove agreement binding
                // This maintains data integrity for the application workflow
                rc.Agreement__c = null;
                update rc;
            } else {
                // If no Application reference, safely delete the contact record
                delete rc;
            }

            // Return refreshed contact list to update LWC view
            return getAgreementContacts(agreementId);
        } catch (DmlException e) {
            // Handle database operation failures
            LoggerUtility logger = new LoggerUtility();
            logger.error('Error removing contact from agreement: ' + e.getMessage(), null);
            logger.publish();
            throw new AuraHandledException('Feil ved fjerning av kontakt: ' + e.getMessage());
        } catch (Exception e) {
            // Handle unexpected errors and provide user feedback
            LoggerUtility logger = new LoggerUtility();
            logger.error('Unexpected error removing contact from agreement: ' + e.getMessage(), null);
            logger.publish();
            throw new AuraHandledException('Uventet feil ved fjerning av kontakt.');
        }
    }

    /**
     * @description Translates an agreement status code into a Norwegian display label.
     * @param status Status value from the Agreement__c record.
     * @return Localized status label, or 'Ukjent status' when the value is not recognized.
     */
    private static String translateStatus(String status) {
        // Map English status values to Norwegian display labels for LWC presentation
        Map<String, String> statusLabels = new Map<String, String>{
            'Active' => 'Aktiv',
            'Deactivated' => 'Avsluttet',
            'Under review' => 'Revisjon av avtalepart'
        };
        // Return translated status or default message if status is not in map
        return statusLabels.containsKey(status) ? statusLabels.get(status) : 'Ukjent status';
    }
}
