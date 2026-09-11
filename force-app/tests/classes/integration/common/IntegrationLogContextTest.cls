/**
 * Verifies the shared technical integration log context.
 *
 * @author Kenneth Sørensen
 * @since 2026-09
 * @group Integration Common
 */
@IsTest
private class IntegrationLogContextTest {
    /**
     * Verifies that technical log fields and the supplied correlation id are preserved.
     *
     * @since 2026-09
     */
    @IsTest
    static void suppliedTechnicalContextIsPreserved() {
        User minimumAccessUser = Integration_TestDataFactory.createMinimumAccessUser();

        System.runAs(minimumAccessUser) {
            IntegrationLogContext context = new IntegrationLogContext('P360', 'CreateDocument', 'Started')
                .withCorrelationId('correlation-supplied');

            System.Assert.areEqual('P360', context.systemName, 'Expected the system name.');
            System.Assert.areEqual('CreateDocument', context.operationName, 'Expected the operation name.');
            System.Assert.areEqual('correlation-supplied', context.correlationId, 'Expected the correlation id.');
            System.Assert.areEqual('Started', context.status, 'Expected the status.');
        }
    }

    /**
     * Verifies that a missing correlation id is generated without storing payload data.
     *
     * @since 2026-09
     */
    @IsTest
    static void missingCorrelationIdIsGenerated() {
        User minimumAccessUser = Integration_TestDataFactory.createMinimumAccessUser();

        System.runAs(minimumAccessUser) {
            IntegrationLogContext context = new IntegrationLogContext('P360', 'CreateDocument', 'Failed');

            System.Assert.isNotNull(context.correlationId, 'Expected a generated correlation id.');
            System.Assert.isTrue(String.isNotBlank(context.correlationId), 'Expected a non-blank correlation id.');
            System.Assert.areEqual('Failed', context.status, 'Expected the status.');
        }
    }
}
