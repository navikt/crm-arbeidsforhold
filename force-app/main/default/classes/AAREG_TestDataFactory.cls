@isTest
public with sharing class AAREG_TestDataFactory {
  public static Application__c getApplication(Id accountId) {
    Application__c application = new Application__c(
      Account__c = accountId,
      Casehandler_Status__c = 'New',
      AA_register_application_text__c = 'Test',
      AA_DecisionArchiveText__c = 'Test',
      IsConfirmationEmailSent__c = true,
      AccountName__c = 'Test Account',
      OrganizationNumber__c = '123456789',
      MailingAddress__c = 'Test 123',
      MailingCity__c = 'Oslo',
      MailingPostalCode__c = '0234',
      ApplicationSubmittedDate__c = Date.today(),
      DecisionDate__c = Date.today()
    );
    return application;
  }

  public static Inquiry__c getInquiry() {
    Inquiry__c inquiry = new Inquiry__c(
      InquiryDescription__c = 'Test Description',
      Status__c = 'New',
      TypeOfInquiry__c = 'Technical questions'
    );
    return inquiry;
  }

  public static Account getAccount() {
    Account acct = new Account(
      Name = 'Test',
      INT_OrganizationNumber__c = '123456789',
      INT_OrganizationalStructure__c = 'ORGL',
      ShippingStreet = 'Test 123',
      ShippingPostalCode = '0211',
      ShippingCity = 'Oslo'
    );
    return acct;
  }

  public static User getStandardUser() {
    Profile profile = [SELECT Id, UserLicense.Name FROM Profile WHERE Name = 'Standard User' LIMIT 1];
    User user = new User(
      FirstName = 'John',
      LastName = 'Doe',
      Email = 'John.Doe@nav.no',
      Username = 'John.Doe@nav.no',
      Alias = 'j.doe',
      LanguageLocaleKey = 'no',
      LocaleSidKey = 'no_NO',
      TimeZoneSidKey = 'Europe/Paris',
      EmailEncodingKey = 'UTF-8',
      ProfileId = profile.Id,
      Department = '1',
      LastUsedOrganization__c = '123456789',
      CRM_NAV_Ident__c = 'test123'
    );
    return user;
  }

  public static ContentVersion getContentVersion() {
    String data = 'Test Data';
    ContentVersion contentVersion = new ContentVersion(
      VersionData = EncodingUtil.base64Decode(data),
      Title = 'TestFile.html',
      PathOnClient = 'Test File'
    );
    return contentVersion;
  }

  public static ContentDocumentLink getContentDocumentLink(Id contentDocumentId, Id linkedEntity) {
    ContentDocumentLink documentLink = new ContentDocumentLink(
      LinkedEntityId = linkedEntity,
      ContentDocumentId = contentDocumentId,
      ShareType = 'I'
    );
    return documentLink;
  }

  public static ContentDocumentLink getContentDocumentLink(Id linkedEntity) {
    ContentVersion content = getContentVersion();
    insert content;

    ContentVersion version = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :content.Id];

    return getContentDocumentLink(version.ContentDocumentId, linkedEntity);
  }
}
