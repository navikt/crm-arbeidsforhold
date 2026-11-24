// Scratch only. Shields the generic Experience test user for manual tests 8.4, 8.7 and 8.8 (ADR-0008).
// Undo with unshield-test-user.apex.
if (![SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox) {
    throw new IllegalArgumentException('Shielding the test user is only allowed in a scratch org.');
}
// Synthetic ident that cannot be a real person; the Person trigger also creates a person account for it.
String SYNTHETIC_IDENT = '00000000001';
String username = 'aareg.community.test.' + UserInfo.getOrganizationId().right(8).toLowerCase() + '@example.invalid';
User user = [SELECT Id, Contact.AccountId FROM User WHERE Username = :username LIMIT 1];
Person__c person = new Person__c(Name = SYNTHETIC_IDENT, INT_Confidential__c = 'STRENGT_FORTROLIG');
insert person;
update new Account(Id = user.Contact.AccountId, CRM_Person__c = person.Id);
System.debug(LoggingLevel.INFO, 'Shielded: ' + AAREG_ContactModelShielding.isShieldedUser(user.Id));
