/**
 * Creates isolated Altinn scenario users and assignments without changing runtime authorization.
 *
 * @author Kenneth Sørensen
 * @since 2026-10-25
 * @group AAREG Altinn Test Utility
 */
@IsTest
public with sharing class AAREG_AltinnTestDataFactory {
    private static final Id administratorId = UserInfo.getUserId();

    /**
     * Creates a minimum-access user with an optional scenario custom permission.
     *
     * @param grantPermission Whether to assign the scenario-only permission set.
     * @return The inserted synthetic minimum-access user.
     */
    public static User createScenarioUser(Boolean grantPermission) {
        User user = Integration_TestDataFactory.createMinimumAccessUser();
        if (grantPermission) {
            PermissionSet permissionSet = [
                SELECT Id
                FROM PermissionSet
                WHERE Name = 'AAREG_AltinnScenarioUser'
                LIMIT 1
            ];
            insert new PermissionSetAssignment(AssigneeId = user.Id, PermissionSetId = permissionSet.Id);
        }
        return user;
    }

    /**
     * Creates an authorized assignment with synthetic platform reads and a live Altinn 3 branch that lacks settings.
     *
     * @param scenarioName The assigned scenario identity.
     * @param subjectAlias The assigned logical subject alias.
     * @return The inserted minimum-access scenario user.
     */
    public static User createAssignedUser(String scenarioName, String subjectAlias) {
        User user = createScenarioUser(true);
        setScenario(user.Id, scenarioName, subjectAlias, true);
        useSyntheticContext(true);
        setAltinnVersion3(true);
        return user;
    }

    /**
     * Writes a raw assignment as the fixture administrator, including updates between runtime operations.
     *
     * @param ownerId The user, profile or organization owning the raw setting.
     * @param scenarioName The scenario identity.
     * @param subjectAlias The logical synthetic alias.
     * @param enabled Whether this assignment explicitly enables scenarios.
     */
    public static void setScenario(Id ownerId, String scenarioName, String subjectAlias, Boolean enabled) {
        System.runAs(new User(Id = administratorId)) {
            AAREG_AltinnScenarioSetting__c assignment = AAREG_AltinnScenarioSetting__c.getValues(ownerId);
            if (assignment?.Id == null) {
                assignment = new AAREG_AltinnScenarioSetting__c(SetupOwnerId = ownerId);
            }
            assignment.UseScenarioProvider__c = enabled;
            assignment.ScenarioName__c = scenarioName;
            assignment.SubjectAlias__c = subjectAlias;
            upsert assignment;
        }
    }

    /**
     * Models a platform environment and a linked synthetic identity without creating a community user.
     *
     * @param sandbox True for sandbox, false for production, null for unknown.
     */
    public static void useSyntheticContext(Boolean sandbox) {
        AAREG_AltinnScenarioPolicy.runtimeContext = new SyntheticContext(sandbox);
    }

    /**
     * Selects a deterministic default Altinn version using the existing metadata test seam.
     *
     * @param enabled Whether the standard facade should select Altinn 3.
     */
    public static void setAltinnVersion3(Boolean enabled) {
        CustomMetadataDAO.customMetadataRecordsMap.put(
            FeatureToggleBase.METADATA_QUERY,
            new List<Feature_Flag__mdt>{
                new Feature_Flag__mdt(
                    MasterLabel = 'Altinn Version 3',
                    DeveloperName = 'Altinn_Version_3',
                    Is_Enabled__c = enabled,
                    Description__c = 'Altinn provider selection test fixture.'
                )
            }
        );
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
}
