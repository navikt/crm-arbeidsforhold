/**
 * @description P360 archive release guard handler used by MyTriggers.
 *
 * @author Kenneth Sørensen
 * @since 2026-04
 * @group P360
 */
public with sharing class P360_ArchiveGuardHandler extends MyTriggers {
    /**
     * @description Runs the archive release guard before insert of `Application_Decision__c`.
     *
     * @since 2026-04
     */
    public override void onBeforeInsert() {
        P360_ApplicationDecisionArchiveGuard.beforeInsert((List<Application_Decision__c>) records);
    }

    /**
     * @description Runs the archive release guard before update of `Application_Decision__c`.
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

    /**
     * @description Creates DecisionDocument jobs after an authorized archive release.
     *
     * @param triggerOldMap Old decision values keyed by id, supplied by MyTriggers.
     * @since 2026-09
     */
    public override void onAfterUpdate(Map<Id, sObject> triggerOldMap) {
        Map<Id, Application_Decision__c> previousById = (Map<Id, Application_Decision__c>) triggerOldMap;
        Set<Id> releasedDecisionIds = new Set<Id>();
        for (Application_Decision__c decision : (List<Application_Decision__c>) records) {
            Application_Decision__c previous = previousById.get(decision.Id);
            if (
                decision.Ready_For_P360_Archive__c == true &&
                (previous == null ||
                previous.Ready_For_P360_Archive__c != true)
            ) {
                releasedDecisionIds.add(decision.Id);
            }
        }

        if (releasedDecisionIds.isEmpty()) {
            return;
        }

        Map<Id, Application_Decision__c> decisionsById = new Map<Id, Application_Decision__c>(
            [
                SELECT Id, Application__r.Access_Request__c
                FROM Application_Decision__c
                WHERE Id IN :releasedDecisionIds
            ]
        );
        for (Id decisionId : releasedDecisionIds) {
            Application_Decision__c decision = decisionsById.get(decisionId);
            if (decision.Application__r?.Access_Request__c == null) {
                continue;
            }
            P360_ArchiveJobService.getOrCreateDecisionDocumentJob(
                decision.Application__r.Access_Request__c,
                decision.Id,
                'DecisionDocument:' + decision.Id
            );
        }
    }
}
