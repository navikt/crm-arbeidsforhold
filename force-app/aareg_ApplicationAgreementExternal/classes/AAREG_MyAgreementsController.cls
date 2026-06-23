/**
 * @description Controller for the "My Agreements" LWC. Returns the agreements
 * belonging to the organization the user last selected.
 */
public with sharing class AAREG_MyAgreementsController {
  /**
   * @description Returns active agreements for the organization last used by the given user.
   * @param userId Id of the user whose last used organization should be looked up.
   * @return List of AAREG_Agreement wrappers; empty list when no organization is set.
   */
  @AuraEnabled(cacheable=true)
  public static List<AAREG_Agreement> getUsersAgreements(String userId) {
    String lastUsedOrganization = [SELECT Id, LastUsedOrganization__c FROM User WHERE Id = :userId WITH USER_MODE]
    ?.LastUsedOrganization__c;

    if (lastUsedOrganization != null) {
      return getAgreements(lastUsedOrganization);
    } else {
      return new List<AAREG_Agreement>();
    }
  }

  /**
   * @description Queries active agreements for the given organization number and maps
   * them to AAREG_Agreement wrappers.
   * @param lastUsedOrganization Organization number to filter agreements by.
   * @return List of AAREG_Agreement wrappers for active agreements.
   */
  private static List<AAREG_Agreement> getAgreements(String lastUsedOrganization) {
    List<AAREG_Agreement> agreementWrapperTempList = new List<AAREG_Agreement>();

    List<Agreement__c> agreements = [
      SELECT Id,CreatedDate, Name, Status__c, Application__c
      FROM Agreement__c
      WHERE OrganizationNumber__c = :lastUsedOrganization
      WITH USER_MODE
    ];

    if (agreements != null) {
      for (Agreement__c agg : agreements) {
        AAREG_Agreement tempList = new AAREG_Agreement();
        tempList.avtaleId = agg.Id;
        tempList.avtaleDato = agg.CreatedDate;
        tempList.avtaleNummer = agg.Name;
        tempList.soknadsNummer = agg.Application__c;
        tempList.status = translateStatus(agg.Status__c);
        agreementWrapperTempList.add(tempList);
      }
    }

    return agreementWrapperTempList;
  }

  @AuraEnabled
public static List<RelatedContact__c> saveAgreementContacts(
    Id currentRecordId,
    List<RelatedContact__c> contacts
) {
    if (currentRecordId == null) {
        throw new AuraHandledException('Avtale-id mangler.');
    }
    if (contacts == null || contacts.isEmpty()) {
        return getAgreementContacts(currentRecordId);
    }

    // Sørg for at alle peker på avtalen
    for (RelatedContact__c rc : contacts) {
        rc.Agreement__c = currentRecordId;
    }

    upsert contacts;
    return getAgreementContacts(currentRecordId);
}

@AuraEnabled
public static void deleteAgreementContact(Id contactId) {
    if (contactId == null) {
        throw new AuraHandledException('Kontaktperson-id mangler.');
    }

    RelatedContact__c rc = [
        SELECT Id, Application__c
        FROM RelatedContact__c
        WHERE Id = :contactId
        WITH USER_MODE
        LIMIT 1
    ];

    if (rc.Application__c != null) {
        // Har lookup til Application – ikke slett, bare fjern avtale-koblingen
        rc.Agreement__c = null;
        update rc;
    } else {
        delete rc;
    }
}

  /**
   * @description Sets the agreement status to inactive/Avsluttet without deleting it.
   * @param agreementId Id of the Agreement__c record to deactivate.
   */
  @AuraEnabled
  public static void endAgreement(Id agreementId) {
    if (agreementId == null) {
      throw new AuraHandledException('AvtaleId mangler.');
    }

    if (!Schema.sObjectType.Agreement__c.isUpdateable()) {
      throw new AuraHandledException('Ingen tilgang til å oppdatere avtalen.');
    }

    Agreement__c agreement = [
      SELECT Id, Status__c
      FROM Agreement__c
      WHERE Id = :agreementId
      WITH USER_MODE
      LIMIT 1
    ];

    agreement.Status__c = 'Deactivated';
    update agreement;
  }

   /**
   * @description Returns all related contacts for the agreement.
   * @param currentRecordId Id of the Agreement record.
   * @return List of RelatedContact__c records with all fields used by the contact LWC.
   */
  @AuraEnabled(cacheable=true)
  public static List<RelatedContact__c> getAgreementContacts(Id currentRecordId) {
    return [
      SELECT Id, Name, Email__c, Phone__c, Application__c, Agreement__c,
      ChangeNotifications__c, SecurityNotifications__c,
      ErrorMessageNotifications__c, AgreementNotifications__c
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
    if (agreementId == null || String.isBlank(name)) {
        throw new AuraHandledException('Avtale og navn er påkrevd.');
    }

    RelatedContact__c rc = new RelatedContact__c(
        Name = name,
        Email__c = email,
        Phone__c = phone,
        Agreement__c = agreementId,
        ChangeNotifications__c = changeNotifications == true,
        SecurityNotifications__c = securityNotifications == true,
        ErrorMessageNotifications__c = errorMessageNotifications == true,
        AgreementNotifications__c = agreementNotifications == true
    );
    insert rc;

    return getAgreementContacts(agreementId);
}

@AuraEnabled
public static List<RelatedContact__c> removeContactFromAgreement(
    Id relatedContactId,
    Id agreementId
) {
    if (relatedContactId == null) {
        throw new AuraHandledException('Kontaktperson-id mangler.');
    }

    RelatedContact__c rc = [
        SELECT Id, Application__c, Agreement__c
        FROM RelatedContact__c
        WHERE Id = :relatedContactId
        LIMIT 1
    ];

    if (rc.Application__c != null) {
        // Har lookup til Application -> bare fjern koblingen til Agreement
        rc.Agreement__c = null;
        update rc;
    } else {
        // Ingen Application-kobling -> slett posten
        delete rc;
    }

    return getAgreementContacts(agreementId);
}

  /**
   * @description Translates an agreement status code into a Norwegian display label.
   * @param status Status value from the Agreement__c record.
   * @return Localized status label, or 'Ukjent status' when the value is not recognized.
   */
  private static String translateStatus(String status) {
    Map<String, String> statusLabels = new Map<String, String>{
      'Active' => 'Aktiv',
      'Deactivated' => 'Avsluttet',
      'Under review' => 'Revisjon av avtalepart'
    };
    return statusLabels.containsKey(status) ? statusLabels.get(status) : 'Ukjent status';
  }
}