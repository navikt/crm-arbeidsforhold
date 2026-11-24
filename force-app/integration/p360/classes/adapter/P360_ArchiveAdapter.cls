/**
 * P360 archive adapter: files one document via SIF `CaseService/CreateCase` and `DocumentService/CreateDocument`.
 * A case is created first unless the document already names an existing case.
 * Transport, credentials and headers belong to the injected RPC client; P360 response details are not propagated.
 *
 * @author Kenneth Sørensen
 * @since 2026-04 F2 foundation
 * @group P360 Adapter
 */
public with sharing class P360_ArchiveAdapter implements P360_IArchiveAdapter {
    @TestVisible
    private final P360_IRpcClient rpcClient;

    /**
     * Creates a new adapter instance.
     *
     * @param rpcClient Low-level RPC client used for P360 transport.
     */
    public P360_ArchiveAdapter(P360_IRpcClient rpcClient) {
        this.rpcClient = rpcClient;
    }

    /**
     * Archives one request in P360.
     *
     * @param request P360 archive request DTO with CreateDocument and, for a new case, CreateCase parameters.
     * @return Successful archive response with the P360 case number and document number.
     * @throws P360_ContractException When the request is incomplete, or P360 rejects or returns an unreadable result.
     * @throws P360_RetryableException When P360 is unavailable or throttles the request.
     * @throws P360_TransportException When the RPC client cannot deliver the request.
     */
    public P360_ArchiveResponseDto archive(P360_ArchiveRequestDto request) {
        if (request == null) {
            throw new P360_ContractException('Archive request is required.');
        }
        if (String.isBlank(request.externalId)) {
            throw new P360_ContractException('Archive request external id is required.');
        }
        if (request.createDocument == null) {
            throw new P360_ContractException('Archive request CreateDocument parameters are required.');
        }

        P360_CreateDocumentRequestDto document = request.createDocument;
        Boolean hasCaseIdentity = String.isNotBlank(document.caseNumber) || String.isNotBlank(document.caseExternalId);
        if (String.isNotBlank(document.caseNumber) && String.isNotBlank(document.caseExternalId)) {
            throw new P360_ContractException('CreateDocument must use exactly one case identity.');
        }
        if (!hasCaseIdentity) {
            if (request.createCase == null) {
                throw new P360_ContractException('Archive request requires an existing case or CreateCase parameters.');
            }
            Map<String, Object> caseResult = send(
                'CaseService',
                'CreateCase',
                P360_SifRequestSerializer.createCase(request.createCase)
            );
            document.caseNumber = requireText(caseResult, 'CaseNumber', 'CreateCase');
        }

        Map<String, Object> documentResult = send(
            'DocumentService',
            'CreateDocument',
            P360_SifRequestSerializer.createDocument(document)
        );

        P360_ArchiveResponseDto response = new P360_ArchiveResponseDto();
        response.success = true;
        response.message = 'Archived in P360.';
        response.externalCaseId = String.isNotBlank(document.caseNumber)
            ? document.caseNumber
            : document.caseExternalId;
        response.externalDocumentId = requireText(documentResult, 'DocumentNumber', 'CreateDocument');
        return response;
    }

    private Map<String, Object> send(String serviceName, String operationName, String body) {
        P360_RpcRequest rpcRequest = new P360_RpcRequest();
        rpcRequest.serviceName = serviceName;
        rpcRequest.operationName = operationName;
        rpcRequest.body = body;
        rpcRequest.headers = new Map<String, String>();

        P360_RpcResponse rpcResponse = rpcClient.send(rpcRequest);
        if (rpcResponse == null) {
            throw new P360_ContractException('P360 ' + operationName + ' returned no response.');
        }
        Integer statusCode = rpcResponse.statusCode;
        if (statusCode != null && (statusCode == 408 || statusCode == 429 || statusCode >= 500)) {
            throw new P360_RetryableException('P360 ' + operationName + ' is temporarily unavailable: ' + statusCode);
        }
        if (statusCode != null && (statusCode < 200 || statusCode > 299)) {
            throw new P360_ContractException('P360 ' + operationName + ' returned HTTP status ' + statusCode + '.');
        }

        Map<String, Object> result;
        try {
            result = (Map<String, Object>) JSON.deserializeUntyped(rpcResponse.body);
        } catch (Exception parseError) {
            throw new P360_ContractException('P360 ' + operationName + ' returned an unreadable response.');
        }
        if (result == null || result.get('Successful') == false) {
            throw new P360_ContractException('P360 ' + operationName + ' was not successful.');
        }
        return result;
    }

    private static String requireText(Map<String, Object> result, String fieldName, String operationName) {
        Object value = result.get(fieldName);
        if (value == null || String.isBlank(String.valueOf(value))) {
            throw new P360_ContractException('P360 ' + operationName + ' returned no ' + fieldName + '.');
        }
        return String.valueOf(value);
    }
}
