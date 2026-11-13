Organization organization = [SELECT IsSandbox FROM Organization LIMIT 1];
if (!organization.IsSandbox) {
    throw new IllegalArgumentException('Synthetic Altinn scenario data can only be seeded in a sandbox.');
}

String organizationId = UserInfo.getOrganizationId();
String syntheticOwnerUsername = 'aareg.altinn.owner.' + organizationId + '@example.invalid';
Set<String> ownerUsernames = new Set<String>{ 'persaksbehandler1@nav.no', syntheticOwnerUsername };
List<User> owners = [
    SELECT Id, IsActive, Profile.Name, UserRoleId
    FROM User
    WHERE Username IN :ownerUsernames
];
if (owners.size() > 1) {
    throw new IllegalArgumentException('Both legacy and synthetic Altinn test-data owners exist.');
}
if (!owners.isEmpty() && (!owners[0].IsActive || owners[0].Profile.Name != 'Standard User')) {
    throw new IllegalArgumentException(
        'The existing Altinn test-data owner must be active and have the Standard User profile.'
    );
}

User owner;
if (owners.isEmpty()) {
    List<Profile> profiles = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
    if (profiles.isEmpty()) {
        throw new IllegalArgumentException('The Standard User profile is required for the Altinn test-data owner.');
    }
    owner = new User(
        Username = syntheticOwnerUsername,
        Email = syntheticOwnerUsername,
        FirstName = 'Synthetic',
        LastName = 'Altinn Test Owner',
        Alias = 'altowner',
        CommunityNickname = 'altinn-owner-' + organizationId,
        TimeZoneSidKey = 'Europe/Oslo',
        LocaleSidKey = 'en_US',
        LanguageLocaleKey = 'en_US',
        EmailEncodingKey = 'UTF-8',
        ProfileId = profiles[0].Id,
        IsActive = true
    );
} else {
    owner = owners[0];
}

Boolean needsRole = owner.UserRoleId == null;
if (needsRole) {
    List<UserRole> roles = [SELECT Id, ParentRoleId FROM UserRole ORDER BY Name];
    Set<Id> parentRoleIds = new Set<Id>();
    for (UserRole role : roles) {
        if (role.ParentRoleId != null) {
            parentRoleIds.add(role.ParentRoleId);
        }
    }

    UserRole leastPrivilegedRole;
    for (UserRole role : roles) {
        if (!parentRoleIds.contains(role.Id)) {
            leastPrivilegedRole = role;
            break;
        }
    }
    if (leastPrivilegedRole == null) {
        String organizationSuffix = UserInfo.getOrganizationId().right(8).toLowerCase();
        leastPrivilegedRole = new UserRole(
            Name = 'Altinn Scratch Test Owner ' + organizationSuffix,
            DeveloperName = 'Altinn_Scratch_Test_Owner_' + organizationSuffix
        );
        insert leastPrivilegedRole;
    }

    owner.UserRoleId = leastPrivilegedRole.Id;
}

if (owner.Id == null) {
    Database.DMLOptions options = new Database.DMLOptions();
    options.EmailHeader.triggerAutoResponseEmail = false;
    options.EmailHeader.triggerOtherEmail = false;
    options.EmailHeader.triggerUserEmail = false;
    owner.setOptions(options);
    insert owner;
} else if (needsRole) {
    update owner;
}

System.debug(LoggingLevel.INFO, 'Synthetic Altinn account owner is ready.');
