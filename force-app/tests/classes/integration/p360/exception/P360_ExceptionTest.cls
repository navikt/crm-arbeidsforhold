/**
 * Tests temporary P360 exception behavior.
 *
 * @author Kenneth Sørensen
 * @since 2026-04 F2 foundation
 * @group P360 Exception
 */
@IsTest
private class P360_ExceptionTest {
    /**
     * Verifies that P360_IntegrationException can be thrown and caught.
     */
    @IsTest
    static void integrationExceptionCanBeThrownAndCaught() {
        try {
            System.Test.startTest();
            throw new P360_IntegrationException('Integration error');
        } catch (P360_IntegrationException e) {
            System.Test.stopTest();

            System.Assert.areEqual('Integration error', e.getMessage(), 'Unexpected exception message.');
        }
    }

    /**
     * Verifies that P360_ContractException can be thrown and caught.
     */
    @IsTest
    static void contractExceptionCanBeThrownAndCaught() {
        try {
            System.Test.startTest();
            throw new P360_ContractException('Contract error');
        } catch (P360_ContractException e) {
            System.Test.stopTest();

            System.Assert.areEqual('Contract error', e.getMessage(), 'Unexpected exception message.');
        }
    }

    /**
     * Verifies that P360_TransportException can be thrown and caught.
     */
    @IsTest
    static void transportExceptionCanBeThrownAndCaught() {
        try {
            System.Test.startTest();
            throw new P360_TransportException('Transport error');
        } catch (P360_TransportException e) {
            System.Test.stopTest();

            System.Assert.areEqual('Transport error', e.getMessage(), 'Unexpected exception message.');
        }
    }
}
