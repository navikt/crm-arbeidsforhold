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
    ?.Name;
    return accountName;
  }

  @AuraEnabled
  public static Id saveAsDraft(
    Application__c application,
    ApplicationBasisCode__c[] basisCode,
    RelatedContact__c[] relatedContacts
  ) {
    application.status__c = 'Draft';
    try {
      upsert application;
      upsertRelatedContacts(application.Id, relatedContacts);
      upsertBasisCodes(application.Id, basisCode);
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
    return application.Id;
  }

  @AuraEnabled
  public static void processApplication(
    Application__c application,
    ApplicationBasisCode__c[] basisCode,
    RelatedContact__c[] relatedContacts,
    String base64,
    String fileName
  ) {
    application.Casehandler_Status__c = 'New';
    application.status__c = 'New';
    try {
      upsert application;
      insertDocumentWithLink(application.Id, base64, fileName);
      upsertRelatedContacts(application.Id, relatedContacts);
      upsertBasisCodes(application.Id, basisCode);
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }

  @AuraEnabled
  public static void deleteDraftRecord(SObject record) {
    try {
      delete record;
    } catch (Exception ex) {
      throw new AuraHandledException(ex.getMessage());
    }
  }

  @AuraEnabled
  public static DraftApplication getDraftApplication(String recordId) {
    return new DraftApplication(getApplication(recordId), getBasisCodes(recordId), getRelatedContacts(recordId));
  }

  private static void upsertRelatedContacts(Id applicationId, RelatedContact__c[] relatedContacts) {
    for (RelatedContact__c contact : relatedContacts) {
      contact.Application__c = applicationId;
    }
    upsert relatedContacts;
  }

  private static void upsertBasisCodes(Id applicationId, ApplicationBasisCode__c[] basisCodes) {
    for (ApplicationBasisCode__c code : basisCodes) {
      code.Application__c = applicationId;
    }
    upsert basisCodes;
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

  private static Application__c getApplication(Id applicationId) {
    return [
      SELECT
        Id,
        AA_isPortalUserEditable__c,
        Email__c,
        DataProcessorName__c,
        APIAccess__c,
        ExtractionAccess__c,
        OnlineAccess__c,
        DataProcessorOrganizationNumber__c,
        TermsOfUse__c
      FROM Application__c
      WHERE Id = :applicationId
    ];
  }

  private static List<RelatedContact__c> getRelatedContacts(Id applicationId) {
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
      WHERE Application__c = :applicationId
    ];
  }

  private static List<ApplicationBasisCode__c> getBasisCodes(Id applicationId) {
    return [
      SELECT
        Id,
        OtherLegalBasis__c,
        OtherPurpose__c,
        ProcessingBasis__c,
        PurposeMunicipality__c,
        LegalBasisMunicipality__c,
        PurposeCounty__c,
        LegalBasisCounty__c,
        PurposeState__c,
        LegalBasisState__c,
        PurposeElectricitySupervision__c,
        LegalBasisElectricitySupervision__c,
        PurposePension__c,
        LegalBasisPension__c
      FROM ApplicationBasisCode__c
      WHERE Application__c = :applicationId
    ];
  }

  public class DraftApplication {
    @AuraEnabled
    public Application__c application;
    @AuraEnabled
    public List<ApplicationBasisCode__c> basisCodes;
    @AuraEnabled
    public List<RelatedContact__c> contacts;

    public DraftApplication(
      Application__c application,
      List<ApplicationBasisCode__c> basisCodes,
      List<RelatedContact__c> contacts
    ) {
      this.application = application;
      this.basisCodes = basisCodes;
      this.contacts = contacts;
    }
  }
}
