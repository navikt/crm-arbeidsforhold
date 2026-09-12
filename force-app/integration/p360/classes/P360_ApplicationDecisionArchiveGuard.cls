/**
 * Enforces the release permission and locking contract for P360 archive readiness on Application_Decision__c.
 *
 * @author Kenneth Sørensen
 * @since 2026-09
 * @group P360 Archive Contract
 */
public with sharing class P360_ApplicationDecisionArchiveGuard {
    private static final String RELEASE_CUSTOM_PERMISSION_NAME = 'P360_Archive_Release';
    private static final Set<String> TECHNICAL_FIELD_ALLOWLIST = new Set<String>{
        'P360_Document_Id__c',
        'P360_Document_Number__c',
        'P360_File_Id__c'
    };

    /**
     * Validates archive release updates before insert.
     *
     * @param records New Application_Decision__c records.
     */
    public static void beforeInsert(List<Application_Decision__c> records) {
        if (records == null || records.isEmpty()) {
            return;
        }

        Boolean hasReleasePermission = hasReleasePermission();
        for (Application_Decision__c decision : records) {
            if (decision.Ready_For_P360_Archive__c == true && !hasReleasePermission) {
                decision.addError(
                    'Ready_For_P360_Archive__c can only be set by a user with the P360 Archive Release permission set.'
                );
            }
        }
    }

    /**
     * Validates archive release updates before update.
     *
     * @param records Updated Application_Decision__c records.
     * @param oldMap Previous Application_Decision__c values.
     */
    public static void beforeUpdate(List<Application_Decision__c> records, Map<Id, Application_Decision__c> oldMap) {
        if (records == null || records.isEmpty()) {
            return;
        }

        Boolean hasReleasePermission = hasReleasePermission();
        for (Application_Decision__c decision : records) {
            Application_Decision__c previous = oldMap == null ? null : oldMap.get(decision.Id);
            if (previous == null) {
                continue;
            }

            if (decision.Ready_For_P360_Archive__c == false && previous.Ready_For_P360_Archive__c == true) {
                decision.addError('Ready_For_P360_Archive__c is a one-way signal and cannot be reset after release.');
                continue;
            }

            if (previous.Ready_For_P360_Archive__c == true) {
                if (hasRegularFieldChange(decision, previous)) {
                    decision.addError(
                        'Application_Decision__c is locked after release. Only P360 technical fields may change.'
                    );
                }
                continue;
            }

            if (decision.Ready_For_P360_Archive__c == true && !hasReleasePermission) {
                decision.addError(
                    'Ready_For_P360_Archive__c can only be set by a user with the P360 Archive Release permission set.'
                );
            }
        }
    }

    private static Boolean hasRegularFieldChange(Application_Decision__c decision, Application_Decision__c previous) {
        for (String fieldName : decision.getPopulatedFieldsAsMap().keySet()) {
            if (fieldName == 'Ready_For_P360_Archive__c' || TECHNICAL_FIELD_ALLOWLIST.contains(fieldName)) {
                continue;
            }
            if (decision.get(fieldName) != previous.get(fieldName)) {
                return true;
            }
        }
        return false;
    }

    private static Boolean hasReleasePermission() {
        return FeatureManagement.checkPermission(RELEASE_CUSTOM_PERMISSION_NAME);
    }
}
