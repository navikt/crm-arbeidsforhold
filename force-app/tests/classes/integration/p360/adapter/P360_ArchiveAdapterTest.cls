/**
 * Tests P360_ArchiveAdapter skeleton behavior.
 *
 * @author Kenneth Sørensen
 * @since 2026-04 F2 foundation
 * @group P360 Adapter
 */
@IsTest
private class P360_ArchiveAdapterTest {
    /**
     * Verifies that archive throws a controlled contract exception while implementation is incomplete.
     */
    @IsTest
    static void archiveThrowsContractException() {
        P360_ArchiveAdapter adapter = new P360_ArchiveAdapter(new FakeRpcClient());

        try {
            System.Test.startTest();
            adapter.archive(new P360_ArchiveRequestDto());
            System.Test.stopTest();

            System.Assert.fail('Expected P360_ContractException.');
        } catch (P360_ContractException e) {
            System.Assert.isTrue(
                e.getMessage().contains('P360_ArchiveAdapter.archive is not implemented yet'),
                'Unexpected exception message: ' + e.getMessage()
            );
        }
    }

    /**
     * Fake RPC client used to construct the adapter without real transport.
     */
    private class FakeRpcClient implements P360_IRpcClient {
        /**
         * Returns a controlled fake RPC response.
         *
         * @param request RPC transport request.
         * @return Fake RPC transport response.
         */
        public P360_RpcResponse send(P360_RpcRequest request) {
            P360_RpcResponse response = new P360_RpcResponse();
            response.statusCode = 200;
            response.body = '{}';
            response.headers = new Map<String, String>();
            return response;
        }
    }
}
