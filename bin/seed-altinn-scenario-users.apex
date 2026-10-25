Organization organization = [SELECT IsSandbox FROM Organization LIMIT 1];
if (!organization.IsSandbox) {
    throw new IllegalArgumentException('Synthetic Altinn scenario data can only be seeded in a sandbox.');
}

String organizationSuffix = UserInfo.getOrganizationId().right(8).toLowerCase();
String highVolumeProfileName = 'High Volume Customer Portal User';
String communityPlusProfileName = 'Customer Community Plus User';
String communityPathPrefix = 'aaregisteret';
Map<String, Profile> portalProfilesByName = new Map<String, Profile>();
for (Profile portalProfile : [
    SELECT Id, Name
    FROM Profile
    WHERE Name IN :new Set<String>{ highVolumeProfileName, communityPlusProfileName }
]) {
    portalProfilesByName.put(portalProfile.Name, portalProfile);
}
if (!portalProfilesByName.containsKey(highVolumeProfileName)) {
    throw new IllegalArgumentException('The High Volume Customer Portal User profile is required.');
}
if (!portalProfilesByName.containsKey(communityPlusProfileName)) {
    throw new IllegalArgumentException('The Customer Community Plus User profile is required.');
}
List<Network> communities = [
    SELECT Id
    FROM Network
    WHERE UrlPathPrefix = :communityPathPrefix
        AND Status = 'Live'
    LIMIT 1
];
if (communities.isEmpty()) {
    throw new IllegalArgumentException('The published Aa-registret community is required.');
}

Set<String> permissionNames = new Set<String>{ 'AAREG_AltinnScenarioUser', 'AAREG_CommunityPermission' };
Map<String, PermissionSet> permissionsByName = new Map<String, PermissionSet>();
for (PermissionSet permissionSet : [
    SELECT Id, Name
    FROM PermissionSet
    WHERE Name IN :permissionNames
]) {
    permissionsByName.put(permissionSet.Name, permissionSet);
}
if (permissionsByName.size() != permissionNames.size()) {
    throw new IllegalArgumentException('Both Altinn scenario and community permission sets must be installed.');
}

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
Map<String, String> emailByUsername = new Map<String, String>();
for (String username : usernames) {
    emailByUsername.put(username, username);
}

List<Contact> contacts = [
    SELECT Id, Email
    FROM Contact
    WHERE Email IN :emailByUsername.values()
];
Map<String, Contact> contactsByEmail = new Map<String, Contact>();
for (Contact contact : contacts) {
    contactsByEmail.put(contact.Email, contact);
}

List<User> existingUsers = [
    SELECT Id, Username, ContactId, ProfileId, IsActive
    FROM User
    WHERE Username IN :usernames
];
Map<String, User> usersByUsername = new Map<String, User>();
for (User existingUser : existingUsers) {
    usersByUsername.put(existingUser.Username, existingUser);
}

List<User> usersToInsert = new List<User>();
for (String username : usernames) {
    Contact contact = contactsByEmail.get(emailByUsername.get(username));
    if (contact == null) {
        throw new IllegalArgumentException('Synthetic Altinn accounts and contacts must be seeded before users.');
    }
    String scenarioName = scenarioByUsername.get(username);
    String scenarioKey = scenarioName.toLowerCase();
    String profileName = scenarioName == 'S01' ? communityPlusProfileName : highVolumeProfileName;
    Profile portalProfile = portalProfilesByName.get(profileName);
    String lastName = 'Scenario User';
    if (scenarioName == 'S01') {
        lastName = 'Permit Scenario User';
    } else if (scenarioName == 'S03') {
        lastName = 'Deny Scenario User';
    }
    if (usersByUsername.containsKey(username)) {
        User existingUser = usersByUsername.get(username);
        if (
            existingUser.ContactId != contact.Id ||
            existingUser.ProfileId != portalProfile.Id ||
            !existingUser.IsActive
        ) {
            throw new IllegalArgumentException('An existing synthetic Altinn user does not match its seed.');
        }
    } else {
        usersToInsert.add(
            new User(
                FirstName = 'Synthetic',
                LastName = lastName,
                Email = emailByUsername.get(username),
                Username = username,
                Alias = 'alts' + scenarioName.right(2),
                TimeZoneSidKey = 'Europe/Oslo',
                LocaleSidKey = 'en_US',
                LanguageLocaleKey = 'en_US',
                EmailEncodingKey = 'UTF-8',
                ProfileId = portalProfile.Id,
                ContactId = contact.Id,
                CommunityNickname = 'altinn-' + scenarioKey + '-' + organizationSuffix,
                LastUsedOrganization__c = '111111111'
            )
        );
    }
}
if (!usersToInsert.isEmpty()) {
    insert usersToInsert;
    for (User scenarioUser : usersToInsert) {
        usersByUsername.put(scenarioUser.Username, scenarioUser);
    }
}

Set<Id> userIds = new Set<Id>();
for (User scenarioUser : usersByUsername.values()) {
    userIds.add(scenarioUser.Id);
}
Set<Id> permissionIds = new Set<Id>();
for (PermissionSet permissionSet : permissionsByName.values()) {
    permissionIds.add(permissionSet.Id);
}

Set<String> existingAssignmentKeys = new Set<String>();
for (PermissionSetAssignment assignment : [
    SELECT AssigneeId, PermissionSetId
    FROM PermissionSetAssignment
    WHERE AssigneeId IN :userIds
        AND PermissionSetId IN :permissionIds
]) {
    existingAssignmentKeys.add(String.valueOf(assignment.AssigneeId) + ':' + String.valueOf(assignment.PermissionSetId));
}

List<PermissionSetAssignment> assignmentsToInsert = new List<PermissionSetAssignment>();
for (User scenarioUser : usersByUsername.values()) {
    for (PermissionSet permissionSet : permissionsByName.values()) {
        String assignmentKey = String.valueOf(scenarioUser.Id) + ':' + String.valueOf(permissionSet.Id);
        if (!existingAssignmentKeys.contains(assignmentKey)) {
            assignmentsToInsert.add(
                new PermissionSetAssignment(
                    AssigneeId = scenarioUser.Id,
                    PermissionSetId = permissionSet.Id
                )
            );
        }
    }
}
if (!assignmentsToInsert.isEmpty()) {
    insert assignmentsToInsert;
}

Set<Id> networkMemberIds = new Set<Id>();
for (NetworkMember member : [
    SELECT MemberId
    FROM NetworkMember
    WHERE NetworkId = :communities[0].Id
        AND MemberId IN :userIds
]) {
    networkMemberIds.add(member.MemberId);
}
if (networkMemberIds.size() != userIds.size()) {
    throw new IllegalArgumentException(
        'Synthetic Altinn users were not added to the community; verify the community permission-set membership.'
    );
}

System.debug(LoggingLevel.INFO, 'Synthetic Altinn scenario users and permissions are ready.');
