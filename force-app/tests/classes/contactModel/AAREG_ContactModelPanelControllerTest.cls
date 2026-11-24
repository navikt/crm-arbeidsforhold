/**
 * Tests the contact model panel on contact, account and application record pages.
 *
 * @author Kenneth Sørensen
 * @since 2026-11
 * @group Contact Model
 */
@IsTest
private class AAREG_ContactModelPanelControllerTest {
    @TestSetup
    static void setUp() {
        AAREG_ContactModelTestDataFactory.setUpPrimaryAccount();
    }

    @IsTest
    static void contactAccountAndApplicationShowTheModel() {
        User submitter = AAREG_ContactModelTestDataFactory.createMinimumAccessUser('Nordmann', null);
        Account organization = AAREG_ContactModelTestDataFactory.createOrganization('Bedrift AS');
        Application__c application = AAREG_ContactModelTestDataFactory.createApplication(
            organization,
            'kari@bedrift.example'
        );
        AAREG_ContactModelService.recordSubmissions(new Map<Id, Id>{ application.Id => submitter.Id });
        Contact contact = AAREG_ContactModelService.findContactForUser(submitter.Id);

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

        System.Assert.isTrue(contactPanel.summary.startsWith('Domenekontakt'), contactPanel.summary);
        System.Assert.areEqual(1, section(contactPanel, 'organizations').rows.size(), 'One organization relation');
        Map<String, Object> point = section(contactPanel, 'contactPoints').rows[0];
        System.Assert.areEqual('kari@bedrift.example', point.get('email'), 'Administrator sees the address');

        System.Assert.areEqual(1, section(accountPanel, 'people').rows.size(), 'One person at the organization');
        System.Assert.areEqual(
            '1 av 1 deltakingar er kopla til ein domenekontakt.',
            applicationPanel.summary,
            'Submitter is linked'
        );
    }

    @IsTest
    static void unsupportedOrMissingRecordGivesSummaryOnly() {
        System.Assert.areEqual('Ingen post.', AAREG_ContactModelPanelController.getPanel(null).summary, 'Null');
        AAREG_ContactModelPanelController.Panel panel = AAREG_ContactModelPanelController.getPanel(
            UserInfo.getUserId()
        );
        System.Assert.isTrue(panel.sections.isEmpty(), 'No sections for users');
    }

    @IsTest
    static void caseHandlerWithoutContactPointAccessSeesNoAddresses() {
        User caseHandler = AAREG_ContactModelTestDataFactory.createMinimumAccessUser(
            'Saksbehandler',
            'AAREG_Arbeidsforhold_Saksbehandling'
        );
        Contact contact = new Contact(LastName = 'Nordmann');
        insert contact;

        AAREG_ContactModelPanelController.Panel panel;
        System.runAs(caseHandler) {
            panel = AAREG_ContactModelPanelController.getPanel(contact.Id);
        }

        AAREG_ContactModelPanelController.Section points = section(panel, 'contactPoints');
        System.Assert.isTrue(points.rows.isEmpty(), 'No contact points without object access');
        System.Assert.isTrue(points.emptyText.contains('ikkje tilgang'), points.emptyText);
    }

    private static AAREG_ContactModelPanelController.Section section(
        AAREG_ContactModelPanelController.Panel panel,
        String key
    ) {
        for (AAREG_ContactModelPanelController.Section candidate : panel.sections) {
            if (candidate.key == key) {
                return candidate;
            }
        }
        System.Assert.fail('Missing section ' + key + ' in ' + JSON.serialize(panel));
        return null;
    }
}
