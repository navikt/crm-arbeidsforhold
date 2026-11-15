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
    private static void shouldReturnAccountNameByOrganizationNumber() {
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
    private static void shouldProcessNewApplication() {
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
     * Submitting an application queues exactly one P360 application document archive job when archiving is enabled.
     *
     * @since 2026-11
     */
    @IsTest
    private static void submittedApplicationQueuesArchiveJobWhenArchivingIsEnabled() {
        P360_TestDataFactory.setArchiveProcessingEnabled(true);
        Account account = [SELECT Id FROM Account LIMIT 1];

        System.Test.startTest();
        Id applicationId = AAREG_ApplicationController.processApplication(
            new Application__c(Account__c = account.Id, IsConfirmationEmailSent__c = true),
            new List<ApplicationBasisCode__c>(),
            new List<RelatedContact__c>(),
            null,
            null
        );
        System.Test.stopTest();

        List<P360_Archive_Job__c> jobs = [
            SELECT Archive_Event_Type__c, Status__c, Idempotency_Key__c, Correlation_Id__c
            FROM P360_Archive_Job__c
            WHERE Application__c = :applicationId
        ];
        System.Assert.areEqual(1, jobs.size(), 'Submission must queue one archive job.');
        System.Assert.areEqual('ApplicationDocument', jobs[0].Archive_Event_Type__c);
        System.Assert.areEqual('Pending', jobs[0].Status__c);
        System.Assert.areEqual('APPLICATION_DOCUMENT:' + applicationId, jobs[0].Idempotency_Key__c);
        System.Assert.areEqual('ApplicationDocument:' + applicationId, jobs[0].Correlation_Id__c);
    }

    /**
     * Submitting an application does not queue P360 archive work while archiving is disabled.
     *
     * @since 2026-11
     */
    @IsTest
    private static void submittedApplicationIsNotQueuedWhileArchivingIsDisabled() {
        P360_TestDataFactory.setArchiveProcessingEnabled(false);
        Account account = [SELECT Id FROM Account LIMIT 1];

        System.Test.startTest();
        Id applicationId = AAREG_ApplicationController.processApplication(
            new Application__c(Account__c = account.Id, IsConfirmationEmailSent__c = true),
            new List<ApplicationBasisCode__c>(),
            new List<RelatedContact__c>(),
            null,
            null
        );
        System.Test.stopTest();

        System.Assert.areEqual(
            0,
            [SELECT COUNT() FROM P360_Archive_Job__c WHERE Application__c = :applicationId],
            'Disabled archiving must not queue jobs.'
        );
    }

    /**
     * Resubmitting an application requiring additional information keeps it in progress.
     *
     * @since October 2026
     */
    @IsTest
    private static void shouldKeepResubmittedApplicationInProgress() {
        Account account = [SELECT Id FROM Account LIMIT 1];

        User casehandler;
        System.runAs(new User(Id = UserInfo.getUserId())) {
            casehandler = Integration_TestDataFactory.createMinimumAccessUser();
        }

        Access_Request__c accessRequest = new Access_Request__c();
        insert accessRequest;

        Application__c application = new Application__c();
        application.Account__c = account.Id;
        application.Access_Request__c = accessRequest.Id;
        application.CasehandlerOwner__c = casehandler.Id;
        application.Status__c = 'Additional Information Required';
        application.Casehandler_Status__c = 'Additional Information Required';
        application.IsConfirmationEmailSent__c = true;
        insert application;

        application = [
            SELECT Id, Account__c, Access_Request__c, Status__c, Casehandler_Status__c
            FROM Application__c
            WHERE Id = :application.Id
        ];
        System.Assert.areEqual(
            'Additional Information Required',
            application.Status__c,
            'Application awaits information'
        );
        System.Assert.areEqual(
            'Additional Information Required',
            application.Casehandler_Status__c,
            'Case handler awaits information'
        );

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

        List<Application__c> result = [
            SELECT Id, Access_Request__c, Status__c, Casehandler_Status__c
            FROM Application__c
            WHERE Id = :appId
        ];

        System.Assert.areEqual(1, result.size(), 'Application should remain available');
        System.Assert.areEqual(application.Id, appId, 'Resubmission should reuse the application');
        System.Assert.areEqual(
            accessRequest.Id,
            result[0].Access_Request__c,
            'Resubmission should reuse the access request'
        );
        System.Assert.areEqual('In Progress', result[0].Status__c, 'Application should be in progress');
        System.Assert.areEqual(
            'In Progress',
            result[0].Casehandler_Status__c,
            'Case handler status should be in progress'
        );
    }

    /**
     * getLastUsedOrganizationInformation should return the account for the user's last used organization.
     *
     * @since May 2021
     */
    @IsTest
    private static void shouldReturnLastUsedOrganizationInformation() {
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
    private static void shouldReturnDraftApplication() {
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
    private static void shouldDeleteDraftRecord() {
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
    private static void shouldSaveApplicationAsDraft() {
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
    private static void shouldReturnDraftApplicationWithAccessRequest() {
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
    private static void shouldReuseAccessRequestWhenUpdatingApplication() {
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
     * processApplication should link uploaded files to both the application and the access request.
     *
     * @since October 2026
     */
    @IsTest
    private static void shouldLinkUploadedFileToApplicationAndAccessRequest() {
        Account account = [SELECT Id FROM Account LIMIT 1];
        Access_Request__c accessRequest = new Access_Request__c();
        insert accessRequest;

        Application__c application = new Application__c();
        application.Account__c = account.Id;
        application.Access_Request__c = accessRequest.Id;
        application.IsConfirmationEmailSent__c = true;
        application.Status__c = 'New';

        List<RelatedContact__c> contacts = new List<RelatedContact__c>{
            new RelatedContact__c(Name = 'Linked Contact')
        };
        List<ApplicationBasisCode__c> basisCodes = new List<ApplicationBasisCode__c>{ new ApplicationBasisCode__c() };
        String base64 = EncodingUtil.base64Encode(Blob.valueOf('test-content'));

        System.Test.startTest();
        Id appId = AAREG_ApplicationController.processApplication(
            application,
            basisCodes,
            contacts,
            base64,
            'document.txt'
        );
        System.Test.stopTest();

        Integer applicationLinks = [
            SELECT COUNT()
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :appId
        ];
        Integer accessRequestLinks = [
            SELECT COUNT()
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :accessRequest.Id
        ];

        System.Assert.areEqual(1, applicationLinks, 'Uploaded file should be linked to the application.');
        System.Assert.areEqual(1, accessRequestLinks, 'Uploaded file should be linked to the access request.');
    }

    /**
     * processApplication should still create the application when the forced sanitize-allowed branch is set.
     *
     * @since August 2026
     */
    @IsTest
    private static void shouldProcessApplicationThroughForcedSanitizeBranch() {
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
    private static void shouldReuseAccessRequestForExistingApplication() {
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
    private static void shouldHandleNullInputDuringSanitization() {
        Application__c sanitized = AAREG_ApplicationController.sanitizeApplicationForDmlForTest(null);
        System.Assert.areEqual(null, sanitized, 'Sanitize should return null when input is null.');
    }

    /**
     * sanitizeApplicationForDmlForTest should skip populated fields when the forced unknown-field branch is set.
     *
     * @since August 2026
     */
    @IsTest
    private static void shouldHandleUnknownFieldDuringForcedSanitization() {
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

    /**
     * Existing application attachments should be selected by default when no selection state exists.
     *
     * @since 2026-11-15
     */
    @IsTest
    private static void shouldSelectAllLegacyAttachmentsByDefault() {
        User communityUser = AAREG_AltinnTestDataFactory.createCommunityAssignedUser('S01', 'subject-a');
        grantCommunityPermissions(communityUser);
        Application__c application = createAttachmentTestApplication(
            communityUser,
            communityUser.LastUsedOrganization__c
        );

        List<ContentVersion> versions = new List<ContentVersion>{
            new ContentVersion(
                Title = 'First attachment',
                PathOnClient = 'first-attachment.txt',
                VersionData = Blob.valueOf('first')
            ),
            new ContentVersion(
                Title = 'Second attachment',
                PathOnClient = 'second-attachment.txt',
                VersionData = Blob.valueOf('second')
            )
        };
        insert versions;

        List<ContentVersion> insertedVersions = [
            SELECT Id, ContentDocumentId, Title
            FROM ContentVersion
            WHERE Id IN :versions
        ];
        List<ContentDocumentLink> links = new List<ContentDocumentLink>();
        Map<Id, String> expectedTitles = new Map<Id, String>();
        for (ContentVersion version : insertedVersions) {
            links.add(
                new ContentDocumentLink(
                    LinkedEntityId = application.Id,
                    ContentDocumentId = version.ContentDocumentId,
                    ShareType = 'I',
                    Visibility = 'AllUsers'
                )
            );
            expectedTitles.put(version.ContentDocumentId, version.Title);
        }
        insert links;

        List<AAREG_ApplicationController.AttachmentSelection> attachments;
        Integer callouts;
        System.Test.startTest();
        System.runAs(communityUser) {
            attachments = AAREG_ApplicationController.getApplicationAttachments(application.Id);
            callouts = Limits.getCallouts();
        }
        System.Test.stopTest();

        System.Assert.areEqual(2, attachments.size(), 'All linked attachments should be returned.');
        Map<Id, String> actualTitles = new Map<Id, String>();
        for (AAREG_ApplicationController.AttachmentSelection attachment : attachments) {
            System.Assert.isTrue(attachment.selected, 'Legacy attachments should be selected by default.');
            actualTitles.put(attachment.contentDocumentId, attachment.title);
        }
        System.Assert.areEqual(expectedTitles, actualTitles, 'Each linked document and its title should be returned.');
        System.Assert.areEqual(0, callouts, 'The assigned synthetic Altinn scenario must not call external services.');
    }

    /**
     * Rejects attachment access when the application belongs to another organization.
     *
     * @since 2026-11-15
     */
    @IsTest
    private static void shouldRejectAttachmentsForAnotherOrganization() {
        User communityUser = AAREG_AltinnTestDataFactory.createCommunityAssignedUser('S01', 'subject-a');
        grantCommunityPermissions(communityUser);
        Application__c application = createAttachmentTestApplication(communityUser, '929882989');

        System.Test.startTest();
        String error = readAttachmentAccessError(communityUser, application.Id);
        System.Test.stopTest();

        System.Assert.areEqual(
            AAREG_ApplicationController.ATTACHMENT_ACCESS_DENIED,
            error,
            'A different organization must not be able to read attachments.'
        );
    }

    /**
     * Rejects attachment access when Altinn denies application rights.
     *
     * @since 2026-11-15
     */
    @IsTest
    private static void shouldRejectAttachmentsWithoutApplicationRights() {
        User communityUser = AAREG_AltinnTestDataFactory.createCommunityAssignedUser('S03', 'subject-a');
        grantCommunityPermissions(communityUser);
        Application__c application = createAttachmentTestApplication(
            communityUser,
            communityUser.LastUsedOrganization__c
        );

        System.Test.startTest();
        String error = readAttachmentAccessError(communityUser, application.Id);
        System.Test.stopTest();

        System.Assert.areEqual(
            AAREG_ApplicationController.ATTACHMENT_ACCESS_DENIED,
            error,
            'Altinn denial must prevent access to attachments.'
        );
    }

    /**
     * Rejects attachment access when the Altinn decision cannot be verified.
     *
     * @since 2026-11-15
     */
    @IsTest
    private static void shouldRejectAttachmentsWhenRightsCannotBeVerified() {
        User communityUser = AAREG_AltinnTestDataFactory.createCommunityAssignedUser('S07', 'subject-a');
        grantCommunityPermissions(communityUser);
        Application__c application = createAttachmentTestApplication(
            communityUser,
            communityUser.LastUsedOrganization__c
        );

        System.Test.startTest();
        String error = readAttachmentAccessError(communityUser, application.Id);
        System.Test.stopTest();

        System.Assert.areEqual(
            AAREG_ApplicationController.ATTACHMENT_ACCESS_UNVERIFIED,
            error,
            'An unverifiable Altinn decision must not grant access to attachments.'
        );
    }

    /**
     * Does not return files that are shared with internal users only.
     *
     * @since 2026-11-15
     */
    @IsTest
    private static void shouldNotReturnInternalOnlyAttachments() {
        User communityUser = AAREG_AltinnTestDataFactory.createCommunityAssignedUser('S01', 'subject-a');
        grantCommunityPermissions(communityUser);
        Application__c application = createAttachmentTestApplication(
            communityUser,
            communityUser.LastUsedOrganization__c
        );
        ContentVersion version = new ContentVersion(
            Title = 'Internal note',
            PathOnClient = 'internal-note.txt',
            VersionData = Blob.valueOf('internal')
        );
        insert version;
        version = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :version.Id];
        insert new ContentDocumentLink(
            LinkedEntityId = application.Id,
            ContentDocumentId = version.ContentDocumentId,
            ShareType = 'I',
            Visibility = 'InternalUsers'
        );

        List<AAREG_ApplicationController.AttachmentSelection> attachments;
        System.Test.startTest();
        System.runAs(communityUser) {
            attachments = AAREG_ApplicationController.getApplicationAttachments(application.Id);
        }
        System.Test.stopTest();

        System.Assert.isTrue(attachments.isEmpty(), 'Internal-only files must not be exposed to portal users.');
    }

    private static String readAttachmentAccessError(User communityUser, Id applicationId) {
        String message;
        System.runAs(communityUser) {
            try {
                AAREG_ApplicationController.getApplicationAttachments(applicationId);
            } catch (AuraHandledException error) {
                message = error.getMessage();
            }
            System.Assert.areEqual(
                0,
                Limits.getCallouts(),
                'Synthetic Altinn scenarios must not call external services.'
            );
        }
        return message;
    }

    private static void grantCommunityPermissions(User communityUser) {
        PermissionSet permissionSet = [SELECT Id FROM PermissionSet WHERE Name = 'AAREG_CommunityPermission' LIMIT 1];
        System.runAs(new User(Id = UserInfo.getUserId())) {
            insert new PermissionSetAssignment(AssigneeId = communityUser.Id, PermissionSetId = permissionSet.Id);
        }
    }

    private static Application__c createAttachmentTestApplication(User communityUser, String organizationNumber) {
        Account account = [
            SELECT Id, Name, INT_OrganizationNumber__c, ShippingStreet, ShippingCity, ShippingPostalCode
            FROM Account
            WHERE INT_OrganizationNumber__c = '929882989'
            LIMIT 1
        ];
        account.INT_OrganizationNumber__c = organizationNumber;
        update account;

        Application__c application = AAREG_TestDataFactory.getApplicationCounty(account);
        application.OwnerId = communityUser.Id;
        insert application;
        return application;
    }
}
