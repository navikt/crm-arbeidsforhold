/**
 * Verifies request validation and the SIF CreateCase/CreateDocument sequence at the P360 archive adapter boundary.
 *
 * @author Kenneth Sørensen
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
        P360_ArchiveAdapter adapter = new P360_ArchiveAdapter(new P360_TestRpcClient());
        User minimumAccessUser = P360_TestDataFactory.createMinimumAccessUser();

        System.runAs(minimumAccessUser) {
            try {
                adapter.archive((P360_ArchiveRequestDto) null);
                System.Assert.fail('Expected a contract exception.');
            } catch (P360_ContractException caughtError) {
                System.Assert.areEqual(
                    'Archive request is required.',
                    caughtError.getMessage(),
                    'Expected the null request validation message.'
                );
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
        P360_ArchiveRequestDto request = P360_TestDataFactory.archiveRequest().withExternalId(null).build();
        P360_ArchiveAdapter adapter = new P360_ArchiveAdapter(new P360_TestRpcClient());
        User minimumAccessUser = P360_TestDataFactory.createMinimumAccessUser();

        System.runAs(minimumAccessUser) {
            try {
                adapter.archive(request);
                System.Assert.fail('Expected a contract exception.');
            } catch (P360_ContractException caughtError) {
                System.Assert.areEqual(
                    'Archive request external id is required.',
                    caughtError.getMessage(),
                    'Expected the missing external id validation message.'
                );
            }
        }
    }

    /**
     * Verifies that a new archive creates the case first and files the document on the returned case number.
     *
     * @since 2026-11
     */
    @IsTest
    static void archiveCreatesCaseThenDocumentWithSifWireFormat() {
        P360_ArchiveAdapter adapter = new P360_ArchiveAdapter(new P360_CapturingRpcClient());
        User minimumAccessUser = P360_TestDataFactory.createMinimumAccessUser();

        System.runAs(minimumAccessUser) {
            P360_ArchiveResponseDto response = adapter.archive(fullRequest(null));

            System.Assert.areEqual(
                2,
                P360_CapturingRpcClient.requests.size(),
                'Expected CreateCase and CreateDocument.'
            );
            P360_RpcRequest caseCall = P360_CapturingRpcClient.requests[0];
            P360_RpcRequest documentCall = P360_CapturingRpcClient.requests[1];
            System.Assert.areEqual('CaseService', caseCall.serviceName);
            System.Assert.areEqual('CreateCase', caseCall.operationName);
            System.Assert.areEqual('DocumentService', documentCall.serviceName);
            System.Assert.areEqual('CreateDocument', documentCall.operationName);
            System.Assert.isTrue(caseCall.headers.isEmpty(), 'The adapter must leave transport headers to the client.');

            Map<String, Object> caseParameter = P360_CapturingRpcClient.parameter(0);
            System.Assert.areEqual('Case title', caseParameter.get('Title'));
            System.Assert.areEqual(
                new Map<String, Object>{ 'Id' => 'ACCESS_REQUEST:a01', 'Type' => 'Salesforce Aa-registeret' },
                caseParameter.get('ExternalId'),
                'SIF expects ExternalId as an Id/Type object.'
            );
            System.Assert.isFalse(caseParameter.containsKey('ExternalSystem'), 'Type is carried inside ExternalId.');
            System.Assert.isFalse(caseParameter.containsKey('ClosedDate'), 'Null values must be omitted.');
            Map<String, Object> archiveCode = (Map<String, Object>) ((List<Object>) caseParameter.get(
                'ArchiveCodes'
            ))[0];
            System.Assert.areEqual(1, archiveCode.get('Sort'));
            System.Assert.areEqual('Arkivnøkkel', archiveCode.get('ArchiveType'));
            System.Assert.areEqual('359', archiveCode.get('ArchiveCode'));

            Map<String, Object> documentParameter = P360_CapturingRpcClient.parameter(1);
            System.Assert.areEqual('26/00001', documentParameter.get('CaseNumber'), 'Expected the created case.');
            System.Assert.areEqual('2026-11-16', documentParameter.get('DocumentDate'));
            System.Assert.areEqual('Dokument inn', documentParameter.get('Category'));
            Map<String, Object> file = (Map<String, Object>) ((List<Object>) documentParameter.get('Files'))[0];
            System.Assert.areEqual('txt', file.get('Format'));
            System.Assert.areEqual('c3ludGhldGlj', file.get('Base64Data'));

            System.Assert.isTrue(response.success);
            System.Assert.areEqual('26/00001', response.externalCaseId);
            System.Assert.areEqual('26/00001-2', response.externalDocumentId);
        }
    }

    /**
     * Verifies that a known case number files the document without creating another case.
     *
     * @since 2026-11
     */
    @IsTest
    static void existingCaseNumberSkipsCaseCreation() {
        P360_ArchiveAdapter adapter = new P360_ArchiveAdapter(new P360_CapturingRpcClient());

        P360_ArchiveResponseDto response = adapter.archive(fullRequest('25/00042'));

        System.Assert.areEqual(1, P360_CapturingRpcClient.requests.size(), 'Expected only CreateDocument.');
        System.Assert.areEqual('CreateDocument', P360_CapturingRpcClient.requests[0].operationName);
        System.Assert.areEqual('25/00042', P360_CapturingRpcClient.parameter(0).get('CaseNumber'));
        System.Assert.areEqual('25/00042', response.externalCaseId);
    }

    /**
     * Verifies that an explicit SIF rejection stops the flow without exposing response details.
     *
     * @since 2026-11
     */
    @IsTest
    static void rejectedCaseStopsBeforeDocumentCreation() {
        P360_CapturingRpcClient.queuedResponses.add(
            P360_CapturingRpcClient.response(200, '{"Successful":false,"ErrorMessage":"untrusted response detail"}')
        );
        P360_ArchiveAdapter adapter = new P360_ArchiveAdapter(new P360_CapturingRpcClient());

        try {
            adapter.archive(fullRequest(null));
            System.Assert.fail('Expected a contract exception.');
        } catch (P360_ContractException caughtError) {
            System.Assert.areEqual('P360 CreateCase was not successful.', caughtError.getMessage());
            System.Assert.isFalse(caughtError.isRetryable);
        }
        System.Assert.areEqual(1, P360_CapturingRpcClient.requests.size(), 'No document may be filed without a case.');
    }

    /**
     * Verifies that unavailable or throttled responses are retryable.
     *
     * @since 2026-11
     */
    @IsTest
    static void unavailableServiceIsRetryable() {
        P360_CapturingRpcClient.queuedResponses.add(P360_CapturingRpcClient.response(503, ''));
        P360_ArchiveAdapter adapter = new P360_ArchiveAdapter(new P360_CapturingRpcClient());

        try {
            adapter.archive(fullRequest(null));
            System.Assert.fail('Expected a retryable exception.');
        } catch (P360_RetryableException caughtError) {
            System.Assert.isTrue(caughtError.isRetryable);
        }
    }

    /**
     * Verifies that a request without CreateDocument parameters is rejected before transport.
     *
     * @since 2026-11
     */
    @IsTest
    static void requestWithoutDocumentIsRejectedBeforeTransport() {
        P360_ArchiveRequestDto request = P360_TestDataFactory.archiveRequest().build();
        P360_ArchiveAdapter adapter = new P360_ArchiveAdapter(new P360_TestRpcClient());

        try {
            adapter.archive(request);
            System.Assert.fail('Expected a contract exception.');
        } catch (P360_ContractException caughtError) {
            System.Assert.areEqual('Archive request CreateDocument parameters are required.', caughtError.getMessage());
        }
    }

    private static P360_ArchiveRequestDto fullRequest(String existingCaseNumber) {
        P360_ArchiveRequestDto request = P360_TestDataFactory.archiveRequest().build();
        if (existingCaseNumber == null) {
            P360_CreateCaseRequestDto createCase = new P360_CreateCaseRequestDto();
            createCase.title = 'Case title';
            createCase.externalId = 'ACCESS_REQUEST:a01';
            createCase.externalSystem = 'Salesforce Aa-registeret';
            P360_ClassCodeParameterDto archiveCode = new P360_ClassCodeParameterDto();
            archiveCode.sortOrder = 1;
            archiveCode.archiveType = 'Arkivnøkkel';
            archiveCode.archiveCode = '359';
            archiveCode.isManualText = false;
            createCase.archiveCodes = new List<P360_ClassCodeParameterDto>{ archiveCode };
            request.createCase = createCase;
        }
        P360_CreateDocumentRequestDto createDocument = new P360_CreateDocumentRequestDto();
        createDocument.title = 'Document title';
        createDocument.documentDate = Date.newInstance(2026, 11, 16);
        createDocument.category = 'Dokument inn';
        createDocument.status = 'J';
        createDocument.caseNumber = existingCaseNumber;
        createDocument.externalId = 'APPLICATION_DOCUMENT:a02';
        createDocument.externalSystem = 'Salesforce Aa-registeret';
        P360_FileParameterDto file = new P360_FileParameterDto();
        file.title = 'Summary';
        file.format = 'txt';
        file.base64Data = 'c3ludGhldGlj';
        createDocument.files = new List<P360_FileParameterDto>{ file };
        request.createDocument = createDocument;
        return request;
    }
}
