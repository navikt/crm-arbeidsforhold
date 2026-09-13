/**
 * Verifies that P360 integration exceptions classify retryability independently of runtime type.
 *
 * @author Kenneth Sørensen
 * @since 2026-09 issue 993
 * @group P360 Exception
 */
@IsTest
private class P360_IntegrationExceptionRetryableTest {
    /**
     * Verifies that a plain exception defaults to not retryable.
     *
     * @since 2026-09
     */
    @IsTest
    static void defaultsToNotRetryable() {
        User minimumAccessUser = P360_TestDataFactory.createMinimumAccessUser();

        System.runAs(minimumAccessUser) {
            P360_IntegrationException error = new P360_ContractException('Simulated contract failure');

            System.Assert.areEqual(false, error.isRetryable, 'Expected the default retryable classification.');
        }
    }

    /**
     * Verifies that retryability can be classified explicitly, independent of the exception type.
     *
     * @since 2026-09
     */
    @IsTest
    static void explicitClassificationOverridesTheDefault() {
        User minimumAccessUser = P360_TestDataFactory.createMinimumAccessUser();

        System.runAs(minimumAccessUser) {
            P360_IntegrationException error = new P360_ContractException('Simulated contract failure')
                .withRetryable(true);

            System.Assert.areEqual(true, error.isRetryable, 'Expected the explicit retryable classification.');
        }
    }

    /**
     * Verifies that the convenience P360_RetryableException classifies itself as retryable by default.
     *
     * @since 2026-09
     */
    @IsTest
    static void retryableExceptionIsRetryableByDefault() {
        User minimumAccessUser = P360_TestDataFactory.createMinimumAccessUser();

        System.runAs(minimumAccessUser) {
            P360_IntegrationException error = new P360_RetryableException();

            System.Assert.areEqual(
                true,
                error.isRetryable,
                'Expected P360_RetryableException to default to retryable.'
            );
        }
    }
}
