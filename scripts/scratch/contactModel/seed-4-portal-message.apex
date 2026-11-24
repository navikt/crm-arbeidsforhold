// Gives the synthetic e2e portal user read access to one Aa-registeret message on its first test organization,
// so the message page and its breadcrumb trail can be tested. Idempotent; scratch orgs only.
List<User> portalUsers = [
    SELECT Id
    FROM User
    WHERE Username LIKE 'aareg.community.test.%@example.invalid' AND IsActive = TRUE
    LIMIT 1
];
List<Thread__c> threads = [
    SELECT Id
    FROM Thread__c
    WHERE CRM_Thread_Type__c LIKE 'AAREG%' AND CRM_Account__r.INT_OrganizationNumber__c = '111111111'
    ORDER BY CreatedDate
    LIMIT 1
];
if (portalUsers.isEmpty() || threads.isEmpty()) {
    System.debug(LoggingLevel.WARN, 'AAREG seed: no portal user or message to share; skipped.');
    return;
}
Id userId = portalUsers[0].Id;
Id threadId = threads[0].Id;
if ([SELECT COUNT() FROM Thread__Share WHERE ParentId = :threadId AND UserOrGroupId = :userId] == 0) {
    insert new Thread__Share(ParentId = threadId, UserOrGroupId = userId, AccessLevel = 'Read', RowCause = 'Manual');
}
System.debug(LoggingLevel.INFO, 'AAREG seed: portal message shared.');
