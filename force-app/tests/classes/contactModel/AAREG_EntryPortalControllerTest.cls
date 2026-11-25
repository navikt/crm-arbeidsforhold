/**
 * Tests the entry portal endpoints: portal state, the role decision with the transition bridge to the existing
 * sub-pages, and the organization list per role.
 *
 * @author Kenneth Sørensen
 * @since 2026-11
 * @group Contact Model
 */
@IsTest
private class AAREG_EntryPortalControllerTest {
    private static final String PERMITTED = '910000001';
    private static final String DENIED = '910000002';

    private class AltinnStub implements IAltinnCalloutService {
        public Object getOrganizations(String personIdent) {
            AltinnCalloutService.AltinnOrganizationsResponse response = new AltinnCalloutService.AltinnOrganizationsResponse();
            response.success = true;
            AltinnCalloutService.Organization organization = new AltinnCalloutService.Organization();
            organization.organizationNumber = PERMITTED;
            organization.name = 'Bedrift AS';
            organization.unitType = 'AS';
            organization.isDeleted = 'false';
            response.organizations = new List<AltinnCalloutService.Organization>{ organization };
            return response;
        }

        public Object getRights(String personIdent, String organizationNumber, String serviceCode) {
            AltinnCalloutService.AltinnRightsResponse response = new AltinnCalloutService.AltinnRightsResponse();
            response.success = true;
            AltinnCalloutService.Right right = new AltinnCalloutService.Right();
            right.Action = 'Access';
            right.Decision = organizationNumber == PERMITTED ? 'Permit' : 'Deny';
            response.rights = new List<AltinnCalloutService.Right>{ right };
            return response;
        }
    }

    @TestSetup
    static void setUp() {
        AAREG_ContactModelTestDataFactory.createPortalUser('Inngangsen', '01010112345');
    }

    private static User portalUser() {
        return [SELECT Id FROM User WHERE LastName = 'Inngangsen' AND ContactId != NULL LIMIT 1];
    }

    private static void enablePortal(Boolean portalOn) {
        AAREG_ContactModelTestDataFactory.setFlags(
            new Map<String, Boolean>{
                AAREG_ContactModelGate.ENTRY_PORTAL => portalOn,
                AAREG_ContactModelGate.ROLE_EMPLOYER => true,
                AAREG_ContactModelGate.ROLE_PARTNER => true,
                AAREG_ContactModelGate.ROLE_PRIVATE => true
            },
            null
        );
        AltinnCalloutService stub = new AltinnCalloutService(new AltinnStub());
        AAREG_RoleAccessService.altinnOverride = stub;
        AAREG_ContactModelPortalController.altinnOverride = stub;
    }

    @IsTest
    static void portalListsRolesWithTheirPagesWhenOn() {
        enablePortal(true);
        AAREG_EntryPortalController.Portal portal;
        System.runAs(portalUser()) {
            portal = AAREG_EntryPortalController.getPortal();
        }

        System.Assert.isTrue(portal.enabled, 'Portal on');
        System.Assert.areEqual(3, portal.roles.size(), JSON.serialize(portal));
        System.Assert.areEqual('Employer', portal.roles[0].roleKey, 'Employer first');
        System.Assert.areEqual('Arbeidsgiver__c', portal.roles[0].pageApiName, 'Role page');
        System.Assert.areEqual('Person', portal.roles[2].contextType, 'Private is person based');
    }

    @IsTest
    static void portalShowsTheOrganizationTheSubPagesUse() {
        enablePortal(true);
        update as system new User(Id = portalUser().Id, LastUsedOrganization__c = PERMITTED);
        System.runAs(new User(Id = UserInfo.getUserId())) {
            insert as system new Account(Name = 'Bedrift AS', INT_OrganizationNumber__c = PERMITTED);
        }
        AAREG_EntryPortalController.Portal portal;
        System.runAs(portalUser()) {
            portal = AAREG_EntryPortalController.getPortal();
        }

        System.Assert.areEqual(PERMITTED, portal.organization?.organizationNumber, JSON.serialize(portal));
        System.Assert.areEqual('Bedrift AS', portal.organization?.name, 'Name although the user cannot see accounts');
    }

    @IsTest
    static void portalShowsNoOrganizationBeforeOneIsChosen() {
        enablePortal(true);
        AAREG_EntryPortalController.Portal portal;
        System.runAs(portalUser()) {
            portal = AAREG_EntryPortalController.getPortal();
        }

        System.Assert.isNull(portal.organization, 'Nothing chosen yet');
    }

    @IsTest
    static void portalIsOffWithoutRolesWhenFlagIsOff() {
        enablePortal(false);
        AAREG_EntryPortalController.Portal portal;
        System.runAs(portalUser()) {
            portal = AAREG_EntryPortalController.getPortal();
        }

        System.Assert.isFalse(portal.enabled, 'Current home page');
        System.Assert.isTrue(portal.roles.isEmpty(), 'No roles leak when off');
    }

    @IsTest
    static void grantedOrganizationRoleKeepsExistingSubPagesWorking() {
        enablePortal(true);
        AAREG_RoleAccessService.Decision decision;
        System.runAs(portalUser()) {
            System.Test.startTest();
            decision = AAREG_EntryPortalController.decide('Employer', PERMITTED);
            System.Test.stopTest();
        }

        System.Assert.areEqual(AAREG_RoleAccessService.GRANTED, decision.outcome, JSON.serialize(decision));
        User reread = [SELECT LastUsedOrganization__c FROM User WHERE Id = :portalUser().Id WITH SYSTEM_MODE];
        System.Assert.areEqual(PERMITTED, reread.LastUsedOrganization__c, 'Sub-pages read the chosen organization');
    }

    @IsTest
    static void deniedOrganizationLeavesLastUsedOrganizationUnchanged() {
        enablePortal(true);
        update as system new User(Id = portalUser().Id, LastUsedOrganization__c = PERMITTED);
        AAREG_RoleAccessService.Decision decision;
        System.runAs(portalUser()) {
            decision = AAREG_EntryPortalController.decide('Employer', DENIED);
        }

        System.Assert.areEqual(AAREG_RoleAccessService.DENIED, decision.outcome, 'No right');
        User reread = [SELECT LastUsedOrganization__c FROM User WHERE Id = :portalUser().Id WITH SYSTEM_MODE];
        System.Assert.areEqual(PERMITTED, reread.LastUsedOrganization__c, 'Denial changes nothing');
    }

    @IsTest
    static void organizationListIsOnlyForAvailableOrganizationRoles() {
        enablePortal(true);
        List<AAREG_ContactModelPortalController.OrganizationOption> options;
        System.runAs(portalUser()) {
            options = AAREG_EntryPortalController.getOrganizations('Employer');
            try {
                AAREG_EntryPortalController.getOrganizations('Private');
                System.Assert.fail('Expected AuraHandledException');
            } catch (AuraHandledException error) {
                System.Assert.areEqual('Rollen er ikke tilgjengelig.', error.getMessage(), 'Readable message');
            }
        }

        System.Assert.areEqual(1, options.size(), JSON.serialize(options));
        System.Assert.areEqual(PERMITTED, options[0].organizationNumber, 'From Altinn');
    }

    @IsTest
    static void userWithoutPersonCannotUseThePrivateRole() {
        enablePortal(true);
        User minimumAccessUser = AAREG_ContactModelTestDataFactory.createMinimumAccessUser('Minimum', null);
        AAREG_RoleAccessService.Decision decision;
        System.runAs(minimumAccessUser) {
            decision = AAREG_EntryPortalController.decide('Private', null);
        }

        System.Assert.areEqual(AAREG_RoleAccessService.DENIED, decision.outcome, 'No person');
        System.Assert.areEqual(AAREG_RoleAccessService.REASON_INVALID_CONTEXT, decision.reason, 'Invalid context');
    }
}
