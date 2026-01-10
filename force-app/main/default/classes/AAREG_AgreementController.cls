public with sharing class AAREG_AgreementController {
  @AuraEnabled(cacheable=true)
  public static List<RelatedContact__c> getAgreementContacts(String recordId) {
    List<RelatedContact__c> contacts = new List<RelatedContact__c>();
    try{

        contacts = [
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
          WHERE Agreement__c = :recordId
        ];

    return contacts;
  }catch (Exception e) {
  throw new AuraHandledException(e.getMessage());
}
  }

  @AuraEnabled
  public static void updateAgreement(
    Agreement__c agreement,
    List<RelatedContact__c> contacts,
    List<RelatedContact__c> contactsToDelete
  ) {
    try {
      for (RelatedContact__c con : contacts) {
        con.Agreement__c = agreement.Id;
      }
      update agreement;
      upsert contacts;
      delete contactsToDelete;
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }

  @AuraEnabled
  public static void cancelAgreement(Agreement__c agreement) {
    try {
      agreement.Status__c = 'Deactivated';
      agreement.OnlineAccess__c = false;
      agreement.ExtractionAccess__c = false;
      agreement.APIAccess__c = false;
      agreement.AA_ConfirmedAgreementCancellationDate__c = System.today();
      agreement.isAccessDeactivationThroughFlow__c = false;
      agreement.isDeactivateThroughBatch__c = false;
      agreement.isNoDeactivationAccess__c = false;
      update agreement;
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }
}