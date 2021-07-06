@isTest
public class AAREG_ApplicationArchiveBatchTest {
  @TestSetup
  static void makeData() {
    Account account = AAREG_TestDataFactory.getAccount();
    insert account;

    User user = AAREG_TestDataFactory.getStandardUser();
    insert user;

    List<Application__c> applications = new List<Application__c>();

    for (Integer i = 0; i < 50; i++) {
      Application__c application = AAREG_TestDataFactory.getApplication(account.Id);
      application.CasehandlerOwner__c = user.Id;
      applications.add(application);
    }
    insert applications;
  }

  @isTest
  static void testBulkApplicationArchive() {
    List<Application__c> applications = [
      SELECT
        Id,
        Name,
        Casehandler_Status__c,
        AA_register_application_text__c,
        AA_ApplicationArchived__c,
        AA_ApplicationArchivedDate__c,
        AA_CaseHandlerNavIdent__c
      FROM Application__c
    ];

    test.startTest();
    ApiMock.setTestMock('POST_FILE_TO_WEBSAK', 200, 'OK');
    AAREG_ApplicationArchiveBatch batch = new AAREG_ApplicationArchiveBatch(applications);
    Database.executeBatch(batch);
    test.stopTest();

    List<Application__c> appsToAssert = [
      SELECT
        Id,
        Name,
        Casehandler_Status__c,
        AA_register_application_text__c,
        AA_ApplicationArchived__c,
        AA_ApplicationArchivedDate__c,
        AA_CaseHandlerNavIdent__c
      FROM Application__c
    ];

    for (Application__c a : appsToAssert) {
      System.assertEquals(true, a.AA_ApplicationArchived__c, 'Updated with application archived flag.');
    }
  }
}
