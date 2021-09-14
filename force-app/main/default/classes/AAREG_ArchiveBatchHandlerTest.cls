@isTest
public class AAREG_ArchiveBatchHandlerTest {
  @TestSetup
  static void makeData() {
    Account account = AAREG_TestDataFactory.getAccount();
    insert account;

    User user = AAREG_TestDataFactory.getStandardUser();
    insert user;

    Application__c application = AAREG_TestDataFactory.getApplication(account.Id);
    application.CasehandlerOwner__c = user.Id;
    application.Casehandler_Status__c = 'In Progress';
    insert application;

    ContentDocumentLink documentLink = AAREG_TestDataFactory.getContentDocumentLink(application.Id);
    insert documentLink;
  }

  @isTest
  static void testApplicationArchiveBatchScheduled() {
    Map<Id, Application__c> applications = new Map<Id, Application__c>(
      [
        SELECT
          Id,
          Name,
          Casehandler_Status__c,
          AA_register_application_text__c,
          AA_ApplicationArchived__c,
          AA_ApplicationArchivedDate__c,
          AA_CaseHandlerNavIdent__c,
          AccountName__c,
          OrganizationNumber__c,
          MailingAddress__c,
          MailingCity__c,
          MailingPostalCode__c,
          ApplicationSubmittedDate__c
        FROM Application__c
      ]
    );

    ApiMock.setTestMock('POST_FILE_TO_WEBSAK', 200, 'OK');

    Test.startTest();
    AAREG_ArchiveBatchHandler.archive(applications.KeySet());
    Test.stopTest();

    List<AsyncApexJob> jobsApexBatch = [
      SELECT Id, ApexClassID, ApexClass.Name, Status, JobType
      FROM AsyncApexJob
      WHERE JobType = 'BatchApex'
    ];
    System.assertEquals(1, jobsApexBatch.size(), 'One job scheduled.');
    System.assertEquals('AAREG_ApplicationArchiveBatch', jobsApexBatch[0].ApexClass.Name, 'Batch job submitted.');
  }

  @isTest
  static void testDecisionArchiveBatchScheduled() {
    User user = [SELECT Id, CRM_NAV_Ident__c FROM User WHERE CRM_NAV_Ident__c = 'test123' LIMIT 1];
    Account account = [SELECT Id FROM Account LIMIT 1];

    Application__c application = AAREG_TestDataFactory.getApplication(account.Id);
    application.CasehandlerOwner__c = user.Id;
    application.AA_ApplicationArchived__c = true;
    application.Casehandler_Status__c = 'Closed';
    application.AA_ApplicationArchived__c = true;
    insert application;

    Set<Id> applicationIds = new Set<Id>{ application.Id };

    ApiMock.setTestMock('POST_FILE_TO_WEBSAK', 200, 'OK');

    Test.startTest();
    AAREG_ArchiveBatchHandler.archive(applicationIds);
    Test.stopTest();

    List<AsyncApexJob> jobsApexBatch = [
      SELECT Id, ApexClassID, ApexClass.Name, Status, JobType
      FROM AsyncApexJob
      WHERE JobType = 'BatchApex'
    ];
    System.assertEquals(1, jobsApexBatch.size(), 'One job scheduled.');
    System.assertEquals('AAREG_DecisionArchiveBatch', jobsApexBatch[0].ApexClass.Name, 'Batch job submitted.');
  }

  @isTest
  static void testDecisionPreviouslyArchived() {
    User user = [SELECT Id, CRM_NAV_Ident__c FROM User WHERE CRM_NAV_Ident__c = 'test123' LIMIT 1];
    Account account = [SELECT Id FROM Account LIMIT 1];

    Application__c application = AAREG_TestDataFactory.getApplication(account.Id);
    application.CasehandlerOwner__c = user.Id;
    application.Casehandler_Status__c = 'Closed';
    application.AA_ApplicationArchived__c = true;
    application.AA_DecisionArchived__c = true;
    application.AA_DecisionArchivedDate__c = Date.today();
    insert application;

    Set<Id> applicationIds = new Set<Id>{ application.Id };

    ApiMock.setTestMock('POST_FILE_TO_WEBSAK', 200, 'OK');

    Test.startTest();
    AAREG_ArchiveBatchHandler.archive(applicationIds);
    Test.stopTest();

    List<AsyncApexJob> jobsApexBatch = [
      SELECT Id, ApexClassID, ApexClass.Name, Status, JobType
      FROM AsyncApexJob
      WHERE JobType = 'BatchApex'
    ];
    System.assertEquals(0, jobsApexBatch.size(), 'No jobs scheduled.');
  }
}
