/**
 * Verifies the P360 exception taxonomy used by integration boundaries.
 *
 * @author Kenneth Sørensen
 * @since 2026-09 issue 993
 * @group P360 Exception
 */
@IsTest
private class P360_ExceptionHierarchyTest {
    /**
     * Verifies that contract, authentication, configuration and mapping errors are integration errors.
     *
     * @since 2026-09
     */
    @IsTest
    static void specializedErrorsAreIntegrationErrors() {
        assertIsIntegrationError(new P360_ContractException());
        assertIsIntegrationError(new P360_AuthenticationException());
        assertIsIntegrationError(new P360_ConfigException());
        assertIsIntegrationError(new P360_MappingException());
    }

    /**
     * Verifies that transport timeout and retry errors are integration errors and retryable errors are transport errors.
     *
     * @since 2026-09
     */
    @IsTest
    static void retryableTransportErrorsHaveRetryableTaxonomy() {
        assertIsIntegrationError(new P360_TransportException());
        assertIsTransportError(new P360_TimeoutException());
        assertIsIntegrationError(new P360_TimeoutException());
        assertIsTransportError(new P360_RetryableException());
        assertIsIntegrationError(new P360_RetryableException());
    }

    private static void assertIsIntegrationError(P360_IntegrationException error) {
        System.assertNotEquals(null, error, 'Expected a P360 integration exception.');
    }

    private static void assertIsTransportError(P360_TransportException error) {
        System.assertNotEquals(null, error, 'Expected a P360 transport exception.');
    }
}
