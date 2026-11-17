/**
 * Selects the standard Altinn facade or an explicitly authorized scenario provider with sharing.
 * Does not change user assignments, grant permissions or catch errors as a reason to use live Altinn.
 *
 * @author Kenneth Sørensen
 * @since 2026-10-25
 * @group AAREG Altinn
 */
public with sharing class AAREG_AltinnServiceFactory {
    /**
     * Creates the existing standard facade when scenarios are off, otherwise injects a guarded scenario provider.
     * The provider rechecks the assignment and identity at every operation and validates catalogue membership before
     * returning any scenario response. Standard construction preserves the existing feature toggle and settings rules.
     *
     * @param targetUserId The user for whom organizations or rights will be requested.
     * @param personIdent The linked identity passed to the existing Altinn operations, never logged here.
     * @return The existing typed Altinn facade with the selected provider.
     * @throws AAREG_AltinnScenarioPolicy.AltinnScenarioPolicyException If scenario activation is invalid or forbidden.
     * @throws Altinn3CalloutService.Altinn3CalloutServiceException If the standard Altinn 3 service lacks configuration.
     */
    public static AltinnCalloutService createService(Id targetUserId, String personIdent) {
        AAREG_AltinnScenarioSetting__c assignment = AAREG_AltinnScenarioPolicy.resolveAssignment(
            targetUserId,
            personIdent
        );
        if (assignment == null) {
            return new AltinnCalloutService();
        }
        return new AltinnCalloutService(new AAREG_AltinnScenarioProvider(targetUserId));
    }
}
