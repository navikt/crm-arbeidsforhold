/**
 * Tests the confirmation recipient in the contact model (K8, REQ-15), directly and through the submission flow.
 *
 * @author Kenneth Sørensen
 * @since 2026-11
 * @group Contact Model
 */
@IsTest
private class AAREG_ContactModelRecipientTest {
    private static final String ENTERED = 'kari@soknad.example';
    private static final String ORGANIZATION_ADDRESS = 'kari@bedrift.example';
    private static final String PRIVATE_ADDRESS = 'kari@privat.example';

    @TestSetup
    static void setUp() {
        AAREG_ContactModelTestDataFactory.setUpPrimaryAccount();
        AAREG_ContactModelTestDataFactory.createOrganization('Bedrift AS');
        AAREG_ContactModelTestDataFactory.createPortalUser('Mottakar', '01010154321');
    }

    private static User portalUser() {
        return [SELECT Id FROM User WHERE LastName = 'Mottakar' AND ContactId != NULL LIMIT 1];
    }

    private static Account organization() {
        return [SELECT Id FROM Account WHERE Name = 'Bedrift AS' LIMIT 1];
    }

    private static void setFlags(Boolean legacyOff, Boolean contextAddress) {
        AAREG_ContactModelTestDataFactory.setFlags(
            new Map<String, Boolean>{
                AAREG_ContactModelGate.LEGACY_MATCHING_OFF => legacyOff,
                AAREG_ContactModelGate.CONTEXT_ADDRESS => contextAddress
            },
            null
        );
    }

    private static AAREG_ContactModelRecipient.Result resolve(Id applicationId) {
        AAREG_ContactModelRecipient.Request request = new AAREG_ContactModelRecipient.Request();
        request.applicationId = applicationId;
        return AAREG_ContactModelRecipient.resolve(new List<AAREG_ContactModelRecipient.Request>{ request })[0];
    }

    private static Contact saveAddresses(User user) {
        Contact contact = AAREG_ContactModelService.ensureContactForUser(user.Id);
        AAREG_ContactModelService.saveContactPoint(contact.Id, organization().Id, ORGANIZATION_ADDRESS, null);
        AAREG_ContactModelService.saveContactPoint(contact.Id, null, PRIVATE_ADDRESS, null);
        return contact;
    }

    @IsTest
    static void switchedOffModelKeepsTheLegacyRecipientAndWritesNothing() {
        setFlags(false, false);
        Application__c application = AAREG_ContactModelTestDataFactory.createSubmittedApplication(
            portalUser(),
            organization(),
            ENTERED
        );

        System.Test.startTest();
        AAREG_ContactModelRecipient.Result result = resolve(application.Id);
        System.Test.stopTest();

        System.Assert.isFalse(result.useDomainContact, 'Legacy contact matching');
        System.Assert.isNull(result.contactId, 'No domain contact');
        System.Assert.isNull(result.toAddress, 'Legacy recipient');
        System.Assert.isNull(AAREG_ContactModelService.findContactForUser(portalUser().Id), 'Nothing written');
    }

    @IsTest
    static void contextAddressUsesTheSavedOrganizationAddressNeverThePrivateOne() {
        setFlags(false, true);
        User user = portalUser();
        saveAddresses(user);
        Application__c application = AAREG_ContactModelTestDataFactory.createSubmittedApplication(
            user,
            organization(),
            null
        );

        System.Test.startTest();
        AAREG_ContactModelRecipient.Result result = resolve(application.Id);
        System.Test.stopTest();

        System.Assert.isFalse(result.useDomainContact, 'Legacy contact matching is still on');
        System.Assert.isNull(result.contactId, 'Contact is chosen by the legacy flow');
        System.Assert.areEqual(
            ORGANIZATION_ADDRESS,
            result.toAddress,
            'Saved address for the application organization'
        );
    }

    @IsTest
    static void enteredAddressBecomesTheOrganizationAddressAndLeavesThePrivateOneAlone() {
        setFlags(false, true);
        User user = portalUser();
        Contact contact = saveAddresses(user);
        Application__c application = AAREG_ContactModelTestDataFactory.createSubmittedApplication(
            user,
            organization(),
            ENTERED
        );

        System.Test.startTest();
        AAREG_ContactModelRecipient.Result result = resolve(application.Id);
        System.Test.stopTest();

        System.Assert.areEqual(ENTERED, result.toAddress, 'The address entered for this organization');
        System.Assert.areEqual(
            ENTERED,
            AAREG_ContactModelService.findContactPoint(contact.Id, organization().Id).Email__c,
            'The organization address is updated'
        );
        System.Assert.areEqual(
            PRIVATE_ADDRESS,
            AAREG_ContactModelService.findContactPoint(contact.Id, null).Email__c,
            'The private address is unchanged'
        );
    }

    @IsTest
    static void legacyMatchingOffUsesTheDomainContactAndTheEnteredAddressForANewOrganization() {
        setFlags(true, false);
        User user = portalUser();
        Application__c application = AAREG_ContactModelTestDataFactory.createSubmittedApplication(
            user,
            organization(),
            ENTERED
        );

        System.Test.startTest();
        AAREG_ContactModelRecipient.Result result = resolve(application.Id);
        System.Test.stopTest();

        Contact contact = AAREG_ContactModelService.findContactForUser(user.Id);
        System.Assert.isNotNull(contact, 'Domain contact created on submission');
        System.Assert.isTrue(result.useDomainContact, 'Domain contact replaces matching per email');
        System.Assert.areEqual(contact.Id, result.contactId, 'Domain contact');
        System.Assert.areEqual(ENTERED, result.toAddress, 'The address entered for this organization');
    }

    @IsTest
    static void shieldedSubmitterKeepsTheLegacyRecipient() {
        setFlags(true, true);
        User user = portalUser();
        AAREG_ContactModelTestDataFactory.shieldPerson(user);
        Application__c application = AAREG_ContactModelTestDataFactory.createSubmittedApplication(
            user,
            organization(),
            ENTERED
        );

        System.Test.startTest();
        AAREG_ContactModelRecipient.Result result = resolve(application.Id);
        System.Test.stopTest();

        System.Assert.isFalse(result.useDomainContact, 'Shielded persons are outside the contact model');
        System.Assert.isNull(result.toAddress, 'Legacy recipient');
        System.Assert.isNull(AAREG_ContactModelService.findContactForUser(user.Id), 'No domain contact');
    }

    @IsTest
    static void personShieldedAfterTheirDataWasCreatedKeepsTheLegacyRecipient() {
        setFlags(true, true);
        User user = portalUser();
        saveAddresses(user);
        AAREG_ContactModelTestDataFactory.shieldPerson(user);
        Application__c application = AAREG_ContactModelTestDataFactory.createSubmittedApplication(
            user,
            organization(),
            ENTERED
        );

        System.Test.startTest();
        AAREG_ContactModelRecipient.Result result = resolve(application.Id);
        System.Test.stopTest();

        System.Assert.isFalse(result.useDomainContact, 'Shielded persons always use the legacy flow');
        System.Assert.isNull(result.contactId, 'No domain contact for a shielded person');
        System.Assert.isNull(result.toAddress, 'Legacy recipient');
    }

    @IsTest
    static void internalSubmitterKeepsTheLegacyRecipient() {
        setFlags(true, true);
        Application__c application = AAREG_ContactModelTestDataFactory.createApplication(organization(), ENTERED);

        System.Test.startTest();
        AAREG_ContactModelRecipient.Result result = resolve(application.Id);
        System.Test.stopTest();

        System.Assert.isFalse(result.useDomainContact, 'Not a portal submission');
        System.Assert.isNull(result.toAddress, 'Legacy recipient');
    }

    @IsTest
    static void submissionFlowLinksTheDomainContactAndQueuesTheOrganizationAddress() {
        P360_TestDataFactory.setArchiveProcessingEnabled(false);
        setFlags(true, true);
        User user = portalUser();
        Contact contact = saveAddresses(user);
        Id applicationId = createDraft(user);

        System.Test.startTest();
        update as system new Application__c(Id = applicationId, Casehandler_Status__c = 'New');
        System.Test.stopTest();

        Application__c result = [
            SELECT Contact__c, IsEmailConfirmationSent__c
            FROM Application__c
            WHERE Id = :applicationId
            WITH SYSTEM_MODE
        ];
        EmailQueue__c queued = confirmation(applicationId);
        System.Assert.areEqual(contact.Id, result.Contact__c, 'The domain contact is linked');
        System.Assert.isTrue(result.IsEmailConfirmationSent__c, 'Confirmation marked as queued');
        System.Assert.areEqual(ENTERED, queued.ToAddress__c, 'Address entered for the organization context');
        System.Assert.areEqual(
            PRIVATE_ADDRESS,
            AAREG_ContactModelService.findContactPoint(contact.Id, null).Email__c,
            'The private address is never used or changed'
        );
        System.Assert.areEqual(String.valueOf(contact.Id), queued.TargetObjectId__c, 'Domain contact is the target');
        System.Assert.areEqual(
            0,
            [SELECT COUNT() FROM Contact WHERE Email = :ENTERED WITH SYSTEM_MODE],
            'No contact per email'
        );
    }

    @IsTest
    static void submissionFlowKeepsLegacyBehaviourWhenSwitchedOff() {
        P360_TestDataFactory.setArchiveProcessingEnabled(false);
        setFlags(false, false);
        Id applicationId = createDraft(portalUser());

        System.Test.startTest();
        update as system new Application__c(Id = applicationId, Casehandler_Status__c = 'New');
        System.Test.stopTest();

        Application__c result = [
            SELECT Contact__c, Contact__r.Email, Contact__r.AAREG_Identity_Key__c
            FROM Application__c
            WHERE Id = :applicationId
            WITH SYSTEM_MODE
        ];
        System.Assert.areEqual(ENTERED, result.Contact__r.Email, 'Legacy contact per email');
        System.Assert.isNull(result.Contact__r.AAREG_Identity_Key__c, 'Not a domain contact');
        System.Assert.isNull(confirmation(applicationId).ToAddress__c, 'Legacy recipient');
    }

    private static Id createDraft(User user) {
        Application__c application = new Application__c(Email__c = ENTERED);
        System.runAs(user) {
            insert as system application;
        }
        update as system new Application__c(Id = application.Id, Account__c = organization().Id);
        return application.Id;
    }

    private static EmailQueue__c confirmation(Id applicationId) {
        return [
            SELECT ToAddress__c, TargetObjectId__c
            FROM EmailQueue__c
            WHERE WhatId__c = :applicationId AND TemplateName__c = 'aaRegApplicationConfirmation'
            WITH SYSTEM_MODE
            LIMIT 1
        ];
    }
}
