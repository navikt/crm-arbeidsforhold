Organization organization = [SELECT IsSandbox FROM Organization LIMIT 1];
if (!organization.IsSandbox) {
    throw new IllegalArgumentException('Synthetic Altinn scenario data can only be seeded in a sandbox.');
}

String organizationSuffix = UserInfo.getOrganizationId().right(8).toLowerCase();
String ownerUsername = 'persaksbehandler1@nav.no';
User accountOwner = [
    SELECT Id, UserRoleId
    FROM User
    WHERE Username = :ownerUsername
        AND IsActive = true
    LIMIT 1
];
if (accountOwner.UserRoleId == null) {
    throw new IllegalArgumentException('The synthetic Altinn account owner must have a role before accounts are seeded.');
}

List<String> scenarioNames = new List<String>{ 'S01', 'S03' };
Map<String, String> identityByAccountName = new Map<String, String>();
Map<String, String> emailByAccountName = new Map<String, String>();
for (String scenarioName : scenarioNames) {
    String scenarioKey = scenarioName == 'S01' ? 'permit' : 'deny';
    String accountName = 'Synthetic Altinn ' + scenarioName + ' ' + organizationSuffix;
    identityByAccountName.put(
        accountName,
        (scenarioKey == 'permit' ? 'AP' : 'AD') + organizationSuffix
    );
    emailByAccountName.put(
        accountName,
        'aareg.altinn.' + scenarioKey + '.' + organizationSuffix + '@example.invalid'
    );
}

List<String> accountNames = new List<String>(identityByAccountName.keySet());
Map<String, Account> accountsByName = new Map<String, Account>();
for (Account account : [
    SELECT Id, Name, OwnerId, INT_PersonIdent__c
    FROM Account
    WHERE Name IN :accountNames
]) {
    accountsByName.put(account.Name, account);
}

List<Account> accountsToInsert = new List<Account>();
for (String accountName : accountNames) {
    if (accountsByName.containsKey(accountName)) {
        Account existingAccount = accountsByName.get(accountName);
        if (
            existingAccount.INT_PersonIdent__c != identityByAccountName.get(accountName) ||
            existingAccount.OwnerId != accountOwner.Id
        ) {
            throw new IllegalArgumentException('An existing synthetic Altinn account does not match its seed.');
        }
    } else {
        accountsToInsert.add(
            new Account(
                Name = accountName,
                OwnerId = accountOwner.Id,
                INT_PersonIdent__c = identityByAccountName.get(accountName)
            )
        );
    }
}
if (!accountsToInsert.isEmpty()) {
    insert accountsToInsert;
    for (Account account : accountsToInsert) {
        accountsByName.put(account.Name, account);
    }
}

List<String> contactEmails = new List<String>(emailByAccountName.values());
Map<String, Contact> contactsByEmail = new Map<String, Contact>();
for (Contact contact : [
    SELECT Id, AccountId, Email
    FROM Contact
    WHERE Email IN :contactEmails
]) {
    contactsByEmail.put(contact.Email, contact);
}

List<Contact> contactsToInsert = new List<Contact>();
for (String accountName : accountNames) {
    String email = emailByAccountName.get(accountName);
    Account account = accountsByName.get(accountName);
    if (contactsByEmail.containsKey(email)) {
        if (contactsByEmail.get(email).AccountId != account.Id) {
            throw new IllegalArgumentException('An existing synthetic Altinn contact is linked to an unexpected account.');
        }
    } else {
        String lastName = accountName.contains('S01') ? 'Permit Scenario User' : 'Deny Scenario User';
        contactsToInsert.add(
            new Contact(
                FirstName = 'Synthetic',
                LastName = lastName,
                Email = email,
                AccountId = account.Id
            )
        );
    }
}
if (!contactsToInsert.isEmpty()) {
    insert contactsToInsert;
}

System.debug(LoggingLevel.INFO, 'Synthetic Altinn accounts and contacts are ready.');
