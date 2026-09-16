trigger P360_ApplicationDecisionArchiveGuard on Application_Decision__c(before insert, before update, after update) {
    MyTriggers.run();
}
