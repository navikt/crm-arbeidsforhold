/**
 * Temporary RPC transport response wrapper used to make F2 compile.
 * TODO F3/S1: Replace with full RPC transport response contract.
 *
 * @author Kenneth Sørensen
 * @since 2026-04 F2 foundation
 * @group P360 RPC Client
 */
public class P360_RpcResponse {
    /** HTTP status code returned by the transport layer. */
    public Integer statusCode;

    /** Raw response body returned by P360. */
    public String body;

    /** Response headers returned by the transport layer. */
    public Map<String, String> headers;
}
