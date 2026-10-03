/**
 * Default P360 RPC client skeleton.
 * This class will later handle HTTP callouts, headers, serialization and response parsing.
 *
 * @author Kenneth Sørensen
 * @since 2026-04 F2 foundation
 * @group P360 RPC Client
 */
public with sharing class P360_RpcClient implements P360_IRpcClient {
    /**
     * Sends one RPC request to P360.
     *
     * @param request RPC transport request.
     * @return RPC transport response.
     * @throws P360_TransportException Until implementation is completed.
     */
    public P360_RpcResponse send(P360_RpcRequest request) {
        throw new P360_TransportException('P360_RpcClient.send is not implemented yet. TODO S1.');
    }
}
