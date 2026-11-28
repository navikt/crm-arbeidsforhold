// Scratch only. Step 3 of 3: submitted applications that cover migration classes A, C, D and E.
// Requires the scratch-only permission set AAREG_ContactModel_ScratchSeed (CreateAuditFields) on the running user.
if (![SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox) {
    throw new IllegalArgumentException('The contact model seed can only run in a scratch org.');
}
String suffix = UserInfo.getOrganizationId().right(8).toLowerCase();
if ([SELECT COUNT() FROM Application__c WHERE Email__c LIKE 'cm-seed.%' OR (Email__c LIKE 'aareg.community.test.%' AND Account__r.Name LIKE 'Synthetic Altinn Organization%')] > 0) {
    System.debug(LoggingLevel.INFO, 'AAREG_CONTACT_MODEL_RESULT=' + JSON.serialize(new Map<String, Object>{ 'applicationsCreated' => 0 }));
    return;
}
Map<String, User> users = new Map<String, User>();
for (User user : [
    SELECT Id, Username, Email
    FROM User
    WHERE Username IN :new List<String>{
        'aareg.community.test.' + suffix + '@example.invalid',
        'cm-seed.c1.' + suffix + '@example.invalid',
        'cm-seed.c2.' + suffix + '@example.invalid',
        'cm-seed.d.' + suffix + '@example.invalid'
    }
]) {
    users.put(user.Username.substringBefore('.' + suffix), user);
}
if (users.size() != 4) {
    throw new IllegalArgumentException('Run seed steps 1 and 2 first. Found users: ' + users.keySet());
}
Map<String, Id> organizations = new Map<String, Id>();
for (Account organization : [
    SELECT Id, INT_OrganizationNumber__c
    FROM Account
    WHERE INT_OrganizationNumber__c IN ('111111111', '222222222', '333333333', '444444444')
]) {
    organizations.put(organization.INT_OrganizationNumber__c, organization.Id);
}
User portal = users.get('aareg.community.test');
User shared1 = users.get('cm-seed.c1');
User shared2 = users.get('cm-seed.c2');
User shielded = users.get('cm-seed.d');
List<Application__c> applications = new List<Application__c>{
    new Application__c(CreatedById = portal.Id, Email__c = portal.Email, Account__c = organizations.get('111111111'), Casehandler_Status__c = 'New'),
    new Application__c(CreatedById = portal.Id, Email__c = portal.Email, Account__c = organizations.get('222222222'), Casehandler_Status__c = 'New'),
    new Application__c(CreatedById = shared1.Id, Email__c = shared1.Email, Account__c = organizations.get('333333333'), Casehandler_Status__c = 'New'),
    new Application__c(CreatedById = shared2.Id, Email__c = shared2.Email, Account__c = organizations.get('333333333'), Casehandler_Status__c = 'New'),
    new Application__c(CreatedById = shielded.Id, Email__c = shielded.Email, Account__c = organizations.get('444444444'), Casehandler_Status__c = 'New'),
    new Application__c(CreatedById = portal.Id, Email__c = portal.Email, Account__c = organizations.get('444444444'), Casehandler_Status__c = 'New')
};
insert applications;
Id otherContactId = (Id) AAREG_Default_Settings__c.getOrgDefaults().Default_Contact__c;
insert new RelatedContact__c(Application__c = applications[5].Id, Contact__c = otherContactId, Role__c = 'Submitter');
System.debug(LoggingLevel.INFO, 'AAREG_CONTACT_MODEL_RESULT=' + JSON.serialize(new Map<String, Object>{ 'applicationsCreated' => applications.size() }));
