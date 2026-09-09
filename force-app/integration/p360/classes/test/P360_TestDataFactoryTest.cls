/**
 * Verifies reusable request and response fixtures for P360 tests.
 *
 * @author Not available (new file)
 * @since 2026-09
 * @group P360 Test Utility
 */
@IsTest
private class P360_TestDataFactoryTest {
    /**
     * Verifies that the archive request builder applies defaults and fluent overrides.
     *
     * @since 2026-09
     */
    @IsTest
    static void archiveRequestBuilderCreatesReadableFixture() {
        User minimumAccessUser = P360_TestDataFactory.createMinimumAccessUser();

        System.runAs(minimumAccessUser) {
            P360_ArchiveRequestDto request = P360_TestDataFactory.archiveRequest()
                .withCorrelationId('correlation-override')
                .withExternalId('external-override')
                .withTitle('Archive title override')
                .build();

            System.Assert.areEqual(
                'correlation-override',
                request.correlationId,
                'Expected the correlation id override.'
            );
            System.Assert.areEqual('external-override', request.externalId, 'Expected the external id override.');
            System.Assert.areEqual('Archive title override', request.title, 'Expected the title override.');
        }
    }

    /**
     * Verifies that the archive response builder applies defaults and fluent overrides.
     *
     * @since 2026-09
     */
    @IsTest
    static void archiveResponseBuilderCreatesReadableFixture() {
        User minimumAccessUser = P360_TestDataFactory.createMinimumAccessUser();

        System.runAs(minimumAccessUser) {
            P360_ArchiveResponseDto response = P360_TestDataFactory.archiveResponse()
                .withSuccess(false)
                .withMessage('Response message override')
                .withExternalCaseId('case-override')
                .withExternalDocumentId('document-override')
                .build();

            System.Assert.isFalse(response.success, 'Expected the success override.');
            System.Assert.areEqual('Response message override', response.message, 'Expected the message override.');
            System.Assert.areEqual('case-override', response.externalCaseId, 'Expected the case id override.');
            System.Assert.areEqual(
                'document-override',
                response.externalDocumentId,
                'Expected the document id override.'
            );
        }
    }

    /**
     * Verifies that the RPC request builder applies fluent overrides.
     *
     * @since 2026-09
     */
    @IsTest
    static void rpcRequestBuilderCreatesReadableFixture() {
        User minimumAccessUser = P360_TestDataFactory.createMinimumAccessUser();
        Map<String, String> headers = new Map<String, String>{ 'X-Test' => 'test-value' };

        System.runAs(minimumAccessUser) {
            P360_RpcRequest request = P360_TestDataFactory.rpcRequest()
                .withServiceName('TestService')
                .withOperationName('TestOperation')
                .withBody('{"test":true}')
                .withHeaders(headers)
                .build();

            System.Assert.areEqual('TestService', request.serviceName, 'Expected the service name override.');
            System.Assert.areEqual('TestOperation', request.operationName, 'Expected the operation name override.');
            System.Assert.areEqual('{"test":true}', request.body, 'Expected the body override.');
            System.Assert.areEqual('test-value', request.headers.get('X-Test'), 'Expected the header override.');
        }
    }

    /**
     * Verifies that the RPC response builder applies fluent overrides.
     *
     * @since 2026-09
     */
    @IsTest
    static void rpcResponseBuilderCreatesReadableFixture() {
        User minimumAccessUser = P360_TestDataFactory.createMinimumAccessUser();
        Map<String, String> headers = new Map<String, String>{ 'X-Test' => 'response-value' };

        System.runAs(minimumAccessUser) {
            P360_RpcResponse response = P360_TestDataFactory.rpcResponse()
                .withStatusCode(201)
                .withBody('{"created":true}')
                .withHeaders(headers)
                .build();

            System.Assert.areEqual(201, response.statusCode, 'Expected the status code override.');
            System.Assert.areEqual('{"created":true}', response.body, 'Expected the body override.');
            System.Assert.areEqual('response-value', response.headers.get('X-Test'), 'Expected the header override.');
        }
    }
}
