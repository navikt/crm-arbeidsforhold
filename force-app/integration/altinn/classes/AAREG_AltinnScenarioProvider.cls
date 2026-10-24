/**
 * Maps authorized scenario definitions to the installed Altinn response DTOs with sharing.
 * Every operation enforces the current user's assignment, environment, permission and linked identity.
 * Does not perform callouts, product DML, UI filtering, access decisions, sharing or live fallback.
 *
 * @author Kenneth Sørensen
 * @since 2026-10-25
 * @group AAREG Altinn
 */
public with sharing class AAREG_AltinnScenarioProvider implements IAltinnCalloutService {
    private Id targetUserId;
    private AAREG_AltinnScenarioRepository repository;

    /**
     * Binds the target user without reading configuration or authorizing future operations.
     *
     * @param targetUserId The user that each operation must verify against the logged-in user.
     */
    public AAREG_AltinnScenarioProvider(Id targetUserId) {
        this.targetUserId = targetUserId;
    }

    /**
     * Returns an unfiltered v3 organization response after validating current runtime authorization.
     *
     * @param personIdent The requested identity, verified by the policy without being logged.
     * @return The installed organization DTO, including configured empty lists or explicit response errors.
     * @throws AAREG_AltinnScenarioPolicy.AltinnScenarioPolicyException If runtime authorization fails.
     * @throws AAREG_AltinnScenarioRepository.AltinnScenarioRepositoryException If the definition is invalid or unknown.
     * @throws AltinnScenarioProviderException If assignment is inactive or the scenario defines a thrown failure.
     */
    public AltinnCalloutService.AltinnOrganizationsResponse getOrganizations(String personIdent) {
        AAREG_AltinnScenarioSetting__c assignment = requireAssignment(personIdent);
        AAREG_AltinnScenarioRepository.OrganizationResult result = getRepository()
            .getSubject(assignment.ScenarioName__c, assignment.SubjectAlias__c)
            .organizations;
        if (result.outcome.equals('Exception')) {
            throw new AltinnScenarioProviderException(result.errorMessage);
        }
        AltinnCalloutService.AltinnOrganizationsResponse response = new AltinnCalloutService.AltinnOrganizationsResponse();
        response.altinnVersion = 'v3';
        if (result.outcome.equals('ResponseError')) {
            response.errorMessage = result.errorMessage;
            return response;
        }
        response.success = true;
        response.organizations = new List<AltinnCalloutService.Organization>();
        for (AAREG_AltinnScenarioRepository.Organization definition : result.organizations) {
            AltinnCalloutService.Organization organization = new AltinnCalloutService.Organization();
            organization.name = definition.name;
            organization.organizationNumber = definition.organizationNumber;
            organization.type = definition.type;
            organization.unitType = definition.unitType;
            response.organizations.add(organization);
        }
        return response;
    }

    /**
     * Returns only the assigned subject's explicit organization/resource outcome after rechecking authorization.
     * Preserves current v3 Deny semantics: success=false with an Access/Deny right and the existing error text.
     *
     * @param personIdent The requested identity, verified by the policy.
     * @param organizationNumber The exact synthetic organization number.
     * @param serviceCode The exact Altinn resource identifier; no service-code translation is performed.
     * @return The installed rights DTO containing the configured decision or response error.
     * @throws AAREG_AltinnScenarioPolicy.AltinnScenarioPolicyException If runtime authorization fails.
     * @throws AAREG_AltinnScenarioRepository.AltinnScenarioRepositoryException If any lookup combination is unknown.
     * @throws AltinnScenarioProviderException If assignment is inactive or the scenario defines a thrown failure.
     */
    public AltinnCalloutService.AltinnRightsResponse getRights(
        String personIdent,
        String organizationNumber,
        String serviceCode
    ) {
        AAREG_AltinnScenarioSetting__c assignment = requireAssignment(personIdent);
        AAREG_AltinnScenarioRepository.RightResult result = getRepository()
            .getRights(assignment.ScenarioName__c, assignment.SubjectAlias__c, organizationNumber, serviceCode);
        if (result.outcome.equals('Exception')) {
            throw new AltinnScenarioProviderException(result.errorMessage);
        }
        AltinnCalloutService.AltinnRightsResponse response = new AltinnCalloutService.AltinnRightsResponse();
        if (result.outcome.equals('ResponseError')) {
            response.errorMessage = result.errorMessage;
            return response;
        }
        AltinnCalloutService.Right right = new AltinnCalloutService.Right();
        right.Action = result.action;
        right.Decision = result.decision;
        right.Resource = result.resource;
        response.rights = new List<AltinnCalloutService.Right>{ right };
        response.success = result.decision.equals('Permit');
        if (!response.success) {
            response.errorMessage = 'Access denied';
        }
        return response;
    }

    private AAREG_AltinnScenarioSetting__c requireAssignment(String personIdent) {
        AAREG_AltinnScenarioSetting__c assignment = AAREG_AltinnScenarioPolicy.resolveAssignment(
            targetUserId,
            personIdent
        );
        if (assignment == null) {
            throw new AltinnScenarioProviderException('Altinn scenario assignment is not active.');
        }
        return assignment;
    }

    private AAREG_AltinnScenarioRepository getRepository() {
        if (repository == null) {
            repository = new AAREG_AltinnScenarioRepository();
        }
        return repository;
    }

    /**
     * Reports inactive scenario use or a controlled synthetic failure without live fallback.
     *
     * @author Kenneth Sørensen
     * @since 2026-10-25
     * @group AAREG Altinn
     */
    public class AltinnScenarioProviderException extends Exception {
    }
}
