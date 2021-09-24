public with sharing class AAREG_AgreementController {
  @AuraEnabled(cacheable=true)
  public static List<RelatedContact__c> getAgreementContacts(String recordId) {
    List<RelatedContact__c> contacts = new List<RelatedContact__c>();
    try {
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
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
    return contacts;
  }
}
