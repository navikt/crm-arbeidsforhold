/**
 * Tests temporary P360 RPC DTO field behavior.
 *
 * @author Kenneth Sørensen
 * @since 2026-04 F2 foundation
 * @group P360 RPC Client
 */
@IsTest
private class P360_RpcDtoTest {
    /**
     * Verifies that all RPC request fields can be set and read.
     */
    @IsTest
    static void rpcRequestFieldsCanBeSetAndRead() {
        P360_RpcRequest request = new P360_RpcRequest();

        System.Test.startTest();
        request.serviceName = 'CaseService';
        request.operationName = 'CreateCase';
        request.body = '{"Title":"Test"}';
        request.headers = new Map<String, String>{ 'x-correlation-id' => 'corr-123' };
        System.Test.stopTest();

        System.Assert.areEqual('CaseService', request.serviceName, 'Unexpected service name.');
        System.Assert.areEqual('CreateCase', request.operationName, 'Unexpected operation name.');
        System.Assert.areEqual('{"Title":"Test"}', request.body, 'Unexpected body.');
        System.Assert.areEqual('corr-123', request.headers.get('x-correlation-id'), 'Unexpected correlation header.');
    }

    /**
     * Verifies that all RPC response fields can be set and read.
     */
    @IsTest
    static void rpcResponseFieldsCanBeSetAndRead() {
        P360_RpcResponse response = new P360_RpcResponse();

        System.Test.startTest();
        response.statusCode = 200;
        response.body = '{"Successful":true}';
        response.headers = new Map<String, String>{ 'content-type' => 'application/json' };
        System.Test.stopTest();

        System.Assert.areEqual(200, response.statusCode, 'Unexpected status code.');
        System.Assert.areEqual('{"Successful":true}', response.body, 'Unexpected response body.');
        System.Assert.areEqual('application/json', response.headers.get('content-type'), 'Unexpected content type.');
    }
}
