/**
 * Verifies the SIF class-code parameter DTO.
 *
 * @author Kenneth Sørensen
 * @since 2026-09
 * @group P360 DTO
 */
@IsTest
private class P360_ClassCodeParameterDtoTest {
    /**
     * Verifies that class-code parameters survive JSON round-trip serialization.
     *
     * @since 2026-09
     */
    @IsTest
    static void classCodeParameterPreservesContractFields() {
        User minimumAccessUser = P360_TestDataFactory.createMinimumAccessUser();

        System.runAs(minimumAccessUser) {
            P360_ClassCodeParameterDto parameter = new P360_ClassCodeParameterDto();
            parameter.sortOrder = 1;
            parameter.archiveType = 'MainArchive';
            parameter.isManualText = false;
            parameter.archiveCode = 'SAKS';

            P360_ClassCodeParameterDto roundTrippedParameter = (P360_ClassCodeParameterDto) JSON.deserialize(
                JSON.serialize(parameter),
                P360_ClassCodeParameterDto.class
            );

            System.Assert.areEqual(parameter.sortOrder, roundTrippedParameter.sortOrder, 'Expected the sort order.');
            System.Assert.areEqual(
                parameter.archiveType,
                roundTrippedParameter.archiveType,
                'Expected the archive type.'
            );
            System.Assert.areEqual(
                parameter.isManualText,
                roundTrippedParameter.isManualText,
                'Expected the manual text flag.'
            );
            System.Assert.areEqual(
                parameter.archiveCode,
                roundTrippedParameter.archiveCode,
                'Expected the archive code.'
            );
        }
    }
}
