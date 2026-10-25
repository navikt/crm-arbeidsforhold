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

List<String> scenarioNames = new List<String>{ 'S01', 'S02', 'S03', 'S04', 'S06' };
Map<String, String> identityByAccountName = new Map<String, String>();
Map<String, String> emailByAccountName = new Map<String, String>();
for (String scenarioName : scenarioNames) {
    String scenarioKey;
    if (scenarioName == 'S01') {
        scenarioKey = 'permit';
    } else if (scenarioName == 'S03') {
        scenarioKey = 'deny';
    } else {
        scenarioKey = scenarioName.toLowerCase();
    }
    String accountName = 'Synthetic Altinn ' + scenarioName + ' ' + organizationSuffix;
    String identity;
    if (scenarioName == 'S01') {
        identity = 'AP' + organizationSuffix;
    } else if (scenarioName == 'S03') {
        identity = 'AD' + organizationSuffix;
    } else {
        identity = 'A' + scenarioName.right(2) + organizationSuffix;
    }
    identityByAccountName.put(accountName, identity);
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
        String lastName = 'Scenario User';
        if (accountName.contains('S01')) {
            lastName = 'Permit Scenario User';
        } else if (accountName.contains('S03')) {
            lastName = 'Deny Scenario User';
        }
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

Map<String, String> organizationNameByNumber = new Map<String, String>{
    '111111111' => 'Synthetic Altinn Organization A ' + organizationSuffix,
    '222222222' => 'Synthetic Altinn Organization B ' + organizationSuffix,
    '333333333' => 'Synthetic Altinn Organization C ' + organizationSuffix,
    '444444444' => 'Synthetic Altinn Organization D ' + organizationSuffix
};
List<String> organizationNumbers = new List<String>(organizationNameByNumber.keySet());
Map<String, String> organizationNumberByName = new Map<String, String>();
for (String organizationNumber : organizationNumbers) {
    organizationNumberByName.put(organizationNameByNumber.get(organizationNumber), organizationNumber);
}
Map<String, Account> organizationAccountsByNumber = new Map<String, Account>();
for (Account organizationAccount : [
    SELECT Id, Name, OwnerId, INT_OrganizationNumber__c, INT_OrganizationalStructure__c
    FROM Account
    WHERE Name IN :organizationNameByNumber.values()
]) {
    String expectedOrganizationNumber = organizationNumberByName.get(organizationAccount.Name);
    if (
        expectedOrganizationNumber == null ||
        organizationAccount.INT_OrganizationNumber__c != expectedOrganizationNumber ||
        organizationAccountsByNumber.containsKey(expectedOrganizationNumber)
    ) {
        throw new IllegalArgumentException('Duplicate synthetic Altinn organization accounts were found.');
    }
    organizationAccountsByNumber.put(expectedOrganizationNumber, organizationAccount);
}

List<Account> organizationsToInsert = new List<Account>();
for (String organizationNumber : organizationNumbers) {
    String organizationName = organizationNameByNumber.get(organizationNumber);
    if (organizationAccountsByNumber.containsKey(organizationNumber)) {
        Account existingOrganization = organizationAccountsByNumber.get(organizationNumber);
        if (
            existingOrganization.Name != organizationName ||
            existingOrganization.OwnerId != accountOwner.Id ||
            existingOrganization.INT_OrganizationalStructure__c != 'AS'
        ) {
            throw new IllegalArgumentException('An existing synthetic Altinn organization does not match its seed.');
        }
    } else {
        organizationsToInsert.add(
            new Account(
                Name = organizationName,
                OwnerId = accountOwner.Id,
                INT_OrganizationNumber__c = organizationNumber,
                INT_OrganizationalStructure__c = 'AS',
                ShippingStreet = 'Synthetic test street 1',
                ShippingPostalCode = '0001',
                ShippingCity = 'Oslo'
            )
        );
    }
}
if (!organizationsToInsert.isEmpty()) {
    insert organizationsToInsert;
    for (Account organizationAccount : organizationsToInsert) {
        organizationAccountsByNumber.put(organizationAccount.INT_OrganizationNumber__c, organizationAccount);
    }
}

Map<String, String> applicationEmailByOrganization = new Map<String, String>();
Map<String, String> organizationNumberByApplicationEmail = new Map<String, String>();
for (String organizationNumber : organizationNumbers) {
    String applicationEmail = 'aareg.altinn.application.' + organizationNumber + '.' + organizationSuffix + '@example.invalid';
    applicationEmailByOrganization.put(organizationNumber, applicationEmail);
    organizationNumberByApplicationEmail.put(applicationEmail, organizationNumber);
}
List<String> applicationEmails = new List<String>(applicationEmailByOrganization.values());
Map<String, Application__c> applicationsByOrganizationNumber = new Map<String, Application__c>();
for (Application__c application : [
    SELECT Id, Account__c, Email__c
    FROM Application__c
    WHERE Email__c IN :applicationEmails
]) {
    String organizationNumber = organizationNumberByApplicationEmail.get(application.Email__c);
    if (
        applicationsByOrganizationNumber.containsKey(organizationNumber) ||
        application.Account__c != organizationAccountsByNumber.get(organizationNumber).Id
    ) {
        throw new IllegalArgumentException('An existing synthetic Altinn application does not match its seed.');
    }
    applicationsByOrganizationNumber.put(organizationNumber, application);
}

Schema.RecordTypeInfo applicationRecordType = Schema.SObjectType.Application__c.getRecordTypeInfosByDeveloperName()
    .get('Aa_RegisterAccess');
if (applicationRecordType == null) {
    throw new IllegalArgumentException('The Aa Register Access application record type is required.');
}
List<Application__c> applicationsToInsert = new List<Application__c>();
for (String organizationNumber : organizationNumbers) {
    if (applicationsByOrganizationNumber.containsKey(organizationNumber)) {
        continue;
    }
    Account organizationAccount = organizationAccountsByNumber.get(organizationNumber);
    applicationsToInsert.add(
        new Application__c(
            Account__c = organizationAccount.Id,
            RecordTypeId = applicationRecordType.getRecordTypeId(),
            AA_AccessTypes__c = 'Access OTP',
            OrganizationStructure__c = 'AS',
            TermsOfUse__c = true,
            DataProcessorName__c = 'Synthetic test processor',
            DataProcessorOrganizationNumber__c = '987654321',
            Email__c = applicationEmailByOrganization.get(organizationNumber),
            Casehandler_Status__c = 'New',
            Status__c = 'New',
            IsEmailConfirmationSent__c = true,
            AccountName__c = organizationAccount.Name,
            OrganizationNumber__c = organizationNumber,
            MailingAddress__c = organizationAccount.ShippingStreet,
            MailingCity__c = organizationAccount.ShippingCity,
            MailingPostalCode__c = organizationAccount.ShippingPostalCode,
            ApplicationSubmittedDate__c = Date.today()
        )
    );
}
if (!applicationsToInsert.isEmpty()) {
    insert applicationsToInsert;
    for (Application__c application : applicationsToInsert) {
        String organizationNumber = application.OrganizationNumber__c;
        applicationsByOrganizationNumber.put(organizationNumber, application);
    }
}

Set<Id> applicationIds = new Set<Id>();
for (Application__c application : applicationsByOrganizationNumber.values()) {
    applicationIds.add(application.Id);
}
Set<Id> applicationsWithActiveAgreements = new Set<Id>();
for (Agreement__c agreement : [
    SELECT Application__c
    FROM Agreement__c
    WHERE Application__c IN :applicationIds AND Status__c = 'Active'
]) {
    applicationsWithActiveAgreements.add(agreement.Application__c);
}

List<Agreement__c> agreementsToInsert = new List<Agreement__c>();
for (String organizationNumber : organizationNumbers) {
    Application__c application = applicationsByOrganizationNumber.get(organizationNumber);
    if (applicationsWithActiveAgreements.contains(application.Id)) {
        continue;
    }
    agreementsToInsert.add(
        new Agreement__c(
            Account__c = organizationAccountsByNumber.get(organizationNumber).Id,
            Application__c = application.Id,
            Status__c = 'Active',
            APIAccess__c = true,
            ExtractionAccess__c = true
        )
    );
}
if (!agreementsToInsert.isEmpty()) {
    insert agreementsToInsert;
}

System.debug(LoggingLevel.INFO, 'Synthetic Altinn users, organizations, applications and agreements are ready.');
