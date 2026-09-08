/**
 * Test RPC client for P360 adapter tests.
 *
 * @author Not available (new file)
 * @since 2026-09
 * @group P360 Test Utility
 */
@IsTest
public with sharing class P360_TestRpcClient implements P360_IRpcClient {
    /** Number of transport calls received by this fake client. */
    public Integer sendCount { get; private set; }

    /**
     * Creates a fake client that fails if the adapter reaches transport.
     *
     * @since 2026-09
     */
    public P360_TestRpcClient() {
        sendCount = 0;
    }

    /**
     * Records transport usage and fails the test because this fake is for pre-transport validation.
     *
     * @param request RPC request received from the adapter.
     * @return Never returns because transport use is unexpected in these tests.
     * @since 2026-09
     */
    public P360_RpcResponse send(P360_RpcRequest request) {
        sendCount++;
        System.Assert.fail('Transport must not be called for invalid requests.');
        return null;
    }
}
