/**
 * Verifies the P360 exception taxonomy used by integration boundaries.
 *
 * @author Not available (new file)
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
        System.runAs([SELECT Id FROM User WHERE Id = :UserInfo.getUserId()]) {
            System.assert(new P360_ContractException() instanceof P360_IntegrationException);
            System.assert(new P360_AuthenticationException() instanceof P360_IntegrationException);
            System.assert(new P360_ConfigException() instanceof P360_IntegrationException);
            System.assert(new P360_MappingException() instanceof P360_IntegrationException);
        }
    }

    /**
     * Verifies that transport timeout and retry errors are integration errors and retryable errors are transport errors.
     *
     * @since 2026-09
     */
    @IsTest
    static void retryableTransportErrorsHaveRetryableTaxonomy() {
        System.runAs([SELECT Id FROM User WHERE Id = :UserInfo.getUserId()]) {
            System.assert(new P360_TransportException() instanceof P360_IntegrationException);
            System.assert(new P360_TimeoutException() instanceof P360_TransportException);
            System.assert(new P360_RetryableException() instanceof P360_TransportException);
            System.assert(new P360_RetryableException() instanceof P360_IntegrationException);
        }
    }
}
