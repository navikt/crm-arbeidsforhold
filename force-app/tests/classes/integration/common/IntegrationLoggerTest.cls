/**
 * Verifies that shared integration logging persists only technical context.
 *
 * @author Kenneth Sørensen
 * @since 2026-10
 * @group Integration Common Test
 */
@IsTest
private class IntegrationLoggerTest {
    /**
     * Verifies that a failure log persists the bounded technical context and correlation id.
     *
     * @since 2026-10
     */
    @IsTest
    static void failureLogPersistsOnlyTechnicalContext() {
        User minimumAccessUser = Integration_TestDataFactory.createMinimumAccessUser();
        IntegrationLogContext context = new IntegrationLogContext('P360', 'CreateDocument', 'Failed')
            .withCorrelationId('0123456789abcdef0123456789abcdef');

        System.runAs(minimumAccessUser) {
            System.Test.startTest();
            IntegrationLogger.logFailure(context);
            System.Test.stopTest();
        }

        Application_Log__c savedLog = [
            SELECT Category__c, Application_Domain__c, Log_Message__c, Pay_Load__c
            FROM Application_Log__c
            WHERE Category__c = 'P360'
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        Map<String, Object> payload = (Map<String, Object>) JSON.deserializeUntyped(savedLog.Pay_Load__c);

        System.Assert.areEqual('P360', savedLog.Category__c);
        System.Assert.areEqual('AAREG', savedLog.Application_Domain__c);
        System.Assert.areEqual(4, payload.size(), 'Only the four technical context fields may be persisted.');
        System.Assert.areEqual('P360', payload.get('systemName'));
        System.Assert.areEqual('CreateDocument', payload.get('operationName'));
        System.Assert.areEqual('Failed', payload.get('status'));
        System.Assert.areEqual('0123456789abcdef0123456789abcdef', payload.get('correlationId'));
    }

    /**
     * Verifies that malformed context values are replaced before persistence.
     *
     * @since 2026-10
     */
    @IsTest
    static void malformedContextValuesAreNotPersisted() {
        User minimumAccessUser = Integration_TestDataFactory.createMinimumAccessUser();
        IntegrationLogContext context = new IntegrationLogContext('P360', 'synthetic-secret-token', 'Failed')
            .withCorrelationId('synthetic-person-identifier');

        System.runAs(minimumAccessUser) {
            System.Test.startTest();
            IntegrationLogger.logFailure(context);
            System.Test.stopTest();
        }

        Application_Log__c savedLog = [
            SELECT Category__c, Log_Message__c, Pay_Load__c
            FROM Application_Log__c
            WHERE Category__c = 'P360'
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        Map<String, Object> payload = (Map<String, Object>) JSON.deserializeUntyped(savedLog.Pay_Load__c);

        System.Assert.areEqual('P360', savedLog.Category__c);
        System.Assert.areEqual('UnknownOperation', payload.get('operationName'));
        System.Assert.areEqual('[REDACTED]', payload.get('correlationId'));
        System.Assert.isFalse(savedLog.Log_Message__c.contains('synthetic-secret-token'));
        System.Assert.isFalse(savedLog.Pay_Load__c.contains('synthetic-person-identifier'));
    }
}