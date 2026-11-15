/**
 * Behaviour tests for the Arbeidsforhold Admin configuration view.
 *
 * @author Kenneth Sørensen
 * @since 2026-11
 * @group Arbeidsforhold Admin
 */
@IsTest
private with sharing class AAREG_AdminConfigurationControllerTest {
    private static AAREG_AdminConfigurationController.Item findItem(String sectionKey, String label) {
        for (
            AAREG_AdminConfigurationController.Section section : AAREG_AdminConfigurationController.getConfiguration()
        ) {
            if (section.key != sectionKey) {
                continue;
            }
            for (AAREG_AdminConfigurationController.Item item : section.items) {
                if (item.label == label) {
                    return item;
                }
            }
        }
        System.Assert.fail('Missing item ' + sectionKey + '/' + label);
        return null;
    }

    @IsTest
    static void enabledArchiveFlagIsShownAsOnWithWarning() {
        P360_TestDataFactory.setArchiveProcessingEnabled(true);

        System.Test.startTest();
        AAREG_AdminConfigurationController.Item item = findItem('p360', 'P360-arkivering (feature flag)');
        System.Test.stopTest();

        System.Assert.areEqual('På', item.value, 'Enabled flag should be shown as on');
        System.Assert.areEqual('warning', item.state, 'Enabled archive processing should stand out');
        System.Assert.isNotNull(item.explanation, 'Every value needs an explanation');
    }

    @IsTest
    static void mockTransportAndMissingNamedCredentialAreReported() {
        P360_TestDataFactory.setArchiveProcessingEnabled(false);
        insert new P360_Integration_Setting__c(
            SetupOwnerId = UserInfo.getOrganizationId(),
            Use_Mock_Transport__c = true
        );

        System.Test.startTest();
        AAREG_AdminConfigurationController.Item mock = findItem('p360', 'Mock-transport');
        AAREG_AdminConfigurationController.Item credential = findItem('p360', 'Named Credential');
        System.Test.stopTest();

        System.Assert.areEqual('På', mock.value, 'Mock transport should be shown as on');
        System.Assert.areEqual('Ikkje sett', credential.value, 'Missing credential name should be explicit');
    }

    @IsTest
    static void unknownNamedCredentialIsShownAsMissing() {
        insert new P360_Integration_Setting__c(
            SetupOwnerId = UserInfo.getOrganizationId(),
            Named_Credential_Name__c = 'Does_Not_Exist_In_Org'
        );

        System.Test.startTest();
        AAREG_AdminConfigurationController.Item credential = findItem('p360', 'Named Credential');
        System.Test.stopTest();

        System.Assert.isTrue(credential.value.contains('finst ikkje'), 'Unknown credential should be flagged');
        System.Assert.areEqual('warning', credential.state, 'Missing credential should stand out');
    }

    @IsTest
    static void triggerSettingsForArchiveGuardAreListed() {
        System.Test.startTest();
        List<AAREG_AdminConfigurationController.Section> sections = AAREG_AdminConfigurationController.getConfiguration();
        System.Test.stopTest();

        Boolean found = false;
        for (AAREG_AdminConfigurationController.Section section : sections) {
            if (section.key == 'triggers') {
                for (AAREG_AdminConfigurationController.Item item : section.items) {
                    found = found || item.label.contains('P360_ArchiveGuardHandler');
                }
            }
        }
        System.Assert.isTrue(found, 'The P360 archive guard trigger setting should be listed');
    }

    @IsTest
    static void readingConfigurationPerformsNoWrites() {
        User minimumAccessUser = P360_TestDataFactory.createMinimumAccessUser();
        List<AAREG_AdminConfigurationController.Section> sections;

        System.runAs(minimumAccessUser) {
            System.Test.startTest();
            sections = AAREG_AdminConfigurationController.getConfiguration();
            System.Assert.areEqual(0, Limits.getDmlStatements(), 'The configuration view must not write');
            System.Test.stopTest();
        }

        System.Assert.isFalse(sections.isEmpty(), 'Minimum access user still gets an explained view');
        for (AAREG_AdminConfigurationController.Section section : sections) {
            System.Assert.isNotNull(section.setupUrl, 'Each section links to Setup');
        }
    }
}
