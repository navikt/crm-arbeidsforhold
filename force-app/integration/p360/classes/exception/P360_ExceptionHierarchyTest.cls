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
        User minimumAccessUser = P360_TestDataFactory.createMinimumAccessUser();

        System.runAs(minimumAccessUser) {
            assertRuntimeType(new P360_ContractException(), P360_ContractException.class);
            assertRuntimeType(new P360_AuthenticationException(), P360_AuthenticationException.class);
            assertRuntimeType(new P360_ConfigException(), P360_ConfigException.class);
            assertRuntimeType(new P360_MappingException(), P360_MappingException.class);

            P360_IntegrationException contractError = new P360_ContractException();
            P360_IntegrationException authError = new P360_AuthenticationException();
            P360_IntegrationException configError = new P360_ConfigException();
            P360_IntegrationException mappingError = new P360_MappingException();

            System.Assert.areEqual(
                P360_ContractException.class.getName(),
                contractError.getTypeName(),
                'Expected the contract exception type.'
            );
            System.Assert.areEqual(
                P360_AuthenticationException.class.getName(),
                authError.getTypeName(),
                'Expected the authentication exception type.'
            );
            System.Assert.areEqual(
                P360_ConfigException.class.getName(),
                configError.getTypeName(),
                'Expected the config exception type.'
            );
            System.Assert.areEqual(
                P360_MappingException.class.getName(),
                mappingError.getTypeName(),
                'Expected the mapping exception type.'
            );
        }
    }

    /**
     * Verifies that transport timeout and retry errors are integration errors and retryable errors are transport errors.
     *
     * @since 2026-09
     */
    @IsTest
    static void retryableTransportErrorsHaveRetryableTaxonomy() {
        User minimumAccessUser = P360_TestDataFactory.createMinimumAccessUser();

        System.runAs(minimumAccessUser) {
            assertRuntimeType(new P360_TransportException(), P360_TransportException.class);
            assertRuntimeType(new P360_TimeoutException(), P360_TimeoutException.class);
            assertRuntimeType(new P360_RetryableException(), P360_RetryableException.class);

            P360_TransportException transportError = new P360_TransportException();
            P360_TransportException timeoutError = new P360_TimeoutException();
            P360_TransportException retryableError = new P360_RetryableException();

            System.Assert.areEqual(
                P360_TransportException.class.getName(),
                transportError.getTypeName(),
                'Expected the transport exception type.'
            );
            System.Assert.areEqual(
                P360_TimeoutException.class.getName(),
                timeoutError.getTypeName(),
                'Expected the timeout exception type.'
            );
            System.Assert.areEqual(
                P360_RetryableException.class.getName(),
                retryableError.getTypeName(),
                'Expected the retryable exception type.'
            );
        }
    }

    private static void assertRuntimeType(Exception error, Type expectedType) {
        System.Assert.isNotNull(error, 'Expected an exception instance.');
        System.Assert.areEqual(expectedType.getName(), error.getTypeName(), 'Expected the runtime exception type.');
    }
}
