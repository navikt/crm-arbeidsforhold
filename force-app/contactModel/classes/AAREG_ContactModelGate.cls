/**
 * Fail-closed switches for the Aa-register contact model.
 *
 * A flag is on for the running user when the Feature_Flag__mdt record is enabled and its required custom
 * permission is either blank or held by the user. Missing records and errors mean off.
 *
 * @author Kenneth Sørensen
 * @since 2026-11
 * @group Contact Model
 * @see .github/specs/aareg-contact-model.md
 */
public with sharing class AAREG_ContactModelGate {
    /** Submission also writes the domain contact, organization relation and submitter participation. */
    public static final String SHADOW_WRITE = 'AAREG_ContactModel_ShadowWrite';
    /** Role first and searchable organization selector in the portal. */
    public static final String ORG_SELECTOR = 'AAREG_ContactModel_OrgSelector';
    /** My profile with private address and address per organization. */
    public static final String PROFILE = 'AAREG_ContactModel_Profile';
    /** Notifications use the address for the current context without fallback. */
    public static final String CONTEXT_ADDRESS = 'AAREG_ContactModel_ContextAddress';
    /** Stops creating legacy contacts per email address. */
    public static final String LEGACY_MATCHING_OFF = 'AAREG_ContactModel_LegacyMatchingOff';

    /** All contact model flags in rollout order. */
    public static final List<String> ALL_FLAGS = new List<String>{
        SHADOW_WRITE,
        ORG_SELECTOR,
        PROFILE,
        CONTEXT_ADDRESS,
        LEGACY_MATCHING_OFF
    };

    @TestVisible
    private static FeatureToggleBase featureToggle;

    /**
     * Returns whether a contact model flag is on for the running user.
     *
     * @param flagName Developer name of the Feature_Flag__mdt record.
     * @return True only when the flag is enabled and the user meets its permission requirement.
     */
    public static Boolean isEnabled(String flagName) {
        return describe(flagName).activeForCurrentUser;
    }

    /**
     * Describes every contact model flag for administration and portal components.
     *
     * @return One status per flag in rollout order.
     */
    public static List<FlagStatus> describeAll() {
        List<FlagStatus> statuses = new List<FlagStatus>();
        for (String flagName : ALL_FLAGS) {
            statuses.add(describe(flagName));
        }
        return statuses;
    }

    /**
     * Describes one flag without throwing.
     *
     * @param flagName Developer name of the Feature_Flag__mdt record.
     * @return Flag status; inactive when the record is missing or unreadable.
     */
    public static FlagStatus describe(String flagName) {
        FlagStatus status = new FlagStatus(flagName);
        try {
            Feature_Flag__mdt flag = getFeatureToggle().getFeatureFlag(flagName);
            if (flag == null) {
                return status;
            }
            status.exists = true;
            status.label = flag.MasterLabel;
            status.description = flag.Description__c;
            status.enabledInOrg = flag.Is_Enabled__c == true;
            status.requiredPermission = flag.Required_Custom_Permission__c;
            status.activeForCurrentUser =
                status.enabledInOrg &&
                (String.isBlank(status.requiredPermission) ||
                FeatureManagement.checkPermission(status.requiredPermission));
        } catch (Exception error) {
            status.activeForCurrentUser = false;
        }
        return status;
    }

    @TestVisible
    private static void resetFeatureToggle() {
        featureToggle = null;
    }

    private static FeatureToggleBase getFeatureToggle() {
        if (featureToggle == null) {
            featureToggle = new FeatureToggleBase();
        }
        return featureToggle;
    }

    /**
     * Status of one contact model flag.
     */
    public class FlagStatus {
        /** Developer name of the flag. */
        @AuraEnabled
        public String name;
        /** Label of the flag record. */
        @AuraEnabled
        public String label;
        /** Description of the flag record. */
        @AuraEnabled
        public String description;
        /** Whether the metadata record exists. */
        @AuraEnabled
        public Boolean exists = false;
        /** Whether Is_Enabled__c is true. */
        @AuraEnabled
        public Boolean enabledInOrg = false;
        /** Custom permission that limits the flag to a pilot group, if any. */
        @AuraEnabled
        public String requiredPermission;
        /** Whether the flag is on for the running user. */
        @AuraEnabled
        public Boolean activeForCurrentUser = false;

        /**
         * Creates an inactive status.
         *
         * @param name Developer name of the flag.
         */
        public FlagStatus(String name) {
            this.name = name;
        }
    }
}
