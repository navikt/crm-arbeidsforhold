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
     * Creates a minimum-access user with the applicant permission set, so submission tests use the applicant's
     * field and object access instead of the running administrator's.
     */
    private static User createApplicant() {
        User applicant = new User(
            FirstName = 'Applicant',
            LastName = 'Tester',
            Email = 'aareg.applicant@example.com',
            Username = 'aareg.applicant.' + System.currentTimeMillis() + '@example.com',
            Alias = 'aaregapp',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'Europe/Oslo',
            EmailEncodingKey = 'UTF-8',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Minimum Access - Salesforce' LIMIT 1]
            .Id
        );
        System.runAs(new User(Id = UserInfo.getUserId())) {
            insert applicant;
            insert new PermissionSetAssignment(
                AssigneeId = applicant.Id,
                PermissionSetId = [SELECT Id FROM PermissionSet WHERE Name = 'AAREG_CommunityPermission' LIMIT 1]
                .Id
            );
        }
        return applicant;
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
        User applicant = createApplicant();

        Id processedApplicationId;
        System.Test.startTest();
        System.runAs(applicant) {
            processedApplicationId = AAREG_ApplicationController.processApplication(
                application,
                basisCodes,
                contacts,
                base64,
                fileName
            );
        }
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
     * processApplication should save an application requiring additional information and move it to In Progress.
     *
     * @since July 2026
     */
    @IsTest
    private static void shouldMoveAdditionalInformationApplicationToInProgress() {
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
        User applicant = createApplicant();

        Id appId;
        System.Test.startTest();
        System.runAs(applicant) {
            appId = AAREG_ApplicationController.processApplication(application, basisCodes, contacts, base64, fileName);
        }
        System.Test.stopTest();

        List<Application__c> result = [SELECT Id, Status__c FROM Application__c WHERE Id = :appId];

        System.Assert.areEqual(1, result.size(), 'Application should be upserted');
        System.Assert.areEqual(
            'In Progress',
            result[0].Status__c,
            'Status should be In Progress after processing Additional Information Required application'
        );
    }

    /**
     * Keeps a previously saved application in progress after additional information is submitted.
     *
     * @since 2026-11-15
     */
    @IsTest
    private static void shouldKeepResubmittedApplicationInProgress() {
        User applicant;
        System.runAs(new User(Id = UserInfo.getUserId())) {
            applicant = Integration_TestDataFactory.createMinimumAccessUser();
            PermissionSet communityPermission = [
                SELECT Id
                FROM PermissionSet
                WHERE Name = 'AAREG_CommunityPermission'
                LIMIT 1
            ];
            insert new PermissionSetAssignment(AssigneeId = applicant.Id, PermissionSetId = communityPermission.Id);
        }

        Account account = [SELECT Id FROM Account LIMIT 1];
        Access_Request__c accessRequest = new Access_Request__c();
        insert accessRequest;

        Application__c application = new Application__c(
            Account__c = account.Id,
            AccountId__c = String.valueOf(account.Id),
            Access_Request__c = accessRequest.Id,
            OwnerId = applicant.Id,
            CasehandlerOwner__c = UserInfo.getUserId(),
            Status__c = 'Additional Information Required',
            Casehandler_Status__c = 'Additional Information Required',
            IsConfirmationEmailSent__c = true
        );
        insert application;
        application = [
            SELECT Id, Account__c, AccountId__c, Access_Request__c, Status__c, Casehandler_Status__c
            FROM Application__c
            WHERE Id = :application.Id
        ];
        System.Assert.areEqual(account.Id, application.Account__c, 'The applicant organization should be linked');
        System.Assert.areEqual(
            String.valueOf(account.Id),
            application.AccountId__c,
            'The account ID used by the after-insert flow should be preserved'
        );
        System.Assert.areEqual('Additional Information Required', application.Status__c);
        System.Assert.areEqual('Additional Information Required', application.Casehandler_Status__c);

        Id originalApplicationId = application.Id;
        Id processedApplicationId;
        System.Test.startTest();
        System.runAs(applicant) {
            processedApplicationId = AAREG_ApplicationController.processApplication(
                application,
                new List<ApplicationBasisCode__c>(),
                new List<RelatedContact__c>(),
                null,
                null
            );
        }
        System.Test.stopTest();

        Application__c result = [
            SELECT Id, Account__c, Access_Request__c, Status__c, Casehandler_Status__c
            FROM Application__c
            WHERE Id = :processedApplicationId
        ];
        System.Assert.areEqual(originalApplicationId, result.Id, 'Resubmission should reuse the application');
        System.Assert.areEqual(account.Id, result.Account__c, 'Resubmission should retain the applicant organization');
        System.Assert.areEqual(accessRequest.Id, result.Access_Request__c, 'The access request should be reused');
        Access_Request__c resultAccessRequest = [
            SELECT Account__c
            FROM Access_Request__c
            WHERE Id = :result.Access_Request__c
        ];
        System.Assert.areEqual(
            account.Id,
            resultAccessRequest.Account__c,
            'The existing access request should retain the applicant organization'
        );
        System.Assert.areEqual('In Progress', result.Status__c, 'Application should be in progress');
        System.Assert.areEqual(
            'In Progress',
            result.Casehandler_Status__c,
            'Case handler status should be in progress'
        );
    }

    /**
     * A direct submission links the applicant contact, queues the confirmation e-mail and generates the archive text
     * with the notification contact's e-mail.
     *
     * @since 2026-11-17
     */
    @IsTest
    private static void shouldLinkApplicantContactWhenSubmittingDirectly() {
        Account account = [SELECT Id FROM Account LIMIT 1];
        User applicant = createApplicant();

        Id applicationId;
        System.Test.startTest();
        System.runAs(applicant) {
            applicationId = AAREG_ApplicationController.processApplication(
                buildPortalApplication(account.Id, 'applicant.direct@example.invalid'),
                new List<ApplicationBasisCode__c>(),
                new List<RelatedContact__c>{ buildNotificationContact('notify.direct@example.invalid') },
                null,
                null
            );
        }
        System.Test.stopTest();

        Application__c result = readSubmittedApplication(applicationId);
        System.Assert.areEqual('New', result.Casehandler_Status__c, 'The application should be new');
        System.Assert.isNotNull(result.Contact__c, 'The applicant contact should be linked');
        System.Assert.areEqual('applicant.direct@example.invalid', result.Contact__r.Email);
        System.Assert.areEqual(
            account.Id,
            result.Contact__r.AccountId,
            'The contact should belong to the organization'
        );
        System.Assert.isTrue(result.IsEmailConfirmationSent__c, 'The confirmation should be marked as queued');
        System.Assert.areEqual(1, countQueuedConfirmations(applicationId), 'One confirmation should be queued');
        System.Assert.isNotNull(result.ApplicationDeadlineForReply__c, 'The reply deadline should be set');
        System.Assert.isTrue(
            result.AA_register_application_text__c.contains('notify.direct@example.invalid'),
            'The generated text should contain the notification contact e-mail'
        );
        System.Assert.isTrue(
            result.AA_register_application_text__c.contains('applicant.direct@example.invalid'),
            'The generated text should contain the applicant contact e-mail'
        );
    }

    /**
     * A direct submission reuses an existing contact with the same organization and e-mail instead of creating a
     * duplicate.
     *
     * @since 2026-11-17
     */
    @IsTest
    private static void shouldReuseExistingContactWhenSubmittingDirectly() {
        Account account = [SELECT Id FROM Account LIMIT 1];
        Contact existingContact = new Contact(
            AccountId = account.Id,
            LastName = 'Existing',
            Email = 'applicant.existing@example.invalid'
        );
        insert existingContact;
        User applicant = createApplicant();

        Id applicationId;
        System.Test.startTest();
        System.runAs(applicant) {
            applicationId = AAREG_ApplicationController.processApplication(
                buildPortalApplication(account.Id, 'applicant.existing@example.invalid'),
                new List<ApplicationBasisCode__c>(),
                new List<RelatedContact__c>(),
                null,
                null
            );
        }
        System.Test.stopTest();

        System.Assert.areEqual(existingContact.Id, readSubmittedApplication(applicationId).Contact__c);
        System.Assert.areEqual(
            1,
            [SELECT COUNT() FROM Contact WHERE Email = 'applicant.existing@example.invalid'],
            'No duplicate contact should be created'
        );
    }

    /**
     * Submitting a draft after changing a notification contact's e-mail generates the archive text with the new
     * e-mail, not the e-mail saved in the draft.
     *
     * @since 2026-11-17
     */
    @IsTest
    private static void shouldUseChangedNotificationEmailWhenSubmittingDraft() {
        Account account = [SELECT Id FROM Account LIMIT 1];
        User applicant = createApplicant();

        Id applicationId;
        System.runAs(applicant) {
            applicationId = AAREG_ApplicationController.saveAsDraft(
                buildPortalApplication(account.Id, 'applicant.draft@example.invalid'),
                new List<ApplicationBasisCode__c>(),
                new List<RelatedContact__c>{ buildNotificationContact('notify.old@example.invalid') },
                null,
                null
            );
        }
        RelatedContact__c changedContact = [
            SELECT Id, Name, Email__c
            FROM RelatedContact__c
            WHERE Application__c = :applicationId
        ];
        changedContact.Email__c = 'notify.new@example.invalid';
        Application__c draft = buildPortalApplication(account.Id, 'applicant.draft@example.invalid');
        draft.Id = applicationId;
        draft.Status__c = 'Draft';

        System.Test.startTest();
        System.runAs(applicant) {
            AAREG_ApplicationController.processApplication(
                draft,
                new List<ApplicationBasisCode__c>(),
                new List<RelatedContact__c>{ changedContact },
                null,
                null
            );
        }
        System.Test.stopTest();

        Application__c result = readSubmittedApplication(applicationId);
        System.Assert.areEqual('applicant.draft@example.invalid', result.Contact__r.Email);
        System.Assert.isTrue(
            result.AA_register_application_text__c.contains('notify.new@example.invalid'),
            'The generated text should contain the changed e-mail'
        );
        System.Assert.isFalse(
            result.AA_register_application_text__c.contains('notify.old@example.invalid'),
            'The generated text should not contain the e-mail saved in the draft'
        );
    }

    /**
     * Submitting a draft after changing the applicant e-mail links a contact with the new e-mail.
     *
     * @since 2026-11-17
     */
    @IsTest
    private static void shouldUseChangedApplicantEmailWhenSubmittingDraft() {
        Account account = [SELECT Id FROM Account LIMIT 1];
        User applicant = createApplicant();

        Id applicationId;
        System.runAs(applicant) {
            applicationId = AAREG_ApplicationController.saveAsDraft(
                buildPortalApplication(account.Id, 'applicant.before@example.invalid'),
                new List<ApplicationBasisCode__c>(),
                new List<RelatedContact__c>(),
                null,
                null
            );
        }
        Application__c draft = buildPortalApplication(account.Id, 'applicant.after@example.invalid');
        draft.Id = applicationId;
        draft.Status__c = 'Draft';

        System.Test.startTest();
        System.runAs(applicant) {
            AAREG_ApplicationController.processApplication(
                draft,
                new List<ApplicationBasisCode__c>(),
                new List<RelatedContact__c>(),
                null,
                null
            );
        }
        System.Test.stopTest();

        Application__c result = readSubmittedApplication(applicationId);
        System.Assert.areEqual('applicant.after@example.invalid', result.Email__c);
        System.Assert.areEqual('applicant.after@example.invalid', result.Contact__r.Email);
        System.Assert.areEqual(1, countQueuedConfirmations(applicationId), 'One confirmation should be queued');
    }

    /**
     * Resubmitting requested information keeps the linked contact and does not queue another confirmation.
     *
     * @since 2026-11-17
     */
    @IsTest
    private static void shouldNotQueueConfirmationAgainWhenResubmitting() {
        Account account = [SELECT Id FROM Account LIMIT 1];
        User applicant = createApplicant();

        Id applicationId;
        System.runAs(applicant) {
            applicationId = AAREG_ApplicationController.processApplication(
                buildPortalApplication(account.Id, 'applicant.resubmit@example.invalid'),
                new List<ApplicationBasisCode__c>(),
                new List<RelatedContact__c>(),
                null,
                null
            );
        }
        Application__c submitted = readSubmittedApplication(applicationId);
        update new Application__c(
            Id = applicationId,
            CasehandlerOwner__c = UserInfo.getUserId(),
            Status__c = 'Additional Information Required',
            Casehandler_Status__c = 'Additional Information Required'
        );
        Application__c resubmission = buildPortalApplication(account.Id, 'applicant.resubmit@example.invalid');
        resubmission.Id = applicationId;
        resubmission.Status__c = 'Additional Information Required';

        System.Test.startTest();
        System.runAs(applicant) {
            AAREG_ApplicationController.processApplication(
                resubmission,
                new List<ApplicationBasisCode__c>(),
                new List<RelatedContact__c>(),
                null,
                null
            );
        }
        System.Test.stopTest();

        Application__c result = readSubmittedApplication(applicationId);
        System.Assert.areEqual('In Progress', result.Casehandler_Status__c);
        System.Assert.areEqual(submitted.Contact__c, result.Contact__c, 'The linked contact should be kept');
        System.Assert.areEqual(1, countQueuedConfirmations(applicationId), 'No extra confirmation should be queued');
    }

    private static Application__c buildPortalApplication(Id accountId, String applicantEmail) {
        return new Application__c(
            AccountId__c = String.valueOf(accountId),
            Email__c = applicantEmail,
            TermsOfUse__c = true
        );
    }

    private static RelatedContact__c buildNotificationContact(String email) {
        return new RelatedContact__c(Name = 'Notification Contact', Email__c = email, Phone__c = '12345678');
    }

    private static Application__c readSubmittedApplication(Id applicationId) {
        return [
            SELECT
                Id,
                Email__c,
                Casehandler_Status__c,
                Contact__c,
                Contact__r.Email,
                Contact__r.AccountId,
                IsEmailConfirmationSent__c,
                ApplicationDeadlineForReply__c,
                AA_register_application_text__c
            FROM Application__c
            WHERE Id = :applicationId
        ];
    }

    private static Integer countQueuedConfirmations(Id applicationId) {
        return [
            SELECT COUNT()
            FROM EmailQueue__c
            WHERE WhatId__c = :applicationId AND TemplateName__c = 'aaRegApplicationConfirmation'
        ];
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
}
