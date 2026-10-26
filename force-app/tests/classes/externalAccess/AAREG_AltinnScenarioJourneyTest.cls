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
     * Rejects another user's organization lookup before selecting a live or scenario provider.
     *
     * @since 2026-10-26
     */
    @IsTest
    static void shouldRejectOrganizationLookupForAnotherUser() {
        Id differentUserId = UserInfo.getUserId();
        User minimumAccessUser = AAREG_AltinnTestDataFactory.createScenarioUser(false);
        System.runAs(minimumAccessUser) {
            System.Test.startTest();
            Boolean rejected = false;
            try {
                AAREG_HomeController.getOrganizationsWithRoles(differentUserId);
            } catch (AuraHandledException error) {
                rejected = true;
            }
            Integer callouts = Limits.getCallouts();
            Integer queries = Limits.getQueries();
            System.Test.stopTest();
            System.Assert.isTrue(rejected, 'Organization lookups must only target the signed-in user.');
            System.Assert.areEqual(0, callouts);
            System.Assert.areEqual(0, queries, 'Reject before reading another user record.');
        }
    }

    /**
     * Rejects another user's rights lookup before selecting a live or scenario provider.
     *
     * @since 2026-10-26
     */
    @IsTest
    static void shouldRejectRightsLookupForAnotherUser() {
        Id differentUserId = UserInfo.getUserId();
        User minimumAccessUser = AAREG_AltinnTestDataFactory.createScenarioUser(false);
        System.runAs(minimumAccessUser) {
            System.Test.startTest();
            Boolean rejected = false;
            try {
                AAREG_CommunityUtils.getUserRights(
                    differentUserId,
                    organizationNumber,
                    'nav_arbeidsforhold_aa-registeret-sok-tilgang'
                );
            } catch (AuraHandledException error) {
                rejected = true;
            }
            Integer callouts = Limits.getCallouts();
            Integer queries = Limits.getQueries();
            System.Test.stopTest();
            System.Assert.isTrue(rejected, 'Rights lookups must only target the signed-in user.');
            System.Assert.areEqual(0, callouts);
            System.Assert.areEqual(0, queries, 'Reject before reading another user record.');
        }
    }

    /**
     * Returns fresh organizations for the signed-in scenario user without live callouts.
     *
     * @since 2026-10-25
     */
    @IsTest
    static void shouldRefreshAssignedOrganizations() {
        User user = AAREG_AltinnTestDataFactory.createCommunityAssignedUser('S01', 'subject-a');
        System.runAs(user) {
            System.Test.startTest();
            AltinnCalloutService.AltinnOrganizationsResponse response = AAREG_HomeController.refreshOrganizationsWithRoles(
                user.Id
            );
            Integer callouts = Limits.getCallouts();
            System.Test.stopTest();
            System.Assert.isTrue(response.success);
            System.Assert.areEqual(3, response.organizations.size());
            System.Assert.areEqual('v3', response.altinnVersion);
            System.Assert.areEqual(0, callouts);
        }
    }

    /**
     * Preserves a response-level organization failure without substituting empty success.
     *
     * @since 2026-10-25
     */
    @IsTest
    static void shouldPreserveRefreshResponseErrors() {
        User user = AAREG_AltinnTestDataFactory.createCommunityAssignedUser('S07', 'subject-a');
        System.runAs(user) {
            System.Test.startTest();
            AltinnCalloutService.AltinnOrganizationsResponse response = AAREG_HomeController.refreshOrganizationsWithRoles(
                user.Id
            );
            System.Test.stopTest();
            System.Assert.isFalse(response.success);
            System.Assert.isNotNull(response.errorMessage);
            System.Assert.areEqual(0, Limits.getCallouts());
        }
    }

    /**
     * Surfaces an organization exception as a handled refresh failure.
     *
     * @since 2026-10-25
     */
    @IsTest
    static void shouldSurfaceRefreshExceptions() {
        User user = AAREG_AltinnTestDataFactory.createCommunityAssignedUser('S07', 'subject-throws');
        System.runAs(user) {
            System.Test.startTest();
            Boolean failed = false;
            try {
                AAREG_HomeController.refreshOrganizationsWithRoles(user.Id);
            } catch (AuraHandledException error) {
                failed = true;
            }
            System.Test.stopTest();
            System.Assert.isTrue(failed, 'An exception must not become an empty organization list.');
        }
    }

    /**
     * Rejects refresh requests for a user other than the signed-in user.
     *
     * @since 2026-10-25
     */
    @IsTest
    static void shouldRejectRefreshForAnotherUser() {
        Id differentUserId = UserInfo.getUserId();
        User minimumAccessUser = AAREG_AltinnTestDataFactory.createScenarioUser(false);
        System.runAs(minimumAccessUser) {
            System.Test.startTest();
            Boolean rejected = false;
            try {
                AAREG_HomeController.refreshOrganizationsWithRoles(differentUserId);
            } catch (AuraHandledException error) {
                rejected = true;
            }
            System.Test.stopTest();
            System.Assert.isTrue(rejected, 'Only the signed-in user can refresh their organizations.');
        }
    }

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
            Set<String> organizationNumbers = new Set<String>();
            for (AltinnCalloutService.Organization organization : response.organizations) {
                organizationNumbers.add(organization.organizationNumber);
            }
            List<AAREG_HomeController.AccessResponse> accessResponses = new List<AAREG_HomeController.AccessResponse>();
            for (String organizationNumber : new List<String>{ '111111111', '222222222', '333333333' }) {
                accessResponses.add(AAREG_HomeController.checkAndShareIfAuthorized(user.Id, organizationNumber));
            }
            Integer callouts = Limits.getCallouts();
            System.Test.stopTest();

            System.Assert.isTrue(response.success);
            System.Assert.areEqual('v3', response.altinnVersion);
            System.Assert.areEqual(3, response.organizations.size());
            System.Assert.areEqual(organizationNumber, response.organizations[0].organizationNumber);
            System.Assert.areEqual(new Set<String>{ '111111111', '222222222', '333333333' }, organizationNumbers);
            for (AAREG_HomeController.AccessResponse accessResponse : accessResponses) {
                System.Assert.isTrue(accessResponse.hasAccess);
                System.Assert.isTrue(accessResponse.hasApplicationAccess);
            }
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
     * Surfaces response-level lookup failures instead of reporting an ordinary rights denial.
     *
     * @since 2026-10-25
     */
    @IsTest
    static void shouldSurfaceScenarioRightsResponseErrors() {
        User user = AAREG_AltinnTestDataFactory.createCommunityAssignedUser('S07', 'subject-a');
        insertAgreementForOrganization(organizationNumber);

        System.runAs(user) {
            System.Test.startTest();
            Boolean lookupFailed = false;
            try {
                AAREG_HomeController.checkAndShareIfAuthorized(user.Id, organizationNumber);
            } catch (AuraHandledException error) {
                lookupFailed = true;
            }
            Integer callouts = Limits.getCallouts();
            System.Test.stopTest();

            System.Assert.isTrue(lookupFailed, 'A technical lookup failure must not become an ordinary denial.');
            System.Assert.areEqual(0, callouts);
        }

        System.Assert.areEqual(0, [SELECT COUNT() FROM Agreement__Share WHERE UserOrGroupId = :user.Id]);
    }

    /**
     * Builds linked agreement fixtures independently of the test runner's product-field permissions.
     *
     * @since 2026-10-26
     */
    @IsTest
    static void shouldPrepareAgreementWithoutRunnerFieldAccess() {
        User minimumAccessUser = AAREG_AltinnTestDataFactory.createScenarioUser(false);
        System.runAs(minimumAccessUser) {
            System.Test.startTest();
            insertAgreementForOrganization(organizationNumber);
            System.Test.stopTest();
        }
        List<Agreement__c> agreements = [
            SELECT Account__c, Application__r.Account__c, Account__r.INT_OrganizationNumber__c
            FROM Agreement__c
            WITH SYSTEM_MODE
        ];
        System.Assert.areEqual(1, agreements.size());
        System.Assert.areEqual(agreements[0].Account__c, agreements[0].Application__r.Account__c);
        System.Assert.areEqual(organizationNumber, agreements[0].Account__r.INT_OrganizationNumber__c);
    }

    /**
     * Inserts only synthetic fixture records in system mode; runtime access checks remain in community runAs blocks.
     */
    private static void insertAgreementForOrganization(String targetOrganizationNumber) {
        Account account = new Account(
            Name = 'Synthetic Altinn Agreement Account',
            INT_OrganizationNumber__c = targetOrganizationNumber,
            INT_OrganizationalStructure__c = 'ORGL'
        );
        insert as system account;

        Application__c application = AAREG_TestDataFactory.getApplicationCounty(account);
        insert as system application;

        Agreement__c agreement = AAREG_TestDataFactory.getAgreement(account.Id);
        agreement.Application__c = application.Id;
        insert as system agreement;
    }
}
