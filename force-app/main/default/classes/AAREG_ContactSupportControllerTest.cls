@isTest
public class AAREG_ContactSupportControllerTest {
  
  @isTest
  static void createNewInquiry() {
    User usr;
    User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
      System.runAs(thisUser){
        usr = AAREG_TestDataFactory.getStandardUser();
    	insert usr;  
      }

    Inquiry__c inquiry = AAREG_TestDataFactory.getInquiry();

    System.Test.startTest();
      try{
          AAREG_contactSupportController.createNewInquiry(String.valueOf(usr.Id), inquiry);
      }catch(exception e){}
    System.Test.stopTest();

    List<Inquiry__c> newInquires = [SELECT Id, InquiryDescription__c, Status__c, TypeOfInquiry__c FROM Inquiry__c];

    List<Thread__c> threads = [SELECT Id, CRM_Related_Object__c, CRM_Number_of_unread_Messages__c FROM Thread__c];

    System.Assert.areEqual(1, newInquires.size(), '1 Inquiry created');
    System.Assert.areEqual(1, threads[0].CRM_Number_of_unread_Messages__c, '1 unread message for the thread');
    System.Assert.areEqual(newInquires[0].Id, threads[0].CRM_Related_Object__c, 'Thread is related to the Inquiry');
  }
}