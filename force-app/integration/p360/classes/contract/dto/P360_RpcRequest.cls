/**
 * Temporary RPC transport request wrapper used to make F2 compile.
 * TODO F3/S1: Replace with full RPC transport request contract.
 *
 * @author Kenneth Sørensen
 * @since 2026-04 F2 foundation
 * @group P360 RPC Client
 */
public class P360_RpcRequest {
    /** P360 SIF service name, for example CaseService or DocumentService. */
    public String serviceName;

    /** P360 SIF operation name, for example CreateCase or CreateDocument. */
    public String operationName;

    /** Serialized request body. */
    public String body;

    /** Transport headers used for RPC calls. */
    public Map<String, String> headers;
}
