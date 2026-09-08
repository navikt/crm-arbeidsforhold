/**
 * Verifies request validation at the P360 archive adapter boundary.
 *
 * @author Not available (new file)
 * @since 2026-09
 * @group P360 Adapter
 */
@IsTest
private class P360_ArchiveAdapterTest {
    /**
     * Verifies that a null archive request is rejected before the RPC client is used.
     *
     * @since 2026-09
     */
    @IsTest
    static void nullRequestIsRejectedBeforeTransport() {
        System.runAs([SELECT Id FROM User WHERE Id = :UserInfo.getUserId()]) {
            P360_ArchiveAdapter adapter = new P360_ArchiveAdapter(new RecordingRpcClient());

            try {
                adapter.archive((P360_ArchiveRequestDto) null);
                System.assert(false, 'Expected a contract exception.');
            } catch (P360_ContractException caughtError) {
                System.assertEquals('Archive request is required.', caughtError.getMessage());
            }
        }
    }

    /**
     * Verifies that an archive request without an external id is rejected before the RPC client is used.
     *
     * @since 2026-09
     */
    @IsTest
    static void missingExternalIdIsRejectedBeforeTransport() {
        System.runAs([SELECT Id FROM User WHERE Id = :UserInfo.getUserId()]) {
            P360_ArchiveRequestDto request = new P360_ArchiveRequestDto();
            request.title = 'Archive request';
            P360_ArchiveAdapter adapter = new P360_ArchiveAdapter(new RecordingRpcClient());

            try {
                adapter.archive(request);
                System.assert(false, 'Expected a contract exception.');
            } catch (P360_ContractException caughtError) {
                System.assertEquals('Archive request external id is required.', caughtError.getMessage());
            }
        }
    }

    private class RecordingRpcClient implements P360_IRpcClient {
        public P360_RpcResponse send(P360_RpcRequest request) {
            System.assert(false, 'Transport must not be called for invalid requests.');
            return null;
        }
    }
}
