// Scratch only. Step 2 of 3: portal users for the seed contacts.
// Scratch orgs have one Customer Community Plus licence, used by the generic test user. The seed users only act as
// application creators for the migration classifier, so they use the High Volume Customer Portal licence and no
// permission sets.
if (![SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox) {
    throw new IllegalArgumentException('The contact model seed can only run in a scratch org.');
}
String suffix = UserInfo.getOrganizationId().right(8).toLowerCase();
Profile profile = [SELECT Id FROM Profile WHERE Name = 'High Volume Customer Portal User' LIMIT 1];
Map<String, String> keyByLastName = new Map<String, String>{ 'Delt e-post 1' => 'c1', 'Delt e-post 2' => 'c2', 'Skjerma' => 'd' };
List<User> users = new List<User>();
for (Contact contact : [
    SELECT Id, LastName, Email
    FROM Contact
    WHERE FirstName = 'Seed' AND LastName IN :keyByLastName.keySet() AND Account.Name LIKE :('Kontaktmodell seed%' + suffix)
]) {
    String key = keyByLastName.get(contact.LastName);
    String username = 'cm-seed.' + key + '.' + suffix + '@example.invalid';
    if ([SELECT COUNT() FROM User WHERE Username = :username] > 0) {
        continue;
    }
    users.add(
        new User(
            FirstName = 'Seed',
            LastName = contact.LastName,
            Username = username,
            Email = contact.Email,
            Alias = 'cms' + key,
            CommunityNickname = 'cm-seed-' + key + '-' + suffix,
            ContactId = contact.Id,
            ProfileId = profile.Id,
            TimeZoneSidKey = 'Europe/Oslo',
            LocaleSidKey = 'no_NO',
            LanguageLocaleKey = 'en_US',
            EmailEncodingKey = 'UTF-8'
        )
    );
}
insert users;
System.debug(LoggingLevel.INFO, 'AAREG_CONTACT_MODEL_RESULT=' + JSON.serialize(new Map<String, Object>{ 'usersCreated' => users.size() }));
