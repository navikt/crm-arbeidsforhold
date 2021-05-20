public without sharing class AAREG_ApplicationController {
  @AuraEnabled(cacheable=true)
  public static Account getLastUsedOrganizationInformation(String userId) {
    User currentUser = [SELECT Id, LastUsedOrganization__c FROM USER WHERE Id = :userId];
    Account lastUsedOrganization = [
      SELECT
        Id,
        Name,
        INT_OrganizationNumber__c,
        INT_OrganizationalStructure__c,
        AAREG_OrganizationCategory__c,
        ShippingStreet,
        ShippingPostalCode,
        ShippingCity
      FROM Account
      WHERE INT_OrganizationNumber__c = :currentUser.LastUsedOrganization__c
    ];

    return lastUsedOrganization;
  }

  @AuraEnabled
  public static string getAccountNameByOrgNumber(String orgNumber) {
    String accountName = '';
    accountName = [
      SELECT Id, Name, INT_OrganizationNumber__c
      FROM Account
      WHERE INT_OrganizationNumber__c = :orgNumber
      LIMIT 1
    ]
    .Name;
    return accountName;
  }

  @AuraEnabled
  public static void processApplication(
    Application__c application,
    ApplicationBasisCode__c[] basisCode,
    RelatedContact__c[] relatedContacts,
    Id contentVersionId
  ) {
    application.Casehandler_Status__c = 'New';
    try {
      insert application;
      generateContentDocumentLink(application.Id, contentVersionId);
      insertRelatedContacts(application.Id, relatedContacts);
      insertBasisCodes(application.Id, basisCode);
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }

  private static void insertRelatedContacts(Id applicationId, RelatedContact__c[] relatedContacts) {
    for (RelatedContact__c contact : relatedContacts) {
      contact.Application__c = applicationId;
    }
    insert relatedContacts;
  }

  private static void insertBasisCodes(Id applicationId, ApplicationBasisCode__c[] basisCodes) {
    for (ApplicationBasisCode__c code : basisCodes) {
      code.Application__c = applicationId;
    }
    insert basisCodes;
  }

  private static void generateContentDocumentLink(Id applicationId, Id contentVersionId) {
    ContentVersion version = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :contentVersionId];

    ContentDocumentLink documentLink = new ContentDocumentLink();
    documentLink.LinkedEntityId = applicationId;
    documentLink.ContentDocumentId = version.ContentDocumentId;
    documentLink.ShareType = 'I';

    insert documentLink;
  }
}
