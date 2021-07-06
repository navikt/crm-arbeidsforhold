@isTest
public class AAREG_ArchiveSchedulerTest {
  private static final String CRON_EXP = '0 0 0 15 3 ? 2022';

  @TestSetup
  static void makeData() {
    Account account = AAREG_TestDataFactory.getAccount();
    insert account;

    User user = AAREG_TestDataFactory.getStandardUser();
    insert user;

    Application__c application = AAREG_TestDataFactory.getApplication(account.Id);
    application.CasehandlerOwner__c = user.Id;
    insert application;

    ContentDocumentLink documentLink = AAREG_TestDataFactory.getContentDocumentLink(application.Id);
    insert documentLink;
  }

  @isTest
  static void testScheduleExecution() {
    ApiMock.setTestMock('POST_FILE_TO_WEBSAK', 200, 'OK');

    Test.startTest();
    String jobId = System.schedule('ScheduledApexTest', CRON_EXP, new AAREG_ArchiveScheduler());
    Test.stopTest();

    List<AsyncApexJob> jobsScheduled = [
      SELECT Id, ApexClassID, ApexClass.Name, Status, JobType
      FROM AsyncApexJob
      WHERE JobType = 'ScheduledApex'
    ];
    System.assertEquals(1, jobsScheduled.size(), 'One job scheduled.');
    System.assertEquals('AAREG_ArchiveScheduler', jobsScheduled[0].ApexClass.Name, 'Scheduled the job.');

    List<AsyncApexJob> jobsApexBatch = [
      SELECT Id, ApexClassID, ApexClass.Name, Status, JobType
      FROM AsyncApexJob
      WHERE JobType = 'BatchApex'
    ];
    System.assertEquals(1, jobsApexBatch.size(), 'One job scheduled.');
    System.assertEquals('AAREG_ApplicationArchiveBatch', jobsApexBatch[0].ApexClass.Name, 'Batch job submitted.');
  }
}
