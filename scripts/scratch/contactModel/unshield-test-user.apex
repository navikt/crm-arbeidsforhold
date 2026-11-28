// Scratch only. Removes the shielding added by shield-test-user.apex.
if (![SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox) {
    throw new IllegalArgumentException('Unshielding the test user is only allowed in a scratch org.');
}
String username = 'aareg.community.test.' + UserInfo.getOrganizationId().right(8).toLowerCase() + '@example.invalid';
User user = [SELECT Id, Contact.AccountId FROM User WHERE Username = :username LIMIT 1];
update new Account(Id = user.Contact.AccountId, CRM_Person__c = null);
List<Person__c> persons = [SELECT Id FROM Person__c WHERE Name = '00000000001'];
delete [SELECT Id FROM Account WHERE CRM_Person__c IN :persons AND IsPersonAccount = true];
delete persons;
System.debug(LoggingLevel.INFO, 'Shielded: ' + AAREG_ContactModelShielding.isShieldedUser(user.Id));
