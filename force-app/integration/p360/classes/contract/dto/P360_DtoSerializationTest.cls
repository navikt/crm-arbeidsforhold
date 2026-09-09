/**
 * Verifies JSON round-trip behaviour for the temporary P360 DTO wrappers.
 *
 * @author Kenneth Sørensen
 * @since 2026-09
 * @group P360 DTO
 */
@IsTest
private class P360_DtoSerializationTest {
    /**
     * Verifies that archive request and response DTO fields survive JSON round-trip serialization.
     *
     * @since 2026-09
     */
    @IsTest
    static void archiveDtosPreserveFieldsThroughJsonRoundTrip() {
        User minimumAccessUser = P360_TestDataFactory.createMinimumAccessUser();

        System.runAs(minimumAccessUser) {
            P360_ArchiveRequestDto request = P360_TestDataFactory.archiveRequest().build();
            P360_ArchiveResponseDto response = P360_TestDataFactory.archiveResponse().build();

            P360_ArchiveRequestDto deserializedRequest = (P360_ArchiveRequestDto) JSON.deserialize(
                JSON.serialize(request),
                P360_ArchiveRequestDto.class
            );
            P360_ArchiveResponseDto deserializedResponse = (P360_ArchiveResponseDto) JSON.deserialize(
                JSON.serialize(response),
                P360_ArchiveResponseDto.class
            );

            System.Assert.areEqual(
                request.correlationId,
                deserializedRequest.correlationId,
                'Expected the request correlation id.'
            );
            System.Assert.areEqual(
                request.externalId,
                deserializedRequest.externalId,
                'Expected the request external id.'
            );
            System.Assert.areEqual(request.title, deserializedRequest.title, 'Expected the request title.');
            System.Assert.areEqual(
                response.success,
                deserializedResponse.success,
                'Expected the response success value.'
            );
            System.Assert.areEqual(response.message, deserializedResponse.message, 'Expected the response message.');
            System.Assert.areEqual(
                response.externalCaseId,
                deserializedResponse.externalCaseId,
                'Expected the response case id.'
            );
            System.Assert.areEqual(
                response.externalDocumentId,
                deserializedResponse.externalDocumentId,
                'Expected the response document id.'
            );
        }
    }

    /**
     * Verifies that RPC request and response wrappers preserve transport fields through JSON round-trip serialization.
     *
     * @since 2026-09
     */
    @IsTest
    static void rpcDtosPreserveFieldsThroughJsonRoundTrip() {
        User minimumAccessUser = P360_TestDataFactory.createMinimumAccessUser();
        Map<String, String> requestHeaders = new Map<String, String>{ 'X-Test' => 'request-value' };
        Map<String, String> responseHeaders = new Map<String, String>{ 'X-Test' => 'response-value' };

        System.runAs(minimumAccessUser) {
            P360_RpcRequest request = P360_TestDataFactory.rpcRequest().withHeaders(requestHeaders).build();
            P360_RpcResponse response = P360_TestDataFactory.rpcResponse().withHeaders(responseHeaders).build();

            P360_RpcRequest deserializedRequest = (P360_RpcRequest) JSON.deserialize(
                JSON.serialize(request),
                P360_RpcRequest.class
            );
            P360_RpcResponse deserializedResponse = (P360_RpcResponse) JSON.deserialize(
                JSON.serialize(response),
                P360_RpcResponse.class
            );

            System.Assert.areEqual(request.serviceName, deserializedRequest.serviceName, 'Expected the service name.');
            System.Assert.areEqual(
                request.operationName,
                deserializedRequest.operationName,
                'Expected the operation name.'
            );
            System.Assert.areEqual(request.body, deserializedRequest.body, 'Expected the request body.');
            System.Assert.areEqual(
                'request-value',
                deserializedRequest.headers.get('X-Test'),
                'Expected the request header.'
            );
            System.Assert.areEqual(response.statusCode, deserializedResponse.statusCode, 'Expected the status code.');
            System.Assert.areEqual(response.body, deserializedResponse.body, 'Expected the response body.');
            System.Assert.areEqual(
                'response-value',
                deserializedResponse.headers.get('X-Test'),
                'Expected the response header.'
            );
        }
    }
}
