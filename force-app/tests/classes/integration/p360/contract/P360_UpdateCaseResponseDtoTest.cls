/**
 * Verifies the UpdateCase response DTO.
 *
 * @author Kenneth Sørensen
 * @since 2026-09
 * @group P360 DTO
 */
@IsTest
private class P360_UpdateCaseResponseDtoTest {
    /**
     * Verifies that update-case response fields survive JSON round-trip serialization.
     *
     * @since 2026-09
     */
    @IsTest
    static void updateCaseResponsePreservesContractFields() {
        User minimumAccessUser = P360_TestDataFactory.createMinimumAccessUser();

        System.runAs(minimumAccessUser) {
            P360_UpdateCaseResponseDto response = new P360_UpdateCaseResponseDto();
            response.recno = '200100';
            response.caseNumber = '26/00005';
            response.successful = true;
            response.errorMessage = 'OK';
            response.errorDetails = 'No additional errors';

            P360_UpdateCaseResponseDto roundTrippedResponse = (P360_UpdateCaseResponseDto) JSON.deserialize(
                JSON.serialize(response),
                P360_UpdateCaseResponseDto.class
            );

            System.Assert.areEqual(response.recno, roundTrippedResponse.recno, 'Expected the case recno.');
            System.Assert.areEqual(response.caseNumber, roundTrippedResponse.caseNumber, 'Expected the case number.');
            System.Assert.areEqual(
                response.successful,
                roundTrippedResponse.successful,
                'Expected the successful flag.'
            );
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
