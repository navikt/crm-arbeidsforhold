/**
 * Verifies the CreateDocument response DTO.
 *
 * @author Kenneth Sørensen
 * @since 2026-09
 * @group P360 DTO
 */
@IsTest
private class P360_CreateDocumentResponseDtoTest {
    /**
     * Verifies that document-operation response fields survive JSON round-trip serialization.
     *
     * @since 2026-09
     */
    @IsTest
    static void createDocumentResponsePreservesContractFields() {
        User minimumAccessUser = P360_TestDataFactory.createMinimumAccessUser();

        System.runAs(minimumAccessUser) {
            P360_CreateDocumentResponseDto response = new P360_CreateDocumentResponseDto();
            response.recno = '700100';
            response.documentNumber = '26/00002';
            response.importedDocumentNumber = 'imported-26-00002';
            response.uid = 'uid-document-002';
            response.uidOrigin = '360';
            response.errorMessage = 'OK';
            response.errorDetails = 'No additional errors';

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
        }
    }
}
