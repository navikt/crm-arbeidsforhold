/**
 * Scheduled batch that deactivates agreements for organizations deleted from the
 * Enhetsregisteret today, and creates a follow-up Task and Inquiry for each affected
 * agreement/account so a case handler can revoke access.
 *
 * @author Erik Fladby
 * @author Ann Kristin Olsen
 * @author Kenneth Sørensen
 * @since December 2022
 * @group AAREG Internal Application Agreement
 */
public with sharing class AAREG_DeactivateAccessOnDeletedOrgsBatch implements Database.Batchable<sObject>, Schedulable {
    /** Test-only toggle to simulate a DML failure in the batch execute method. */
    @TestVisible
    static Boolean forceExceptionInTest = false;

    /**
     * Scheduled entry point. Launches the batch with a chunk size of 50.
     *
     * @param sc The scheduled job context.
     */
    public void execute(SchedulableContext sc) {
        AAREG_DeactivateAccessOnDeletedOrgsBatch instance = new AAREG_DeactivateAccessOnDeletedOrgsBatch();
        database.executebatch(instance, 50);
    }

    /**
     * Queries the agreements belonging to organizations deleted from the
     * Enhetsregisteret today.
     *
     * @param bc The batch job context.
     * @return A QueryLocator over the affected Agreement__c records.
     */
    public Database.QueryLocator start(Database.BatchableContext bc) {
        String query = 'SELECT Id, Status__c, Account__c, Account__r.INT_OrganizationNumber__c, Application__r.Contact__c, Application__r.Email__c FROM Agreement__c WHERE Account__r.EmployerDeletedDate__c = TODAY AND Account__r.IsDeletedEmployer__c = true';
        return Database.getQueryLocator(query);
    }

    /**
     * Deactivates each agreement in the batch chunk, creates a case handler Task per
     * agreement, and creates a follow-up Inquiry per affected account. Insert/update
     * failures are logged rather than thrown.
     *
     * @param bc The batch job context.
     * @param records The Agreement__c records in this batch chunk.
     */
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
            Task newTask = new Task(
                WhatId = agreement.Id,
                Type = 'Tilgang',
                Status = 'Completed',
                ActivityDate = Date.today(),
                RecordTypeId = recordType[0].Id,
                Subject = 'Organisasjonen har opphørt fra Enhetsregisteret',
                Description = 'Organisasjonen har opphørt fra Enhetsregisteret. Avtale er deaktivert. Deaktiver tilganger.'
            );
            newTasks.add(newTask);
        }
        for (Id accountId : accountIds) {
            Inquiry__c inquiry = new Inquiry__c(
                CreatedThroughBatch__c = true,
                AccountId__c = accountId,
                TypeOfInquiry__c = 'Spørsmål før du søker om tilgang',
                InquiryDescription__c = 'Organisasjonen har opphørt fra Enhetsregisteret. Deaktiver tilganger.',
                Subject__c = 'Organisasjonen har opphørt fra Enhetsregisteret'
            );
            newInquiries.add(inquiry);
        }

        try {
            if (Test.isRunningTest() && forceExceptionInTest) {
                Integer fail = 1 / 0;
            }
            insert newTasks;
            insert newInquiries;
            update agreements;
        } catch (Exception e) {
            LoggerUtility logger = new LoggerUtility();
            logger.exception(e, CRM_ApplicationDomain.Domain.AAREG);
            logger.publishSynch();
        }
    }
    /**
     * No cleanup work is required after the batch completes.
     *
     * @param bc The batch job context.
     */
    public void finish(Database.BatchableContext bc) {
    }
}
