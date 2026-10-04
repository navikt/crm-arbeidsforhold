/**
 * Verifies the SIF GetDocuments response DTO.
 *
 * @author Kenneth Sørensen
 * @since 2026-09
 * @group P360 DTO
 */
@IsTest
private class P360_GetDocumentsResponseDtoTest {
    /**
     * Verifies that a paged GetDocuments response survives JSON round-trip serialization.
     *
     * @since 2026-09
     */
    @IsTest
    static void getDocumentsResponsePreservesContractFields() {
        User minimumAccessUser = P360_TestDataFactory.createMinimumAccessUser();

        System.runAs(minimumAccessUser) {
            P360_GetDocumentsResponseDto response = new P360_GetDocumentsResponseDto();
            response.totalCount = 1;
            response.errorMessage = 'OK';
            response.errorDetails = 'No additional errors';

            P360_DocumentResultDto document = new P360_DocumentResultDto();
            document.recno = '700200';
            document.documentNumber = '26/00002';
            document.title = 'Decision document';
            document.archive = 'Saksdokument';
            document.category = 'Innsendt dokument';
            document.status = 'Journalført';
            document.documentDate = Date.newInstance(2026, 9, 5);
            document.journalDate = Date.newInstance(2026, 9, 10);
            document.caseNumber = '26/00001';
            document.caseExternalId = 'case-123';
            document.externalId = 'document-123';

            P360_DocumentFileResultDto file = new P360_DocumentFileResultDto();
            file.recno = '800100';
            file.title = 'Decision attachment';
            file.format = 'pdf';
            file.size = 24567;
            document.files = new List<P360_DocumentFileResultDto>{ file };

            response.documents = new List<P360_DocumentResultDto>{ document };

            P360_GetDocumentsResponseDto roundTrippedResponse = (P360_GetDocumentsResponseDto) JSON.deserialize(
                JSON.serialize(response),
                P360_GetDocumentsResponseDto.class
            );

            System.Assert.areEqual(response.totalCount, roundTrippedResponse.totalCount, 'Expected the total count.');
            System.Assert.areEqual(
                response.errorMessage,
                roundTrippedResponse.errorMessage,
                'Expected the error message.'
            );
            System.Assert.areEqual(
                response.errorDetails,
                roundTrippedResponse.errorDetails,
                'Expected the error details.'
            );
            System.Assert.areEqual(
                response.documents.size(),
                roundTrippedResponse.documents.size(),
                'Expected the document count.'
            );
            System.Assert.areEqual(
                response.documents[0].documentNumber,
                roundTrippedResponse.documents[0].documentNumber,
                'Expected the document number.'
            );
            System.Assert.areEqual(
                response.documents[0].files[0].title,
                roundTrippedResponse.documents[0].files[0].title,
                'Expected the nested file title.'
            );
        }
    }
}
