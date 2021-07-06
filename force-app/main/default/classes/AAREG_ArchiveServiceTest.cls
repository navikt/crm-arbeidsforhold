@isTest
public with sharing class AAREG_ArchiveServiceTest {
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
  static void testArchiveApplications() {
    Map<Id, Application__c> applications = new Map<Id, Application__c>(
      [
        SELECT
          Id,
          Name,
          Casehandler_Status__c,
          AA_register_application_text__c,
          AA_ApplicationArchived__c,
          AA_ApplicationArchivedDate__c,
          AA_CaseHandlerNavIdent__c
        FROM Application__c
      ]
    );

    ApiMock.setTestMock('POST_FILE_TO_WEBSAK', 200, 'OK');

    Test.startTest();
    AAREG_ArchiveService service = new AAREG_ArchiveService();
    service.archiveApplications(applications.values());
    Test.stopTest();

    Application__c appToAssert = [
      SELECT Id, AA_ApplicationArchived__c, AA_ApplicationArchivedDate__c
      FROM Application__c
      WHERE Id IN :applications.keySet()
      LIMIT 1
    ];

    System.assertEquals(true, appToAssert.AA_ApplicationArchived__c, 'Updated with application archived flag.');
  }

  @isTest
  static void testArchiveDecisionSuccess() {
    Map<Id, Application__c> applications = new Map<Id, Application__c>(
      [
        SELECT
          Id,
          Name,
          Casehandler_Status__c,
          AA_register_application_text__c,
          AA_ApplicationArchived__c,
          AA_ApplicationArchivedDate__c,
          AA_DecisionArchived__c,
          AA_CaseHandlerNavIdent__c,
          AA_DecisionArchiveText__c
        FROM Application__c
      ]
    );

    for (Id appId : applications.keySet()) {
      applications.get(appId).Casehandler_Status__c = 'Closed';
    }

    update applications.values();

    ApiMock.setTestMock('POST_FILE_TO_WEBSAK', 200, 'OK');

    Test.startTest();
    AAREG_ArchiveService service = new AAREG_ArchiveService();
    service.archiveDecisions(applications.values());
    Test.stopTest();

    Application__c appToAssert = [
      SELECT Id, AA_DecisionArchived__c, AA_DecisionArchivedDate__c
      FROM Application__c
      WHERE Id IN :applications.keySet()
    ];

    System.assertEquals(true, appToAssert.AA_DecisionArchived__c, 'Application updated with decision archived flag.');
  }

  @isTest
  static void testArchiveDecisionError() {
    Map<Id, Application__c> applications = new Map<Id, Application__c>(
      [
        SELECT
          Id,
          Name,
          Casehandler_Status__c,
          AA_register_application_text__c,
          AA_DecisionArchived__c,
          AA_ApplicationArchived__c,
          AA_ApplicationArchivedDate__c,
          AA_CaseHandlerNavIdent__c,
          AA_DecisionArchiveText__c
        FROM Application__c
      ]
    );

    for (Id appId : applications.keySet()) {
      applications.get(appId).Casehandler_Status__c = 'Closed';
    }

    update applications.values();

    ApiMock.setTestMock('POST_FILE_TO_WEBSAK', 500, 'Unable to post file');

    Test.startTest();
    AAREG_ArchiveService service = new AAREG_ArchiveService();
    service.archiveDecisions(applications.values());
    Test.stopTest();

    Application__c appToAssert = [
      SELECT Id, AA_DecisionArchived__c, AA_DecisionArchivedDate__c
      FROM Application__c
      WHERE Id IN :applications.keySet()
      LIMIT 1
    ];

    System.assertEquals(false, appToAssert.AA_DecisionArchived__c, 'Application updated with decision archived flag.');
  }

  @isTest
  static void testNoRelatedFiles() {
    Account account = [SELECT ID FROM Account LIMIT 1];

    User user = [SELECT Id, CRM_NAV_Ident__c FROM User WHERE CRM_NAV_Ident__c = 'test123' LIMIT 1];

    Application__c application = AAREG_TestDataFactory.getApplication(account.Id);
    application.CasehandlerOwner__c = user.Id;
    insert application;

    List<Application__c> applicationList = [
      SELECT
        Id,
        Name,
        Casehandler_Status__c,
        AA_register_application_text__c,
        AA_ApplicationArchived__c,
        AA_ApplicationArchivedDate__c,
        AA_CaseHandlerNavIdent__c
      FROM Application__c
      WHERE Id = :application.Id
    ];

    ApiMock.setTestMock('POST_FILE_TO_WEBSAK', 200, 'OK');

    Test.startTest();
    AAREG_ArchiveService service = new AAREG_ArchiveService();
    service.archiveApplications(applicationList);
    Test.stopTest();

    Application__c appToAssert = [
      SELECT Id, AA_ApplicationArchived__c, AA_ApplicationArchivedDate__c
      FROM Application__c
      WHERE Id = :application.Id
    ];

    System.assertEquals(true, appToAssert.AA_ApplicationArchived__c, 'Updated with application archived flag.');
  }
}
