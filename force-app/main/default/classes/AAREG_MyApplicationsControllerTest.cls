@isTest
public class AAREG_MyApplicationsControllerTest {
    @TestSetup
    static void makeData() {
        Account account = AAREG_TestDataFactory.getAccount();
        insert account;

        User user = AAREG_TestDataFactory.getStandardUser();
        user.LastUsedOrganization__c = '123456789';
        insert user;

        Application__c application = AAREG_TestDataFactory.getApplication(account.Id);
        application.OrganizationNumber__c = '123456789';
        insert application;
    }

    @isTest
    static void testGetUsersApplications() {
        User user = [SELECT Id, LastUsedOrganization__c FROM User WHERE Username = :'John.Doe@nav.no'];
        Account account = [SELECT Id FROM Account LIMIT 1];

        Application__c application = AAREG_TestDataFactory.getApplication(account.Id);
        application.OrganizationNumber__c = '123456788';

        insert application;

        test.startTest();
        List<Application__c> applications = AAREG_MyApplicationsController.getUsersApplications(user.Id);
        System.assertEquals(1, applications.size(), 'Only on application returned');
        test.stoptest();
    }
}
