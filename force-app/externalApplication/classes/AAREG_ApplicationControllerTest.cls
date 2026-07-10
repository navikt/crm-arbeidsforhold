@SuppressWarnings('PMD')
@IsTest
private class AAREG_ApplicationControllerTest {
    @TestSetup
    private static void makeData() {
        Account acct = AAREG_TestDataFactory.getAccountCounty();
        insert acct;
    }

    @IsTest
    private static void testGetAccountNameByOrgNumber() {
        Account acct = [SELECT Id, INT_OrganizationNumber__c FROM Account LIMIT 1];

        System.Test.startTest();
        String accountName = AAREG_ApplicationController.getAccountNameByOrgNumber(acct.INT_OrganizationNumber__c);
        System.Test.stopTest();

        System.Assert.isNotNull(accountName, 'Account name should not be null');
    }

    @IsTest
    private static void testProcessNewApplication() {
        Account account = [SELECT Id FROM Account LIMIT 1];

        Application__c application = new Application__c();
        application.Account__c = account.Id;
        application.IsConfirmationEmailSent__c = true;
        application.Status__c = 'New';

        List<RelatedContact__c> contacts = new List<RelatedContact__c>();
        contacts.add(new RelatedContact__c(name = 'Test Contact 1'));
        contacts.add(new RelatedContact__c(name = 'Test Contact 2'));

        List<ApplicationBasisCode__c> basisCodes = new List<ApplicationBasisCode__c>();
        basisCodes.add(new ApplicationBasisCode__c());
        basisCodes.add(new ApplicationBasisCode__c());

        String base64 = 'sdkldsfjlcm';
        String fileName = 'Test file name';

        System.Test.startTest();
        Id processedApplicationId = AAREG_ApplicationController.processApplication(
            application,
            basisCodes,
            contacts,
            base64,
            fileName
        );
        System.Test.stopTest();

        List<Application__c> result = [
            SELECT Id, Status__c
            FROM Application__c
            WHERE Id = :processedApplicationId
        ];

        System.Assert.areEqual(1, result.size(), 'Application should be created');
        System.Assert.areEqual('New', result[0].Status__c, 'Status should be New');
    }

    @IsTest
    private static void testProcessAdditionalInformationApplication() {
        Account account = [SELECT Id FROM Account LIMIT 1];

        Application__c application = new Application__c();
        application.Account__c = account.Id;
        application.Status__c = 'Additional Information Required';
        application.IsConfirmationEmailSent__c = true;

        List<RelatedContact__c> contacts = new List<RelatedContact__c>();
        contacts.add(new RelatedContact__c(name = 'Test Contact 1'));
        contacts.add(new RelatedContact__c(name = 'Test Contact 2'));

        List<ApplicationBasisCode__c> basisCodes = new List<ApplicationBasisCode__c>();
        basisCodes.add(new ApplicationBasisCode__c());
        basisCodes.add(new ApplicationBasisCode__c());

        String base64 = null;
        String fileName = null;

        System.Test.startTest();
        Id appId = AAREG_ApplicationController.processApplication(application, basisCodes, contacts, base64, fileName);
        System.Test.stopTest();

        List<Application__c> result = [SELECT Id, Status__c FROM Application__c WHERE Id = :appId];

        System.Assert.areEqual(1, result.size(), 'Application should be upserted');
        System.Assert.areEqual('In Progress', result[0].Status__c, 'Status should be In Progress');
    }

    @IsTest
    private static void testGetLastUsedOrganizationInformation() {
        Profile profile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        Account account = [SELECT Id, INT_OrganizationNumber__c FROM Account LIMIT 1];

        User user = new User();
        user.FirstName = 'John';
        user.LastName = 'Doe';
        user.Email = 'John.Doe@nav.no';
        user.Username = 'John.Doe@nav.no.test';
        user.Alias = 'j.doe';
        user.LanguageLocaleKey = 'no';
        user.LocaleSidKey = 'no_NO';
        user.TimeZoneSidKey = 'Europe/Paris';
        user.EmailEncodingKey = 'UTF-8';
        user.ProfileId = profile.Id;
        user.LastUsedOrganization__c = account.INT_OrganizationNumber__c;
        insert user;

        System.Test.startTest();
        Account lastUsedOrganization = AAREG_ApplicationController.getLastUsedOrganizationInformation(user.Id);
        System.Test.stopTest();

        System.Assert.isNotNull(lastUsedOrganization, 'Account should be returned');
    }

    @IsTest
    private static void testGetDraftApplication() {
        Account account = [SELECT Id FROM Account LIMIT 1];

        Application__c application = AAREG_TestDataFactory.getApplicationCounty(account);
        insert application;

        List<RelatedContact__c> contacts = new List<RelatedContact__c>();
        contacts.add(new RelatedContact__c(application__c = application.Id, name = 'Test Contact 1'));
        contacts.add(new RelatedContact__c(application__c = application.Id, name = 'Test Contact 2'));
        insert contacts;

        List<ApplicationBasisCode__c> basisCodes = new List<ApplicationBasisCode__c>();
        basisCodes.add(new ApplicationBasisCode__c(application__c = application.Id));
        basisCodes.add(new ApplicationBasisCode__c(application__c = application.Id));
        insert basisCodes;

        System.Test.startTest();
        AAREG_ApplicationController.DraftApplication draft = AAREG_ApplicationController.getDraftApplication(
            application.Id
        );
        System.Test.stopTest();

        System.Assert.areEqual(application.Id, draft.application.Id, 'Draft application retrieved');
        System.Assert.areEqual(2, draft.basisCodes.size(), '2 draft basis codes retrieved');
        System.Assert.areEqual(2, draft.contacts.size(), '2 draft related contacts retrieved');
    }

    @IsTest
    private static void testDeleteDraftRecord() {
        Account account = [SELECT Id FROM Account LIMIT 1];
        Application__c application = AAREG_TestDataFactory.getApplicationCounty(account);
        insert application;

        System.Test.startTest();
        AAREG_ApplicationController.deleteDraftRecord(application);
        System.Test.stopTest();

        List<Application__c> applications = [SELECT Id FROM Application__c];
        System.Assert.areEqual(0, applications.size(), 'No applications. Successful record deletion.');
    }

    @IsTest
    private static void testSaveAsDraft() {
        Account account = [SELECT Id FROM Account LIMIT 1];

        Application__c application = new Application__c();
        application.Account__c = account.Id;
        application.IsConfirmationEmailSent__c = true;

        List<RelatedContact__c> contacts = new List<RelatedContact__c>();
        contacts.add(new RelatedContact__c(name = 'Test Contact 1'));
        contacts.add(new RelatedContact__c(name = 'Test Contact 2'));

        List<ApplicationBasisCode__c> basisCodes = new List<ApplicationBasisCode__c>();
        basisCodes.add(new ApplicationBasisCode__c());
        basisCodes.add(new ApplicationBasisCode__c());

        String base64 = null;
        String fileName = null;

        System.Test.startTest();
        AAREG_ApplicationController.saveAsDraft(application, basisCodes, contacts, base64, fileName);
        System.Test.stopTest();

        Application__c processedApplication = [SELECT Id, Status__c FROM Application__c LIMIT 1];
        System.Assert.areEqual('Draft', processedApplication.Status__c, 'Assert correct application status');
    }
}
