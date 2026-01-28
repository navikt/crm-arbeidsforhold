@SuppressWarnings('PMD')
@IsTest
private class AAREG_ApplicationControllerTest {
    @TestSetup
    private static void makeData() {
        Account acct = AAREG_TestDataFactory.getAccountCounty();
        insert acct;
              
    }

    @isTest
    private static void getAccountNameByOrgNumber() {
        Test.startTest();
        String accountName = AAREG_ApplicationController.getAccountNameByOrgNumber('929882989');
        Test.stopTest();
        System.Assert.areEqual('Fylke', accountName, 'Assert that correct account name is returned');
    }
    
    @isTest
    private static void processNewApplication() {
        Account account = [SELECT Id, Name FROM Account LIMIT 1];
        
        Application__c application = new Application__c();
        application.Account__c = account.Id;
        application.IsConfirmationEmailSent__c = true;

        List<RelatedContact__c> contacts = new List<RelatedContact__c>();
        contacts.add(new RelatedContact__c(name = 'Test Contact 1'));
        contacts.add(new RelatedContact__c(name = 'Test Contact 2'));

        List<ApplicationBasisCode__c> basisCodes = new List<ApplicationBasisCode__c>();
        basisCodes.add(new ApplicationBasisCode__c());
        basisCodes.add(new ApplicationBasisCode__c());

        String base64 = 'sdkldsfjlcm';
        String fileName = 'Test file name';
        
        Test.startTest();
        Id processedApplicationId = AAREG_ApplicationController.processApplication(
            application,
            basisCodes,
            contacts,
            base64,
            fileName
        );
        
        List<Application__c> processedApplications = [
            SELECT Id, Casehandler_Status__c
            FROM Application__c
            WHERE Id = :processedApplicationId
        ];
        List<RelatedContact__c> processedContacts = [SELECT Id, Name, Application__c FROM RelatedContact__c];
        List<ApplicationBasisCode__c> processedBasisCodes = [SELECT Id, Application__c FROM ApplicationBasisCode__c];
        List<ContentDocumentLink> documentLink = [
            SELECT Id
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :processedApplications[0].Id
        ];
        Test.stopTest();

        System.Assert.areEqual(1, processedApplications.size(), 'Check only one application was inserted');
        System.Assert.areEqual(2, processedContacts.size(), 'Check that both contacts were inserted');
        System.Assert.areEqual(2, processedBasisCodes.size(), 'Check that both Application Basis Codes were inserted');
        System.Assert.areEqual('New', processedApplications[0].Casehandler_Status__c, 'Assert correct application status');
        System.Assert.areEqual(1, documentLink.size(), 'Assert successful documentLink');
    }
    
    @isTest
    private static void processAdditionalInformationApplication() {
        Account account = [SELECT Id, Name FROM Account LIMIT 1];

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
        
        Test.startTest();
        AAREG_ApplicationController.processApplication(application, basisCodes, contacts, base64, fileName);
        List<Application__c> processedApplications = [SELECT Id, Status__c, Casehandler_Status__c FROM Application__c];
        List<RelatedContact__c> processedContacts = [SELECT Id, Name, Application__c FROM RelatedContact__c];
        List<ApplicationBasisCode__c> processedBasisCodes = [SELECT Id, Application__c FROM ApplicationBasisCode__c];
        List<ContentDocumentLink> documentLink = [
            SELECT Id
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :processedApplications[0].Id
        ];
        Test.stopTest();

        System.Assert.areEqual(1, processedApplications.size(), 'Check only one application was upserted');
        System.Assert.areEqual(2, processedContacts.size(), 'Check that both contacts were upserted');
        System.Assert.areEqual(2, processedBasisCodes.size(), 'Check that both Application Basis Codes were upserted');
       System.Assert.areEqual('In Progress', processedApplications[0].Status__c, 'Correct application status');
        System.Assert.areEqual(
            'In Progress',
            processedApplications[0].Casehandler_Status__c,
            'Correct application status'
        );
        System.Assert.areEqual(true, documentLink.isEmpty(), 'No documentLinks created');
    }
    
     @isTest
    private static void getLastUsedOrganizationInformation() {
        Profile profile = [SELECT Id, UserLicense.Name FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User user = new User();

        user.FirstName = 'John';
        user.LastName = 'Doe';
        user.Email = 'John.Doe@nav.no';
        user.Username = 'John.Doe@nav.no';
        user.Alias = 'j.doe';
        user.LanguageLocaleKey = 'no';
        user.LocaleSidKey = 'no_NO';
        user.TimeZoneSidKey = 'Europe/Paris';
        user.EmailEncodingKey = 'UTF-8';
        user.ProfileId = profile.Id;
        user.Department = '1';
        user.LastUsedOrganization__c = '929882989';

        insert user;

        Test.startTest();
        Account lastUsedOrganization = AAREG_ApplicationController.getLastUsedOrganizationInformation(user.id);
        Test.stopTest();

        System.Assert.areEqual(lastUsedOrganization.name, 'Fylke', 'Assert that the correct account name is returned.');
    }
    
     @isTest
    private static void getDraftApplication() {
        Profile profile = [SELECT Id, UserLicense.Name FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User user = AAREG_TestDataFactory.getStandardUser();
        insert user;

        Account account = [SELECT Id, Name,INT_OrganizationNumber__c,ShippingStreet,ShippingCity,ShippingPostalCode FROM Account LIMIT 1];

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

        Test.startTest();
        AAREG_ApplicationController.DraftApplication draft = AAREG_ApplicationController.getDraftApplication(
            application.Id
        );
        Test.stopTest();
        System.Assert.areEqual(application.Id, draft.application.Id, 'Draft application retrieved');
        System.Assert.areEqual(2, draft.basisCodes.size(), '2 draft basis codes retrieved');
        System.Assert.areEqual(2, draft.contacts.size(), '2 draft related contacts retrieved');
    }
    
     @isTest
    private static void deleteDraftRecord() {
         Account account = [SELECT Id, Name,INT_OrganizationNumber__c,ShippingStreet,ShippingCity,ShippingPostalCode FROM Account LIMIT 1];

        Application__c application = AAREG_TestDataFactory.getApplicationCounty(account);
        insert application;

        Test.startTest();
        AAREG_ApplicationController.deleteDraftRecord(application);
        Test.stopTest();

        List<Application__c> applications = [SELECT Id FROM Application__c];

        System.Assert.areEqual(0, applications.size(), 'No applications. Successful record deletion.');
    }
    
     @isTest
    private static void saveAsDraft() {
        Account account = [SELECT Id, Name,INT_OrganizationNumber__c,ShippingStreet,ShippingCity,ShippingPostalCode FROM Account LIMIT 1];

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

        Test.startTest();
        AAREG_ApplicationController.saveAsDraft(application, basisCodes, contacts, base64, fileName);
        Application__c processedApplication = [SELECT Id, Status__c FROM Application__c LIMIT 1];
        List<RelatedContact__c> processedContacts = [
            SELECT Id, Name, Application__c
            FROM RelatedContact__c
            WHERE Application__c = :processedApplication.Id
        ];
        List<ApplicationBasisCode__c> processedBasisCodes = [
            SELECT Id, Application__c
            FROM ApplicationBasisCode__c
            WHERE Application__c = :processedApplication.Id
        ];
        Test.stopTest();

        System.Assert.areEqual(2, processedContacts.size(), 'Check that both contacts were inserted');
        System.Assert.areEqual(2, processedBasisCodes.size(), 'Check that both Application Basis Codes were inserted');
        System.Assert.areEqual('Draft', processedApplication.Status__c, 'Assert correct application status');
    }
}