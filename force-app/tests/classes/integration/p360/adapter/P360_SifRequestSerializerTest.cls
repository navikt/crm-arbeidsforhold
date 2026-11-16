/**
 * Verifies selected SIF request fields without activating the archive adapter or making callouts.
 *
 * @author Kenneth Sørensen
 * @since 2026-11
 * @group P360 Adapter
 */
@IsTest
private class P360_SifRequestSerializerTest {
    /**
     * Serializes case identity, dates and archive codes while preserving empty strings and omitting nulls.
     *
     * @since 2026-11
     */
    @IsTest
    static void caseParametersPreserveIdentityDatesAndArchiveCodes() {
        User minimumAccessUser = P360_TestDataFactory.createMinimumAccessUser();

        System.runAs(minimumAccessUser) {
            System.Test.startTest();
            P360_CreateCaseRequestDto request = new P360_CreateCaseRequestDto();
            request.title = 'Synthetic case';
            request.unofficialTitle = '';
            request.externalId = 'case-123';
            request.externalSystem = 'synthetic-system';
            request.startDate = Date.newInstance(2026, 11, 16);
            P360_ClassCodeParameterDto code = new P360_ClassCodeParameterDto();
            code.sortOrder = 1;
            code.archiveType = 'synthetic-type';
            code.isManualText = false;
            code.archiveCode = 'synthetic-code';
            request.archiveCodes = new List<P360_ClassCodeParameterDto>{ code };
            Map<String, Object> envelope = (Map<String, Object>) JSON.deserializeUntyped(
                P360_SifRequestSerializer.createCase(request)
            );
            System.Test.stopTest();

            System.Assert.areEqual(new Set<String>{ 'parameter' }, envelope.keySet());
            Map<String, Object> parameter = (Map<String, Object>) envelope.get('parameter');
            System.Assert.areEqual('Synthetic case', parameter.get('Title'));
            System.Assert.areEqual('', parameter.get('UnofficialTitle'));
            System.Assert.areEqual('2026-11-16', parameter.get('StartDate'));
            System.Assert.areEqual(
                new Map<String, Object>{ 'Id' => 'case-123', 'Type' => 'synthetic-system' },
                parameter.get('ExternalId')
            );
            System.Assert.isFalse(parameter.containsKey('ClosedDate'));
            System.Assert.isFalse(parameter.containsKey('ExternalSystem'));
            Map<String, Object> archiveCode = (Map<String, Object>) ((List<Object>) parameter.get('ArchiveCodes'))[0];
            System.Assert.areEqual(1, archiveCode.get('Sort'));
            System.Assert.areEqual('synthetic-type', archiveCode.get('ArchiveType'));
            System.Assert.areEqual(false, archiveCode.get('IsManualText'));
            System.Assert.areEqual('synthetic-code', archiveCode.get('ArchiveCode'));
        }
    }

    /**
     * Serializes document identity and file parameters without applying context or service defaults.
     *
     * @since 2026-11
     */
    @IsTest
    static void documentParametersPreserveCaseFileAndExternalIdentity() {
        User minimumAccessUser = P360_TestDataFactory.createMinimumAccessUser();

        System.runAs(minimumAccessUser) {
            System.Test.startTest();
            P360_CreateDocumentRequestDto request = new P360_CreateDocumentRequestDto();
            request.title = 'Synthetic document';
            request.documentDate = Date.newInstance(2026, 11, 16);
            request.caseNumber = 'synthetic-case-number';
            request.caseExternalId = 'case-123';
            request.externalId = 'document-123';
            request.externalSystem = 'synthetic-system';
            P360_FileParameterDto file = new P360_FileParameterDto();
            file.title = 'attachment';
            file.format = 'txt';
            file.base64Data = 'c3ludGhldGlj';
            request.files = new List<P360_FileParameterDto>{ file };
            Map<String, Object> envelope = (Map<String, Object>) JSON.deserializeUntyped(
                P360_SifRequestSerializer.createDocument(request)
            );
            System.Test.stopTest();

            Map<String, Object> parameter = (Map<String, Object>) envelope.get('parameter');
            System.Assert.areEqual('Synthetic document', parameter.get('Title'));
            System.Assert.areEqual('2026-11-16', parameter.get('DocumentDate'));
            System.Assert.areEqual('synthetic-case-number', parameter.get('CaseNumber'));
            System.Assert.areEqual(
                new Map<String, Object>{ 'Id' => 'case-123', 'Type' => 'synthetic-system' },
                parameter.get('CaseExternalId')
            );
            System.Assert.areEqual(
                new Map<String, Object>{ 'Id' => 'document-123', 'Type' => 'synthetic-system' },
                parameter.get('ExternalId')
            );
            System.Assert.isFalse(parameter.containsKey('ADUserContext'));
            System.Assert.isFalse(parameter.containsKey('Status'));
            Map<String, Object> serializedFile = (Map<String, Object>) ((List<Object>) parameter.get('Files'))[0];
            System.Assert.areEqual('attachment', serializedFile.get('Title'));
            System.Assert.areEqual('txt', serializedFile.get('Format'));
            System.Assert.areEqual('c3ludGhldGlj', serializedFile.get('Base64Data'));
            System.Assert.isFalse(serializedFile.containsKey('UploadedFileReference'));
        }
    }

    /**
     * Omits empty collections and missing identities rather than supplying defaults.
     *
     * @since 2026-11
     */
    @IsTest
    static void emptyCollectionsAndMissingIdentityAreOmitted() {
        User minimumAccessUser = P360_TestDataFactory.createMinimumAccessUser();

        System.runAs(minimumAccessUser) {
            System.Test.startTest();
            P360_CreateCaseRequestDto caseRequest = new P360_CreateCaseRequestDto();
            caseRequest.archiveCodes = new List<P360_ClassCodeParameterDto>();
            caseRequest.externalId = '';
            Map<String, Object> caseEnvelope = (Map<String, Object>) JSON.deserializeUntyped(
                P360_SifRequestSerializer.createCase(caseRequest)
            );
            P360_CreateDocumentRequestDto documentRequest = new P360_CreateDocumentRequestDto();
            documentRequest.files = new List<P360_FileParameterDto>();
            Map<String, Object> documentEnvelope = (Map<String, Object>) JSON.deserializeUntyped(
                P360_SifRequestSerializer.createDocument(documentRequest)
            );
            System.Test.stopTest();

            System.Assert.areEqual(0, ((Map<String, Object>) caseEnvelope.get('parameter')).size());
            System.Assert.areEqual(0, ((Map<String, Object>) documentEnvelope.get('parameter')).size());
        }
    }
}
