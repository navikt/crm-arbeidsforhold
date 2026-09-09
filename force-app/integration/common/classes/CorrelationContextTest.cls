/**
 * Verifies shared correlation context behavior.
 *
 * @author Not available (new file)
 * @since 2026-09
 * @group Integration Common
 */
@IsTest
private class CorrelationContextTest {
    /**
     * Verifies that a supplied correlation id is preserved unchanged.
     *
     * @since 2026-09
     */
    @IsTest
    static void suppliedCorrelationIdIsPreserved() {
        User minimumAccessUser = createMinimumAccessUser();

        System.runAs(minimumAccessUser) {
            CorrelationContext context = new CorrelationContext('correlation-supplied');

            System.Assert.areEqual(
                'correlation-supplied',
                context.correlationId,
                'Expected the supplied correlation id.'
            );
        }
    }

    /**
     * Verifies that a missing correlation id is replaced with a generated opaque value.
     *
     * @since 2026-09
     */
    @IsTest
    static void missingCorrelationIdIsGenerated() {
        User minimumAccessUser = createMinimumAccessUser();

        System.runAs(minimumAccessUser) {
            CorrelationContext context = new CorrelationContext(null);

            System.Assert.isTrue(String.isNotBlank(context.correlationId), 'Expected a generated correlation id.');
        }
    }

    private static User createMinimumAccessUser() {
        Profile minimumAccessProfile = [
            SELECT Id
            FROM Profile
            WHERE Name = 'Minimum Access - Salesforce'
            LIMIT 1
        ];

        User minimumAccessUser = new User(
            FirstName = 'Correlation',
            LastName = 'Tester',
            Email = 'correlation.context@example.com',
            Username = 'correlation.context.' + System.currentTimeMillis() + '@example.com',
            Alias = 'corrctx',
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
