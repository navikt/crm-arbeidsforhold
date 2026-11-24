/**
 * Test-only RPC client that records every request and replays queued responses.
 * State is static so tests can inspect a client the adapter factory instantiated through `Type.forName`.
 *
 * @author Kenneth Sørensen
 * @since 2026-11
 * @group P360 Test Utility
 */
@IsTest
public with sharing class P360_CapturingRpcClient implements P360_IRpcClient {
    /** Requests in the order they were sent. */
    public static List<P360_RpcRequest> requests = new List<P360_RpcRequest>();

    /** Responses to return in order; a successful SIF result is synthesised when empty. */
    public static List<P360_RpcResponse> queuedResponses = new List<P360_RpcResponse>();

    /**
     * Records the request and returns the next queued or synthesised response.
     *
     * @param request RPC request built by the adapter.
     * @return Queued response, or a successful SIF result for the requested operation.
     */
    public P360_RpcResponse send(P360_RpcRequest request) {
        requests.add(request);
        if (!queuedResponses.isEmpty()) {
            return queuedResponses.remove(0);
        }
        Map<String, Object> body = new Map<String, Object>{ 'Successful' => true, 'Recno' => requests.size() };
        body.put(
            request.operationName == 'CreateCase' ? 'CaseNumber' : 'DocumentNumber',
            request.operationName == 'CreateCase' ? '26/00001' : '26/00001-' + requests.size()
        );
        return response(200, JSON.serialize(body));
    }

    /**
     * Creates an RPC response for queueing.
     *
     * @param statusCode HTTP-like status code.
     * @param body Response body.
     * @return RPC response.
     */
    public static P360_RpcResponse response(Integer statusCode, String body) {
        P360_RpcResponse result = new P360_RpcResponse();
        result.statusCode = statusCode;
        result.body = body;
        return result;
    }

    /**
     * Returns the SIF `parameter` object of a captured request.
     *
     * @param index Request index.
     * @return Parsed parameter map.
     */
    public static Map<String, Object> parameter(Integer index) {
        Map<String, Object> envelope = (Map<String, Object>) JSON.deserializeUntyped(requests[index].body);
        return (Map<String, Object>) envelope.get('parameter');
    }
}
