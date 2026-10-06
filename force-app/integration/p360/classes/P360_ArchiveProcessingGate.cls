/**
 * Provides the fail-closed switch for P360 archive processing.
 *
 * @author Kenneth Sørensen
 * @since 2026-10
 * @group P360 Archive Job
 */
public with sharing class P360_ArchiveProcessingGate {
    private static final String ARCHIVE_PROCESSING_FEATURE = 'P360_Archive_Processing';

    /**
     * Per-transaction feature-toggle instance; test-visible so tests can reset it after changing metadata fixtures.
     */
    @TestVisible
    private static FeatureToggleBase featureToggle;

    /**
     * Returns whether P360 archive processing is explicitly enabled for this org.
     *
     * @return True only when the P360 archive-processing feature flag is explicitly enabled.
     * @since 2026-10
     */
    public static Boolean isEnabled() {
        try {
            if (featureToggle == null) {
                featureToggle = new FeatureToggleBase();
            }
            Feature_Flag__mdt archiveProcessingFlag = featureToggle.getFeatureFlag(ARCHIVE_PROCESSING_FEATURE);
            if (archiveProcessingFlag == null) {
                return false;
            }
            Boolean enabled = archiveProcessingFlag.Is_Enabled__c;
            if (enabled == null || !enabled) {
                return false;
            }

            return String.isBlank(archiveProcessingFlag.Required_Custom_Permission__c);
        } catch (FeatureToggleException error) {
            return false;
        }
    }

    /**
     * Resets the cached feature-toggle instance between test metadata fixtures.
     *
     * @since 2026-10
     */
    @TestVisible
    private static void resetFeatureToggle() {
        featureToggle = null;
    }
}
