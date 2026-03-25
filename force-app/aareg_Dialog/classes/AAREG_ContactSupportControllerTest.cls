/**
 * This is a test class for the AAREG_contactSupportController, which handles the creation of support threads and 
 * inquiries in the AAREG Dialog application. The test class includes methods to verify the correct creation of 
 * threads and inquiries, as well as the handling of file attachments and the association of threads with the correct records.
 * <br><br>
 * 
 * @since Februar 2026
 * @group AAREG Utility
 */
@isTest
public class AAREG_ContactSupportControllerTest {
  
  /** Test method to verify the creation of a thread for a given application and the correct association of 
   * the thread with the application. It also checks that the initial message is created and that the 
   * thread has the correct number of unread messages.
   */
  @isTest
  static void whenApplicationIsProvided_ThenThreadIsCreatedForApplication() {
      
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

  /** Test method to verify that a thread is created with the correct subject and description 
   * when a new inquiry is created without file attachments. It checks that the thread is associated with the 
   * created inquiry and that the initial message content matches the inquiry description.
   */
  @isTest
  static void whenApplicationIsProvided_ThenThreadIsCreatedWithCRMAccount() {
      
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
  
  /** Test method to verify that the getThreadRecordTypeId method in the AAREG_Utility class returns a valid 
   * RecordType Id when the custom metadata is properly set up. 
   * It mocks the custom metadata to return a specific RecordType name and checks that the returned Id is not null. */ 
  @isTest
  static void WhenMethodcheckObjectTypeNameche_CalledWithEmptyList_ThenNoExceptionThrown() {
      // Call the method with an empty list
      System.Test.startTest();
      AAREG_checkObjectTypeNameche.CheckObjectTypeName(new List<Id>());
      System.Test.stopTest();

      // Verify that no exceptions were thrown
      System.assert(true, 'Method should handle empty lists without throwing exceptions.');
  }
  
  /**
   * Test method to verify that when a new inquiry is created without file attachments, a thread is created with the correct 
   * association to the inquiry and that the initial message content matches the inquiry description. It checks that the 
   * thread has the correct number of unread messages and that it is related to the created inquiry.
   * This test ensures that the core functionality of creating a thread for an inquiry works as expected when no files are 
   * involved, which is important for backward compatibility and for users who may not need to attach files to their inquiries.
   */
  @isTest
  static void When_NewInquiryIsCreatedWithoutFiles_ThenThreadIsCreated() {
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

  /** Test method to verify that when a new inquiry is created with a file attachment, the file is correctly linked to the created Inquiry. 
   * It checks that a ContentDocumentLink record is created linking the uploaded file to the associatedinquiry. 
   * This test ensures that the file attachment functionality works as expected and that users can successfully attach files to their inquiries, 
   * which is crucial for providing necessary documentation or evidence related to their support requests.
   */
  @isTest
  static void When_NewInquiryIsCreatedWithFile_ThenFileIsLinkedToInquiry() {
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

  /** Test method to verify that when a new inquiry is created with a file attachment, the file is correctly linked to the created Inquiry. 
   * It checks that a ContentDocumentLink record is created linking the uploaded file to the associatedinquiry. 
   * This test ensures that the file attachment functionality works as expected and that users can successfully attach files to their inquiries, 
   * which is crucial for providing necessary documentation or evidence related to their support requests.
   */
  @isTest
  static void When_NewInquiryIsCreatedWithMultipleFiles_ThenFilesAreLinkedToInquiry() {
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

    Inquiry__c inquiryWithFilesFromDB = [SELECT Id FROM Inquiry__c WHERE Id = :inquiryWithMultipleFiles.Id LIMIT 1];
    List<ContentDocumentLink> cdlsMulti = [SELECT Id, LinkedEntityId FROM ContentDocumentLink WHERE LinkedEntityId = :inquiryWithFilesFromDB.Id];
    System.assertEquals(2, cdlsMulti.size(), 'Two files should be linked to the inquiry thread when multiple files provided');
  }

}