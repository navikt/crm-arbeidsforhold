@isTest
public class AAREG_DeactivateAccessBatchTest {
  @TestSetup
  static void makeData() {
    Account account = AAREG_TestDataFactory.getDeletedAccount();
    insert account;

    List<Application__c> applications = new List<Application__c>();
    List<Agreement__c> agreements = new List<Agreement__c>();
    Application__c application = AAREG_TestDataFactory.getApplication(account.Id);
    Application__c application2 = AAREG_TestDataFactory.getApplication(account.Id);
    insert application;
    insert application2;
    Agreement__c agreement = AAREG_TestDataFactory.getAgreement(account.id);
    agreement.Application__c = application.Id;
    Agreement__c agreement2 = AAREG_TestDataFactory.getAgreement(account.id);
    agreement2.Application__c = application2.Id;
    insert agreement;
    insert agreement2;
  }

  @isTest
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
    List<Id> agreementIds = new List<Id>();
    for (Agreement__c agreement : agreements) {
      agreementIds.add(agreement.Id);
    }

    Test.startTest();
      AAREG_DeactivateAccessOnDeletedOrgsBatch batch = new AAREG_DeactivateAccessOnDeletedOrgsBatch();
      Database.executeBatch(batch);
    Test.stopTest();

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
        WhatId IN :agreementIds
        AND Subject = 'Organisasjonen har opphørt fra Enhetsregisteret'
    ];
    List<Agreement__c> agreementsRes = [
      SELECT
        Id,
        Status__c
      FROM Agreement__c
      WHERE 
        Id IN :agreementIds
    ];
    System.assertEquals(1, inquiries.size(), 'All inquiries were not created correctly.');
    System.assertEquals(2, tasks.size(), 'All tasks were not created correctly.');
    for (Agreement__c agreement : agreementsRes) {
      System.assertEquals('Deactivated', agreement.Status__c, 'Status was not set to deactivated for Agreement.');
    }
  }
}