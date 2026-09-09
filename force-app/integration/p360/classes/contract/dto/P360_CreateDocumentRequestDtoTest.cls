/**
 * Verifies the internal DTO contract for SIF CreateDocument requests and responses.
 *
 * @author Kenneth Sørensen
 * @since 2026-09
 * @group P360 DTO
 */
@IsTest
private class P360_CreateDocumentRequestDtoTest {
    /**
     * Verifies that CreateDocument request fields and file references survive JSON round-trip serialization.
     *
     * @since 2026-09
     */
    @IsTest
    static void createDocumentRequestPreservesContractFields() {
        User minimumAccessUser = P360_TestDataFactory.createMinimumAccessUser();

        System.runAs(minimumAccessUser) {
            P360_FileParameterDto file = new P360_FileParameterDto();
            file.title = 'decision.pdf';
            file.format = 'PDF';
            file.uploadedFileReference = 'file-reference-123';

            P360_CreateDocumentRequestDto request = new P360_CreateDocumentRequestDto();
            request.adUserContext = 'no\\sif.integration';
            request.title = 'Decision document';
            request.documentDate = Date.newInstance(2026, 9, 9);
            request.archive = 'Saksdokument';
            request.category = 'recno:60005';
            request.status = 'recno:1';
            request.caseExternalId = 'application-123';
            request.externalId = 'document-123';
            request.externalSystem = 'crm-arbeidsforhold';
            request.journalDate = Date.newInstance(2026, 9, 12);
            request.dispatchedDate = Date.newInstance(2026, 9, 10);
            request.files = new List<P360_FileParameterDto>{ file };

            P360_CreateDocumentRequestDto roundTrippedRequest = (P360_CreateDocumentRequestDto) JSON.deserialize(
                JSON.serialize(request),
                P360_CreateDocumentRequestDto.class
            );

            System.Assert.areEqual(request.title, roundTrippedRequest.title, 'Expected the document title.');
            System.Assert.areEqual(request.category, roundTrippedRequest.category, 'Expected the category.');
            System.Assert.areEqual(request.status, roundTrippedRequest.status, 'Expected the status.');
            System.Assert.areEqual(
                request.caseExternalId,
                roundTrippedRequest.caseExternalId,
                'Expected the case external id.'
            );
            System.Assert.areEqual(
                request.externalId,
                roundTrippedRequest.externalId,
                'Expected the document external id.'
            );
            System.Assert.areEqual(request.files.size(), roundTrippedRequest.files.size(), 'Expected the file list.');
            System.Assert.areEqual(
                'file-reference-123',
                roundTrippedRequest.files[0].uploadedFileReference,
                'Expected the uploaded file reference.'
            );
        }
    }

    /**
     * Verifies that CreateDocument response fields survive JSON round-trip serialization.
     *
     * @since 2026-09
     */
    @IsTest
    static void createDocumentResponsePreservesResultFields() {
        User minimumAccessUser = P360_TestDataFactory.createMinimumAccessUser();

        System.runAs(minimumAccessUser) {
            P360_CreateDocumentResponseDto response = new P360_CreateDocumentResponseDto();
            response.recno = '700123';
            response.documentNumber = '26/00001-1';
            response.importedDocumentNumber = 'imported-26-00001-1';
            response.uid = 'uid-document-123';
            response.uidOrigin = '360';

            P360_CreateDocumentResponseDto roundTrippedResponse = (P360_CreateDocumentResponseDto) JSON.deserialize(
                JSON.serialize(response),
                P360_CreateDocumentResponseDto.class
            );

            System.Assert.areEqual(response.recno, roundTrippedResponse.recno, 'Expected the document recno.');
            System.Assert.areEqual(
                response.documentNumber,
                roundTrippedResponse.documentNumber,
                'Expected the document number.'
            );
            System.Assert.areEqual(
                response.importedDocumentNumber,
                roundTrippedResponse.importedDocumentNumber,
                'Expected the imported document number.'
            );
            System.Assert.areEqual(response.uid, roundTrippedResponse.uid, 'Expected the UID.');
            System.Assert.areEqual(response.uidOrigin, roundTrippedResponse.uidOrigin, 'Expected the UID origin.');
        }
    }
}
