@IsTest
public class AAREG_DeactivateAccessBatchTest {
  @TestSetup
  static void makeData() {
    Account account = AAREG_TestDataFactory.getDeletedAccount();
    insert account;

    List<Application__c> applications = new List<Application__c>();
    List<Agreement__c> agreements = new List<Agreement__c>();
    Application__c application = AAREG_TestDataFactory.getApplicationCounty(account);
    Application__c application2 = AAREG_TestDataFactory.getApplicationCounty(account);
    insert application;
    insert application2;
    Agreement__c agreement = AAREG_TestDataFactory.getAgreement(account.id);
    agreement.application__c = application.Id;
    Agreement__c agreement2 = AAREG_TestDataFactory.getAgreement(account.id);
    agreement2.application__c = application2.Id;
    insert agreement;
    insert agreement2;
  }

  @IsTest
  static void testBatch() {
    Account account = [SELECT Id FROM Account WHERE EmployerDeletedDate__c = TODAY AND IsDeletedEmployer__c = TRUE LIMIT 1];
    List<Agreement__c> agreements = [
      SELECT
        Id,
        Account__c,
        Account__r.INT_OrganizationNumber__c,
        Application__r.Contact__c,
        Application__r.Email__c
      FROM Agreement__c
      WHERE 
        Account__r.EmployerDeletedDate__c = TODAY
        AND Account__r.IsDeletedEmployer__c = true
    ];

    System.Test.startTest();
      AAREG_DeactivateAccessOnDeletedOrgsBatch batch = new AAREG_DeactivateAccessOnDeletedOrgsBatch();
      Database.executeBatch(batch);
    System.Test.stopTest();

    List<Inquiry__c> inquiries = [
      SELECT
        AccountId__c,
        Subject__c
      FROM Inquiry__c
      WHERE 
        Subject__c = 'Organisasjonen har opphørt fra Enhetsregisteret'
        AND AccountId__c = :account.Id
    ];
    List<Task> tasks = [
      SELECT
        WhatId,
        Subject
      FROM Task
      WHERE 
        WhatId IN :agreements
        AND Subject = 'Organisasjonen har opphørt fra Enhetsregisteret'
    ];
    List<Agreement__c> agreementsRes = [
      SELECT
        Id,
        Status__c
      FROM Agreement__c
      WHERE 
        Id IN :agreements
    ];
    System.assertEquals(1, inquiries.size(), 'All inquiries were not created correctly.');
    System.assertEquals(2, tasks.size(), 'All tasks were not created correctly.');
    for (Agreement__c agreement : agreementsRes) {
      System.assertEquals('Deactivated', agreement.Status__c, 'Status was not set to deactivated for Agreement.');
    }
  }

  @IsTest
  static void schedulableTest() {
    String cronExp = '0 0 0 3 9 ? *';
    System.Test.startTest();
    String jobId = System.schedule(
        'AAREG_DeactivateAccessOnDeletedOrgsBatch',
        cronExp,
        new AAREG_DeactivateAccessOnDeletedOrgsBatch()
    );
    System.Test.stopTest();
    System.assert(jobId != null, 'Job ID should not be null after scheduling the batch.');
  }
}