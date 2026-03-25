@isTest
public class AAREG_ContactSupportControllerTest {
  
  @isTest
  static void createThreadForApplication() {
      
    User usr;
    User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
      System.runAs(thisUser){
        usr = AAREG_TestDataFactory.getStandardUser();
    	insert usr; 
      }

    // Create test Account
        Account testAccount = AAREG_TestDataFactory.getAccount();
        insert testAccount;

        // Create test Application
        Application__c testApplication = AAREG_TestDataFactory.getApplicationCounty(testAccount);
        insert testApplication;

    System.Test.startTest();
      try{
         // Call without file (backwards compatibility)
         AAREG_contactSupportController.createThreadForApplication(usr.Id, testApplication.Id, 'Test Description','Endringsbehov'); 
      }catch(exception e){}
          
    
    System.Test.stopTest();

    List<Thread__c> threads = [SELECT Id, CRM_Related_Object__c, CRM_Number_of_unread_Messages__c FROM Thread__c];

    System.assertEquals(1, threads.size(), '1 Thread created');
    System.assertEquals(1, threads[0].CRM_Number_of_unread_Messages__c, '1 unread message for the thread');
    System.assertEquals(testApplication.Id, threads[0].CRM_Related_Object__c, 'Thread is related to the application');
  }
  @isTest
  static void testCheckObjectTypeName_PositiveScenario() {
      
      User testUser;
      User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
      System.runAs(thisUser){
          testUser = AAREG_TestDataFactory.getStandardUser();
          insert testUser;
      }
          
      // Create test Account
      Account testAccount = AAREG_TestDataFactory.getAccount();
      insert testAccount;
      
      // Create test Application
      Application__c testApplication = AAREG_TestDataFactory.getApplicationCounty(testAccount);
      insert testApplication;
      
      // Call the method
      System.Test.startTest();
    AAREG_contactSupportController.createThreadForApplication(testUser.Id, testApplication.Id, 'Test Description','Endringsbehov');
    // Retrieve the test Thread__c record
      Thread__c testThread = [SELECT Id FROM Thread__c LIMIT 1];
      AAREG_checkObjectTypeNameche.CheckObjectTypeName(new List<Id>{testThread.Id});
      System.Test.stopTest();
      
      // Verify the results
      Thread__c updatedThread = [SELECT OwnerId, CRM_Account__c FROM Thread__c WHERE Id = :testThread.Id];
      System.Assert.isNotNull(updatedThread.OwnerId, 'OwnerId should be updated.');
      System.Assert.isNotNull(updatedThread.CRM_Account__c, 'CRM_Account__c should be updated.');
  }
  
  @isTest
  static void testCheckObjectTypeName_EmptyList() {
      // Call the method with an empty list
      System.Test.startTest();
      AAREG_checkObjectTypeNameche.CheckObjectTypeName(new List<Id>());
      System.Test.stopTest();

      // Verify that no exceptions were thrown
      System.assert(true, 'Method should handle empty lists without throwing exceptions.');
  }
    
  @isTest
  static void createNewInquiryWithoutFiles() {
    User usr;
    User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
      System.runAs(thisUser){
        usr = AAREG_TestDataFactory.getStandardUser();
    	insert usr;  
      }

    Inquiry__c inquiry = AAREG_TestDataFactory.getInquiry();

    System.Test.startTest();
      try{
          // Call without file (backwards compatibility)
          AAREG_contactSupportController.createNewInquiry(String.valueOf(usr.Id), inquiry, null);
      }catch(exception e){}
    System.Test.stopTest();

    List<Inquiry__c> newInquires = [SELECT Id, InquiryDescription__c, Status__c, TypeOfInquiry__c FROM Inquiry__c];

    List<Thread__c> threads = [SELECT Id, CRM_Related_Object__c, CRM_Number_of_unread_Messages__c FROM Thread__c];

    System.assertEquals(1, newInquires.size(), '1 Inquiry created');
    System.assertEquals(1, threads[0].CRM_Number_of_unread_Messages__c, '1 unread message for the thread');
    System.assertEquals(newInquires[0].Id, threads[0].CRM_Related_Object__c, 'Thread is related to the Inquiry');

  }

  @isTest
  static void createNewInquiryWithOneFile() {
    User usr;
    User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
      System.runAs(thisUser){
        usr = AAREG_TestDataFactory.getStandardUser();
    	insert usr;  
      }

    Inquiry__c inquiryWithFile = AAREG_TestDataFactory.getInquiry();
    System.Test.startTest();
      String data = 'Test Data';
      String base64 = EncodingUtil.base64Encode(Blob.valueOf(data));
      AAREG_contactSupportController.FileData file = new AAREG_contactSupportController.FileData();
      file.base64 = base64;
      file.fileName = 'evidence.pdf';
      AAREG_contactSupportController.createNewInquiry(String.valueOf(usr.Id), inquiryWithFile, new List<AAREG_contactSupportController.FileData>{file});
    System.Test.stopTest();

    Inquiry__c inquiryWithFileFromDB = [SELECT Id FROM Inquiry__c WHERE Id = :inquiryWithFile.Id LIMIT 1];
    List<ContentDocumentLink> cdls = [SELECT Id, LinkedEntityId FROM ContentDocumentLink WHERE LinkedEntityId = :inquiryWithFileFromDB.Id];
    System.assertEquals(1, cdls.size(), 'One file should be linked to the inquiry when file provided');
  }

  @isTest
  static void createNewInquiryWithMultipleFiles() {
    User usr;
    User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
      System.runAs(thisUser){
        usr = AAREG_TestDataFactory.getStandardUser();
    	insert usr;  
      }

    // Now call with multiple files and assert all are attached
    Inquiry__c inquiryWithMultipleFiles = AAREG_TestDataFactory.getInquiry();
    System.Test.startTest();
      String data1 = 'Test Data 1';
      String data2 = 'Test Data 2';
      String base64_1 = EncodingUtil.base64Encode(Blob.valueOf(data1));
      String base64_2 = EncodingUtil.base64Encode(Blob.valueOf(data2));
      AAREG_contactSupportController.FileData file1 = new AAREG_contactSupportController.FileData();
      file1.base64 = base64_1;
      file1.fileName = 'evidence1.pdf';
      AAREG_contactSupportController.FileData file2 = new AAREG_contactSupportController.FileData();
      file2.base64 = base64_2;
      file2.fileName = 'evidence2.png';
      AAREG_contactSupportController.createNewInquiry(String.valueOf(usr.Id), inquiryWithMultipleFiles, new List<AAREG_contactSupportController.FileData>{file1, file2});
    System.Test.stopTest();

    Thread__c inquiryThreadWithMultipleFiles = [SELECT Id FROM Thread__c WHERE CRM_Related_Object__c = :inquiryWithMultipleFiles.Id LIMIT 1];
    List<ContentDocumentLink> cdlsMulti = [SELECT Id, LinkedEntityId FROM ContentDocumentLink WHERE LinkedEntityId = :inquiryThreadWithMultipleFiles.Id];
    System.assertEquals(2, cdlsMulti.size(), 'Two files should be linked to the inquiry thread when multiple files provided');
  }

}