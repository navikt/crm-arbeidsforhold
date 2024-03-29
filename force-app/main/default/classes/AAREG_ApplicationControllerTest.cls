@isTest
public class AAREG_ApplicationControllerTest {
  @TestSetup
  static void makeData() {
    Account acct = new Account();
    acct.Name = 'Test';
    acct.INT_OrganizationNumber__c = '123456789';
    acct.INT_OrganizationalStructure__c = 'ORGL';
    acct.ShippingStreet = 'Test 123';
    acct.ShippingPostalCode = '0211';
    acct.ShippingCity = 'Oslo';
    insert acct;
  }

  @isTest
  static void getAccountNameByOrgNumber() {
    String accountName = AAREG_ApplicationController.getAccountNameByOrgNumber('123456789');
    System.assertEquals('Test', accountName, 'Assert that correct account name is returned');
  }

  @isTest
  static void processNewApplication() {
    Account account = [SELECT Id, Name FROM Account LIMIT 1];

    Application__c application = new Application__c();
    application.Account__c = account.Id;
    application.IsConfirmationEmailSent__c = true;

    List<RelatedContact__c> contacts = new List<RelatedContact__c>();
    contacts.add(new RelatedContact__c(name = 'Test Contact 1'));
    contacts.add(new RelatedContact__c(name = 'Test Contact 2'));

    List<ApplicationBasisCode__c> basisCodes = new List<ApplicationBasisCode__c>();
    basisCodes.add(new ApplicationBasisCode__c());
    basisCodes.add(new ApplicationBasisCode__c());

    String base64 = 'sdkldsfjlcm';
    String fileName = 'Test file name';
    Id processedApplicationId = AAREG_ApplicationController.processApplication(application, basisCodes, contacts, base64, fileName);
    List<Application__c> processedApplications = [SELECT Id, Casehandler_Status__c FROM Application__c WHERE Id = :processedApplicationId];
    List<RelatedContact__c> processedContacts = [SELECT Id, Name, Application__c FROM RelatedContact__c];
    List<ApplicationBasisCode__c> processedBasisCodes = [SELECT Id, Application__c FROM ApplicationBasisCode__c];
    List<ContentDocumentLink> documentLink = [
      SELECT Id
      FROM ContentDocumentLink
      WHERE LinkedEntityId = :processedApplications[0].Id
    ];

    System.assertEquals(1, processedApplications.size(), 'Check only one application was inserted');
    System.assertEquals(2, processedContacts.size(), 'Check that both contacts were inserted');
    System.assertEquals(2, processedBasisCodes.size(), 'Check that both Application Basis Codes were inserted');
    System.assertEquals('New', processedApplications[0].Casehandler_Status__c, 'Assert correct application status');
    System.assertEquals(1, documentLink.size(), 'Assert successful documentLink');
  }

  @isTest
  static void processAdditionalInformationApplication() {
    Account account = [SELECT Id, Name FROM Account LIMIT 1];

    Application__c application = new Application__c();
    application.Account__c = account.Id;
    application.Status__c = 'Additional Information Required';
    application.IsConfirmationEmailSent__c = true;

    List<RelatedContact__c> contacts = new List<RelatedContact__c>();
    contacts.add(new RelatedContact__c(name = 'Test Contact 1'));
    contacts.add(new RelatedContact__c(name = 'Test Contact 2'));

    List<ApplicationBasisCode__c> basisCodes = new List<ApplicationBasisCode__c>();
    basisCodes.add(new ApplicationBasisCode__c());
    basisCodes.add(new ApplicationBasisCode__c());

    String base64 = null;
    String fileName = null;

    AAREG_ApplicationController.processApplication(application, basisCodes, contacts, base64, fileName);
    List<Application__c> processedApplications = [SELECT Id, Status__c, Casehandler_Status__c FROM Application__c];
    List<RelatedContact__c> processedContacts = [SELECT Id, Name, Application__c FROM RelatedContact__c];
    List<ApplicationBasisCode__c> processedBasisCodes = [SELECT Id, Application__c FROM ApplicationBasisCode__c];
    List<ContentDocumentLink> documentLink = [
      SELECT Id
      FROM ContentDocumentLink
      WHERE LinkedEntityId = :processedApplications[0].Id
    ];

    System.assertEquals(1, processedApplications.size(), 'Check only one application was upserted');
    System.assertEquals(2, processedContacts.size(), 'Check that both contacts were upserted');
    System.assertEquals(2, processedBasisCodes.size(), 'Check that both Application Basis Codes were upserted');
    System.assertEquals('In Progress', processedApplications[0].Status__c, 'Correct application status');
    System.assertEquals('In Progress', processedApplications[0].Casehandler_Status__c, 'Correct application status');
    System.assertEquals(true, documentLink.isEmpty(), 'No documentLinks created');
  }

  @isTest
  static void saveAsDraft() {
    Account account = [SELECT Id, Name FROM Account LIMIT 1];

    Application__c application = new Application__c();
    application.Account__c = account.Id;
    application.IsConfirmationEmailSent__c = true;

    List<RelatedContact__c> contacts = new List<RelatedContact__c>();
    contacts.add(new RelatedContact__c(name = 'Test Contact 1'));
    contacts.add(new RelatedContact__c(name = 'Test Contact 2'));

    List<ApplicationBasisCode__c> basisCodes = new List<ApplicationBasisCode__c>();
    basisCodes.add(new ApplicationBasisCode__c());
    basisCodes.add(new ApplicationBasisCode__c());

    AAREG_ApplicationController.saveAsDraft(application, basisCodes, contacts, null, null);
    Application__c processedApplication = [SELECT Id, Status__c FROM Application__c LIMIT 1];
    List<RelatedContact__c> processedContacts = [
      SELECT Id, Name, Application__c
      FROM RelatedContact__c
      WHERE Application__c = :processedApplication.Id
    ];
    List<ApplicationBasisCode__c> processedBasisCodes = [
      SELECT Id, Application__c
      FROM ApplicationBasisCode__c
      WHERE Application__c = :processedApplication.Id
    ];

    System.assertEquals(2, processedContacts.size(), 'Check that both contacts were inserted');
    System.assertEquals(2, processedBasisCodes.size(), 'Check that both Application Basis Codes were inserted');
    System.assertEquals('Draft', processedApplication.Status__c, 'Assert correct application status');
  }

  @isTest
  static void getLastUsedOrganizationInformation() {
    Profile profile = [SELECT Id, UserLicense.Name FROM Profile WHERE Name = 'Standard User' LIMIT 1];
    User user = new User();

    user.FirstName = 'John';
    user.LastName = 'Doe';
    user.Email = 'John.Doe@nav.no';
    user.Username = 'John.Doe@nav.no';
    user.Alias = 'j.doe';
    user.LanguageLocaleKey = 'no';
    user.LocaleSidKey = 'no_NO';
    user.TimeZoneSidKey = 'Europe/Paris';
    user.EmailEncodingKey = 'UTF-8';
    user.ProfileId = profile.Id;
    user.Department = '1';
    user.LastUsedOrganization__c = '123456789';

    insert user;

    Account lastUsedOrganization = AAREG_ApplicationController.getLastUsedOrganizationInformation(user.id);

    System.assertEquals(lastUsedOrganization.name, 'Test', 'Assert that the correct account name is returned.');
  }

  @isTest
  static void getDraftApplication() {
    Profile profile = [SELECT Id, UserLicense.Name FROM Profile WHERE Name = 'Standard User' LIMIT 1];
    User user = AAREG_TestDataFactory.getStandardUser();
    insert user;

    Account account = [SELECT Id, Name FROM Account LIMIT 1];

    Application__c application = AAREG_TestDataFactory.getApplication(account.Id);
    insert application;

    List<RelatedContact__c> contacts = new List<RelatedContact__c>();
    contacts.add(new RelatedContact__c(application__c = application.Id, name = 'Test Contact 1'));
    contacts.add(new RelatedContact__c(application__c = application.Id, name = 'Test Contact 2'));
    insert contacts;

    List<ApplicationBasisCode__c> basisCodes = new List<ApplicationBasisCode__c>();
    basisCodes.add(new ApplicationBasisCode__c(application__c = application.Id));
    basisCodes.add(new ApplicationBasisCode__c(application__c = application.Id));
    insert basisCodes;

    AAREG_ApplicationController.DraftApplication draft = AAREG_ApplicationController.getDraftApplication(
      application.Id
    );
    System.assertEquals(application.Id, draft.application.Id, 'Draft application retrieved');
    System.assertEquals(2, draft.basisCodes.size(), '2 draft basis codes retrieved');
    System.assertEquals(2, draft.contacts.size(), '2 draft related contacts retrieved');
  }

  @isTest
  static void deleteDraftRecord() {
    Account account = [SELECT Id, Name FROM Account LIMIT 1];

    Application__c application = AAREG_TestDataFactory.getApplication(account.Id);
    insert application;

    AAREG_ApplicationController.deleteDraftRecord(application);

    List<Application__c> applications = [SELECT Id FROM Application__c];

    System.assertEquals(0, applications.size(), 'No applications. Successful record deletion.');
  }
}
