@isTest
public class AAREG_MyApplicationsControllerTest {
  @TestSetup
  static void makeData() {
    Account account = AAREG_TestDataFactory.getAccount();
    insert account;

    Application__c application = AAREG_TestDataFactory.getApplication(account.Id);
    application.OrganizationNumber__c = '123456789';
    insert application;
  }

  @isTest
  static void getUsersApplications() {
    User user = AAREG_TestDataFactory.getStandardUser();
    user.LastUsedOrganization__c = '123456789';
    insert user;

    Account account = [SELECT Id FROM Account LIMIT 1];

    Application__c application = AAREG_TestDataFactory.getApplication(account.Id);
    application.OrganizationNumber__c = '123456788';

    insert application;

    test.startTest();
    List<Application__c> applications = AAREG_MyApplicationsController.getUsersApplications(user.Id);
    System.assertEquals(1, applications.size(), 'Only on application returned');
    test.stoptest();
  }

  @isTest
  static void noLastUsedOrganization() {
    User user = AAREG_TestDataFactory.getStandardUser();
    user.LastUsedOrganization__c = '';
    insert user;

    Account account = [SELECT Id FROM Account LIMIT 1];

    Application__c application = AAREG_TestDataFactory.getApplication(account.Id);
    application.OrganizationNumber__c = '123456788';

    insert application;

    test.startTest();
    List<Application__c> applications = AAREG_MyApplicationsController.getUsersApplications(user.Id);
    System.debug(applications);
    System.assertEquals(true, applications.isEmpty(), 'Empty list returned');
    test.stoptest();
  }
}
