/**
 * Test class for AAREG_ApplicationController.
 *
 * @author Jordan Mathews
 * @author Ann Kristin Olsen
 * @author Kenneth Sørensen
 * @since May 2021
 * @group AAREG External Application
 */
@IsTest
private class AAREG_ApplicationControllerTest {
    /**
     * Creates a county account for use across the controller tests.
     *
     * @since May 2021
     */
    @TestSetup
    private static void makeData() {
        Account acct = AAREG_TestDataFactory.getAccountCounty();
        insert acct;
    }

    /**
     * getAccountNameByOrgNumber should return the account name for a known organization number.
     *
     * @since May 2021
     */
    @IsTest
    private static void testGetAccountNameByOrgNumber() {
        Account acct = [SELECT Id, INT_OrganizationNumber__c FROM Account LIMIT 1];

        System.Test.startTest();
        String accountName = AAREG_ApplicationController.getAccountNameByOrgNumber(acct.INT_OrganizationNumber__c);
        System.Test.stopTest();

        System.Assert.isNotNull(accountName, 'Account name should not be null');
    }

    /**
     * processApplication should create a new application with status New.
     *
     * @since May 2021
     */
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

    /**
     * processApplication should upsert an existing application and reset status to New.
     *
     * @since July 2026
     */
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
        System.Assert.areEqual(
            'New',
            result[0].Status__c,
            'Status should be New after processing Additional Information Required application'
        );
    }

    /**
     * getLastUsedOrganizationInformation should return the account for the user's last used organization.
     *
     * @since May 2021
     */
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

    /**
     * getDraftApplication should return the application together with its basis codes and related contacts.
     *
     * @since July 2026
     */
    @IsTest
    private static void testGetDraftApplication() {
        Account account = [
            SELECT Id, Name, INT_OrganizationNumber__c, ShippingStreet, ShippingCity, ShippingPostalCode
            FROM Account
            LIMIT 1
        ];

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

    /**
     * deleteDraftRecord should delete the given application record.
     *
     * @since July 2026
     */
    @IsTest
    private static void testDeleteDraftRecord() {
        Account account = [
            SELECT Id, Name, INT_OrganizationNumber__c, ShippingStreet, ShippingCity, ShippingPostalCode
            FROM Account
            LIMIT 1
        ];
        Application__c application = AAREG_TestDataFactory.getApplicationCounty(account);
        insert application;

        System.Test.startTest();
        AAREG_ApplicationController.deleteDraftRecord(application);
        System.Test.stopTest();

        List<Application__c> applications = [SELECT Id FROM Application__c];
        System.Assert.areEqual(0, applications.size(), 'No applications. Successful record deletion.');
    }

    /**
     * saveAsDraft should persist the application with status Draft.
     *
     * @since July 2026
     */
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

    /**
     * getDraftApplication should return the linked access request when present on the application.
     *
     * @since August 2026
     */
    @IsTest
    private static void testGetDraftApplicationWithAccessRequest() {
        Account account = [
            SELECT Id, Name, INT_OrganizationNumber__c, ShippingStreet, ShippingCity, ShippingPostalCode
            FROM Account
            LIMIT 1
        ];
        Access_Request__c ar = new Access_Request__c();
        insert ar;

        Application__c application = AAREG_TestDataFactory.getApplicationCounty(account);
        application.Access_Request__c = ar.Id;
        insert application;

        System.Test.startTest();
        AAREG_ApplicationController.DraftApplication draft = AAREG_ApplicationController.getDraftApplication(
            application.Id
        );
        System.Test.stopTest();

        System.Assert.isNotNull(draft.accessRequest, 'Access request should be returned when linked on application.');
        System.Assert.areEqual(ar.Id, draft.accessRequest.Id, 'Expected linked access request id.');
    }

    /**
     * saveAsDraft should reuse the existing access request when updating an application.
     *
     * @since August 2026
     */
    @IsTest
    private static void testUpdateExistingApplicationReusesAccessRequest() {
        Account account = [
            SELECT Id, Name, INT_OrganizationNumber__c, ShippingStreet, ShippingCity, ShippingPostalCode
            FROM Account
            LIMIT 1
        ];
        Access_Request__c ar = new Access_Request__c();
        insert ar;

        Application__c existing = AAREG_TestDataFactory.getApplicationCounty(account);
        existing.Access_Request__c = ar.Id;
        insert existing;

        List<RelatedContact__c> contacts = new List<RelatedContact__c>{
            new RelatedContact__c(Name = 'Updated Contact')
        };
        List<ApplicationBasisCode__c> basisCodes = new List<ApplicationBasisCode__c>{ new ApplicationBasisCode__c() };

        Application__c updateForDraft = new Application__c(
            Id = existing.Id,
            Access_Request__c = null,
            Email__c = 'draft-update@nav.no'
        );

        System.Test.startTest();
        Id draftId = AAREG_ApplicationController.saveAsDraft(updateForDraft, basisCodes, contacts, null, null);
        System.Test.stopTest();

        Application__c afterDraft = [
            SELECT Id, Access_Request__c, Email__c, Status__c
            FROM Application__c
            WHERE Id = :draftId
            LIMIT 1
        ];

        System.Assert.areEqual(
            ar.Id,
            afterDraft.Access_Request__c,
            'Existing access request should be reused on saveAsDraft.'
        );
        System.Assert.areEqual('Draft', afterDraft.Status__c, 'Status should be set to Draft.');

        AAREG_ApplicationController.forceSanitizeAllowedBranch = false;
    }

    /**
     * processApplication should still create the application when the forced sanitize-allowed branch is set.
     *
     * @since August 2026
     */
    @IsTest
    private static void testProcessApplicationForceSanitizeAllowedBranch() {
        Account account = [SELECT Id FROM Account LIMIT 1];

        Application__c application = new Application__c();
        application.Account__c = account.Id;
        application.IsConfirmationEmailSent__c = true;
        application.Status__c = 'New';

        List<RelatedContact__c> contacts = new List<RelatedContact__c>{
            new RelatedContact__c(Name = 'Sanitize Contact')
        };
        List<ApplicationBasisCode__c> basisCodes = new List<ApplicationBasisCode__c>{ new ApplicationBasisCode__c() };

        Test.startTest();
        AAREG_ApplicationController.forceSanitizeAllowedBranch = true;
        Id appId = AAREG_ApplicationController.processApplication(application, basisCodes, contacts, null, null);
        AAREG_ApplicationController.forceSanitizeAllowedBranch = false;
        Test.stopTest();

        System.Assert.isNotNull(appId, 'Application should be created when forcing sanitize allowed branch.');
    }

    /**
     * processApplication should reuse the existing access request when updating an existing application.
     *
     * @since August 2026
     */
    @IsTest
    private static void testProcessApplicationExistingRecordReusesAccessRequest() {
        Account account = [
            SELECT Id, Name, INT_OrganizationNumber__c, ShippingStreet, ShippingCity, ShippingPostalCode
            FROM Account
            LIMIT 1
        ];
        Access_Request__c ar = new Access_Request__c();
        insert ar;

        Application__c existing = AAREG_TestDataFactory.getApplicationCounty(account);
        existing.Access_Request__c = ar.Id;
        insert existing;

        Application__c updateForProcess = new Application__c(
            Id = existing.Id,
            Access_Request__c = null,
            Status__c = 'New',
            IsConfirmationEmailSent__c = true
        );

        List<RelatedContact__c> contacts = new List<RelatedContact__c>{ new RelatedContact__c(Name = 'Reuse Contact') };
        List<ApplicationBasisCode__c> basisCodes = new List<ApplicationBasisCode__c>{ new ApplicationBasisCode__c() };

        Test.startTest();
        Id processedId = AAREG_ApplicationController.processApplication(
            updateForProcess,
            basisCodes,
            contacts,
            null,
            null
        );
        Test.stopTest();

        Application__c afterProcess = [
            SELECT Id, Access_Request__c
            FROM Application__c
            WHERE Id = :processedId
            LIMIT 1
        ];

        System.Assert.areEqual(
            ar.Id,
            afterProcess.Access_Request__c,
            'Existing access request should be reused in processApplication update path.'
        );
    }

    /**
     * sanitizeApplicationForDmlForTest should return null for a null input.
     *
     * @since August 2026
     */
    @IsTest
    private static void testSanitizeApplicationForDmlNullInput() {
        Application__c sanitized = AAREG_ApplicationController.sanitizeApplicationForDmlForTest(null);
        System.Assert.areEqual(null, sanitized, 'Sanitize should return null when input is null.');
    }

    /**
     * sanitizeApplicationForDmlForTest should skip populated fields when the forced unknown-field branch is set.
     *
     * @since August 2026
     */
    @IsTest
    private static void testSanitizeApplicationForDmlForcedUnknownFieldBranch() {
        Application__c application = new Application__c(Status__c = 'Draft', IsConfirmationEmailSent__c = true);

        AAREG_ApplicationController.forceSanitizeUnknownFieldBranch = true;
        Application__c sanitized = AAREG_ApplicationController.sanitizeApplicationForDmlForTest(application);
        AAREG_ApplicationController.forceSanitizeUnknownFieldBranch = false;

        System.Assert.isNotNull(sanitized, 'Sanitize should return an Application instance.');
        System.Assert.areEqual(
            null,
            sanitized.Status__c,
            'When forced branch is enabled, populated fields should be skipped.'
        );
    }
}
