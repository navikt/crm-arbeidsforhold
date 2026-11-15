/**
 * Verifies the internal UpdateDocument response contract.
 *
 * @author Kenneth Sørensen
 * @since 2026-11
 * @group P360 DTO
 */
@IsTest
private class P360_UpdateDocumentResponseDtoTest {
    /**
     * Preserves a successful document-operation result through a JSON round trip.
     *
     * @since 2026-11
     */
    @IsTest
    static void successfulResultPreservesDocumentIdentity() {
        User minimumAccessUser = P360_TestDataFactory.createMinimumAccessUser();

        System.runAs(minimumAccessUser) {
            System.Test.startTest();
            P360_UpdateDocumentResponseDto response = new P360_UpdateDocumentResponseDto();
            response.recno = '700123';
            response.documentNumber = '26/00001-1';
            response.successful = true;
            P360_UpdateDocumentResponseDto output = (P360_UpdateDocumentResponseDto) JSON.deserialize(
                JSON.serialize(response),
                P360_UpdateDocumentResponseDto.class
            );
            System.Test.stopTest();

            System.Assert.areEqual('700123', output.recno);
            System.Assert.areEqual('26/00001-1', output.documentNumber);
            System.Assert.areEqual(true, output.successful);
            System.Assert.isNull(output.errorMessage);
            System.Assert.isNull(output.errorDetails);
        }
    }

    /**
     * Preserves an unsuccessful result and its documented error fields.
     *
     * @since 2026-11
     */
    @IsTest
    static void unsuccessfulResultPreservesErrorDetails() {
        User minimumAccessUser = P360_TestDataFactory.createMinimumAccessUser();

        System.runAs(minimumAccessUser) {
            System.Test.startTest();
            P360_UpdateDocumentResponseDto response = new P360_UpdateDocumentResponseDto();
            response.successful = false;
            response.errorMessage = 'Invalid document';
            response.errorDetails = 'Validation failed';
            P360_UpdateDocumentResponseDto output = (P360_UpdateDocumentResponseDto) JSON.deserialize(
                JSON.serialize(response),
                P360_UpdateDocumentResponseDto.class
            );
            System.Test.stopTest();

            System.Assert.areEqual(false, output.successful);
            System.Assert.areEqual('Invalid document', output.errorMessage);
            System.Assert.areEqual('Validation failed', output.errorDetails);
            System.Assert.isNull(output.recno);
            System.Assert.isNull(output.documentNumber);
        }
    }
}
