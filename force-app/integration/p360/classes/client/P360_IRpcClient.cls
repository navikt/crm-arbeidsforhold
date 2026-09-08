/**
 * Contract for low-level P360 RPC transport.
 *
 * @author Kenneth Sørensen
 * @since 2026-04 F2 foundation
 * @group P360 RPC Client
 */
public interface P360_IRpcClient {
    /**
     * Sends one RPC request to P360.
     *
     * @param request RPC transport request.
     * @return RPC transport response.
     * @throws P360_TransportException When transport fails.
     */
    P360_RpcResponse send(P360_RpcRequest request);
}
