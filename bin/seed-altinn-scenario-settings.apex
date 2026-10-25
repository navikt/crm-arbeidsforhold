Organization organization = [SELECT IsSandbox FROM Organization LIMIT 1];
if (!organization.IsSandbox) {
    throw new IllegalArgumentException('Synthetic Altinn settings can only be seeded in a sandbox.');
}
String organizationSuffix = UserInfo.getOrganizationId().right(8).toLowerCase();
String username = 'aareg.community.test.' + organizationSuffix + '@example.invalid';
List<User> users = [
    SELECT Id
    FROM User
    WHERE Username = :username AND IsActive = true AND Profile.UserLicense.Name = 'Customer Community Plus'
];
if (users.size() != 1) {
    throw new IllegalArgumentException('Exactly one active generic Community Plus test user is required.');
}
Id userId = users[0].Id;
AAREG_AltinnScenarioSetting__c setting = AAREG_AltinnScenarioSetting__c.getValues(userId);
if (setting?.Id == null) {
    setting = new AAREG_AltinnScenarioSetting__c(SetupOwnerId = userId);
}
setting.UseScenarioProvider__c = true;
setting.ScenarioName__c = 'S01';
setting.SubjectAlias__c = 'subject-a';
upsert setting;

Set<String> legacyUsernames = new Set<String>();
for (String legacyKey : new List<String>{ 's02', 'deny', 's04', 's06' }) {
    legacyUsernames.add('aareg.altinn.' + legacyKey + '.' + organizationSuffix + '@example.invalid');
}
List<AAREG_AltinnScenarioSetting__c> retiredSettings = [
    SELECT Id
    FROM AAREG_AltinnScenarioSetting__c
    WHERE SetupOwnerId IN (SELECT Id FROM User WHERE Username IN :legacyUsernames AND IsActive = false)
];
if (!retiredSettings.isEmpty()) {
    delete retiredSettings;
}
System.debug(LoggingLevel.INFO, 'The generic community test user is assigned S01; retired scenario settings are removed.');
