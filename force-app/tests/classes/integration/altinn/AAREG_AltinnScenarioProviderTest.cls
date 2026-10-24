/**
 * Verifies typed scenario responses and guards through the provider's public operations.
 *
 * @author Kenneth Sørensen
 * @since 2026-10-25
 * @group AAREG Altinn Test
 */
@IsTest
private with sharing class AAREG_AltinnScenarioProviderTest {
    private static final String applicationResource = 'nav_arbeidsforhold_aa-registeret-sok-tilgang';
    private static final String supportResource = 'nav_arbeidsforhold_aa-registeret-brukerstotte';

    /**
     * Enforces the same policy when the provider is used without the factory or facade.
     *
     * @since 2026-10-25
     */
    @IsTest
    static void shouldReturnTypedOrganizationsThroughDirectProvider() {
        User user = AAREG_AltinnTestDataFactory.createScenarioUser(true);
        AAREG_AltinnTestDataFactory.setScenario(user.Id, 'S01', 'subject-a', true);
        AAREG_AltinnTestDataFactory.useSyntheticContext(true);
        System.runAs(user) {
            System.Test.startTest();
            AAREG_AltinnScenarioProvider provider = new AAREG_AltinnScenarioProvider(user.Id);
            AltinnCalloutService.AltinnOrganizationsResponse response = provider.getOrganizations('synthetic-subject');
            Integer callouts = Limits.getCallouts();
            Integer dmlStatements = Limits.getDmlStatements();
            System.Test.stopTest();

            System.Assert.isTrue(response.success);
            System.Assert.areEqual('v3', response.altinnVersion);
            System.Assert.areEqual(1, response.organizations.size());
            System.Assert.areEqual('Synthetic organization A', response.organizations[0].name);
            System.Assert.areEqual('111111111', response.organizations[0].organizationNumber);
            System.Assert.areEqual('Organization', response.organizations[0].type);
            System.Assert.areEqual('AS', response.organizations[0].unitType);
            System.Assert.isNull(response.errorMessage);
            System.Assert.areEqual(0, callouts);
            System.Assert.areEqual(0, dmlStatements);
        }
    }

    /**
     * Preserves current Deny response semantics while keeping application and support decisions independent.
     *
     * @since 2026-10-25
     */
    @IsTest
    static void shouldPreserveDenyAndSupportOnlyResponses() {
        User user = AAREG_AltinnTestDataFactory.createAssignedUser('S02', 'subject-a');
        System.runAs(user) {
            System.Test.startTest();
            AAREG_AltinnScenarioProvider provider = new AAREG_AltinnScenarioProvider(user.Id);
            assertDecision(provider, '111111111', applicationResource, 'Deny');
            assertDecision(provider, '111111111', supportResource, 'Permit');
            System.Assert.areEqual(0, Limits.getCallouts());
            System.Assert.areEqual(0, Limits.getDmlStatements());
            System.Test.stopTest();
        }
    }

    /**
     * Produces only explicit Deny rights for a clean denial scenario without changing product records.
     *
     * @since 2026-10-25
     */
    @IsTest
    static void shouldReturnBothDeniedResourcesWithoutDml() {
        User user = AAREG_AltinnTestDataFactory.createAssignedUser('S03', 'subject-a');
        System.runAs(user) {
            System.Test.startTest();
            AAREG_AltinnScenarioProvider provider = new AAREG_AltinnScenarioProvider(user.Id);
            assertDecision(provider, '111111111', applicationResource, 'Deny');
            assertDecision(provider, '111111111', supportResource, 'Deny');
            System.Assert.areEqual(0, Limits.getDmlStatements(), 'A provider must neither create nor revoke shares.');
            System.Assert.areEqual(0, Limits.getCallouts());
            System.Test.stopTest();
        }
    }

    /**
     * Uses each selected organization's rights matrix instead of retaining the previous organization's Permit.
     *
     * @since 2026-10-25
     */
    @IsTest
    static void shouldResolveRightsForSelectedOrganization() {
        User user = AAREG_AltinnTestDataFactory.createAssignedUser('S04', 'subject-a');
        System.runAs(user) {
            System.Test.startTest();
            AAREG_AltinnScenarioProvider provider = new AAREG_AltinnScenarioProvider(user.Id);
            System.Assert.areEqual(2, provider.getOrganizations('synthetic-subject').organizations.size());
            assertDecision(provider, '111111111', applicationResource, 'Permit');
            assertDecision(provider, '111111111', supportResource, 'Deny');
            assertDecision(provider, '222222222', applicationResource, 'Deny');
            assertDecision(provider, '222222222', supportResource, 'Permit');
            System.Assert.areEqual(0, Limits.getCallouts());
            System.Test.stopTest();
        }
    }

    /**
     * Keeps an empty organization list as a successful v3 response rather than a failure or null list.
     *
     * @since 2026-10-25
     */
    @IsTest
    static void shouldReturnSuccessfulEmptyOrganizationList() {
        User user = AAREG_AltinnTestDataFactory.createAssignedUser('S05', 'subject-a');
        System.runAs(user) {
            System.Test.startTest();
            AltinnCalloutService.AltinnOrganizationsResponse response = new AAREG_AltinnScenarioProvider(user.Id)
                .getOrganizations('synthetic-subject');
            System.Test.stopTest();

            System.Assert.isTrue(response.success);
            System.Assert.areEqual('v3', response.altinnVersion);
            System.Assert.isTrue(response.organizations.isEmpty());
            System.Assert.isNull(response.errorMessage);
        }
    }

    /**
     * Leaves party and organization-form filtering to the existing application.
     *
     * @since 2026-10-25
     */
    @IsTest
    static void shouldReturnMixedPartiesWithoutFiltering() {
        User user = AAREG_AltinnTestDataFactory.createAssignedUser('S06', 'subject-a');
        System.runAs(user) {
            System.Test.startTest();
            AltinnCalloutService.AltinnOrganizationsResponse response = new AAREG_AltinnScenarioProvider(user.Id)
                .getOrganizations('synthetic-subject');
            System.Test.stopTest();

            System.Assert.isTrue(response.success);
            System.Assert.areEqual('v3', response.altinnVersion);
            System.Assert.areEqual(4, response.organizations.size());
            System.Assert.areEqual('AS', response.organizations[0].unitType);
            System.Assert.areEqual('ENK', response.organizations[1].unitType);
            System.Assert.areEqual('BEDR', response.organizations[2].unitType);
            System.Assert.areEqual('Person', response.organizations[3].type);
            System.Assert.isNull(response.organizations[3].personId);
            System.Assert.isNull(response.organizations[3].organizationNumber);
        }
    }

    /**
     * Returns explicit response errors without inventing an organization list or a Deny decision.
     *
     * @since 2026-10-25
     */
    @IsTest
    static void shouldReturnConfiguredResponseErrors() {
        User user = AAREG_AltinnTestDataFactory.createAssignedUser('S07', 'subject-a');
        System.runAs(user) {
            System.Test.startTest();
            AAREG_AltinnScenarioProvider provider = new AAREG_AltinnScenarioProvider(user.Id);
            AltinnCalloutService.AltinnOrganizationsResponse organizations = provider.getOrganizations(
                'synthetic-subject'
            );
            AltinnCalloutService.AltinnRightsResponse rights = provider.getRights(
                'synthetic-subject',
                '111111111',
                applicationResource
            );
            System.Assert.areEqual(0, Limits.getCallouts());
            System.Assert.areEqual(0, Limits.getDmlStatements());
            System.Test.stopTest();

            System.Assert.isFalse(organizations.success);
            System.Assert.areEqual('v3', organizations.altinnVersion);
            System.Assert.areEqual('Synthetic organization response error.', organizations.errorMessage);
            System.Assert.isNull(organizations.organizations);
            System.Assert.isFalse(rights.success);
            System.Assert.areEqual('Synthetic rights response error.', rights.errorMessage);
            System.Assert.isNull(rights.rights);
        }
    }

    /**
     * Throws distinct synthetic exceptions for both operations without fallback.
     *
     * @since 2026-10-25
     */
    @IsTest
    static void shouldThrowConfiguredExceptionsForBothOperations() {
        User user = AAREG_AltinnTestDataFactory.createAssignedUser('S07', 'subject-throws');
        System.runAs(user) {
            System.Test.startTest();
            assertProviderRejected(new AAREG_AltinnScenarioProvider(user.Id), true);
            System.Assert.areEqual(0, Limits.getCallouts());
            System.Assert.areEqual(0, Limits.getDmlStatements());
            System.Test.stopTest();
        }
    }

    /**
     * Does not supply the missing previous organization or grant rights to its stale selection.
     *
     * @since 2026-10-25
     */
    @IsTest
    static void shouldRejectMissingPreviousOrganization() {
        User user = AAREG_AltinnTestDataFactory.createAssignedUser('S08', 'subject-a');
        System.runAs(user) {
            System.Test.startTest();
            AAREG_AltinnScenarioProvider provider = new AAREG_AltinnScenarioProvider(user.Id);
            AltinnCalloutService.AltinnOrganizationsResponse response = provider.getOrganizations('synthetic-subject');
            System.Assert.areEqual(1, response.organizations.size());
            System.Assert.areEqual('222222222', response.organizations[0].organizationNumber);
            assertDecision(provider, '222222222', applicationResource, 'Deny');
            assertDecision(provider, '222222222', supportResource, 'Permit');
            assertUnknownRights(provider, '111111111', applicationResource);
            System.Assert.areEqual(0, Limits.getDmlStatements(), 'Do not rewrite the stored organization selection.');
            System.Test.stopTest();
        }
    }

    /**
     * Refuses direct provider use when no active user assignment exists, before loading scenario data.
     *
     * @since 2026-10-25
     */
    @IsTest
    static void shouldRejectDirectUseWithoutAssignment() {
        User user = AAREG_AltinnTestDataFactory.createScenarioUser(false);
        System.runAs(user) {
            System.Test.startTest();
            assertProviderRejected(new AAREG_AltinnScenarioProvider(user.Id), false);
            System.Assert.areEqual(0, Limits.getQueries(), 'Do not load the catalogue for inactive scenario use.');
            System.Assert.areEqual(0, Limits.getCallouts());
            System.Test.stopTest();
        }
    }

    /**
     * Rechecks activation after the same provider has already returned an authorized response.
     *
     * @since 2026-10-25
     */
    @IsTest
    static void shouldRejectDeactivatedAssignmentOnExistingProvider() {
        User user = AAREG_AltinnTestDataFactory.createAssignedUser('S01', 'subject-a');
        System.runAs(user) {
            System.Test.startTest();
            AAREG_AltinnScenarioProvider provider = new AAREG_AltinnScenarioProvider(user.Id);
            System.Assert.isTrue(provider.getOrganizations('synthetic-subject').success);
            AAREG_AltinnTestDataFactory.setScenario(user.Id, 'S01', 'subject-a', false);
            Integer fixtureDmlStatements = Limits.getDmlStatements();
            assertProviderRejected(provider, false);
            System.Assert.areEqual(
                fixtureDmlStatements,
                Limits.getDmlStatements(),
                'Only the fixture changes settings.'
            );
            System.Assert.areEqual(0, Limits.getCallouts());
            System.Test.stopTest();
        }
    }

    /**
     * Reads a changed scenario and alias for each operation rather than caching authorization or assignment values.
     *
     * @since 2026-10-25
     */
    @IsTest
    static void shouldReReadScenarioAndAliasForEveryOperation() {
        User user = AAREG_AltinnTestDataFactory.createAssignedUser('S01', 'subject-a');
        System.runAs(user) {
            System.Test.startTest();
            AAREG_AltinnScenarioProvider provider = new AAREG_AltinnScenarioProvider(user.Id);
            System.Assert.isTrue(provider.getOrganizations('synthetic-subject').success);
            AAREG_AltinnTestDataFactory.setScenario(user.Id, 'S04', 'subject-a', true);
            assertDecision(provider, '222222222', supportResource, 'Permit');
            AAREG_AltinnTestDataFactory.setScenario(user.Id, 'S07', 'subject-throws', true);
            assertProviderRejected(provider, true);
            System.Assert.areEqual(0, Limits.getCallouts());
            System.Test.stopTest();
        }
    }

    /**
     * Enforces production and unknown-environment rejection on both direct provider operations.
     *
     * @since 2026-10-25
     */
    @IsTest
    static void shouldRecheckEnvironmentOnEveryOperation() {
        User user = AAREG_AltinnTestDataFactory.createAssignedUser('S01', 'subject-a');
        System.runAs(user) {
            System.Test.startTest();
            AAREG_AltinnScenarioProvider provider = new AAREG_AltinnScenarioProvider(user.Id);
            System.Assert.isTrue(provider.getOrganizations('synthetic-subject').success);
            AAREG_AltinnTestDataFactory.useSyntheticContext(false);
            assertPolicyRejected(
                provider,
                'synthetic-subject',
                'Altinn scenarios require a verified non-production environment.'
            );
            AAREG_AltinnTestDataFactory.useSyntheticContext(null);
            assertPolicyRejected(
                provider,
                'synthetic-subject',
                'Altinn scenarios require a verified non-production environment.'
            );
            System.Assert.areEqual(0, Limits.getCallouts());
            System.Test.stopTest();
        }
    }

    /**
     * Rejects an active assignment without the separate scenario custom permission.
     *
     * @since 2026-10-25
     */
    @IsTest
    static void shouldRejectMissingPermissionOnDirectProvider() {
        User user = AAREG_AltinnTestDataFactory.createScenarioUser(false);
        AAREG_AltinnTestDataFactory.setScenario(user.Id, 'S01', 'subject-a', true);
        AAREG_AltinnTestDataFactory.useSyntheticContext(true);
        System.runAs(user) {
            System.Test.startTest();
            assertPolicyRejected(
                new AAREG_AltinnScenarioProvider(user.Id),
                'synthetic-subject',
                'Altinn scenario permission is required.'
            );
            System.Assert.areEqual(0, Limits.getQueries(), 'Reject before reading scenario data.');
            System.Assert.areEqual(0, Limits.getCallouts());
            System.Test.stopTest();
        }
    }

    /**
     * Enforces target-user and linked-identity binding through both public operations.
     *
     * @since 2026-10-25
     */
    @IsTest
    static void shouldRejectDifferentTargetOrIdentityOnDirectProvider() {
        Id otherUserId = UserInfo.getUserId();
        User user = AAREG_AltinnTestDataFactory.createAssignedUser('S01', 'subject-a');
        System.runAs(user) {
            System.Test.startTest();
            assertPolicyRejected(
                new AAREG_AltinnScenarioProvider(otherUserId),
                'synthetic-subject',
                'Altinn scenarios may only be used by the assigned user.'
            );
            assertPolicyRejected(
                new AAREG_AltinnScenarioProvider(user.Id),
                'different-subject',
                'Altinn scenario identity does not match the assigned user.'
            );
            assertPolicyRejected(
                new AAREG_AltinnScenarioProvider(user.Id),
                null,
                'Altinn scenario identity does not match the assigned user.'
            );
            System.Assert.areEqual(0, Limits.getCallouts());
            System.Test.stopTest();
        }
    }

    /**
     * Rejects unknown organizations and resources instead of inventing rights or calling the live provider.
     *
     * @since 2026-10-25
     */
    @IsTest
    static void shouldRejectUnknownRightsCombinations() {
        User user = AAREG_AltinnTestDataFactory.createAssignedUser('S01', 'subject-a');
        System.runAs(user) {
            System.Test.startTest();
            AAREG_AltinnScenarioProvider provider = new AAREG_AltinnScenarioProvider(user.Id);
            assertUnknownRights(provider, '999999999', applicationResource);
            assertUnknownRights(provider, '111111111', 'unknown-resource');
            assertUnknownRights(provider, null, null);
            System.Assert.areEqual(0, Limits.getCallouts());
            System.Test.stopTest();
        }
    }

    /**
     * Maps each response independently so caller mutations cannot corrupt the provider's catalogue definitions.
     *
     * @since 2026-10-25
     */
    @IsTest
    static void shouldReturnIndependentResponseObjects() {
        User user = AAREG_AltinnTestDataFactory.createAssignedUser('S01', 'subject-a');
        System.runAs(user) {
            System.Test.startTest();
            AAREG_AltinnScenarioProvider provider = new AAREG_AltinnScenarioProvider(user.Id);
            AltinnCalloutService.AltinnOrganizationsResponse first = provider.getOrganizations('synthetic-subject');
            first.organizations.clear();
            AltinnCalloutService.AltinnOrganizationsResponse second = provider.getOrganizations('synthetic-subject');
            AltinnCalloutService.AltinnRightsResponse rights = provider.getRights(
                'synthetic-subject',
                '111111111',
                applicationResource
            );
            rights.rights[0].Decision = 'Deny';
            assertDecision(provider, '111111111', applicationResource, 'Permit');
            System.Test.stopTest();

            System.Assert.isFalse(first === second);
            System.Assert.areEqual(1, second.organizations.size());
        }
    }

    private static void assertDecision(
        AAREG_AltinnScenarioProvider provider,
        String organizationNumber,
        String resource,
        String decision
    ) {
        AltinnCalloutService.AltinnRightsResponse response = provider.getRights(
            'synthetic-subject',
            organizationNumber,
            resource
        );
        Boolean permit = decision.equals('Permit');
        System.Assert.areEqual(permit, response.success);
        System.Assert.areEqual(permit ? null : 'Access denied', response.errorMessage);
        System.Assert.areEqual(1, response.rights.size());
        System.Assert.areEqual('Access', response.rights[0].Action);
        System.Assert.areEqual(decision, response.rights[0].Decision);
        System.Assert.areEqual(resource, response.rights[0].Resource);
    }

    private static void assertProviderRejected(AAREG_AltinnScenarioProvider provider, Boolean configuredFailure) {
        try {
            provider.getOrganizations('synthetic-subject');
            System.Assert.fail('Scenario use must fail explicitly without live fallback.');
        } catch (AAREG_AltinnScenarioProvider.AltinnScenarioProviderException caughtException) {
            System.Assert.areEqual(
                configuredFailure ? 'Synthetic organization exception.' : 'Altinn scenario assignment is not active.',
                caughtException.getMessage()
            );
        }
        try {
            provider.getRights('synthetic-subject', '111111111', applicationResource);
            System.Assert.fail('Scenario use must fail explicitly without live fallback.');
        } catch (AAREG_AltinnScenarioProvider.AltinnScenarioProviderException caughtException) {
            System.Assert.areEqual(
                configuredFailure ? 'Synthetic rights exception.' : 'Altinn scenario assignment is not active.',
                caughtException.getMessage()
            );
        }
    }

    private static void assertPolicyRejected(
        AAREG_AltinnScenarioProvider provider,
        String personIdent,
        String expectedMessage
    ) {
        try {
            provider.getOrganizations(personIdent);
            System.Assert.fail('Direct organization lookup must enforce runtime authorization.');
        } catch (AAREG_AltinnScenarioPolicy.AltinnScenarioPolicyException caughtException) {
            System.Assert.areEqual(expectedMessage, caughtException.getMessage());
        }
        try {
            provider.getRights(personIdent, '111111111', applicationResource);
            System.Assert.fail('Direct rights lookup must enforce runtime authorization.');
        } catch (AAREG_AltinnScenarioPolicy.AltinnScenarioPolicyException caughtException) {
            System.Assert.areEqual(expectedMessage, caughtException.getMessage());
        }
    }

    private static void assertUnknownRights(
        AAREG_AltinnScenarioProvider provider,
        String organizationNumber,
        String resource
    ) {
        try {
            provider.getRights('synthetic-subject', organizationNumber, resource);
            System.Assert.fail('Unknown rights must not produce an implicit decision or live fallback.');
        } catch (AAREG_AltinnScenarioRepository.AltinnScenarioRepositoryException caughtException) {
            System.Assert.areEqual('Unknown Altinn scenario organization or resource.', caughtException.getMessage());
        }
    }
}
