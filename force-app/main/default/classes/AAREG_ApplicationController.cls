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
    String base64,
    String fileName //Id contentVersionId
  ) {
    application.Casehandler_Status__c = 'New';
    try {
      insert application;
      insertDocumentWithLink(application.Id, base64, fileName);
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

  private static void insertDocumentWithLink(Id applicationId, String base64, String fileName) {
    ContentVersion cv = generateContentVersion(base64, filename);
    generateContentDocumentLink(applicationId, cv.Id);
  }

  private static ContentVersion generateContentVersion(String base64, String filename) {
    ContentVersion cv = new ContentVersion();
    cv.VersionData = EncodingUtil.base64Decode(base64);
    cv.Title = filename;
    cv.PathOnClient = filename;
    insert cv;
    return cv;
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
