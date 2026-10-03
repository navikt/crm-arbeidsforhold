/**
 * Provides the fail-closed switch for P360 archive processing.
 *
 * @author Kenneth Sørensen
 * @since 2026-10
 * @group P360 Archive Job
 */
public with sharing class P360_ArchiveProcessingGate {
    /**
     * Returns whether P360 archive processing is explicitly enabled for this org.
     *
     * @return True only when the org-default processing setting is explicitly enabled.
     * @since 2026-10
     */
    public static Boolean isEnabled() {
        P360_Integration_Setting__c settings = P360_Integration_Setting__c.getOrgDefaults();
        return isExplicitlyEnabled(settings);
    }

    /**
     * Evaluates a supplied setting for focused tests of null and false fail-closed behavior.
     *
     * @param settings Setting value to evaluate.
     * @return True only when archive processing is explicitly enabled.
     * @since 2026-10
     */
    @TestVisible
    private static Boolean isExplicitlyEnabled(P360_Integration_Setting__c settings) {
        return settings != null && settings.Archive_Processing_Enabled__c == true;
    }
}
