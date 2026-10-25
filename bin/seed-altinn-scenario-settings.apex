Organization organization = [SELECT IsSandbox FROM Organization LIMIT 1];
if (!organization.IsSandbox) {
    throw new IllegalArgumentException('Synthetic Altinn scenario data can only be seeded in a sandbox.');
}

String organizationSuffix = UserInfo.getOrganizationId().right(8).toLowerCase();
Map<String, String> scenarioByUsername = new Map<String, String>();
for (String scenarioName : new List<String>{ 'S01', 'S02', 'S03', 'S04', 'S06' }) {
    String scenarioKey;
    if (scenarioName == 'S01') {
        scenarioKey = 'permit';
    } else if (scenarioName == 'S03') {
        scenarioKey = 'deny';
    } else {
        scenarioKey = scenarioName.toLowerCase();
    }
    String username = 'aareg.altinn.' + scenarioKey + '.' + organizationSuffix + '@example.invalid';
    scenarioByUsername.put(username, scenarioName);
}
List<String> usernames = new List<String>(scenarioByUsername.keySet());
List<User> users = [
    SELECT Id, Username
    FROM User
    WHERE Username IN :usernames
];
if (users.size() != scenarioByUsername.size()) {
    throw new IllegalArgumentException('All seeded Altinn scenario users must exist before scenario settings are seeded.');
}

Set<Id> userIds = new Set<Id>();
Map<Id, String> scenarioByUserId = new Map<Id, String>();
for (User scenarioUser : users) {
    userIds.add(scenarioUser.Id);
    scenarioByUserId.put(scenarioUser.Id, scenarioByUsername.get(scenarioUser.Username));
}

Map<Id, AAREG_AltinnScenarioSetting__c> settingsByUserId = new Map<Id, AAREG_AltinnScenarioSetting__c>();
for (AAREG_AltinnScenarioSetting__c setting : [
    SELECT Id, SetupOwnerId
    FROM AAREG_AltinnScenarioSetting__c
    WHERE SetupOwnerId IN :userIds
]) {
    settingsByUserId.put(setting.SetupOwnerId, setting);
}

List<AAREG_AltinnScenarioSetting__c> settingsToUpsert = new List<AAREG_AltinnScenarioSetting__c>();
for (User scenarioUser : users) {
    AAREG_AltinnScenarioSetting__c setting = settingsByUserId.get(scenarioUser.Id);
    if (setting == null) {
        setting = new AAREG_AltinnScenarioSetting__c(SetupOwnerId = scenarioUser.Id);
    }
    setting.UseScenarioProvider__c = true;
    setting.ScenarioName__c = scenarioByUserId.get(scenarioUser.Id);
    setting.SubjectAlias__c = 'subject-a';
    settingsToUpsert.add(setting);
}
upsert settingsToUpsert;

System.debug(LoggingLevel.INFO, 'Synthetic Altinn scenario settings are ready.');
