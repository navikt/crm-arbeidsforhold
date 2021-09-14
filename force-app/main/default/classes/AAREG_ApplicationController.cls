public without sharing class AAREG_ApplicationController {
  private static final String ADDITIONAL_INFORMATION = 'Additional Information Required';
  private static final String DRAFT_APPLICATION = 'Draft';
  private static final String NEW_APPLICATION = 'New';
  private static final String IN_PROGRESS = 'In Progress';

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
    String accountName = [
      SELECT Id, Name, INT_OrganizationNumber__c
      FROM Account
      WHERE INT_OrganizationNumber__c = :orgNumber
      LIMIT 1
    ]
    ?.Name;

    return accountName;
  }

  @AuraEnabled
  public static DraftApplication getDraftApplication(String recordId) {
    return new DraftApplication(getApplication(recordId), getBasisCodes(recordId), getRelatedContacts(recordId));
  }

  @AuraEnabled
  public static Id saveAsDraft(
    Application__c application,
    List<ApplicationBasisCode__c> basisCode,
    List<RelatedContact__c> relatedContacts
  ) {
    if (application.Status__c != ADDITIONAL_INFORMATION) {
      application.status__c = DRAFT_APPLICATION;
    }

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
  public static Id processApplication(
    Application__c application,
    List<ApplicationBasisCode__c> basisCode,
    List<RelatedContact__c> relatedContacts,
    String base64,
    String fileName
  ) {
    if (application.Status__c != ADDITIONAL_INFORMATION) {
      application.Casehandler_Status__c = NEW_APPLICATION;
      application.status__c = NEW_APPLICATION;
    } else {
      application.AA_ApplicationArchived__c = false;
      application.Casehandler_Status__c = IN_PROGRESS;
      application.status__c = IN_PROGRESS;
    }

    try {
      upsert application;
      upsertRelatedContacts(application.Id, relatedContacts);
      upsertBasisCodes(application.Id, basisCode);
      insertDocumentWithLink(application.Id, base64, fileName);
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
    return application.Id;
  }

  @AuraEnabled
  public static void deleteDraftRecord(SObject record) {
    try {
      delete record;
    } catch (Exception ex) {
      throw new AuraHandledException(ex.getMessage());
    }
  }

  private static void upsertRelatedContacts(Id applicationId, List<RelatedContact__c> relatedContacts) {
    for (RelatedContact__c contact : relatedContacts) {
      contact.Application__c = applicationId;
    }
    upsert relatedContacts;
  }

  private static void upsertBasisCodes(Id applicationId, List<ApplicationBasisCode__c> basisCodes) {
    for (ApplicationBasisCode__c code : basisCodes) {
      code.Application__c = applicationId;
    }
    upsert basisCodes;
  }

  private static void insertDocumentWithLink(Id applicationId, String base64, String fileName) {
    if (base64 == null || fileName == null) {
      return;
    }
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
        Status__c,
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
