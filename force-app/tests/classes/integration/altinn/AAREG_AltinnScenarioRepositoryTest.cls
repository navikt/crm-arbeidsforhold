/**
 * Verifies the versioned Altinn scenario catalogue independently of Setup and runtime authorization.
 *
 * @author Kenneth Sørensen
 * @since 2026-10-25
 * @group AAREG Altinn Test
 */
@IsTest
private with sharing class AAREG_AltinnScenarioRepositoryTest {
    private static final String applicationResource = 'nav_arbeidsforhold_aa-registeret-sok-tilgang';
    private static final String supportResource = 'nav_arbeidsforhold_aa-registeret-brukerstotte';

    /**
     * Loads all documented scenario identities and the application Permit without configuration or elevated access.
     *
     * @since 2026-10-25
     */
    @IsTest
    static void shouldReadVersionedScenariosAsMinimumAccessUser() {
        User minimumAccessUser = Integration_TestDataFactory.createMinimumAccessUser();
        System.runAs(minimumAccessUser) {
            System.Test.startTest();
            AAREG_AltinnScenarioRepository repository = new AAREG_AltinnScenarioRepository();
            List<AAREG_AltinnScenarioRepository.Scenario> scenarios = repository.getScenarios();
            AAREG_AltinnScenarioRepository.Scenario applicationScenario = repository.getScenario('S01');
            AAREG_AltinnScenarioRepository.Subject subject = repository.getSubject('S01', 'subject-a');
            AAREG_AltinnScenarioRepository.RightResult applicationRight = repository.getRights(
                'S01',
                'subject-a',
                '111111111',
                applicationResource
            );
            assertDecision(repository, 'S01', '111111111', supportResource, 'Permit');
            Integer callouts = Limits.getCallouts();
            Integer dmlStatements = Limits.getDmlStatements();
            Integer queries = Limits.getQueries();
            System.Test.stopTest();

            Set<String> scenarioNames = new Set<String>();
            for (AAREG_AltinnScenarioRepository.Scenario scenario : scenarios) {
                scenarioNames.add(scenario.name);
                System.Assert.areEqual(1, scenario.version, 'Each scenario must have a supported version.');
                System.Assert.isFalse(String.isBlank(scenario.description), 'Each scenario must explain its purpose.');
            }
            System.Assert.areEqual(
                new Set<String>{ 'S01', 'S02', 'S03', 'S04', 'S05', 'S06', 'S07', 'S08' },
                scenarioNames,
                'Deliver exactly the eight documented scenario identities.'
            );
            System.Assert.areEqual(8, scenarios.size(), 'Do not hide duplicate scenario identities.');
            System.Assert.areEqual('ContractShape', applicationScenario.classification);
            System.Assert.areEqual('Success', subject.organizations.outcome);
            System.Assert.areEqual(3, subject.organizations.organizations.size());
            System.Assert.areEqual('111111111', subject.organizations.organizations[0].organizationNumber);
            System.Assert.areEqual('Decision', applicationRight.outcome);
            System.Assert.areEqual('Access', applicationRight.action);
            System.Assert.areEqual('Permit', applicationRight.decision);
            System.Assert.areEqual(applicationResource, applicationRight.resource);
            System.Assert.areEqual(0, callouts, 'Reading scenario definitions must never contact Altinn.');
            System.Assert.areEqual(0, dmlStatements, 'Reading scenarios must not create or change records.');
            System.Assert.areEqual(1, queries, 'Load only the named resource once per repository instance.');
        }
    }

    /**
     * Keeps support-only access and clean denial as separate resource decisions.
     *
     * @since 2026-10-25
     */
    @IsTest
    static void shouldDefineSupportOnlyAndDeniedScenarios() {
        System.Test.startTest();
        AAREG_AltinnScenarioRepository repository = new AAREG_AltinnScenarioRepository();
        assertDecision(repository, 'S02', '111111111', applicationResource, 'Deny');
        assertDecision(repository, 'S02', '111111111', supportResource, 'Permit');
        assertDecision(repository, 'S03', '111111111', applicationResource, 'Deny');
        assertDecision(repository, 'S03', '111111111', supportResource, 'Deny');
        System.Assert.areEqual(3, repository.getSubject('S02', 'subject-a').organizations.organizations.size());
        System.Assert.areEqual(3, repository.getSubject('S03', 'subject-a').organizations.organizations.size());
        System.Test.stopTest();
    }

    /**
     * Resolves rights for the selected organization instead of reusing the previous organization's rights.
     *
     * @since 2026-10-25
     */
    @IsTest
    static void shouldKeepOrganizationRightsIndependent() {
        System.Test.startTest();
        AAREG_AltinnScenarioRepository repository = new AAREG_AltinnScenarioRepository();
        System.Assert.areEqual(3, repository.getSubject('S04', 'subject-a').organizations.organizations.size());
        assertDecision(repository, 'S04', '111111111', applicationResource, 'Permit');
        assertDecision(repository, 'S04', '111111111', supportResource, 'Deny');
        assertDecision(repository, 'S04', '222222222', applicationResource, 'Deny');
        assertDecision(repository, 'S04', '222222222', supportResource, 'Permit');
        assertDecision(repository, 'S04', '333333333', applicationResource, 'Permit');
        assertDecision(repository, 'S04', '333333333', supportResource, 'Deny');
        System.Test.stopTest();
    }

    /**
     * Preserves a successful empty organization list without inventing rights for unknown organizations.
     *
     * @since 2026-10-25
     */
    @IsTest
    static void shouldPreserveSuccessfulEmptyOrganizationList() {
        System.Test.startTest();
        AAREG_AltinnScenarioRepository repository = new AAREG_AltinnScenarioRepository();
        AAREG_AltinnScenarioRepository.Subject subject = repository.getSubject('S05', 'subject-a');
        System.Assert.areEqual('Success', subject.organizations.outcome);
        System.Assert.isTrue(subject.organizations.organizations.isEmpty());
        System.Assert.isTrue(subject.rights.isEmpty());
        assertLookupRejected(
            repository,
            'S05',
            'subject-a',
            '111111111',
            applicationResource,
            'Unknown Altinn scenario organization or resource.'
        );
        System.Test.stopTest();
    }

    /**
     * Leaves party types and organization forms untouched for the existing UI to filter.
     *
     * @since 2026-10-25
     */
    @IsTest
    static void shouldReturnMixedPartiesWithoutFiltering() {
        System.Test.startTest();
        AAREG_AltinnScenarioRepository repository = new AAREG_AltinnScenarioRepository();
        List<AAREG_AltinnScenarioRepository.Organization> organizations = repository
            .getSubject('S06', 'subject-a')
            .organizations.organizations;
        for (String organizationNumber : new List<String>{ '111111111', '222222222', '333333333', '444444444' }) {
            assertDecision(repository, 'S06', organizationNumber, applicationResource, 'Permit');
            assertDecision(repository, 'S06', organizationNumber, supportResource, 'Permit');
        }
        System.Test.stopTest();

        System.Assert.areEqual(5, organizations.size(), 'Catalogue reading must not duplicate UI filtering.');
        System.Assert.areEqual('AS', organizations[0].unitType);
        System.Assert.areEqual('ENK', organizations[1].unitType);
        System.Assert.areEqual('BEDR', organizations[2].unitType);
        System.Assert.areEqual('AS', organizations[3].unitType);
        System.Assert.areEqual('444444444', organizations[3].organizationNumber);
        System.Assert.areEqual('Person', organizations[4].type);
        System.Assert.isNull(organizations[4].organizationNumber, 'A Person fixture must not contain an identity.');
    }

    /**
     * Distinguishes response errors and exceptions without executing either failure while reading the catalogue.
     *
     * @since 2026-10-25
     */
    @IsTest
    static void shouldDefineSeparateResponseAndExceptionRobustnessInputs() {
        System.Test.startTest();
        AAREG_AltinnScenarioRepository repository = new AAREG_AltinnScenarioRepository();
        System.Assert.areEqual('Robustness', repository.getScenario('S07').classification);
        for (String alias : new List<String>{ 'subject-a', 'subject-throws' }) {
            String expectedOutcome = alias == 'subject-a' ? 'ResponseError' : 'Exception';
            AAREG_AltinnScenarioRepository.OrganizationResult organizations = repository
                .getSubject('S07', alias)
                .organizations;
            System.Assert.areEqual(expectedOutcome, organizations.outcome);
            System.Assert.isFalse(String.isBlank(organizations.errorMessage));
            System.Assert.isNull(organizations.organizations);
            for (String resource : new List<String>{ applicationResource, supportResource }) {
                AAREG_AltinnScenarioRepository.RightResult right = repository.getRights(
                    'S07',
                    alias,
                    '111111111',
                    resource
                );
                System.Assert.areEqual(expectedOutcome, right.outcome);
                System.Assert.isFalse(String.isBlank(right.errorMessage));
                System.Assert.isNull(right.action);
                System.Assert.isNull(right.decision, 'A failure definition must not also define Permit.');
            }
        }
        System.Test.stopTest();
    }

    /**
     * Removes the formerly selected organization without adding implicit rights or changing stored user data.
     *
     * @since 2026-10-25
     */
    @IsTest
    static void shouldDefineMissingPreviousOrganization() {
        System.Test.startTest();
        AAREG_AltinnScenarioRepository repository = new AAREG_AltinnScenarioRepository();
        List<AAREG_AltinnScenarioRepository.Organization> organizations = repository
            .getSubject('S08', 'subject-a')
            .organizations.organizations;
        System.Assert.areEqual(1, organizations.size());
        System.Assert.areEqual('222222222', organizations[0].organizationNumber);
        assertDecision(repository, 'S08', '222222222', applicationResource, 'Deny');
        assertDecision(repository, 'S08', '222222222', supportResource, 'Permit');
        assertLookupRejected(
            repository,
            'S08',
            'subject-a',
            '111111111',
            applicationResource,
            'Unknown Altinn scenario organization or resource.'
        );
        System.Assert.areEqual(0, Limits.getDmlStatements());
        System.Test.stopTest();
    }

    /**
     * Rejects unknown and blank identities or lookup keys instead of returning implicit decisions.
     *
     * @since 2026-10-25
     */
    @IsTest
    static void shouldRejectUnknownLookupCombinations() {
        System.Test.startTest();
        AAREG_AltinnScenarioRepository repository = new AAREG_AltinnScenarioRepository();
        assertLookupRejected(
            repository,
            'S99',
            'subject-a',
            '111111111',
            applicationResource,
            'Unknown Altinn scenario.'
        );
        assertLookupRejected(
            repository,
            null,
            'subject-a',
            '111111111',
            applicationResource,
            'Unknown Altinn scenario.'
        );
        assertLookupRejected(
            repository,
            's01',
            'subject-a',
            '111111111',
            applicationResource,
            'Unknown Altinn scenario.'
        );
        assertLookupRejected(
            repository,
            'S01',
            'unknown-subject',
            '111111111',
            applicationResource,
            'Unknown Altinn scenario subject.'
        );
        assertLookupRejected(
            repository,
            'S01',
            null,
            '111111111',
            applicationResource,
            'Unknown Altinn scenario subject.'
        );
        assertLookupRejected(
            repository,
            'S01',
            'subject-a',
            '999999999',
            applicationResource,
            'Unknown Altinn scenario organization or resource.'
        );
        assertLookupRejected(
            repository,
            'S01',
            'subject-a',
            '111111111',
            'unknown-resource',
            'Unknown Altinn scenario organization or resource.'
        );
        assertLookupRejected(
            repository,
            'S01',
            'subject-a',
            null,
            null,
            'Unknown Altinn scenario organization or resource.'
        );
        System.Assert.areEqual(0, Limits.getCallouts());
        System.Test.stopTest();
    }

    /**
     * Rejects malformed JSON without copying source text into the surfaced error.
     *
     * @since 2026-10-25
     */
    @IsTest
    static void shouldRejectMalformedOrUnknownJsonFields() {
        System.Test.startTest();
        assertCatalogueRejected('{"source-marker":', 'Invalid Altinn scenario catalogue JSON.');
        assertCatalogueRejected(
            '{"schemaVersion":1,"unexpected":"source-marker"}',
            'Invalid Altinn scenario catalogue JSON.'
        );
        assertCatalogueRejected('', 'Invalid Altinn scenario catalogue JSON.');
        assertCatalogueRejected(null, 'Invalid Altinn scenario catalogue JSON.');
        System.Test.stopTest();
    }

    /**
     * Rejects unsupported schema versions and missing or empty catalogue contents.
     *
     * @since 2026-10-25
     */
    @IsTest
    static void shouldRejectUnsupportedOrEmptyCatalogue() {
        System.Test.startTest();
        assertCatalogueRejected('{"schemaVersion":2,"scenarios":[]}', 'Unsupported Altinn scenario catalogue version.');
        assertCatalogueRejected('{"scenarios":[]}', 'Unsupported Altinn scenario catalogue version.');
        assertCatalogueRejected('{"schemaVersion":1,"scenarios":[]}', 'Invalid Altinn scenario catalogue.');
        assertCatalogueRejected('{"schemaVersion":1}', 'Invalid Altinn scenario catalogue.');
        assertCatalogueRejected('null', 'Invalid Altinn scenario catalogue.');
        System.Test.stopTest();
    }

    /**
     * Requires versioned, described scenario definitions and rejects duplicate scenario identities.
     *
     * @since 2026-10-25
     */
    @IsTest
    static void shouldRejectInvalidOrDuplicateScenarioDefinitions() {
        AAREG_AltinnScenarioRepository.Scenario scenario = getValidScenario();
        System.Test.startTest();
        scenario.version = 2;
        assertScenarioRejected(scenario, 'Unsupported Altinn scenario version.');
        scenario.version = 1;
        scenario.description = null;
        assertScenarioRejected(scenario, 'Invalid Altinn scenario definition.');
        scenario.description = 'Synthetic fixture.';
        scenario.classification = 'Unverified';
        assertScenarioRejected(scenario, 'Invalid Altinn scenario definition.');
        scenario.classification = 'ContractShape';
        scenario.name = null;
        assertScenarioRejected(scenario, 'Invalid Altinn scenario definition.');
        scenario.name = 'S01';
        assertCatalogueRejected(
            serializeCatalogue(new List<AAREG_AltinnScenarioRepository.Scenario>{ scenario, scenario }),
            'Duplicate Altinn scenario identity.'
        );
        System.Test.stopTest();
    }

    /**
     * Rejects missing subjects, duplicate aliases and incomplete logical identities.
     *
     * @since 2026-10-25
     */
    @IsTest
    static void shouldRejectInvalidOrDuplicateSubjects() {
        AAREG_AltinnScenarioRepository.Scenario scenario = getValidScenario();
        AAREG_AltinnScenarioRepository.Subject subject = scenario.subjects[0];
        System.Test.startTest();
        scenario.subjects.add(subject);
        assertScenarioRejected(scenario, 'Duplicate Altinn scenario subject.');
        scenario.subjects.remove(1);
        subject.alias = null;
        assertScenarioRejected(scenario, 'Invalid Altinn scenario subject.');
        subject.alias = 'subject-a';
        subject.rights = null;
        assertScenarioRejected(scenario, 'Invalid Altinn scenario subject.');
        scenario.subjects.clear();
        assertScenarioRejected(scenario, 'Invalid Altinn scenario definition.');
        scenario.subjects = null;
        assertScenarioRejected(scenario, 'Invalid Altinn scenario definition.');
        System.Test.stopTest();
    }

    /**
     * Rejects null entries at each definition level with explicit catalogue errors instead of null dereferences.
     *
     * @since 2026-10-25
     */
    @IsTest
    static void shouldRejectNullDefinitionEntries() {
        AAREG_AltinnScenarioRepository.Scenario scenario = getValidScenario();
        System.Test.startTest();
        assertCatalogueRejected(
            serializeCatalogue(new List<AAREG_AltinnScenarioRepository.Scenario>{ null }),
            'Invalid Altinn scenario catalogue JSON.'
        );
        scenario.subjects.add(null);
        assertScenarioRejected(scenario, 'Invalid Altinn scenario catalogue JSON.');
        scenario.subjects.remove(1);
        scenario.subjects[0].organizations.organizations.add(null);
        assertScenarioRejected(scenario, 'Invalid Altinn scenario catalogue JSON.');
        scenario.subjects[0].organizations.organizations.remove(1);
        scenario.subjects[0].rights.add(null);
        assertScenarioRejected(scenario, 'Invalid Altinn scenario catalogue JSON.');
        System.Test.stopTest();
    }

    /**
     * Requires explicit successful lists or unambiguous failure results with synthetic messages.
     *
     * @since 2026-10-25
     */
    @IsTest
    static void shouldRejectInvalidOrganizationResultShapes() {
        AAREG_AltinnScenarioRepository.Scenario scenario = getValidScenario();
        AAREG_AltinnScenarioRepository.OrganizationResult result = scenario.subjects[0].organizations;
        System.Test.startTest();
        result.outcome = 'Unknown';
        assertScenarioRejected(scenario, 'Invalid Altinn scenario organization result.');
        result.outcome = 'Success';
        result.errorMessage = 'Synthetic error.';
        assertScenarioRejected(scenario, 'Invalid Altinn scenario organization result.');
        result.errorMessage = null;
        result.organizations = null;
        assertScenarioRejected(scenario, 'Invalid Altinn scenario organization result.');
        result.outcome = 'ResponseError';
        result.errorMessage = 'Synthetic error.';
        assertScenarioRejected(scenario, 'Failure inputs must be classified as Robustness.');
        scenario.classification = 'Robustness';
        result.organizations = new List<AAREG_AltinnScenarioRepository.Organization>();
        assertScenarioRejected(scenario, 'Invalid Altinn scenario organization result.');
        result.organizations = null;
        result.errorMessage = null;
        assertScenarioRejected(scenario, 'Invalid Altinn scenario organization result.');
        scenario.subjects[0].organizations = null;
        assertScenarioRejected(scenario, 'Invalid Altinn scenario organization result.');
        System.Test.stopTest();
    }

    /**
     * Rejects duplicate, malformed and identifying party entries before they can be used as definitions.
     *
     * @since 2026-10-25
     */
    @IsTest
    static void shouldRejectInvalidOrganizationDefinitions() {
        AAREG_AltinnScenarioRepository.Scenario scenario = getValidScenario();
        List<AAREG_AltinnScenarioRepository.Organization> organizations = scenario.subjects[0]
            .organizations.organizations;
        AAREG_AltinnScenarioRepository.Organization organization = organizations[0];
        System.Test.startTest();
        organizations.add(organization);
        assertScenarioRejected(scenario, 'Duplicate Altinn scenario organization.');
        organizations.remove(1);
        organization.organizationNumber = 'not-an-organization-number';
        assertScenarioRejected(scenario, 'Invalid Altinn scenario organization.');
        organization.organizationNumber = '111111111';
        organization.type = 'Unknown';
        assertScenarioRejected(scenario, 'Invalid Altinn scenario organization.');
        organization.type = 'Person';
        assertScenarioRejected(scenario, 'Invalid Altinn scenario organization.');
        organization.type = 'Organization';
        organization.unitType = null;
        assertScenarioRejected(scenario, 'Invalid Altinn scenario organization.');
        organization.unitType = 'AS';
        organization.name = null;
        assertScenarioRejected(scenario, 'Invalid Altinn scenario organization.');
        System.Test.stopTest();
    }

    /**
     * Rejects duplicate rights keys, unknown outcomes and ambiguous failure or access decisions.
     *
     * @since 2026-10-25
     */
    @IsTest
    static void shouldRejectInvalidRightsDefinitions() {
        AAREG_AltinnScenarioRepository.Scenario scenario = getValidScenario();
        List<AAREG_AltinnScenarioRepository.RightResult> rights = scenario.subjects[0].rights;
        AAREG_AltinnScenarioRepository.RightResult right = rights[0];
        System.Test.startTest();
        rights.add(right);
        assertScenarioRejected(scenario, 'Duplicate Altinn scenario rights combination.');
        rights.remove(rights.size() - 1);
        right.outcome = 'Unknown';
        assertScenarioRejected(scenario, 'Invalid Altinn scenario rights result.');
        right.outcome = 'Decision';
        right.decision = 'Unknown';
        assertScenarioRejected(scenario, 'Invalid Altinn scenario rights result.');
        right.decision = 'Permit';
        right.action = 'Delete';
        assertScenarioRejected(scenario, 'Invalid Altinn scenario rights result.');
        right.action = 'Access';
        right.resource = null;
        assertScenarioRejected(scenario, 'Invalid Altinn scenario rights result.');
        right.resource = applicationResource;
        right.organizationNumber = '999999999';
        assertScenarioRejected(scenario, 'Unknown Altinn scenario organization in rights matrix.');
        right.organizationNumber = '111111111';
        right.outcome = 'Exception';
        right.errorMessage = 'Synthetic exception.';
        scenario.classification = 'Robustness';
        assertScenarioRejected(scenario, 'Invalid Altinn scenario rights result.');
        right.action = null;
        right.decision = null;
        right.errorMessage = null;
        assertScenarioRejected(scenario, 'Invalid Altinn scenario rights result.');
        System.Test.stopTest();
    }

    private static void assertDecision(
        AAREG_AltinnScenarioRepository repository,
        String scenarioName,
        String organizationNumber,
        String resource,
        String decision
    ) {
        AAREG_AltinnScenarioRepository.RightResult right = repository.getRights(
            scenarioName,
            'subject-a',
            organizationNumber,
            resource
        );
        System.Assert.areEqual('Decision', right.outcome);
        System.Assert.areEqual('Access', right.action);
        System.Assert.areEqual(decision, right.decision);
        System.Assert.areEqual(resource, right.resource);
    }

    private static void assertLookupRejected(
        AAREG_AltinnScenarioRepository repository,
        String scenarioName,
        String subjectAlias,
        String organizationNumber,
        String resource,
        String expectedMessage
    ) {
        try {
            repository.getRights(scenarioName, subjectAlias, organizationNumber, resource);
            System.Assert.fail('An unknown combination must not produce an implicit decision.');
        } catch (AAREG_AltinnScenarioRepository.AltinnScenarioRepositoryException caughtException) {
            System.Assert.areEqual(expectedMessage, caughtException.getMessage());
        }
    }

    private static AAREG_AltinnScenarioRepository.Scenario getValidScenario() {
        return new AAREG_AltinnScenarioRepository().getScenario('S01');
    }

    private static String serializeCatalogue(List<AAREG_AltinnScenarioRepository.Scenario> scenarios) {
        return JSON.serialize(new Map<String, Object>{ 'schemaVersion' => 1, 'scenarios' => scenarios });
    }

    private static void assertScenarioRejected(
        AAREG_AltinnScenarioRepository.Scenario scenario,
        String expectedMessage
    ) {
        assertCatalogueRejected(
            serializeCatalogue(new List<AAREG_AltinnScenarioRepository.Scenario>{ scenario }),
            expectedMessage
        );
    }

    private static void assertCatalogueRejected(String catalogueJson, String expectedMessage) {
        try {
            new AAREG_AltinnScenarioRepository(catalogueJson);
            System.Assert.fail('Invalid catalogue content must fail explicitly before it can supply scenario results.');
        } catch (AAREG_AltinnScenarioRepository.AltinnScenarioRepositoryException caughtException) {
            System.Assert.areEqual(
                expectedMessage,
                caughtException.getMessage(),
                'Do not echo source or lookup values.'
            );
        }
    }
}
