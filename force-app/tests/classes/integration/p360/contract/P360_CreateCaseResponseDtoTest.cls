/**
 * Verifies the CreateCase response DTO.
 *
 * @author Kenneth Sørensen
 * @since 2026-09
 * @group P360 DTO
 */
@IsTest
private class P360_CreateCaseResponseDtoTest {
    /**
     * Verifies that case-operation response fields survive JSON round-trip serialization.
     *
     * @since 2026-09
     */
    @IsTest
    static void createCaseResponsePreservesContractFields() {
        User minimumAccessUser = P360_TestDataFactory.createMinimumAccessUser();

        System.runAs(minimumAccessUser) {
            P360_CreateCaseResponseDto response = new P360_CreateCaseResponseDto();
            response.recno = '200100';
            response.caseNumber = '26/00005';
            response.importedCaseNumber = 'imported-26-00005';
            response.uid = 'uid-case-005';
            response.uidOrigin = '360';
            response.errorMessage = 'OK';
            response.errorDetails = 'No additional errors';

            P360_CreateCaseResponseDto roundTrippedResponse = (P360_CreateCaseResponseDto) JSON.deserialize(
                JSON.serialize(response),
                P360_CreateCaseResponseDto.class
            );

            System.Assert.areEqual(response.recno, roundTrippedResponse.recno, 'Expected the case recno.');
            System.Assert.areEqual(response.caseNumber, roundTrippedResponse.caseNumber, 'Expected the case number.');
            System.Assert.areEqual(
                response.importedCaseNumber,
                roundTrippedResponse.importedCaseNumber,
                'Expected the imported case number.'
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
