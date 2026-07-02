public with sharing class AAREG_DeactivateAccessOnDeletedOrgsBatch implements Database.Batchable<sObject>, Schedulable {
  public void execute(SchedulableContext sc) {
    AAREG_DeactivateAccessOnDeletedOrgsBatch instance = new AAREG_DeactivateAccessOnDeletedOrgsBatch();
    database.executebatch(instance, 50);
  }

  public Database.QueryLocator start(Database.BatchableContext bc) {
    String query = 'SELECT Id, Status__c, Account__c, Account__r.INT_OrganizationNumber__c, Application__r.Contact__c, Application__r.Email__c FROM Agreement__c WHERE Account__r.EmployerDeletedDate__c = TODAY AND Account__r.IsDeletedEmployer__c = true';
    return Database.getQueryLocator(query);
  }

  public void execute(Database.BatchableContext bc, List<Agreement__c> records) {
    List<RecordType> recordType = [SELECT Id FROM RecordType WHERE DeveloperName = 'AAREG_TASK' LIMIT 1];
    List<Id> accountIds = new List<Id>();
    List<Task> newTasks = new List<Task>();
    List<Inquiry__c> newInquiries = new List<Inquiry__c>();
    List<Agreement__c> agreements = new List<Agreement__c>();

    for (Agreement__c agreement : records) {
      agreement.Status__c = 'Deactivated';
      agreement.isDeactivateThroughBatch__c = true;
      agreements.add(agreement);
      if (!accountIds.contains(agreement.Account__c)) {
        accountIds.add(agreement.account__c);
      }
      Task newTask = new Task(WhatId=agreement.Id, Type='Tilgang', Status='Completed', ActivityDate=Date.today(), RecordTypeId=recordType[0].Id, Subject='Organisasjonen har opphørt fra Enhetsregisteret', Description='Organisasjonen har opphørt fra Enhetsregisteret. Avtale er deaktivert. Deaktiver tilganger.');
      newTasks.add(newTask);
    }
    for (Id accountId : accountIds) {
      Inquiry__c inquiry = new Inquiry__c(CreatedThroughBatch__c=true, AccountId__c=accountId, TypeOfInquiry__c='Spørsmål før du søker om tilgang', InquiryDescription__c='Organisasjonen har opphørt fra Enhetsregisteret. Deaktiver tilganger.', Subject__c='Organisasjonen har opphørt fra Enhetsregisteret'); 
      newInquiries.add(inquiry);
    }

    try {
      insert newTasks;
      insert newInquiries;
      update agreements;
    } catch (Exception e) {
        LoggerUtility logger = new LoggerUtility();
        logger.exception(e, CRM_ApplicationDomain.Domain.AAREG);
        logger.publishSynch();
    }
  }
  public void finish(Database.BatchableContext bc) {}
}