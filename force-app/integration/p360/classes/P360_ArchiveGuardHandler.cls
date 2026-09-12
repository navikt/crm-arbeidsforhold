/**
 * P360 archive release guard handler used by MyTriggers.
 */
public with sharing class P360_ArchiveGuardHandler extends MyTriggers {
    public override void onBeforeInsert() {
        P360_ApplicationDecisionArchiveGuard.beforeInsert((List<Application_Decision__c>) records);
    }

    public override void onBeforeUpdate(Map<Id, sObject> triggerOldMap) {
        P360_ApplicationDecisionArchiveGuard.beforeUpdate(
            (List<Application_Decision__c>) records,
            (Map<Id, Application_Decision__c>) triggerOldMap
        );
    }
}
