@isTest
public with sharing class AAREG_HomeControllerTest {
  @TestSetup
  static void makeData() {
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
  }

  @isTest
  private static void testGetOrganizationsWithRoles() {
    User user = [SELECT Id FROM USER WHERE Username = 'John.Doe@nav.no' LIMIT 1];
    ApiMock.setTestMock('GET_ALTINN_ORGANIZATIONS', 200, 'OK');

    Test.startTest();
    AltinnCalloutService.AltinnOrganizationsResponse response = AAREG_HomeController.getOrganizationsWithRoles(user.Id);
    Test.stopTest();

    System.assertEquals(true, response.success, 'Expect success');
    System.assertEquals(null, response.errorMessage, 'Expect no error message');
    System.assertEquals(18, response.organizations.size(), 'Expect 18 organaizations');
  }

  @isTest
  private static void testGetLastUsedOrganizationNumber() {
    User user = [SELECT Id FROM USER WHERE Username = 'John.Doe@nav.no' LIMIT 1];

    String lastUsedOrganizationNumber = AAREG_HomeController.getLastUsersLastUsedOrganization(user.Id);

    System.assertEquals('123456789', lastUsedOrganizationNumber, 'Last used organization number returned correctly.');
  }

  @isTest
  private static void testUpdateLastUsedOrganization() {
    String orgNumber = '999999999';
    User user = [SELECT Id FROM USER WHERE Username = 'John.Doe@nav.no' LIMIT 1];

    AAREG_HomeController.updateLastUsedOrganization(orgNumber, user.Id);

    User updatedUser = [SELECT Id, LastUsedOrganization__c FROM USER WHERE ID = :user.Id];

    System.assertEquals(orgNumber, updatedUser.LastUsedOrganization__c, 'Last used organization number updated.');
  }

  @isTest
  private static void testShareAgreementsWithUser() {
    User user = [SELECT Id FROM User WHERE Username = 'John.Doe@nav.no'];
    Account acct = AAREG_TestDataFactory.getAccount();
    insert acct;

    Application__c application = AAREG_TestDataFactory.getApplication(acct.Id);
    insert application;

    Agreement__c agreement = AAREG_TestDataFactory.getAgreement(acct.id);
    agreement.Application__c = application.Id;
    insert agreement;

    List<RelatedContact__c> contacts = new List<RelatedContact__c>();
    RelatedContact__c contact = AAREG_TestDataFactory.getRelatedContact();
    RelatedContact__c contactTwo = AAREG_TestDataFactory.getRelatedContact();
    contact.Agreement__c = agreement.Id;
    contactTwo.Agreement__c = agreement.Id;
    contacts.add(contact);
    contacts.add(contactTwo);

    insert contacts;

    Test.startTest();
    AAREG_HomeController.shareAgreementsWithUser(user.Id);
    Test.stopTest();

    List<Agreement__Share> sharedAgreements = [
      SELECT Id
      FROM Agreement__Share
      WHERE UserOrGroupId = :user.Id
    ];
    List<RelatedContact__Share> sharedRelatedContacts = [
      SELECT Id
      FROM RelatedContact__Share
      WHERE UserOrGroupId = :user.Id
    ];
    System.assertEquals(1, sharedAgreements.size(), '1 Shared agreement records not created.');
    System.assertEquals(2, sharedRelatedContacts.size(), '2 Shared related contact records not created.');
  }
}