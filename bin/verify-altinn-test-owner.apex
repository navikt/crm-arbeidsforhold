System.Assert.isTrue([SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox, 'Only run in a sandbox.');

String organizationId = UserInfo.getOrganizationId();
String organizationSuffix = organizationId.right(8).toLowerCase();
Set<String> ownerUsernames = new Set<String>{
    'persaksbehandler1@nav.no',
    'aareg.altinn.owner.' + organizationId + '@example.invalid'
};
List<User> owners = [
    SELECT Id, IsActive, Profile.Name, UserRoleId
    FROM User
    WHERE Username IN :ownerUsernames
];
System.Assert.areEqual(1, owners.size(), 'Exactly one synthetic Altinn test-data owner must exist.');
User owner = owners[0];
System.Assert.isTrue(owner.IsActive, 'The synthetic Altinn test-data owner must be active.');
System.Assert.areEqual('Standard User', owner.Profile.Name, 'The test-data owner must use the Standard User profile.');
System.Assert.isNotNull(owner.UserRoleId, 'The synthetic Altinn test-data owner must have a role.');

Set<String> identityNames = new Set<String>{
    'Synthetic Community Test ' + organizationSuffix,
    'Synthetic Altinn S01 ' + organizationSuffix
};
List<Account> identities = [SELECT OwnerId FROM Account WHERE Name IN :identityNames];
System.Assert.isTrue(identities.size() <= 1, 'There must not be duplicate synthetic identity accounts.');
if (!identities.isEmpty()) {
    System.Assert.areEqual(owner.Id, identities[0].OwnerId, 'The synthetic identity account must retain its owner.');
}

System.debug(LoggingLevel.INFO, 'Synthetic Altinn test-data owner verification passed.');
