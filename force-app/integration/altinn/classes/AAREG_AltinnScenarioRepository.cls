/**
 * Reads synthetic, versioned Altinn scenario definitions without Setup, callouts or record changes.
 * This catalogue does not authorize scenario execution; runtime callers must enforce AAREG_AltinnScenarioPolicy.
 * Only the named static resource is read in system mode so minimum-access users can read packaged definitions.
 *
 * @author Kenneth Sørensen
 * @since 2026-10-25
 * @group AAREG Altinn
 */
public with sharing class AAREG_AltinnScenarioRepository {
    private Catalogue catalogue;

    /**
     * Loads the packaged catalogue once for this repository instance.
     *
     * @throws AltinnScenarioRepositoryException If the resource is missing, malformed, unsupported or inconsistent.
     * @throws QueryException If reading the packaged resource fails; no fallback is provided.
     */
    public AAREG_AltinnScenarioRepository() {
        this(readCatalogue());
    }

    /** Allows malformed catalogue fixtures without replacing packaged resources or exposing a runtime override. */
    @TestVisible
    private AAREG_AltinnScenarioRepository(String catalogueJson) {
        if (String.isBlank(catalogueJson)) {
            throw new AltinnScenarioRepositoryException('Invalid Altinn scenario catalogue JSON.');
        }
        try {
            catalogue = (Catalogue) JSON.deserializeStrict(catalogueJson, Catalogue.class);
        } catch (System.JSONException caughtException) {
            throw new AltinnScenarioRepositoryException('Invalid Altinn scenario catalogue JSON.');
        }
        validateCatalogue();
    }

    /**
     * Lists scenario definitions in catalogue order without applying runtime authorization or UI filtering.
     *
     * @return The versioned definitions, including their logical subject aliases.
     */
    public List<Scenario> getScenarios() {
        return catalogue.scenarios;
    }

    /**
     * Finds an exact scenario identity.
     *
     * @param scenarioName The stable, case-sensitive catalogue identity.
     * @return The matching versioned definition.
     * @throws AltinnScenarioRepositoryException If the scenario is unknown.
     */
    public Scenario getScenario(String scenarioName) {
        for (Scenario scenario : catalogue.scenarios) {
            if (scenario.name.equals(scenarioName)) {
                return scenario;
            }
        }
        throw new AltinnScenarioRepositoryException('Unknown Altinn scenario.');
    }

    /**
     * Resolves a logical subject without accepting or returning a person identifier.
     *
     * @param scenarioName The stable scenario identity.
     * @param subjectAlias The exact logical alias assigned to the synthetic user.
     * @return The subject's organization result and explicit rights matrix.
     * @throws AltinnScenarioRepositoryException If the scenario or alias is unknown.
     */
    public Subject getSubject(String scenarioName, String subjectAlias) {
        for (Subject subject : getScenario(scenarioName).subjects) {
            if (subject.alias.equals(subjectAlias)) {
                return subject;
            }
        }
        throw new AltinnScenarioRepositoryException('Unknown Altinn scenario subject.');
    }

    /**
     * Resolves one explicitly configured organization and resource combination without defaulting to Permit or Deny.
     *
     * @param scenarioName The stable scenario identity.
     * @param subjectAlias The assigned logical subject alias.
     * @param organizationNumber The synthetic organization number.
     * @param resource The exact Altinn resource identifier.
     * @return The configured decision, response error or exception definition.
     * @throws AltinnScenarioRepositoryException If any part of the combination is unknown.
     */
    public RightResult getRights(String scenarioName, String subjectAlias, String organizationNumber, String resource) {
        for (RightResult right : getSubject(scenarioName, subjectAlias).rights) {
            if (right.organizationNumber.equals(organizationNumber) && right.resource.equals(resource)) {
                return right;
            }
        }
        throw new AltinnScenarioRepositoryException('Unknown Altinn scenario organization or resource.');
    }

    private void validateCatalogue() {
        if (catalogue == null) {
            throw new AltinnScenarioRepositoryException('Invalid Altinn scenario catalogue.');
        }
        if (catalogue.schemaVersion != 1) {
            throw new AltinnScenarioRepositoryException('Unsupported Altinn scenario catalogue version.');
        }
        if (catalogue.scenarios == null || catalogue.scenarios.isEmpty()) {
            throw new AltinnScenarioRepositoryException('Invalid Altinn scenario catalogue.');
        }
        Set<String> scenarioNames = new Set<String>();
        for (Scenario scenario : catalogue.scenarios) {
            if (
                scenario == null ||
                String.isBlank(scenario.name) ||
                String.isBlank(scenario.description) ||
                !new Set<String>{ 'ContractShape', 'Robustness' }.contains(scenario.classification) ||
                scenario.subjects == null ||
                scenario.subjects.isEmpty()
            ) {
                throw new AltinnScenarioRepositoryException('Invalid Altinn scenario definition.');
            }
            if (scenario.version != 1) {
                throw new AltinnScenarioRepositoryException('Unsupported Altinn scenario version.');
            }
            if (!scenarioNames.add(scenario.name)) {
                throw new AltinnScenarioRepositoryException('Duplicate Altinn scenario identity.');
            }
            validateSubjects(scenario);
        }
    }

    private static void validateSubjects(Scenario scenario) {
        Set<String> aliases = new Set<String>();
        for (Subject subject : scenario.subjects) {
            if (subject == null || String.isBlank(subject.alias) || subject.rights == null) {
                throw new AltinnScenarioRepositoryException('Invalid Altinn scenario subject.');
            }
            if (!aliases.add(subject.alias)) {
                throw new AltinnScenarioRepositoryException('Duplicate Altinn scenario subject.');
            }
            Set<String> organizationNumbers = validateOrganizations(subject.organizations, scenario.classification);
            validateRights(subject, organizationNumbers, scenario.classification);
        }
    }

    private static Set<String> validateOrganizations(OrganizationResult result, String classification) {
        if (result == null || !new Set<String>{ 'Success', 'ResponseError', 'Exception' }.contains(result.outcome)) {
            throw new AltinnScenarioRepositoryException('Invalid Altinn scenario organization result.');
        }
        Set<String> organizationNumbers = new Set<String>();
        if (!result.outcome.equals('Success')) {
            requireRobustness(classification);
            if (String.isBlank(result.errorMessage) || result.organizations != null) {
                throw new AltinnScenarioRepositoryException('Invalid Altinn scenario organization result.');
            }
            return organizationNumbers;
        }
        if (result.organizations == null || result.errorMessage != null) {
            throw new AltinnScenarioRepositoryException('Invalid Altinn scenario organization result.');
        }
        for (Organization organization : result.organizations) {
            if (
                organization == null ||
                String.isBlank(organization.name) ||
                !new Set<String>{ 'Organization', 'Person' }.contains(organization.type)
            ) {
                throw new AltinnScenarioRepositoryException('Invalid Altinn scenario organization.');
            }
            if (organization.type.equals('Person')) {
                if (organization.organizationNumber != null || organization.unitType != null) {
                    throw new AltinnScenarioRepositoryException('Invalid Altinn scenario organization.');
                }
            } else {
                if (!isOrganizationNumber(organization.organizationNumber) || String.isBlank(organization.unitType)) {
                    throw new AltinnScenarioRepositoryException('Invalid Altinn scenario organization.');
                }
                if (!organizationNumbers.add(organization.organizationNumber)) {
                    throw new AltinnScenarioRepositoryException('Duplicate Altinn scenario organization.');
                }
            }
        }
        return organizationNumbers;
    }

    private static void validateRights(Subject subject, Set<String> organizationNumbers, String classification) {
        Set<String> combinations = new Set<String>();
        for (RightResult right : subject.rights) {
            if (
                right == null ||
                !isOrganizationNumber(right.organizationNumber) ||
                String.isBlank(right.resource) ||
                !new Set<String>{ 'Decision', 'ResponseError', 'Exception' }.contains(right.outcome)
            ) {
                throw new AltinnScenarioRepositoryException('Invalid Altinn scenario rights result.');
            }
            if (right.outcome.equals('Decision')) {
                if (
                    !'Access'.equals(right.action) ||
                    !new Set<String>{ 'Permit', 'Deny' }.contains(right.decision) ||
                    right.errorMessage != null
                ) {
                    throw new AltinnScenarioRepositoryException('Invalid Altinn scenario rights result.');
                }
            } else {
                requireRobustness(classification);
                if (String.isBlank(right.errorMessage) || right.action != null || right.decision != null) {
                    throw new AltinnScenarioRepositoryException('Invalid Altinn scenario rights result.');
                }
            }
            if (
                subject.organizations.outcome.equals('Success') &&
                !organizationNumbers.contains(right.organizationNumber)
            ) {
                throw new AltinnScenarioRepositoryException('Unknown Altinn scenario organization in rights matrix.');
            }
            if (!combinations.add(right.organizationNumber + '|' + right.resource)) {
                throw new AltinnScenarioRepositoryException('Duplicate Altinn scenario rights combination.');
            }
        }
    }

    private static Boolean isOrganizationNumber(String value) {
        return value != null && value.length() == 9 && value.isNumeric();
    }

    private static void requireRobustness(String classification) {
        if (!'Robustness'.equals(classification)) {
            throw new AltinnScenarioRepositoryException('Failure inputs must be classified as Robustness.');
        }
    }

    private static String readCatalogue() {
        List<StaticResource> resources = [
            SELECT Body
            FROM StaticResource
            WHERE Name = 'AAREG_AltinnScenarios' AND NamespacePrefix = NULL
            WITH SYSTEM_MODE
            LIMIT 1
        ];
        if (resources.isEmpty()) {
            throw new AltinnScenarioRepositoryException('Altinn scenario catalogue is missing.');
        }
        return resources[0].Body.toString();
    }

    private class Catalogue {
        public Integer schemaVersion;
        public List<Scenario> scenarios;
    }

    /**
     * Describes a stable scenario and the synthetic subjects supported by that version.
     *
     * @author Kenneth Sørensen
     * @since 2026-10-25
     * @group AAREG Altinn
     */
    public class Scenario {
        /** Stable scenario identity, such as S01. */
        public String name;
        /** Supported definition version, independent of the catalogue schema version. */
        public Integer version;
        /** Explains the intended application observation without claiming an observed UI outcome. */
        public String description;
        /** Distinguishes current contract-shaped data from explicit robustness inputs. */
        public String classification;
        /** Logical subjects supported by this scenario. */
        public List<Subject> subjects;
    }

    /**
     * Groups organization and rights definitions under a logical synthetic identity.
     *
     * @author Kenneth Sørensen
     * @since 2026-10-25
     * @group AAREG Altinn
     */
    public class Subject {
        /** Logical alias, never a person identifier. */
        public String alias;
        /** Organization result before any application filtering. */
        public OrganizationResult organizations;
        /** Explicit outcomes keyed by organization and resource. */
        public List<RightResult> rights;
    }

    /**
     * Defines a successful organization list, a response-level error or a thrown failure.
     *
     * @author Kenneth Sørensen
     * @since 2026-10-25
     * @group AAREG Altinn
     */
    public class OrganizationResult {
        /** Success, ResponseError or Exception; no transport or authentication behavior is simulated. */
        public String outcome;
        /** Synthetic error text for failure outcomes only. */
        public String errorMessage;
        /** Unfiltered organizations for Success, including a valid empty list. */
        public List<Organization> organizations;
    }

    /**
     * Contains only the synthetic party fields needed by the existing organization selection flow.
     *
     * @author Kenneth Sørensen
     * @since 2026-10-25
     * @group AAREG Altinn
     */
    public class Organization {
        /** Clearly synthetic display name. */
        public String name;
        /** Synthetic organization number, absent for Person entries. */
        public String organizationNumber;
        /** Organization or Person, deliberately left unfiltered. */
        public String type;
        /** Organization form consumed by the existing UI filter. */
        public String unitType;
    }

    /**
     * Defines a decision or controlled failure for one synthetic organization and resource.
     *
     * @author Kenneth Sørensen
     * @since 2026-10-25
     * @group AAREG Altinn
     */
    public class RightResult {
        /** Synthetic organization number used as part of the lookup key. */
        public String organizationNumber;
        /** Exact Altinn resource identifier used as part of the lookup key. */
        public String resource;
        /** Decision, ResponseError or Exception. */
        public String outcome;
        /** Access for Decision outcomes, matching the current integration response. */
        public String action;
        /** Explicit Permit or Deny for Decision outcomes. */
        public String decision;
        /** Synthetic error text for ResponseError or Exception outcomes. */
        public String errorMessage;
    }

    /**
     * Signals missing or invalid scenario definitions without including source data or lookup values.
     *
     * @author Kenneth Sørensen
     * @since 2026-10-25
     * @group AAREG Altinn
     */
    public class AltinnScenarioRepositoryException extends Exception {
    }
}
