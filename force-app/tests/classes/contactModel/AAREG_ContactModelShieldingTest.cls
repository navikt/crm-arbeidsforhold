/**
 * Tests that shielded persons stay outside the contact model (ADR-0008, K9).
 *
 * @author Kenneth Sørensen
 * @since 2026-11
 * @group Contact Model
 */
@IsTest
private class AAREG_ContactModelShieldingTest {
    @TestSetup
    static void setUp() {
        AAREG_ContactModelTestDataFactory.setUpPrimaryAccount();
        AAREG_ContactModelTestDataFactory.createOrganization('Bedrift AS');
        AAREG_ContactModelTestDataFactory.createPortalUser('Open', '01010111111');
        AAREG_ContactModelTestDataFactory.createPortalUser('Shielded', '01010122222');
    }

    private static User portalUser(String lastName) {
        return [SELECT Id FROM User WHERE LastName = :lastName AND ContactId != NULL LIMIT 1];
    }

    private static Account organization() {
        return [SELECT Id FROM Account WHERE Name = 'Bedrift AS' LIMIT 1];
    }

    @IsTest
    static void confidentialAddressAndNavEmployeesAreShielded() {
        User open = portalUser('Open');
        User shielded = portalUser('Shielded');
        AAREG_ContactModelTestDataFactory.shieldPerson(shielded);

        System.Test.startTest();
        Set<Id> result = AAREG_ContactModelShielding.shieldedUserIds(new Set<Id>{ open.Id, shielded.Id });
        Id openAccountId = [SELECT Contact.AccountId FROM User WHERE Id = :open.Id WITH SYSTEM_MODE].Contact.AccountId;
        Person__c employee = new Person__c(
            Name = '20088100000',
            INT_IsNavEmployee__c = true,
            INT_IsDeceased__c = false
        );
        insert as system employee;
        update as system new Account(Id = openAccountId, CRM_Person__c = employee.Id);
        Boolean employeeShielded = AAREG_ContactModelShielding.isShieldedUser(open.Id);
        System.Test.stopTest();

        System.Assert.areEqual(new Set<Id>{ shielded.Id }, result, 'Only the confidential person');
        System.Assert.isTrue(employeeShielded, 'Nav employees are shielded');
        System.Assert.isFalse(AAREG_ContactModelShielding.isShieldedUser(null), 'No user');
        System.Assert.isTrue(AAREG_ContactModelShielding.shieldedUserIds(null).isEmpty(), 'Null input');
    }

    @IsTest
    static void shieldedSubmitterGetsNoDomainContactOrProfile() {
        User open = portalUser('Open');
        User shielded = portalUser('Shielded');
        AAREG_ContactModelTestDataFactory.shieldPerson(shielded);
        Application__c openApplication = AAREG_ContactModelTestDataFactory.createSubmittedApplication(
            open,
            organization(),
            'open@bedrift.example'
        );
        Application__c shieldedApplication = AAREG_ContactModelTestDataFactory.createSubmittedApplication(
            shielded,
            organization(),
            'shielded@bedrift.example'
        );

        System.Test.startTest();
        AAREG_ContactModelService.recordSubmissions(
            new Map<Id, Id>{ openApplication.Id => open.Id, shieldedApplication.Id => shielded.Id }
        );
        System.Test.stopTest();

        System.Assert.isNotNull(AAREG_ContactModelService.findContactForUser(open.Id), 'Open submitter recorded');
        System.Assert.isNull(AAREG_ContactModelService.findContactForUser(shielded.Id), 'Shielded submitter skipped');
        System.Assert.areEqual(
            0,
            [
                SELECT COUNT()
                FROM AAREG_Contact_Point__c
                WHERE Email__c = 'shielded@bedrift.example'
                WITH SYSTEM_MODE
            ],
            'No contact point for the shielded submitter'
        );
        try {
            AAREG_ContactModelService.ensureContactForUser(shielded.Id);
            System.Assert.fail('Expected ContactModelException');
        } catch (AAREG_ContactModelService.ContactModelException error) {
            System.Assert.isTrue(error.getMessage().contains('Shielded'), error.getMessage());
        }
    }

    @IsTest
    static void panelMasksPersonsShieldedAfterTheirDataWasCreated() {
        User shielded = portalUser('Shielded');
        Account organization = organization();
        Application__c application = AAREG_ContactModelTestDataFactory.createSubmittedApplication(
            shielded,
            organization,
            'shielded@bedrift.example'
        );
        AAREG_ContactModelService.recordSubmissions(new Map<Id, Id>{ application.Id => shielded.Id });
        Contact contact = AAREG_ContactModelService.findContactForUser(shielded.Id);
        AAREG_ContactModelTestDataFactory.shieldPerson(shielded);
        AAREG_ContactModelTestDataFactory.assignToCurrentUser('AAREG_ContactModel_Admin');

        AAREG_ContactModelPanelController.Panel contactPanel;
        AAREG_ContactModelPanelController.Panel accountPanel;
        AAREG_ContactModelPanelController.Panel applicationPanel;
        System.runAs(new User(Id = UserInfo.getUserId())) {
            System.Test.startTest();
            contactPanel = AAREG_ContactModelPanelController.getPanel(contact.Id);
            accountPanel = AAREG_ContactModelPanelController.getPanel(organization.Id);
            applicationPanel = AAREG_ContactModelPanelController.getPanel(application.Id);
            System.Test.stopTest();
        }

        System.Assert.isTrue(contactPanel.summary.startsWith('Skjerma person'), contactPanel.summary);
        System.Assert.isTrue(contactPanel.sections.isEmpty(), 'No sections for a shielded contact');
        String accountJson = JSON.serialize(accountPanel);
        String applicationJson = JSON.serialize(applicationPanel);
        System.Assert.isFalse(accountJson.contains('shielded@bedrift.example'), accountJson);
        System.Assert.isFalse(accountJson.contains('Shielded'), 'Name masked: ' + accountJson);
        System.Assert.isTrue(accountJson.contains('Skjerma person'), accountJson);
        System.Assert.isFalse(applicationJson.contains('Shielded'), 'Name masked: ' + applicationJson);
        System.Assert.isTrue(applicationJson.contains('Skjerma person'), applicationJson);
    }

    @IsTest
    static void shieldedPortalUserHasNoProfileOrRoleFirstStart() {
        AAREG_ContactModelTestDataFactory.setFlags(
            new Map<String, Boolean>{
                AAREG_ContactModelGate.PROFILE => true,
                AAREG_ContactModelGate.ORG_SELECTOR => true
            },
            null
        );
        User shielded = portalUser('Shielded');
        AAREG_ContactModelTestDataFactory.shieldPerson(shielded);

        System.runAs(shielded) {
            System.Test.startTest();
            AAREG_ContactModelPortalController.Settings settings = AAREG_ContactModelPortalController.getSettings();
            System.Assert.isFalse(settings.profile, 'Profile hidden');
            System.Assert.isFalse(settings.orgSelector, 'Legacy application start');
            try {
                AAREG_ContactModelPortalController.getProfile(null);
                System.Assert.fail('Expected AuraHandledException');
            } catch (AuraHandledException error) {
                System.Assert.areEqual('Funksjonen er ikkje tilgjengeleg for deg.', error.getMessage(), 'Readable');
            }
            try {
                AAREG_ContactModelPortalController.selectApplicationOrganization('910000001');
                System.Assert.fail('Expected AuraHandledException');
            } catch (AuraHandledException error) {
                System.Assert.areEqual('Funksjonen er ikkje tilgjengeleg for deg.', error.getMessage(), 'Readable');
            }
            System.Test.stopTest();
        }
    }
}
