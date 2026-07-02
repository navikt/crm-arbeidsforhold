/**
 * Controller for internal agreement maintenance in the AAREG application.
 *
 * Provides methods used by the agreement LWC to read related contacts,
 * update agreements, and cancel agreements.
 */
public with sharing class AAREG_AgreementController {
  /**
   * Returns related contact records for a given agreement.
   *
   * @param agreementId The Agreement__c Id to load contacts for.
   * @return List of related contacts for the agreement.
   */
  @AuraEnabled(cacheable=true)
  public static List<RelatedContact__c> getAgreementContacts(Id agreementId) {
    if (agreementId == null) {
      return new List<RelatedContact__c>();
    }

    if (!Schema.sObjectType.RelatedContact__c.isAccessible()) {
      return new List<RelatedContact__c>();
    }

    return [
      SELECT
        Id,
        Name,
        Phone__c,
        Email__c,
        AgreementNotifications__c,
        ChangeNotifications__c,
        ErrorMessageNotifications__c,
        SecurityNotifications__c
      FROM RelatedContact__c
      WHERE Agreement__c = :agreementId
      WITH USER_MODE
    ];
  }

  /**
   * Updates the Agreement__c record and its related contacts.
   *
   * @param agreement The agreement record to update.
   * @param contacts The related contacts to insert/update.
   * @param contactsToDelete The related contacts to delete.
   */
  @AuraEnabled
  public static void updateAgreement(
    Agreement__c agreement,
    List<RelatedContact__c> contacts,
    List<RelatedContact__c> contactsToDelete
  ) {
    if (agreement == null || agreement.Id == null) {
      throw new AuraHandledException('Agreement Id is required.');
    }

    if (!Schema.sObjectType.Agreement__c.isUpdateable()) {
      throw new AuraHandledException('Ingen tilgang til å oppdatere avtalen.');
    }

    if (contacts == null) {
      contacts = new List<RelatedContact__c>();
    }

    if (contactsToDelete == null) {
      contactsToDelete = new List<RelatedContact__c>();
    }

    if (!contacts.isEmpty()) {
      Boolean canCreate = Schema.sObjectType.RelatedContact__c.isCreateable();
      Boolean canUpdate = Schema.sObjectType.RelatedContact__c.isUpdateable();

      for (RelatedContact__c contact : contacts) {
        if (contact.Id == null && !canCreate) {
          throw new AuraHandledException('Ingen tilgang til å opprette kontaktpersoner.');
        }
        if (contact.Id != null && !canUpdate) {
          throw new AuraHandledException('Ingen tilgang til å oppdatere kontaktpersoner.');
        }
      }
    }

    if (!contactsToDelete.isEmpty() && !Schema.sObjectType.RelatedContact__c.isDeletable()) {
      throw new AuraHandledException('Ingen tilgang til å slette kontaktpersoner.');
    }

    for (RelatedContact__c con : contacts) {
      con.Agreement__c = agreement.Id;
    }

    update agreement;

    if (!contacts.isEmpty()) {
      upsert contacts;
    }

    if (!contactsToDelete.isEmpty()) {
      delete contactsToDelete;
    }
  }

  /**
   * Cancels the agreement by disabling access flags and setting the status.
   *
   * @param agreement The agreement record to cancel.
   */
  @AuraEnabled
  public static void cancelAgreement(Agreement__c agreement) {
    if (agreement == null || agreement.Id == null) {
      throw new AuraHandledException('Agreement Id is required.');
    }

    if (!Schema.sObjectType.Agreement__c.isUpdateable()) {
      throw new AuraHandledException('Ingen tilgang til å oppdatere avtalen.');
    }

    agreement.Status__c = 'Deactivated';
    agreement.OnlineAccess__c = false;
    agreement.ExtractionAccess__c = false;
    agreement.APIAccess__c = false;
    agreement.AA_ConfirmedAgreementCancellationDate__c = System.today();
    agreement.isAccessDeactivationThroughFlow__c = false;
    agreement.isDeactivateThroughBatch__c = false;
    agreement.isNoDeactivationAccess__c = false;

    update agreement;
  }
}