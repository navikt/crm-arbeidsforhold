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
     * Verifies that logging persists an Application_Log__c with the technical context, using the
     * existing AAREG application domain since no P360-specific domain value is defined.
     *
     * @since 2026-09
     */
    @IsTest
    static void logPersistsAnApplicationLogWithTechnicalContext() {
        IntegrationLogContext context = new IntegrationLogContext('P360', 'CreateDocument', 'Started')
            .withCorrelationId('correlation-supplied');

        Test.startTest();
        IntegrationLogger.log(context, null, LoggerUtility.LogLevel.INFO);
        Test.stopTest();

        Application_Log__c persistedLog = [
            SELECT Category__c, Application_Domain__c, Log_Message__c, Pay_Load__c
            FROM Application_Log__c
            WHERE Category__c = 'P360'
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];

        System.Assert.areEqual('P360', persistedLog.Category__c, 'Expected the category to match the system name.');
        System.Assert.areEqual(
            'AAREG',
            persistedLog.Application_Domain__c,
            'Expected the existing AAREG application domain.'
        );
        System.Assert.isTrue(
            persistedLog.Log_Message__c.contains('CreateDocument'),
            'Expected the operation name in the log message.'
        );
        System.Assert.isTrue(
            persistedLog.Pay_Load__c.contains('correlation-supplied'),
            'Expected the correlation id in the payload.'
        );
    }

    /**
     * Verifies that sensitive additional fields are redacted before the log entry is persisted.
     *
     * @since 2026-09
     */
    @IsTest
    static void logRedactsSensitiveAdditionalFieldsBeforePersisting() {
        IntegrationLogContext context = new IntegrationLogContext('P360', 'CreateDocument', 'Failed');
        Map<String, Object> additionalFields = new Map<String, Object>{
            'authorization' => 'Bearer raw-secret-value',
            'caseNumber' => '00012345'
        };

        Test.startTest();
        IntegrationLogger.log(context, additionalFields, LoggerUtility.LogLevel.ERROR);
        Test.stopTest();

        Application_Log__c persistedLog = [
            SELECT Pay_Load__c
            FROM Application_Log__c
            WHERE Category__c = 'P360'
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];

        System.Assert.isFalse(
            persistedLog.Pay_Load__c.contains('raw-secret-value'),
            'Expected the raw secret value to be redacted before persisting.'
        );
        System.Assert.isTrue(
            persistedLog.Pay_Load__c.contains('00012345'),
            'Expected a non-sensitive value to remain in the payload.'
        );
    }
}
