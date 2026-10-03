/**
 * Verifies that a correlation id attached to a P360 integration exception propagates through a catch boundary.
 *
 * @author Kenneth Sørensen
 * @since 2026-09 issue 1021
 * @group P360 Exception
 */
@IsTest
private class P360_IntegrationExceptionCorrelationTest {
    /**
     * Verifies that an attached correlation id is preserved when the exception is caught elsewhere.
     *
     * @since 2026-09
     */
    @IsTest
    static void attachedCorrelationIdPropagatesThroughACatchBoundary() {
        User minimumAccessUser = P360_TestDataFactory.createMinimumAccessUser();

        System.runAs(minimumAccessUser) {
            String correlationId = new CorrelationContext('correlation-propagation-test').correlationId;
            P360_IntegrationException caughtError;

            try {
                throw new P360_ContractException('Simulated contract failure').withCorrelationId(correlationId);
            } catch (P360_IntegrationException error) {
                caughtError = error;
            }

            System.Assert.isNotNull(caughtError, 'Expected the exception to be caught.');
            System.Assert.areEqual(
                correlationId,
                caughtError.correlationId,
                'Expected the correlation id to propagate through the exception.'
            );
        }
    }

    /**
     * Verifies that an exception without an attached correlation id exposes null rather than a guessed value.
     *
     * @since 2026-09
     */
    @IsTest
    static void missingCorrelationIdRemainsNull() {
        User minimumAccessUser = P360_TestDataFactory.createMinimumAccessUser();

        System.runAs(minimumAccessUser) {
            P360_IntegrationException error = new P360_ContractException('Simulated contract failure');

            System.Assert.isNull(error.correlationId, 'Expected no correlation id when none was attached.');
        }
    }
}
