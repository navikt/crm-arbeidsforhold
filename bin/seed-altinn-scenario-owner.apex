Organization organization = [SELECT IsSandbox FROM Organization LIMIT 1];
if (!organization.IsSandbox) {
    throw new IllegalArgumentException('Synthetic Altinn scenario data can only be seeded in a sandbox.');
}

String ownerUsername = 'persaksbehandler1@nav.no';
List<User> owners = [
    SELECT Id, IsActive, Profile.Name, UserRoleId
    FROM User
    WHERE Username = :ownerUsername
    LIMIT 1
];
if (owners.isEmpty() || !owners[0].IsActive || owners[0].Profile.Name != 'Standard User') {
    throw new IllegalArgumentException(
        'The active Standard User scratch test user from dummy-data/User.json is required as the synthetic account owner.'
    );
}

User owner = owners[0];
if (owner.UserRoleId == null) {
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
    update owner;
}

System.debug(LoggingLevel.INFO, 'Synthetic Altinn account owner is ready.');
