/**
 * Resolves explicit user assignments with non-production, permission and identity guards.
 * Reads configuration in system mode with sharing; does not grant configuration write access or perform DML/callouts.
 *
 * @author Kenneth Sørensen
 * @since 2026-10-25
 * @group AAREG Altinn
 */
public with sharing class AAREG_AltinnScenarioPolicy {
    /** Allows tests to model production, unknown environments and synthetic linked identities without org changes. */
    @TestVisible
    private static RuntimeContext runtimeContext = new RuntimeContext();

    /**
     * Returns the current user's raw assignment only after validating all runtime guards.
     * An absent or disabled user assignment returns null, except that broad activation without a user opt-in is rejected.
     * Scenario names and aliases are required here; catalogue membership is validated by the scenario repository.
     *
     * @param targetUserId The user for whom the caller is requesting scenario results.
     * @param personIdent The requested identity, compared with the current user's linked account without logging it.
     * @return The explicit user setting, or null when scenario mode is disabled.
     * @throws AltinnScenarioPolicyException If activation is broad, incomplete or forbidden.
     * @throws QueryException If platform configuration or identity reads fail; no live fallback is provided.
     */
    public static AAREG_AltinnScenarioSetting__c resolveAssignment(Id targetUserId, String personIdent) {
        Id currentUserId = UserInfo.getUserId();
        AAREG_AltinnScenarioSetting__c userAssignment = AAREG_AltinnScenarioSetting__c.getValues(currentUserId);
        if (userAssignment?.Id == null) {
            AAREG_AltinnScenarioSetting__c profileAssignment = AAREG_AltinnScenarioSetting__c.getValues(
                UserInfo.getProfileId()
            );
            AAREG_AltinnScenarioSetting__c organizationAssignment = AAREG_AltinnScenarioSetting__c.getOrgDefaults();
            if (
                profileAssignment?.UseScenarioProvider__c == true ||
                organizationAssignment?.UseScenarioProvider__c == true
            ) {
                throw new AltinnScenarioPolicyException('Altinn scenarios require an explicit user assignment.');
            }
            return null;
        }
        if (userAssignment.UseScenarioProvider__c != true) {
            return null;
        }
        if (runtimeContext.isSandbox() != true) {
            throw new AltinnScenarioPolicyException('Altinn scenarios require a verified non-production environment.');
        }
        if (!FeatureManagement.checkPermission('AAREG_UseAltinnScenario')) {
            throw new AltinnScenarioPolicyException('Altinn scenario permission is required.');
        }
        if (targetUserId != currentUserId) {
            throw new AltinnScenarioPolicyException('Altinn scenarios may only be used by the assigned user.');
        }
        if (String.isBlank(userAssignment.ScenarioName__c) || String.isBlank(userAssignment.SubjectAlias__c)) {
            throw new AltinnScenarioPolicyException('Altinn scenario name and subject alias are required.');
        }
        String linkedIdentity = runtimeContext.getPersonIdent();
        if (String.isBlank(personIdent) || String.isBlank(linkedIdentity) || !personIdent.equals(linkedIdentity)) {
            throw new AltinnScenarioPolicyException('Altinn scenario identity does not match the assigned user.');
        }
        return userAssignment;
    }

    /**
     * Reports forbidden or invalid scenario activation without exposing identity or configuration values.
     *
     * @author Kenneth Sørensen
     * @since 2026-10-25
     * @group AAREG Altinn
     */
    public class AltinnScenarioPolicyException extends Exception {
    }

    /**
     * Reads only the org environment and current user's linked identity using explicit system-mode queries.
     * Minimum-access users cannot query Organization in user mode; this private boundary grants no Setup permission.
     * The identity query is always restricted to UserInfo.getUserId(), never a caller-supplied user.
     * Tests can replace these platform reads; production exposes no override API.
     */
    @TestVisible
    private virtual with sharing class RuntimeContext {
        public virtual Boolean isSandbox() {
            return [SELECT IsSandbox FROM Organization WITH SYSTEM_MODE LIMIT 1].IsSandbox;
        }

        public virtual String getPersonIdent() {
            Id currentUserId = UserInfo.getUserId();
            User currentUser = [
                SELECT Contact.Account.INT_PersonIdent__c
                FROM User
                WHERE Id = :currentUserId
                WITH SYSTEM_MODE
                LIMIT 1
            ];
            return currentUser.Contact?.Account?.INT_PersonIdent__c;
        }
    }
}
