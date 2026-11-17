Organization organization = [SELECT IsSandbox FROM Organization LIMIT 1];
if (!organization.IsSandbox) {
    throw new IllegalArgumentException('Synthetic community test users can only be seeded in a sandbox.');
}

String organizationSuffix = UserInfo.getOrganizationId().right(8).toLowerCase();
String username = 'aareg.community.test.' + organizationSuffix + '@example.invalid';
String legacyPermitUsername = 'aareg.altinn.permit.' + organizationSuffix + '@example.invalid';
Set<String> legacyUsernames = new Set<String>();
for (String legacyKey : new List<String>{ 's02', 'deny', 's04', 's06' }) {
    legacyUsernames.add('aareg.altinn.' + legacyKey + '.' + organizationSuffix + '@example.invalid');
}
List<Profile> profiles = [
    SELECT Id
    FROM Profile
    WHERE Name = 'Customer Community Plus User' AND UserLicense.Name = 'Customer Community Plus'
    LIMIT 1
];
if (profiles.isEmpty()) {
    throw new IllegalArgumentException('The Customer Community Plus User profile and license are required.');
}
List<Network> communities = [
    SELECT Id
    FROM Network
    WHERE UrlPathPrefix = 'aaregisteret' AND Status = 'Live'
    LIMIT 1
];
if (communities.isEmpty()) {
    throw new IllegalArgumentException('The published Aa-registret community is required.');
}
Set<String> permissionNames = new Set<String>{ 'AAREG_AltinnScenarioUser', 'AAREG_CommunityPermission' };
List<PermissionSet> permissions = [SELECT Id FROM PermissionSet WHERE Name IN :permissionNames];
if (permissions.size() != permissionNames.size()) {
    throw new IllegalArgumentException('Both Altinn scenario and community permission sets must be installed.');
}
List<Contact> contacts = [
    SELECT Id
    FROM Contact
    WHERE Email = :username AND Account.Name = :('Synthetic Community Test ' + organizationSuffix)
];
if (contacts.size() != 1) {
    throw new IllegalArgumentException('Exactly one generic synthetic community contact must be seeded first.');
}

List<User> existingUsers = [
    SELECT Id, Username, ContactId, ProfileId, IsActive
    FROM User
    WHERE Username IN :new Set<String>{ username, legacyPermitUsername }
];
if (existingUsers.size() > 1) {
    throw new IllegalArgumentException('Both legacy and generic community test users exist; resolve the duplicate first.');
}
User testUser;
if (existingUsers.isEmpty()) {
    testUser = new User(
        TimeZoneSidKey = 'Europe/Oslo',
        LocaleSidKey = 'en_US',
        LanguageLocaleKey = 'en_US',
        EmailEncodingKey = 'UTF-8',
        ProfileId = profiles[0].Id,
        ContactId = contacts[0].Id,
        LastUsedOrganization__c = '111111111'
    );
} else {
    testUser = existingUsers[0];
    if (testUser.ContactId != contacts[0].Id || testUser.ProfileId != profiles[0].Id) {
        throw new IllegalArgumentException('The existing test user must match the synthetic contact and Plus profile.');
    }
}
testUser.FirstName = 'Synthetic';
testUser.LastName = 'Community Test User';
testUser.Username = username;
testUser.Email = username;
testUser.Alias = 'comtest';
testUser.CommunityNickname = 'community-test-' + organizationSuffix;
testUser.IsActive = true;

List<User> retiredUsers = [
    SELECT Id, Contact.Email, IsActive
    FROM User
    WHERE Username IN :legacyUsernames
];
List<User> usersToDeactivate = new List<User>();
for (User retiredUser : retiredUsers) {
    if (!legacyUsernames.contains(retiredUser.Contact?.Email)) {
        throw new IllegalArgumentException('A legacy username is not linked to its expected synthetic contact.');
    }
    if (retiredUser.IsActive) {
        retiredUser.IsActive = false;
        usersToDeactivate.add(retiredUser);
    }
}
if (!usersToDeactivate.isEmpty()) {
    update usersToDeactivate;
}
if (testUser.Id == null) {
    insert testUser;
} else {
    update testUser;
}

Set<Id> existingPermissionIds = new Set<Id>();
for (PermissionSetAssignment assignment : [
    SELECT PermissionSetId
    FROM PermissionSetAssignment
    WHERE AssigneeId = :testUser.Id AND PermissionSet.Name IN :permissionNames
]) {
    existingPermissionIds.add(assignment.PermissionSetId);
}
List<PermissionSetAssignment> assignments = new List<PermissionSetAssignment>();
for (PermissionSet permission : permissions) {
    if (!existingPermissionIds.contains(permission.Id)) {
        assignments.add(new PermissionSetAssignment(AssigneeId = testUser.Id, PermissionSetId = permission.Id));
    }
}
if (!assignments.isEmpty()) {
    insert assignments;
}
if ([SELECT COUNT() FROM NetworkMember WHERE NetworkId = :communities[0].Id AND MemberId = :testUser.Id] != 1) {
    throw new IllegalArgumentException('Verify the generic test user community permission-set membership.');
}
System.debug(LoggingLevel.INFO, 'One generic Community Plus test user is ready; legacy scenario users are inactive.');
