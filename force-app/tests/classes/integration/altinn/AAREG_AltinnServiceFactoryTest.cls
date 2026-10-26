/**
 * Verifies the consumer-side Altinn package boundary and service selection contract.
 *
 * @author Kenneth Sørensen
 * @since 2026-10-25
 * @group AAREG Altinn Test
 */
@IsTest
private with sharing class AAREG_AltinnServiceFactoryTest {
    /**
     * Uses the scenario provider through the installed facade without initializing the selected live Altinn 3 service.
     *
     * @since 2026-10-25
     */
    @IsTest
    static void shouldSelectScenarioWithoutLiveConfiguration() {
        User user = AAREG_AltinnTestDataFactory.createScenarioUser(true);
        AAREG_AltinnTestDataFactory.setScenario(user.Id, 'S01', 'subject-a', true);
        AAREG_AltinnTestDataFactory.useSyntheticContext(true);
        AAREG_AltinnTestDataFactory.setAltinnVersion3(true);
        System.runAs(user) {
            System.Test.startTest();
            AltinnCalloutService service = AAREG_AltinnServiceFactory.createService(user.Id, 'synthetic-subject');
            AltinnCalloutService.AltinnOrganizationsResponse organizations = service.getOrganizations(
                'synthetic-subject'
            );
            AltinnCalloutService.AltinnRightsResponse rights = service.getRights(
                'synthetic-subject',
                '111111111',
                'nav_arbeidsforhold_aa-registeret-sok-tilgang'
            );
            Integer callouts = Limits.getCallouts();
            Integer dmlStatements = Limits.getDmlStatements();
            System.Test.stopTest();

            System.Assert.isTrue(organizations.success, 'Active scenario selection must not initialize live settings.');
            System.Assert.areEqual('v3', organizations.altinnVersion, 'Keep current organization filtering semantics.');
            System.Assert.areEqual('111111111', organizations.organizations[0].organizationNumber);
            System.Assert.isTrue(rights.success);
            System.Assert.areEqual('Access', rights.rights[0].Action);
            System.Assert.areEqual('Permit', rights.rights[0].Decision);
            System.Assert.areEqual('nav_arbeidsforhold_aa-registeret-sok-tilgang', rights.rights[0].Resource);
            System.Assert.areEqual(0, callouts);
            System.Assert.areEqual(0, dmlStatements);
        }
    }

    /**
     * Compiles and exercises the installed provider API from consumer source without live settings.
     *
     * @since 2026-10-25
     */
    @IsTest
    static void shouldUseInjectedFacadeWithoutLiveConfiguration() {
        User minimumAccessUser = Integration_TestDataFactory.createMinimumAccessUser();
        System.Assert.areEqual(
            0,
            [SELECT COUNT() FROM Altinn3IntegrationSetting__c WITH SYSTEM_MODE],
            'Consumer injection must work without live Altinn configuration.'
        );
        System.runAs(minimumAccessUser) {
            ContractProvider provider = new ContractProvider();
            System.Test.startTest();
            AltinnCalloutService service = new AltinnCalloutService(provider);
            AltinnCalloutService.AltinnOrganizationsResponse organizations = service.getOrganizations(
                'synthetic-subject'
            );
            AltinnCalloutService.AltinnRightsResponse rights = service.getRights(
                'synthetic-subject',
                '111111111',
                'synthetic-resource'
            );
            try {
                new AltinnCalloutService((IAltinnCalloutService) null);
                System.Assert.fail('A null provider must not fall back to a live service.');
            } catch (AltinnCalloutService.AltinnCalloutServiceException caughtException) {
                System.Assert.areEqual('Altinn provider must not be null.', caughtException.getMessage());
            }
            Integer queries = Limits.getQueries();
            Integer callouts = Limits.getCallouts();
            Integer dmlStatements = Limits.getDmlStatements();
            System.Test.stopTest();

            System.Assert.isTrue(provider.organizations === organizations, 'Preserve the installed organization DTO.');
            System.Assert.isTrue(provider.rights === rights, 'Preserve the installed rights DTO.');
            System.Assert.areEqual(1, provider.organizationCalls, 'Delegate each operation exactly once.');
            System.Assert.areEqual(1, provider.rightsCalls, 'Delegate each operation exactly once.');
            System.Assert.areEqual(0, queries, 'Injected facade construction must not initialize live configuration.');
            System.Assert.areEqual(0, callouts, 'Consumer injection must not contact Altinn.');
            System.Assert.areEqual(0, dmlStatements, 'Consumer injection must not change records.');
        }
    }

    /**
     * Preserves standard Altinn 2 behavior without a scenario assignment for a caller authorized to read live metadata.
     *
     * @since 2026-10-25
     */
    @IsTest
    static void shouldUseStandardOrganizationsWithoutAssignment() {
        User user = new User(Id = UserInfo.getUserId());
        AAREG_AltinnTestDataFactory.setAltinnVersion3(false);
        System.Test.setMock(HttpCalloutMock.class, new StandardResponseMock());
        System.runAs(user) {
            System.Test.startTest();
            AltinnCalloutService service = AAREG_AltinnServiceFactory.createService(user.Id, 'synthetic-subject');
            AltinnCalloutService.AltinnOrganizationsResponse response = service.getOrganizations('synthetic-subject');
            Integer callouts = Limits.getCallouts();
            System.Test.stopTest();

            System.Assert.isTrue(response.success);
            System.Assert.areEqual('v2', response.altinnVersion, 'Keep the existing standard version selection.');
            System.Assert.areEqual('444444444', response.organizations[0].organizationNumber);
            System.Assert.areEqual('Synthetic standard organization', response.organizations[0].name);
            System.Assert.areEqual(1, callouts, 'Only the standard operation uses the mocked HTTP transport.');
        }
    }

    /**
     * Ignores disabled scenario fields and preserves standard rights for a caller authorized to read live metadata.
     *
     * @since 2026-10-25
     */
    @IsTest
    static void shouldUseStandardRightsWhenAssignmentIsDisabled() {
        User user = new User(Id = UserInfo.getUserId());
        AAREG_AltinnTestDataFactory.setScenario(user.Id, 'S99', 'unknown-subject', false);
        AAREG_AltinnTestDataFactory.useSyntheticContext(false);
        AAREG_AltinnTestDataFactory.setAltinnVersion3(false);
        System.Test.setMock(HttpCalloutMock.class, new StandardResponseMock());
        System.runAs(user) {
            System.Test.startTest();
            AltinnCalloutService service = AAREG_AltinnServiceFactory.createService(user.Id, 'synthetic-subject');
            AltinnCalloutService.AltinnRightsResponse response = service.getRights(
                'synthetic-subject',
                '444444444',
                'synthetic-standard-resource'
            );
            Integer callouts = Limits.getCallouts();
            System.Test.stopTest();

            System.Assert.isTrue(response.success);
            System.Assert.areEqual('Permit', response.rights[0].Decision);
            System.Assert.areEqual('synthetic-standard-resource', response.rights[0].Resource);
            System.Assert.areEqual(1, callouts);
        }
    }

    /**
     * Preserves the standard Altinn 3 configuration error instead of blocking normal mode with scenario guards.
     *
     * @since 2026-10-25
     */
    @IsTest
    static void shouldPreserveStandardAltinn3ConfigurationFailure() {
        User user = AAREG_AltinnTestDataFactory.createScenarioUser(false);
        AAREG_AltinnTestDataFactory.useSyntheticContext(false);
        AAREG_AltinnTestDataFactory.setAltinnVersion3(true);
        System.runAs(user) {
            System.Test.startTest();
            try {
                AAREG_AltinnServiceFactory.createService(user.Id, 'synthetic-subject');
                System.Assert.fail('The standard Altinn 3 constructor must still require its live configuration.');
            } catch (Altinn3CalloutService.Altinn3CalloutServiceException caughtException) {
                System.Assert.areEqual('Altinn3IntegrationSetting__c is not configured.', caughtException.getMessage());
            }
            System.Assert.areEqual(0, Limits.getCallouts());
            System.Test.stopTest();
        }
    }

    /**
     * Rejects production and unknown environment activation before selecting a facade, without live fallback.
     *
     * @since 2026-10-25
     */
    @IsTest
    static void shouldRejectForbiddenEnvironmentAtSelection() {
        User user = AAREG_AltinnTestDataFactory.createAssignedUser('S01', 'subject-a');
        System.runAs(user) {
            System.Test.startTest();
            AAREG_AltinnTestDataFactory.useSyntheticContext(false);
            assertFactoryRejected(
                user.Id,
                'synthetic-subject',
                'Altinn scenarios require a verified non-production environment.'
            );
            AAREG_AltinnTestDataFactory.useSyntheticContext(null);
            assertFactoryRejected(
                user.Id,
                'synthetic-subject',
                'Altinn scenarios require a verified non-production environment.'
            );
            System.Assert.areEqual(0, Limits.getCallouts());
            System.Test.stopTest();
        }
    }

    /**
     * Requires the scenario permission before selecting an injected provider.
     *
     * @since 2026-10-25
     */
    @IsTest
    static void shouldRejectMissingPermissionAtSelection() {
        User user = AAREG_AltinnTestDataFactory.createScenarioUser(false);
        AAREG_AltinnTestDataFactory.setScenario(user.Id, 'S01', 'subject-a', true);
        AAREG_AltinnTestDataFactory.useSyntheticContext(true);
        AAREG_AltinnTestDataFactory.setAltinnVersion3(true);
        System.runAs(user) {
            System.Test.startTest();
            assertFactoryRejected(user.Id, 'synthetic-subject', 'Altinn scenario permission is required.');
            System.Assert.areEqual(0, Limits.getCallouts());
            System.Test.stopTest();
        }
    }

    /**
     * Applies current-user and linked-identity checks at the factory boundary.
     *
     * @since 2026-10-25
     */
    @IsTest
    static void shouldRejectDifferentUserOrIdentityAtSelection() {
        Id otherUserId = UserInfo.getUserId();
        User user = AAREG_AltinnTestDataFactory.createAssignedUser('S01', 'subject-a');
        System.runAs(user) {
            System.Test.startTest();
            assertFactoryRejected(
                otherUserId,
                'synthetic-subject',
                'Altinn scenarios may only be used by the assigned user.'
            );
            assertFactoryRejected(
                user.Id,
                'different-subject',
                'Altinn scenario identity does not match the assigned user.'
            );
            System.Assert.areEqual(0, Limits.getCallouts());
            System.Test.stopTest();
        }
    }

    /**
     * Propagates invalid scenario identities through the injected facade without constructing a live service.
     *
     * @since 2026-10-25
     */
    @IsTest
    static void shouldRejectUnknownScenarioAndAliasWithoutFallback() {
        User user = AAREG_AltinnTestDataFactory.createAssignedUser('S99', 'subject-a');
        System.runAs(user) {
            System.Test.startTest();
            AltinnCalloutService service = AAREG_AltinnServiceFactory.createService(user.Id, 'synthetic-subject');
            assertUnknownDefinition(service, 'Unknown Altinn scenario.');
            AAREG_AltinnTestDataFactory.setScenario(user.Id, 'S01', 'unknown-subject', true);
            assertUnknownDefinition(service, 'Unknown Altinn scenario subject.');
            System.Assert.areEqual(0, Limits.getCallouts());
            System.Test.stopTest();
        }
    }

    /**
     * Does not retain mock authorization when the assignment is disabled after the factory returned a service.
     *
     * @since 2026-10-25
     */
    @IsTest
    static void shouldRecheckAssignmentAfterServiceSelection() {
        User user = AAREG_AltinnTestDataFactory.createAssignedUser('S01', 'subject-a');
        System.runAs(user) {
            System.Test.startTest();
            AltinnCalloutService service = AAREG_AltinnServiceFactory.createService(user.Id, 'synthetic-subject');
            AAREG_AltinnTestDataFactory.setScenario(user.Id, 'S01', 'subject-a', false);
            try {
                service.getOrganizations('synthetic-subject');
                System.Assert.fail('An already selected scenario service must not bypass current activation.');
            } catch (AAREG_AltinnScenarioProvider.AltinnScenarioProviderException caughtException) {
                System.Assert.areEqual('Altinn scenario assignment is not active.', caughtException.getMessage());
            }
            System.Assert.areEqual(0, Limits.getCallouts());
            System.Test.stopTest();
        }
    }

    /**
     * Leaves a configured provider exception unwrapped when it crosses the installed facade.
     *
     * @since 2026-10-25
     */
    @IsTest
    static void shouldPropagateControlledExceptionThroughFacade() {
        User user = AAREG_AltinnTestDataFactory.createAssignedUser('S07', 'subject-throws');
        System.runAs(user) {
            System.Test.startTest();
            AltinnCalloutService service = AAREG_AltinnServiceFactory.createService(user.Id, 'synthetic-subject');
            try {
                service.getOrganizations('synthetic-subject');
                System.Assert.fail('A configured exception must not become a response error or a live call.');
            } catch (AAREG_AltinnScenarioProvider.AltinnScenarioProviderException caughtException) {
                System.Assert.areEqual('Synthetic organization exception.', caughtException.getMessage());
            }
            try {
                service.getRights('synthetic-subject', '111111111', 'nav_arbeidsforhold_aa-registeret-sok-tilgang');
                System.Assert.fail('A configured exception must not become a response error or a live call.');
            } catch (AAREG_AltinnScenarioProvider.AltinnScenarioProviderException caughtException) {
                System.Assert.areEqual('Synthetic rights exception.', caughtException.getMessage());
            }
            System.Assert.areEqual(0, Limits.getCallouts());
            System.Test.stopTest();
        }
    }

    private static void assertFactoryRejected(Id targetUserId, String personIdent, String expectedMessage) {
        try {
            AAREG_AltinnServiceFactory.createService(targetUserId, personIdent);
            System.Assert.fail('Forbidden scenario selection must not fall back to the standard constructor.');
        } catch (AAREG_AltinnScenarioPolicy.AltinnScenarioPolicyException caughtException) {
            System.Assert.areEqual(expectedMessage, caughtException.getMessage());
        }
    }

    private static void assertUnknownDefinition(AltinnCalloutService service, String expectedMessage) {
        try {
            service.getOrganizations('synthetic-subject');
            System.Assert.fail('An unknown definition must not produce synthetic or live results.');
        } catch (AAREG_AltinnScenarioRepository.AltinnScenarioRepositoryException caughtException) {
            System.Assert.areEqual(expectedMessage, caughtException.getMessage());
        }
        try {
            service.getRights('synthetic-subject', '111111111', 'nav_arbeidsforhold_aa-registeret-sok-tilgang');
            System.Assert.fail('An unknown definition must not produce synthetic or live results.');
        } catch (AAREG_AltinnScenarioRepository.AltinnScenarioRepositoryException caughtException) {
            System.Assert.areEqual(expectedMessage, caughtException.getMessage());
        }
    }

    private class StandardResponseMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest request) {
            System.Assert.areEqual('GET', request.getMethod(), 'Only the standard lookup should reach HTTP.');
            HttpResponse response = new HttpResponse();
            response.setStatusCode(200);
            response.setBody(
                '{"_embedded":{"reportees":[{"name":"Synthetic standard organization","organizationNumber":"444444444","type":"Organization","unitType":"AS"}]},"rights":[{"Action":"Access","Decision":"Permit","Resource":"synthetic-standard-resource"}]}'
            );
            return response;
        }
    }

    private class ContractProvider implements IAltinnCalloutService {
        private AltinnCalloutService.AltinnOrganizationsResponse organizations = new AltinnCalloutService.AltinnOrganizationsResponse();
        private AltinnCalloutService.AltinnRightsResponse rights = new AltinnCalloutService.AltinnRightsResponse();
        private Integer organizationCalls = 0;
        private Integer rightsCalls = 0;

        public Object getOrganizations(String personIdent) {
            System.Assert.areEqual('synthetic-subject', personIdent);
            organizationCalls++;
            return organizations;
        }

        public Object getRights(String personIdent, String organizationNumber, String serviceCode) {
            System.Assert.areEqual('synthetic-subject', personIdent);
            System.Assert.areEqual('111111111', organizationNumber);
            System.Assert.areEqual('synthetic-resource', serviceCode);
            rightsCalls++;
            return rights;
        }
    }
}
