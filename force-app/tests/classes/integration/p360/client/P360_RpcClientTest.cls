/**
 * Tests P360_RpcClient skeleton behavior.
 *
 * @author Kenneth Sørensen
 * @since 2026-04 F2 foundation
 * @group P360 RPC Client
 */
@IsTest
private class P360_RpcClientTest {
    /**
     * Verifies that send throws a controlled transport exception while implementation is incomplete.
     */
    @IsTest
    static void sendThrowsTransportException() {
        P360_RpcClient client = new P360_RpcClient();

        try {
            System.Test.startTest();
            client.send(new P360_RpcRequest());
            System.Test.stopTest();

            System.Assert.fail('Expected P360_TransportException.');
        } catch (P360_TransportException e) {
            System.Assert.isTrue(
                e.getMessage().contains('P360_RpcClient.send is not implemented yet'),
                'Unexpected exception message: ' + e.getMessage()
            );
        }
    }
}
