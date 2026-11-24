// Scratch only. Step 1 of 3: synthetic accounts, a shielded person and portal contacts for the contact model seed.
if (![SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox) {
    throw new IllegalArgumentException('The contact model seed can only run in a scratch org.');
}
String suffix = UserInfo.getOrganizationId().right(8).toLowerCase();
User template = [
    SELECT Contact.Account.OwnerId
    FROM User
    WHERE Username = :('aareg.community.test.' + suffix + '@example.invalid')
    LIMIT 1
];
Id ownerId = template.Contact.Account.OwnerId;

String holderName = 'Kontaktmodell seed ' + suffix;
String shieldedName = 'Kontaktmodell seed skjerma ' + suffix;
Map<String, Account> accounts = new Map<String, Account>();
for (Account existing : [SELECT Id, Name FROM Account WHERE Name IN :new Set<String>{ holderName, shieldedName }]) {
    accounts.put(existing.Name, existing);
}
if (!accounts.containsKey(holderName)) {
    accounts.put(holderName, new Account(Name = holderName, OwnerId = ownerId));
}
if (!accounts.containsKey(shieldedName)) {
    Person__c person = new Person__c(
        Name = '0101' + String.valueOf(Math.mod(Math.abs(Crypto.getRandomInteger()), 10000000)).leftPad(7, '0'),
        INT_Confidential__c = 'STRENGT_FORTROLIG',
        INT_IsDeceased__c = false
    );
    insert person;
    accounts.put(shieldedName, new Account(Name = shieldedName, OwnerId = ownerId, CRM_Person__c = person.Id));
}
upsert accounts.values();

String sharedEmail = 'cm-seed.delt.' + suffix + '@example.invalid';
Map<String, Contact> wanted = new Map<String, Contact>{
    'C1' => new Contact(FirstName = 'Seed', LastName = 'Delt e-post 1', Email = sharedEmail, AccountId = accounts.get(holderName).Id),
    'C2' => new Contact(FirstName = 'Seed', LastName = 'Delt e-post 2', Email = sharedEmail, AccountId = accounts.get(holderName).Id),
    'D' => new Contact(
        FirstName = 'Seed',
        LastName = 'Skjerma',
        Email = 'cm-seed.skjerma.' + suffix + '@example.invalid',
        AccountId = accounts.get(shieldedName).Id
    )
};
Set<String> lastNames = new Set<String>();
for (Contact contact : wanted.values()) {
    lastNames.add(contact.LastName);
}
Set<String> existing = new Set<String>();
for (Contact contact : [
    SELECT LastName
    FROM Contact
    WHERE FirstName = 'Seed' AND LastName IN :lastNames AND AccountId IN :new List<Id>(new Map<Id, Account>(accounts.values()).keySet())
]) {
    existing.add(contact.LastName);
}
List<Contact> inserts = new List<Contact>();
for (Contact contact : wanted.values()) {
    if (!existing.contains(contact.LastName)) {
        inserts.add(contact);
    }
}
insert inserts;
System.debug(LoggingLevel.INFO, 'AAREG_CONTACT_MODEL_RESULT=' + JSON.serialize(new Map<String, Object>{ 'contactsCreated' => inserts.size() }));
