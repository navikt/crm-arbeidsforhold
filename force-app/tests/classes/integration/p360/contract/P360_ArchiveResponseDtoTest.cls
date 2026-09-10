/**
 * Verifies the temporary archive response DTO.
 *
 * @author Kenneth Sørensen
 * @since 2026-09
 * @group P360 DTO
 */
@IsTest
private class P360_ArchiveResponseDtoTest {
    /**
     * Verifies that archive response fields survive JSON round-trip serialization.
     *
     * @since 2026-09
     */
    @IsTest
    static void archiveResponsePreservesContractFields() {
        User minimumAccessUser = P360_TestDataFactory.createMinimumAccessUser();

        System.runAs(minimumAccessUser) {
            P360_ArchiveResponseDto response = new P360_ArchiveResponseDto();
            response.success = true;
            response.message = 'Archived';
            response.externalCaseId = 'case-123';
            response.externalDocumentId = 'document-123';

            P360_ArchiveResponseDto roundTrippedResponse = (P360_ArchiveResponseDto) JSON.deserialize(
                JSON.serialize(response),
                P360_ArchiveResponseDto.class
            );

            System.Assert.areEqual(response.success, roundTrippedResponse.success, 'Expected the success flag.');
            System.Assert.areEqual(response.message, roundTrippedResponse.message, 'Expected the message.');
            System.Assert.areEqual(
                response.externalCaseId,
                roundTrippedResponse.externalCaseId,
                'Expected the external case id.'
            );
            System.Assert.areEqual(
                response.externalDocumentId,
                roundTrippedResponse.externalDocumentId,
                'Expected the external document id.'
            );
        }
    }
}
