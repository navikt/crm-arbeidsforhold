@isTest
public class AAREG_ContactSupportControllerTest {
  @isTest
  static void createThreadForApplication() {
    User usr = AAREG_TestDataFactory.getStandardUser();
    insert usr;

    Account acct = AAREG_TestDataFactory.getAccount();
    insert acct;

    Application__c application = AAREG_TestDataFactory.getApplication(acct.Id);
    insert application;

    Test.startTest();
    AAREG_contactSupportController.createThreadForApplication(usr.Id, application.Id, 'Test Description');
    Test.stopTest();

    List<Thread__c> threads = [SELECT Id, CRM_Related_Object__c, CRM_Number_of_unread_Messages__c FROM Thread__c];

    System.assertEquals(1, threads.size(), '1 Thread created');
    System.assertEquals(1, threads[0].CRM_Number_of_unread_Messages__c, '1 unread message for the thread');
    System.assertEquals(application.Id, threads[0].CRM_Related_Object__c, 'Thread is related to the application');
  }

  @isTest
  static void createNewInquiry() {
    User usr = AAREG_TestDataFactory.getStandardUser();
    insert usr;

    Inquiry__c inquiry = AAREG_TestDataFactory.getInquiry();

    Test.startTest();
    AAREG_contactSupportController.createNewInquiry(String.valueOf(user.Id), inquiry);
    Test.stopTest();

    List<Inquiry__c> newInquires = [SELECT Id, InquiryDescription__c, Status__c, TypeOfInquiry__c FROM Inquiry__c];

    List<Thread__c> threads = [SELECT Id, CRM_Related_Object__c, CRM_Number_of_unread_Messages__c FROM Thread__c];

    System.assertEquals(1, newInquires.size(), '1 Inquiry created');
    System.assertEquals(1, threads.size(), '1 Thread created');
    System.assertEquals(1, threads[0].CRM_Number_of_unread_Messages__c, '1 unread message for the thread');
    System.assertEquals(newInquires[0].Id, threads[0].CRM_Related_Object__c, 'Thread is related to the Inquiry');
  }
}
