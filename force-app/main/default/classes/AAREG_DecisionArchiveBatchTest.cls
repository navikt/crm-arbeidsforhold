@isTest
public class AAREG_DecisionArchiveBatchTest {
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
      application.Casehandler_Status__c = 'Closed';
      applications.add(application);
    }
    insert applications;
  }

  @isTest
  static void testBulkDecisionArchive() {
    List<Application__c> applications = [
      SELECT
        Id,
        Name,
        Casehandler_Status__c,
        AA_register_application_text__c,
        AA_ApplicationArchived__c,
        AA_ApplicationArchivedDate__c,
        AA_CaseHandlerNavIdent__c,
        AA_DecisionArchiveText__c,
        AA_DecisionArchived__c
      FROM Application__c
    ];

    test.startTest();
    ApiMock.setTestMock('POST_FILE_TO_WEBSAK', 200, 'OK');
    AAREG_DecisionArchiveBatch batch = new AAREG_DecisionArchiveBatch(applications);
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
        AA_CaseHandlerNavIdent__c,
        AA_DecisionArchived__c
      FROM Application__c
    ];

    for (Application__c a : appsToAssert) {
      System.assertEquals(true, a.AA_DecisionArchived__c, 'Updated with decision archived flag.');
    }
  }
}
