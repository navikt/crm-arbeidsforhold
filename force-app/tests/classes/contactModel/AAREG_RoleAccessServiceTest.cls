/**
 * Tests the server-side access decision for entry portal roles against the decision table in the role model.
 *
 * @author Kenneth Sørensen
 * @since 2026-11
 * @group Contact Model
 */
@IsTest
private class AAREG_RoleAccessServiceTest {
    private static final String ORGANIZATION = '910000001';
    private static final String APPLY = 'nav_arbeidsforhold_aa-registeret-sok-tilgang';
    private static final String SUPPORT = 'nav_arbeidsforhold_aa-registeret-brukerstotte';

    private class AltinnStub implements IAltinnCalloutService {
        private Map<String, String> decisionByResource;

        private AltinnStub(Map<String, String> decisionByResource) {
            this.decisionByResource = decisionByResource;
        }

        public Object getOrganizations(String personIdent) {
            return null;
        }

        public Object getRights(String personIdent, String organizationNumber, String serviceCode) {
            AltinnCalloutService.AltinnRightsResponse response = new AltinnCalloutService.AltinnRightsResponse();
            String decision = decisionByResource.get(serviceCode) ?? 'Deny';
            if (decision == 'Error') {
                response.success = false;
                response.errorMessage = 'Timeout';
                return response;
            }
            response.success = true;
            AltinnCalloutService.Right right = new AltinnCalloutService.Right();
            right.Action = 'Access';
            right.Decision = decision;
            response.rights = new List<AltinnCalloutService.Right>{ right };
            return response;
        }
    }

    @TestSetup
    static void setUp() {
        AAREG_ContactModelTestDataFactory.createPortalUser('Rollesen', '01010112345');
    }

    private static User portalUser() {
        return [SELECT Id FROM User WHERE LastName = 'Rollesen' AND ContactId != NULL LIMIT 1];
    }

    private static void enablePortal(Boolean employerOn) {
        AAREG_ContactModelTestDataFactory.setFlags(
            new Map<String, Boolean>{
                AAREG_ContactModelGate.ENTRY_PORTAL => true,
                AAREG_ContactModelGate.ROLE_EMPLOYER => employerOn,
                AAREG_ContactModelGate.ROLE_PRIVATE => true
            },
            null
        );
    }

    private static void altinn(String applyDecision, String supportDecision) {
        AAREG_RoleAccessService.altinnOverride = new AltinnCalloutService(
            new AltinnStub(new Map<String, String>{ APPLY => applyDecision, SUPPORT => supportDecision })
        );
    }

    private static AAREG_RoleAccessService.Decision decideAsPortalUser(String roleKey, String contextKey) {
        AAREG_RoleAccessService.Decision decision;
        System.runAs(portalUser()) {
            System.Test.startTest();
            decision = AAREG_RoleAccessService.decide(roleKey, contextKey);
            System.Test.stopTest();
        }
        return decision;
    }

    @IsTest
    static void applyAccessGrantsAllFiveCapabilities() {
        enablePortal(true);
        altinn('Permit', 'Deny');

        AAREG_RoleAccessService.Decision decision = decideAsPortalUser('Employer', ' 910 000 001 ');

        System.Assert.areEqual(AAREG_RoleAccessService.GRANTED, decision.outcome, JSON.serialize(decision));
        System.Assert.areEqual(
            new List<String>{ 'AGREEMENTS', 'APPLICATION', 'MESSAGES', 'MY_APPLICATIONS', 'SUPPORT' },
            decision.capabilities,
            'Apply access gives every capability'
        );
        System.Assert.areEqual(ORGANIZATION, decision.organizationNumber, 'Normalized organization number');
    }

    @IsTest
    static void supportAccessGrantsOnlySupportCapabilities() {
        enablePortal(true);
        altinn('Deny', 'Permit');

        AAREG_RoleAccessService.Decision decision = decideAsPortalUser('Employer', ORGANIZATION);

        System.Assert.areEqual(AAREG_RoleAccessService.GRANTED, decision.outcome, JSON.serialize(decision));
        System.Assert.areEqual(
            new List<String>{ 'AGREEMENTS', 'MESSAGES', 'SUPPORT' },
            decision.capabilities,
            'Support access gives agreements, support and messages'
        );
    }

    @IsTest
    static void missingRightsAreDenied() {
        enablePortal(true);
        altinn('Deny', 'Deny');

        AAREG_RoleAccessService.Decision decision = decideAsPortalUser('Employer', ORGANIZATION);

        System.Assert.areEqual(AAREG_RoleAccessService.DENIED, decision.outcome, 'No right');
        System.Assert.areEqual(AAREG_RoleAccessService.REASON_NO_ACCESS, decision.reason, 'Fixed reason');
        System.Assert.isTrue(decision.capabilities.isEmpty(), 'Nothing granted');
    }

    @IsTest
    static void failingAltinnIsTechnicalErrorNotDenial() {
        enablePortal(true);
        altinn('Error', 'Error');

        AAREG_RoleAccessService.Decision decision = decideAsPortalUser('Employer', ORGANIZATION);

        System.Assert.areEqual(AAREG_RoleAccessService.TECHNICAL_ERROR, decision.outcome, 'Retry, not denial');
        System.Assert.isTrue(decision.capabilities.isEmpty(), 'Nothing granted on error');
    }

    @IsTest
    static void switchedOffRoleIsDeniedEvenWithRights() {
        enablePortal(false);
        altinn('Permit', 'Permit');

        AAREG_RoleAccessService.Decision decision = decideAsPortalUser('Employer', ORGANIZATION);

        System.Assert.areEqual(AAREG_RoleAccessService.DENIED, decision.outcome, 'Flag off denies');
        System.Assert.areEqual(AAREG_RoleAccessService.REASON_ROLE_NOT_ACTIVE, decision.reason, 'Role not active');
    }

    @IsTest
    static void switchedOffPortalDeniesEveryRole() {
        AAREG_ContactModelTestDataFactory.setFlags(
            new Map<String, Boolean>{
                AAREG_ContactModelGate.ENTRY_PORTAL => false,
                AAREG_ContactModelGate.ROLE_EMPLOYER => true
            },
            null
        );
        altinn('Permit', 'Permit');

        AAREG_RoleAccessService.Decision decision = decideAsPortalUser('Employer', ORGANIZATION);

        System.Assert.areEqual(AAREG_RoleAccessService.REASON_ROLE_NOT_ACTIVE, decision.reason, 'Portal off');
    }

    @IsTest
    static void unknownRoleAndInvalidContextAreDeniedWithoutCallingAltinn() {
        enablePortal(true);
        AAREG_RoleAccessService.Decision unknown;
        AAREG_RoleAccessService.Decision invalid;
        System.runAs(portalUser()) {
            unknown = AAREG_RoleAccessService.decide('Admin', ORGANIZATION);
            invalid = AAREG_RoleAccessService.decide('Employer', '12345');
        }

        System.Assert.areEqual(AAREG_RoleAccessService.REASON_UNKNOWN_ROLE, unknown.reason, 'Unknown role');
        System.Assert.areEqual(AAREG_RoleAccessService.REASON_INVALID_CONTEXT, invalid.reason, 'Not nine digits');
    }

    @IsTest
    static void privatePersonIsGrantedWithoutOrganization() {
        enablePortal(true);

        AAREG_RoleAccessService.Decision decision = decideAsPortalUser('Private', null);

        System.Assert.areEqual(AAREG_RoleAccessService.GRANTED, decision.outcome, JSON.serialize(decision));
        System.Assert.areEqual(AAREG_RoleAccessService.CONTEXT_PERSON, decision.contextType, 'Person context');
        System.Assert.isNull(decision.organizationNumber, 'No organization');
    }

    @IsTest
    static void privatePersonCannotPassAnOrganization() {
        enablePortal(true);

        AAREG_RoleAccessService.Decision decision = decideAsPortalUser('Private', ORGANIZATION);

        System.Assert.areEqual(AAREG_RoleAccessService.REASON_INVALID_CONTEXT, decision.reason, 'Person only');
    }

    @IsTest
    static void shieldedPersonGetsNoPortalAndNoRole() {
        enablePortal(true);
        altinn('Permit', 'Permit');
        AAREG_ContactModelTestDataFactory.shieldPerson(portalUser());
        AAREG_RoleAccessService.Decision decision;
        Boolean portalEnabled;
        System.runAs(portalUser()) {
            portalEnabled = AAREG_RoleAccessService.isPortalEnabled();
            decision = AAREG_RoleAccessService.decide('Employer', ORGANIZATION);
        }

        System.Assert.isFalse(portalEnabled, 'Current home page for shielded persons');
        System.Assert.areEqual(AAREG_RoleAccessService.REASON_ROLE_NOT_ACTIVE, decision.reason, 'Fail closed');
    }

    @IsTest
    static void requireRejectsMissingCapability() {
        enablePortal(true);
        altinn('Deny', 'Permit');
        System.runAs(portalUser()) {
            System.Assert.areEqual(
                AAREG_RoleAccessService.GRANTED,
                AAREG_RoleAccessService.require('Employer', ORGANIZATION, 'SUPPORT').outcome,
                'Support allowed'
            );
            try {
                AAREG_RoleAccessService.require('Employer', ORGANIZATION, 'APPLICATION');
                System.Assert.fail('Expected AccessDeniedException');
            } catch (AAREG_RoleAccessService.AccessDeniedException error) {
                System.Assert.isTrue(error.getMessage().startsWith('DENIED'), error.getMessage());
            }
        }
    }

    @IsTest
    static void availableRolesFollowFlagsAndSortOrder() {
        AAREG_ContactModelTestDataFactory.setFlags(
            new Map<String, Boolean>{
                AAREG_ContactModelGate.ENTRY_PORTAL => true,
                AAREG_ContactModelGate.ROLE_EMPLOYER => true,
                AAREG_ContactModelGate.ROLE_PARTNER => false,
                AAREG_ContactModelGate.ROLE_PRIVATE => true
            },
            null
        );
        List<String> roleKeys = new List<String>();
        System.runAs(portalUser()) {
            for (AAREG_PortalRole__mdt role : AAREG_RoleAccessService.availableRoles()) {
                roleKeys.add(role.DeveloperName);
            }
        }

        System.Assert.areEqual(new List<String>{ 'Employer', 'Private' }, roleKeys, 'Partner is switched off');
    }

    @IsTest
    static void inactiveRoleIsDeniedForMinimumAccessUser() {
        enablePortal(true);
        AAREG_RoleAccessService.rolesOverride = new Map<String, AAREG_PortalRole__mdt>{
            'Employer' => new AAREG_PortalRole__mdt(
                DeveloperName = 'Employer',
                ContextType__c = 'Organization',
                FeatureFlag__c = AAREG_ContactModelGate.ROLE_EMPLOYER,
                IsActive__c = false
            )
        };
        User minimumAccessUser = AAREG_ContactModelTestDataFactory.createMinimumAccessUser('Minimum', null);
        AAREG_RoleAccessService.Decision decision;
        System.runAs(minimumAccessUser) {
            decision = AAREG_RoleAccessService.decide('Employer', ORGANIZATION);
        }

        System.Assert.areEqual(AAREG_RoleAccessService.REASON_ROLE_NOT_ACTIVE, decision.reason, 'Inactive role');
    }
}
