/**
 * Verifies that the structured integration logger includes technical context and redacts additional fields.
 *
 * @author Kenneth Sørensen
 * @since 2026-09 issue 1021
 * @group Integration Common
 */
@IsTest
private class IntegrationLoggerTest {
    /**
     * Verifies that the built log payload contains the technical context fields.
     *
     * @since 2026-09
     */
    @IsTest
    static void logPayloadContainsTechnicalContext() {
        User minimumAccessUser = Integration_TestDataFactory.createMinimumAccessUser();

        System.runAs(minimumAccessUser) {
            IntegrationLogContext context = new IntegrationLogContext('P360', 'CreateDocument', 'Started')
                .withCorrelationId('correlation-supplied');

            Map<String, Object> payload = IntegrationLogger.buildLogPayload(context, null);

            System.Assert.areEqual('P360', payload.get('systemName'), 'Expected the system name.');
            System.Assert.areEqual('CreateDocument', payload.get('operationName'), 'Expected the operation name.');
            System.Assert.areEqual(
                'correlation-supplied',
                payload.get('correlationId'),
                'Expected the correlation id.'
            );
            System.Assert.areEqual('Started', payload.get('status'), 'Expected the status.');
        }
    }

    /**
     * Verifies that additional fields are redacted using the shared redaction policy before inclusion.
     *
     * @since 2026-09
     */
    @IsTest
    static void additionalFieldsAreRedactedBeforeInclusion() {
        User minimumAccessUser = Integration_TestDataFactory.createMinimumAccessUser();

        System.runAs(minimumAccessUser) {
            IntegrationLogContext context = new IntegrationLogContext('P360', 'CreateDocument', 'Failed');
            Map<String, Object> additionalFields = new Map<String, Object>{
                'authorization' => 'Bearer raw-value',
                'caseNumber' => '00012345'
            };

            Map<String, Object> payload = IntegrationLogger.buildLogPayload(context, additionalFields);

            System.Assert.areEqual(
                '[REDACTED]',
                payload.get('authorization'),
                'Expected the authorization field to be redacted.'
            );
            System.Assert.areEqual(
                '00012345',
                payload.get('caseNumber'),
                'Expected a non-sensitive additional field to remain unchanged.'
            );
        }
    }

    /**
     * Verifies that logging without additional fields does not throw.
     *
     * @since 2026-09
     */
    @IsTest
    static void logWithoutAdditionalFieldsDoesNotThrow() {
        User minimumAccessUser = Integration_TestDataFactory.createMinimumAccessUser();

        System.runAs(minimumAccessUser) {
            IntegrationLogContext context = new IntegrationLogContext('P360', 'CreateDocument', 'Started');

            try {
                IntegrationLogger.log(context, null);
            } catch (Exception unexpectedError) {
                System.Assert.fail('Expected logging to complete without throwing: ' + unexpectedError.getMessage());
            }
        }
    }
}
