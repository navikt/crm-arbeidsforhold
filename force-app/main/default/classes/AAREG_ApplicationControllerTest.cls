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
  static void testGetAccountNameByOrgNumber() {
    String accountName = AAREG_ApplicationController.getAccountNameByOrgNumber('123456789');

    System.assertEquals('Test', accountName);
  }

  @isTest
  static void testProcessNewApplication() {
    Account account = [SELECT Id, Name FROM Account LIMIT 1];

    Application__c application = new Application__c();
    application.Account__c = account.Id;

    List<RelatedContact__c> contacts = new List<RelatedContact__c>();
    contacts.add(new RelatedContact__c(name = 'Test Contact 1'));
    contacts.add(new RelatedContact__c(name = 'Test Contact 2'));

    List<ApplicationBasisCode__c> basisCodes = new List<ApplicationBasisCode__c>();
    basisCodes.add(new ApplicationBasisCode__c());
    basisCodes.add(new ApplicationBasisCode__c());

    AAREG_ApplicationController.processApplication(application, basisCodes, contacts);
    List<Application__c> processedApplications = [SELECT Id FROM Application__c];
    List<RelatedContact__c> processedContacts = [SELECT Id, Name, Application__c FROM RelatedContact__c];
    List<ApplicationBasisCode__c> processedBasisCodes = [SELECT Id, Application__c FROM ApplicationBasisCode__c];

    System.assertEquals(1, processedApplications.size(), 'Check only one application was inserted');
    System.assertEquals(2, processedContacts.size(), 'Check that both contacts were inserted');
    System.assertEquals(2, processedBasisCodes.size(), 'Check that both Application Basis Codes were inserted');
  }

  @isTest
  static void testGetLastUsedOrganizationInformation() {
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

    System.assertEquals(lastUsedOrganization.name, 'Test');
  }
}
