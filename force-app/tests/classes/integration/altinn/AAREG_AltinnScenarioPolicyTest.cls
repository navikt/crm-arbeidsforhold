/**
 * Verifies default-off behavior and runtime guards for Altinn scenario assignments.
 *
 * @author Kenneth Sørensen
 * @since 2026-10-25
 * @group AAREG Altinn Test
 */
@IsTest
private with sharing class AAREG_AltinnScenarioPolicyTest {
    private static final Id administratorId = UserInfo.getUserId();

    /**
     * Creates the isolated minimum-access user without scenario permissions.
     *
     * @since 2026-10-25
     */
    @TestSetup
    static void createTestUser() {
        Integration_TestDataFactory.createMinimumAccessUser();
    }

    /**
     * Keeps ordinary service selection available without a scenario assignment or test permission.
     *
     * @since 2026-10-25
     */
    @IsTest
    static void shouldDisableScenariosWhenNoAssignmentExists() {
        User minimumAccessUser = getMinimumAccessUser();

        System.runAs(minimumAccessUser) {
            AAREG_AltinnScenarioPolicy.runtimeContext = new FailingContext();
            System.Test.startTest();
            AAREG_AltinnScenarioSetting__c assignment = AAREG_AltinnScenarioPolicy.resolveAssignment(
                UserInfo.getUserId(),
                null
            );
            Integer callouts = Limits.getCallouts();
            System.Test.stopTest();

            System.Assert.isNull(
                assignment,
                'Missing scenario configuration must preserve ordinary service selection.'
            );
            System.Assert.areEqual(0, callouts, 'Resolving an assignment must not contact Altinn.');
        }
    }

    /**
     * Does not inherit enabled organization or profile configuration into a disabled user assignment.
     *
     * @since 2026-10-25
     */
    @IsTest
    static void shouldKeepExplicitlyDisabledUserOnOrdinaryService() {
        User minimumAccessUser = getMinimumAccessUser();
        System.runAs(minimumAccessUser) {
            insertAssignment(UserInfo.getOrganizationId(), true);
            insertAssignment(UserInfo.getProfileId(), true);
            insertAssignment(UserInfo.getUserId(), false);

            System.Test.startTest();
            AAREG_AltinnScenarioSetting__c assignment = AAREG_AltinnScenarioPolicy.resolveAssignment(
                UserInfo.getUserId(),
                null
            );
            System.Test.stopTest();

            System.Assert.isNull(assignment, 'An explicit user false must not inherit broad activation.');
        }
    }

    /**
     * Treats unset activation as disabled without reading the environment or requiring test permission.
     *
     * @since 2026-10-25
     */
    @IsTest
    static void shouldDisableScenariosWhenActivationIsUnset() {
        System.runAs(getMinimumAccessUser()) {
            insertAssignment(UserInfo.getUserId(), null);
            AAREG_AltinnScenarioPolicy.runtimeContext = new FailingContext();
            System.Test.startTest();
            AAREG_AltinnScenarioSetting__c assignment = AAREG_AltinnScenarioPolicy.resolveAssignment(
                UserInfo.getUserId(),
                null
            );
            System.Test.stopTest();

            System.Assert.isNull(assignment, 'Unset activation must not invoke scenario-only guards.');
        }
    }

    /**
     * Rejects organization-level activation instead of silently falling back to live Altinn.
     *
     * @since 2026-10-25
     */
    @IsTest
    static void shouldRejectOrganizationActivationWithoutUserAssignment() {
        System.runAs(getMinimumAccessUser()) {
            insertAssignment(UserInfo.getOrganizationId(), true);
            assertRejected('Altinn scenarios require an explicit user assignment.');
        }
    }

    /**
     * Rejects profile-level activation instead of treating it as a user opt-in.
     *
     * @since 2026-10-25
     */
    @IsTest
    static void shouldRejectProfileActivationWithoutUserAssignment() {
        System.runAs(getMinimumAccessUser()) {
            insertAssignment(UserInfo.getProfileId(), true);
            assertRejected('Altinn scenarios require an explicit user assignment.');
        }
    }

    /**
     * Allows an explicitly authorized user assignment without an organization default.
     *
     * @since 2026-10-25
     */
    @IsTest
    static void shouldResolveUserAssignmentWithoutOrganizationDefault() {
        User minimumAccessUser = getMinimumAccessUser();
        grantScenarioPermission(minimumAccessUser.Id);
        System.runAs(minimumAccessUser) {
            AAREG_AltinnScenarioSetting__c configured = insertAssignment(UserInfo.getUserId(), true);
            AAREG_AltinnScenarioPolicy.runtimeContext = new SyntheticContext(true);

            System.Test.startTest();
            AAREG_AltinnScenarioSetting__c assignment = AAREG_AltinnScenarioPolicy.resolveAssignment(
                UserInfo.getUserId(),
                'synthetic-subject'
            );
            Integer callouts = Limits.getCallouts();
            Integer dmlStatements = Limits.getDmlStatements();
            System.Test.stopTest();

            System.Assert.areEqual(
                configured.Id,
                assignment.Id,
                'Resolve the raw user record, not a merged hierarchy.'
            );
            System.Assert.areEqual('S01', assignment.ScenarioName__c, 'Preserve the assigned scenario identity.');
            System.Assert.areEqual('subject-a', assignment.SubjectAlias__c, 'Preserve the logical identity alias.');
            System.Assert.areEqual(0, callouts, 'Scenario policy must not contact Altinn.');
            System.Assert.areEqual(0, dmlStatements, 'Scenario policy must not mutate configuration or product data.');
        }
    }

    /**
     * Requires a separate custom permission even when the user assignment is enabled.
     *
     * @since 2026-10-25
     */
    @IsTest
    static void shouldRejectUserWithoutScenarioPermission() {
        System.runAs(getMinimumAccessUser()) {
            insertAssignment(UserInfo.getUserId(), true);
            AAREG_AltinnScenarioPolicy.runtimeContext = new SyntheticContext(true);
            assertRejected('Altinn scenario permission is required.');
        }
    }

    /**
     * Blocks scenario activation in production before returning any assignment.
     *
     * @since 2026-10-25
     */
    @IsTest
    static void shouldRejectProductionEnvironment() {
        System.runAs(getMinimumAccessUser()) {
            insertAssignment(UserInfo.getUserId(), true);
            AAREG_AltinnScenarioPolicy.runtimeContext = new SyntheticContext(false);
            assertRejected('Altinn scenarios require a verified non-production environment.');
        }
    }

    /**
     * Treats unknown environment status as forbidden rather than as a sandbox.
     *
     * @since 2026-10-25
     */
    @IsTest
    static void shouldRejectUnknownEnvironment() {
        System.runAs(getMinimumAccessUser()) {
            insertAssignment(UserInfo.getUserId(), true);
            AAREG_AltinnScenarioPolicy.runtimeContext = new SyntheticContext(null);
            assertRejected('Altinn scenarios require a verified non-production environment.');
        }
    }

    /**
     * Prevents an authorized scenario user from requesting another target user.
     *
     * @since 2026-10-25
     */
    @IsTest
    static void shouldRejectDifferentTargetUser() {
        Id otherUserId = UserInfo.getUserId();
        User minimumAccessUser = getMinimumAccessUser();
        grantScenarioPermission(minimumAccessUser.Id);
        System.runAs(minimumAccessUser) {
            insertAssignment(UserInfo.getUserId(), true);
            AAREG_AltinnScenarioPolicy.runtimeContext = new SyntheticContext(true);
            assertRejected('Altinn scenarios may only be used by the assigned user.', otherUserId, 'synthetic-subject');
        }
    }

    /**
     * Rejects requests whose identity differs from the current user's linked identity.
     *
     * @since 2026-10-25
     */
    @IsTest
    static void shouldRejectMismatchedIdentity() {
        User minimumAccessUser = getMinimumAccessUser();
        grantScenarioPermission(minimumAccessUser.Id);
        System.runAs(minimumAccessUser) {
            insertAssignment(UserInfo.getUserId(), true);
            AAREG_AltinnScenarioPolicy.runtimeContext = new SyntheticContext(true);
            assertRejected('Altinn scenario identity does not match the assigned user.', UserInfo.getUserId(), 'other');
        }
    }

    /**
     * Requires both a scenario name and a logical subject alias on an active assignment.
     *
     * @since 2026-10-25
     */
    @IsTest
    static void shouldRejectIncompleteAssignment() {
        User minimumAccessUser = getMinimumAccessUser();
        grantScenarioPermission(minimumAccessUser.Id);
        System.runAs(minimumAccessUser) {
            AAREG_AltinnScenarioSetting__c assignment = insertAssignment(UserInfo.getUserId(), true);
            assignment.SubjectAlias__c = null;
            System.runAs(new User(Id = administratorId)) {
                update assignment;
            }
            AAREG_AltinnScenarioPolicy.runtimeContext = new SyntheticContext(true);
            assertRejected('Altinn scenario name and subject alias are required.');
        }
    }

    /**
     * Does not fill a missing user alias from a profile or organization assignment.
     *
     * @since 2026-10-25
     */
    @IsTest
    static void shouldRejectMissingUserAliasDespiteProfileDefault() {
        User minimumAccessUser = getMinimumAccessUser();
        grantScenarioPermission(minimumAccessUser.Id);
        System.runAs(minimumAccessUser) {
            insertAssignment(UserInfo.getProfileId(), true);
            AAREG_AltinnScenarioSetting__c assignment = insertAssignment(UserInfo.getUserId(), true);
            assignment.SubjectAlias__c = null;
            System.runAs(new User(Id = administratorId)) {
                update assignment;
            }
            AAREG_AltinnScenarioPolicy.runtimeContext = new SyntheticContext(true);
            assertRejected('Altinn scenario name and subject alias are required.');
        }
    }

    /**
     * Propagates infrastructure failures without returning a disabled assignment.
     *
     * @since 2026-10-25
     */
    @IsTest
    static void shouldPropagateEnvironmentReadFailure() {
        System.runAs(getMinimumAccessUser()) {
            insertAssignment(UserInfo.getUserId(), true);
            AAREG_AltinnScenarioPolicy.runtimeContext = new FailingContext();
            System.Test.startTest();
            try {
                AAREG_AltinnScenarioPolicy.resolveAssignment(UserInfo.getUserId(), 'synthetic-subject');
                System.Assert.fail('An environment read failure must not enable live fallback.');
            } catch (EnvironmentReadException caughtException) {
                System.Assert.areEqual('Environment lookup failed.', caughtException.getMessage());
            }
            System.Test.stopTest();
        }
    }

    /**
     * Verifies the real sandbox flag and refuses an internal user with no linked contact identity.
     *
     * @since 2026-10-25
     */
    @IsTest
    static void shouldRejectMissingLinkedIdentityInScratch() {
        System.Assert.isTrue(
            [SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox,
            'Run this suite in a scratch org.'
        );
        User minimumAccessUser = getMinimumAccessUser();
        grantScenarioPermission(minimumAccessUser.Id);
        System.runAs(minimumAccessUser) {
            insertAssignment(UserInfo.getUserId(), true);
            assertRejected('Altinn scenario identity does not match the assigned user.');
        }
    }

    private static User getMinimumAccessUser() {
        return [SELECT Id FROM User WHERE Alias = 'inttest' LIMIT 1];
    }

    private static AAREG_AltinnScenarioSetting__c insertAssignment(Id ownerId, Boolean enabled) {
        AAREG_AltinnScenarioSetting__c assignment = new AAREG_AltinnScenarioSetting__c(
            SetupOwnerId = ownerId,
            ScenarioName__c = 'S01',
            SubjectAlias__c = 'subject-a'
        );
        if (enabled != null) {
            assignment.UseScenarioProvider__c = enabled;
        }
        System.runAs(new User(Id = administratorId)) {
            insert assignment;
        }
        return assignment;
    }

    private static void grantScenarioPermission(Id userId) {
        PermissionSet permissionSet = [SELECT Id FROM PermissionSet WHERE Name = 'AAREG_AltinnScenarioUser' LIMIT 1];
        insert new PermissionSetAssignment(AssigneeId = userId, PermissionSetId = permissionSet.Id);
    }

    private static void assertRejected(String expectedMessage) {
        assertRejected(expectedMessage, UserInfo.getUserId(), 'synthetic-subject');
    }

    private static void assertRejected(String expectedMessage, Id targetUserId, String personIdent) {
        System.Test.startTest();
        try {
            AAREG_AltinnScenarioPolicy.resolveAssignment(targetUserId, personIdent);
            System.Assert.fail('Invalid scenario activation must fail explicitly without live fallback.');
        } catch (AAREG_AltinnScenarioPolicy.AltinnScenarioPolicyException caughtException) {
            System.Assert.areEqual(
                expectedMessage,
                caughtException.getMessage(),
                'Return an explicit, non-sensitive error.'
            );
        }
        System.Assert.areEqual(0, Limits.getCallouts(), 'Rejected scenario use must never contact Altinn.');
        System.Test.stopTest();
    }

    private class SyntheticContext extends AAREG_AltinnScenarioPolicy.RuntimeContext {
        private Boolean sandbox;

        SyntheticContext(Boolean sandbox) {
            this.sandbox = sandbox;
        }

        public override Boolean isSandbox() {
            return sandbox;
        }

        public override String getPersonIdent() {
            return 'synthetic-subject';
        }
    }

    private class FailingContext extends AAREG_AltinnScenarioPolicy.RuntimeContext {
        public override Boolean isSandbox() {
            throw new EnvironmentReadException('Environment lookup failed.');
        }
    }

    private class EnvironmentReadException extends Exception {
    }
}
