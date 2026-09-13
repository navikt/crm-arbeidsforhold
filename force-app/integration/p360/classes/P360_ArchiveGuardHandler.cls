/**
 * P360 archive release guard handler used by MyTriggers.
 */
public with sharing class P360_ArchiveGuardHandler extends MyTriggers {
    /**
     * Runs the archive release guard before insert of `Application_Decision__c`.
     *
     * @since 2026-04
     */
    public override void onBeforeInsert() {
        P360_ApplicationDecisionArchiveGuard.beforeInsert((List<Application_Decision__c>) records);
    }

    /**
     * Runs the archive release guard before update of `Application_Decision__c`.
     *
     * @param triggerOldMap Old field values keyed by record id, supplied by MyTriggers.
     * @since 2026-04
     */
    public override void onBeforeUpdate(Map<Id, sObject> triggerOldMap) {
        P360_ApplicationDecisionArchiveGuard.beforeUpdate(
            (List<Application_Decision__c>) records,
            (Map<Id, Application_Decision__c>) triggerOldMap
        );
    }
}
