System.Assert.isTrue([SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox, 'Only run in a sandbox.');
String organizationSuffix = UserInfo.getOrganizationId().right(8).toLowerCase();
String username = 'aareg.community.test.' + organizationSuffix + '@example.invalid';
Set<String> usernames = new Set<String>{ username };
for (String legacyKey : new List<String>{ 'permit', 's02', 'deny', 's04', 's06' }) {
    usernames.add('aareg.altinn.' + legacyKey + '.' + organizationSuffix + '@example.invalid');
}
List<User> users = [
    SELECT Id, Username, Name, IsActive, Profile.UserLicense.Name, Contact.Name
    FROM User
    WHERE Username IN :usernames
];
Integer activeUsers = 0;
Id testUserId;
Set<Id> retiredUserIds = new Set<Id>();
for (User candidate : users) {
    if (candidate.Username == username) {
        testUserId = candidate.Id;
        System.Assert.isTrue(candidate.IsActive, 'The generic community test user must be active.');
        System.Assert.areEqual('Synthetic Community Test User', candidate.Name);
        System.Assert.areEqual('Synthetic Community Test User', candidate.Contact.Name);
        System.Assert.areEqual('Customer Community Plus', candidate.Profile.UserLicense.Name);
    } else {
        System.Assert.isFalse(candidate.IsActive, 'Legacy scenario users must be inactive.');
        retiredUserIds.add(candidate.Id);
    }
    if (candidate.IsActive) {
        activeUsers++;
    }
}
System.Assert.isNotNull(testUserId, 'The generic community test user must exist.');
System.Assert.areEqual(1, activeUsers, 'Exactly one seeded community test user must be active.');
System.Assert.areEqual(
    2,
    [
        SELECT COUNT()
        FROM PermissionSetAssignment
        WHERE AssigneeId = :testUserId
            AND PermissionSet.Name IN ('AAREG_CommunityPermission', 'AAREG_AltinnScenarioUser')
    ],
    'The community and scenario permissions must be assigned.'
);
AAREG_AltinnScenarioSetting__c setting = AAREG_AltinnScenarioSetting__c.getValues(testUserId);
System.Assert.isNotNull(setting, 'An explicit user scenario setting is required.');
System.Assert.isNotNull(setting.Id, 'The scenario setting must be stored on the user, not inherited.');
System.Assert.isTrue(setting.UseScenarioProvider__c);
System.Assert.areEqual('subject-a', setting.SubjectAlias__c);
System.Assert.isTrue(
    new Set<String>{ 'S01', 'S02', 'S03', 'S04', 'S05', 'S06', 'S07', 'S08' }.contains(setting.ScenarioName__c),
    'The test user must have a known scenario.'
);
System.Assert.areEqual(
    0,
    [
        SELECT COUNT()
        FROM AAREG_AltinnScenarioSetting__c
        WHERE SetupOwnerId IN :retiredUserIds
    ],
    'Retired scenario users must not retain scenario settings.'
);
System.debug(LoggingLevel.INFO, 'Generic community test user verification passed.');
