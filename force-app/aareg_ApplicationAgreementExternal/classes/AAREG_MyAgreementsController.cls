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

  /**
   * @description Upserts the contact list for an application (used by the "Se kontaktpersoner" modal).
   * @param currentRecordId Id of the Agreement the contacts belong to.
   * @param contacts List of RelatedContact__c records to upsert.
   */
  @AuraEnabled
  public static void saveAgreementContacts(Id currentRecordId, List<RelatedContact__c> contacts) {
    if (contacts == null || contacts.isEmpty()) {
      return;
    }
    for (RelatedContact__c c : contacts) {
      c.Agreement__c = currentRecordId;
    }
    if (Schema.sObjectType.RelatedContact__c.isCreateable() && Schema.sObjectType.RelatedContact__c.isUpdateable()) {
        upsert contacts;
    } else {
        throw new AuraHandledException('Insufficient permissions to modify RelatedContact__c records.');
    }
  }

  /**
   * @description Deletes a single related contact.
   * @param contactId Id of the RelatedContact__c to delete.
   */
  @AuraEnabled
  public static void deleteAgreementContact(Id contactId) {
    if (contactId == null) {
      return;
    }
    delete [SELECT Id FROM RelatedContact__c WHERE Id = :contactId];
  }

   /**
   * @description Returns all related contacts for the agreement.
   * @param currentRecordId Id of the Agreement record.
   * @return List of RelatedContact__c records with all fields used by the contact LWC.
   */
  @AuraEnabled(cacheable=true)
  public static List<RelatedContact__c> getAgreementContacts(Id currentRecordId) {
    return [
      SELECT Id, Name, Phone__c, Email__c,
             AgreementNotifications__c, ChangeNotifications__c,
             ErrorMessageNotifications__c, SecurityNotifications__c,
             Agreement__c
      FROM RelatedContact__c
      WHERE Agreement__c = :currentRecordId
      WITH USER_MODE
    ];
  }

  /**
   * @description Translates an agreement status code into a Norwegian display label.
   * @param status Status value from the Agreement__c record.
   * @return Localized status label, or 'Ukjent status' when the value is not recognized.
   */
  private static String translateStatus(String status) {
    Map<String, String> statusLabels = new Map<String, String>{
      'Active' => 'Aktiv',
      'Deactivated' => 'Avsluttet'
    };
    return statusLabels.containsKey(status) ? statusLabels.get(status) : 'Ukjent status';
  }
}