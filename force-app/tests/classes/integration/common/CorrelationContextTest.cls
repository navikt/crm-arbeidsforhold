/**
 * Verifies shared correlation context behavior.
 *
 * @author Kenneth Sørensen
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
        User minimumAccessUser = Integration_TestDataFactory.createMinimumAccessUser();

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
        User minimumAccessUser = Integration_TestDataFactory.createMinimumAccessUser();

        System.runAs(minimumAccessUser) {
            CorrelationContext context = new CorrelationContext(null);

            System.Assert.isTrue(String.isNotBlank(context.correlationId), 'Expected a generated correlation id.');
        }
    }
}
