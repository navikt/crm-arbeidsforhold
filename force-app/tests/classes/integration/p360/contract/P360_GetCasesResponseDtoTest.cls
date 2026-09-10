/**
 * Verifies the SIF GetCases response DTO.
 *
 * @author Kenneth Sørensen
 * @since 2026-09
 * @group P360 DTO
 */
@IsTest
private class P360_GetCasesResponseDtoTest {
    /**
     * Verifies that a paged GetCases response survives JSON round-trip serialization.
     *
     * @since 2026-09
     */
    @IsTest
    static void getCasesResponsePreservesContractFields() {
        User minimumAccessUser = P360_TestDataFactory.createMinimumAccessUser();

        System.runAs(minimumAccessUser) {
            P360_GetCasesResponseDto response = new P360_GetCasesResponseDto();
            response.totalCount = 1;
            response.errorMessage = 'OK';
            response.errorDetails = 'No additional errors';

            P360_CaseResultDto aCase = new P360_CaseResultDto();
            aCase.recno = '200100';
            aCase.title = 'Decision request';
            aCase.caseNumber = '26/00005';
            aCase.externalId = 'case-005';
            aCase.startDate = Date.newInstance(2026, 9, 1);
            aCase.statusDescription = 'Under behandling';
            aCase.responsibleEnterpriseName = 'Example Enterprise';
            aCase.responsiblePersonName = 'Ola Nordmann';
            aCase.lastChangedDate = Date.newInstance(2026, 9, 10);
            aCase.uid = 'uid-case-005';
            aCase.uidOrigin = '360';
            response.cases = new List<P360_CaseResultDto>{ aCase };

            P360_GetCasesResponseDto roundTrippedResponse = (P360_GetCasesResponseDto) JSON.deserialize(
                JSON.serialize(response),
                P360_GetCasesResponseDto.class
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
                response.cases.size(),
                roundTrippedResponse.cases.size(),
                'Expected the case count.'
            );
            System.Assert.areEqual(
                response.cases[0].caseNumber,
                roundTrippedResponse.cases[0].caseNumber,
                'Expected the case number.'
            );
            System.Assert.areEqual(
                response.cases[0].statusDescription,
                roundTrippedResponse.cases[0].statusDescription,
                'Expected the status description.'
            );
            System.Assert.areEqual(response.cases[0].uid, roundTrippedResponse.cases[0].uid, 'Expected the UID.');
        }
    }
}
