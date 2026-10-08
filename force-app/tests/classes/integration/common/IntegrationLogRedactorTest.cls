/**
 * Verifies that sensitive field values are removed before technical fields are logged.
 *
 * @author Kenneth Sørensen
 * @since 2026-09 issue 1021
 * @group Integration Common
 */
@IsTest
private class IntegrationLogRedactorTest {
    /**
     * Verifies that keys matching a sensitive fragment are redacted regardless of case.
     *
     * @since 2026-09
     */
    @IsTest
    static void sensitiveKeysAreRedacted() {
        User minimumAccessUser = Integration_TestDataFactory.createMinimumAccessUser();

        System.runAs(minimumAccessUser) {
            Map<String, Object> fields = new Map<String, Object>{
                'AccessToken' => 'raw-token-value',
                'Authorization' => 'Bearer raw-value',
                'fnr' => '12345678901',
                'operationName' => 'CreateDocument'
            };

            Map<String, Object> redacted = IntegrationLogRedactor.redactFields(fields);

            System.Assert.areEqual(
                '[REDACTED]',
                redacted.get('AccessToken'),
                'Expected the access token to be redacted.'
            );
            System.Assert.areEqual(
                '[REDACTED]',
                redacted.get('Authorization'),
                'Expected the authorization header to be redacted.'
            );
            System.Assert.areEqual(
                '[REDACTED]',
                redacted.get('fnr'),
                'Expected the national identity number to be redacted.'
            );
            System.Assert.areEqual(
                'CreateDocument',
                redacted.get('operationName'),
                'Expected a non-sensitive technical field to remain unchanged.'
            );
        }
    }

    /**
     * Verifies that an empty map is handled without error and that the input map is not mutated.
     *
     * @since 2026-09
     */
    @IsTest
    static void emptyMapIsHandledAndInputIsNotMutated() {
        User minimumAccessUser = Integration_TestDataFactory.createMinimumAccessUser();

        System.runAs(minimumAccessUser) {
            Map<String, Object> emptyFields = new Map<String, Object>();
            System.Assert.areEqual(
                0,
                IntegrationLogRedactor.redactFields(emptyFields).size(),
                'Expected an empty result.'
            );

            Map<String, Object> originalFields = new Map<String, Object>{ 'token' => 'raw-value' };
            IntegrationLogRedactor.redactFields(originalFields);

            System.Assert.areEqual(
                'raw-value',
                originalFields.get('token'),
                'Expected the original map to remain unchanged.'
            );
        }
    }
}
