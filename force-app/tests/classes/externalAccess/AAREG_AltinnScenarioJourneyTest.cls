/**
 * Verifies scenario behavior through the public community controller and utility methods.
 *
 * @author Kenneth Sørensen
 * @since 2026-10-25
 * @group AAREG External Access Test
 */
@IsTest
private with sharing class AAREG_AltinnScenarioJourneyTest {
    private static final String organizationNumber = '111111111';

    /**
     * Gives the existing application path the configured Permit decision.
     *
     * @since 2026-10-25
     */
    @IsTest
    static void shouldGrantApplicationAccessForPermitScenario() {
        User user = AAREG_AltinnTestDataFactory.createCommunityAssignedUser('S01', 'subject-a');

        System.runAs(user) {
            System.Test.startTest();
            AAREG_HomeController.AccessResponse response = AAREG_HomeController.checkAndShareIfAuthorized(
                user.Id,
                organizationNumber
            );
            Integer callouts = Limits.getCallouts();
            System.Test.stopTest();

            System.Assert.isTrue(response.hasAccess);
            System.Assert.isTrue(response.hasApplicationAccess);
            System.Assert.areEqual(0, callouts);
        }
    }

    /**
     * Returns the assigned user's synthetic organizations from the home controller.
     *
     * @since 2026-10-25
     */
    @IsTest
    static void shouldReturnAssignedOrganizationsThroughHomeController() {
        User user = AAREG_AltinnTestDataFactory.createCommunityAssignedUser('S01', 'subject-a');

        System.runAs(user) {
            System.Test.startTest();
            AltinnCalloutService.AltinnOrganizationsResponse response = AAREG_HomeController.getOrganizationsWithRoles(
                user.Id
            );
            Integer callouts = Limits.getCallouts();
            System.Test.stopTest();

            System.Assert.isTrue(response.success);
            System.Assert.areEqual('v3', response.altinnVersion);
            System.Assert.areEqual(1, response.organizations.size());
            System.Assert.areEqual(organizationNumber, response.organizations[0].organizationNumber);
            System.Assert.areEqual(0, callouts);
        }
    }

    /**
     * Uses the configured support Permit after application Deny.
     *
     * @since 2026-10-25
     */
    @IsTest
    static void shouldUseSupportPermitAfterApplicationDeny() {
        User user = AAREG_AltinnTestDataFactory.createCommunityAssignedUser('S02', 'subject-a');

        System.runAs(user) {
            System.Test.startTest();
            AAREG_HomeController.AccessResponse response = AAREG_HomeController.checkAndShareIfAuthorized(
                user.Id,
                organizationNumber
            );
            Integer callouts = Limits.getCallouts();
            System.Test.stopTest();

            System.Assert.isTrue(response.hasAccess);
            System.Assert.isFalse(response.hasApplicationAccess);
            System.Assert.areEqual(0, callouts);
        }
    }

    /**
     * Leaves existing agreements untouched when both scenario rights are Deny.
     *
     * @since 2026-10-25
     */
    @IsTest
    static void shouldNotShareAgreementForCleanDenyScenario() {
        User user = AAREG_AltinnTestDataFactory.createCommunityAssignedUser('S03', 'subject-a');
        insertAgreementForOrganization(organizationNumber);

        System.runAs(user) {
            System.Test.startTest();
            AAREG_HomeController.AccessResponse response = AAREG_HomeController.checkAndShareIfAuthorized(
                user.Id,
                organizationNumber
            );
            Integer callouts = Limits.getCallouts();
            System.Test.stopTest();

            System.Assert.isFalse(response.hasAccess);
            System.Assert.isFalse(response.hasApplicationAccess);
            System.Assert.areEqual(0, callouts);
        }

        System.Assert.areEqual(0, [SELECT COUNT() FROM Agreement__Share WHERE UserOrGroupId = :user.Id]);
    }

    /**
     * Does not grant access or create shares when the assigned scenario returns response errors.
     *
     * @since 2026-10-25
     */
    @IsTest
    static void shouldDenyAccessWhenScenarioRightsReturnErrors() {
        User user = AAREG_AltinnTestDataFactory.createCommunityAssignedUser('S07', 'subject-a');
        insertAgreementForOrganization(organizationNumber);

        System.runAs(user) {
            System.Test.startTest();
            AAREG_HomeController.AccessResponse response = AAREG_HomeController.checkAndShareIfAuthorized(
                user.Id,
                organizationNumber
            );
            Integer callouts = Limits.getCallouts();
            System.Test.stopTest();

            System.Assert.isFalse(response.hasAccess);
            System.Assert.isFalse(response.hasApplicationAccess);
            System.Assert.areEqual(0, callouts);
        }

        System.Assert.areEqual(0, [SELECT COUNT() FROM Agreement__Share WHERE UserOrGroupId = :user.Id]);
    }

    private static void insertAgreementForOrganization(String targetOrganizationNumber) {
        Account account = new Account(
            Name = 'Synthetic Altinn Agreement Account',
            INT_OrganizationNumber__c = targetOrganizationNumber,
            INT_OrganizationalStructure__c = 'ORGL'
        );
        insert account;

        Application__c application = AAREG_TestDataFactory.getApplicationCounty(account);
        insert application;

        Agreement__c agreement = AAREG_TestDataFactory.getAgreement(account.Id);
        agreement.Application__c = application.Id;
        insert agreement;
    }
}
