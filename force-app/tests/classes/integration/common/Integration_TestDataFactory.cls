/**
 * Shared test data factory for common integration tests.
 *
 * @since 2026-09
 * @group Integration Common Test Utility
 */
@IsTest
public with sharing class Integration_TestDataFactory {
    /**
     * Creates a minimum-access user for tests that do not require elevated permissions.
     *
     * @return User Inserted minimum-access test user.
     * @since 2026-09
     */
    public static User createMinimumAccessUser() {
        Profile minimumAccessProfile = [
            SELECT Id
            FROM Profile
            WHERE Name = 'Minimum Access - Salesforce'
            LIMIT 1
        ];

        User minimumAccessUser = new User(
            FirstName = 'Integration',
            LastName = 'Tester',
            Email = 'integration.minimum.access@example.com',
            Username = 'integration.minimum.access.' + System.currentTimeMillis() + '@example.com',
            Alias = 'inttest',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'Europe/Oslo',
            EmailEncodingKey = 'UTF-8',
            ProfileId = minimumAccessProfile.Id
        );

        insert minimumAccessUser;
        return minimumAccessUser;
    }
}
