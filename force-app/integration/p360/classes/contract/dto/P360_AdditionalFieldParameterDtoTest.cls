/**
 * Verifies the SIF single-value additional-field parameter DTO.
 *
 * @author Kenneth Sørensen
 * @since 2026-09
 * @group P360 DTO
 */
@IsTest
private class P360_AdditionalFieldParameterDtoTest {
    /**
     * Verifies that all documented additional-field parameter fields survive JSON round-trip serialization.
     *
     * @since 2026-09
     */
    @IsTest
    static void additionalFieldParameterPreservesContractFields() {
        User minimumAccessUser = P360_TestDataFactory.createMinimumAccessUser();

        System.runAs(minimumAccessUser) {
            P360_AdditionalFieldParameterDto additionalField = new P360_AdditionalFieldParameterDto();
            additionalField.name = 'DocumentNumber';
            additionalField.value = '26/00001-1';
            additionalField.operatorType = '=';

            P360_AdditionalFieldParameterDto roundTrippedAdditionalField = (P360_AdditionalFieldParameterDto) JSON.deserialize(
                JSON.serialize(additionalField),
                P360_AdditionalFieldParameterDto.class
            );

            System.Assert.areEqual(additionalField.name, roundTrippedAdditionalField.name, 'Expected the field name.');
            System.Assert.areEqual(
                additionalField.value,
                roundTrippedAdditionalField.value,
                'Expected the field value.'
            );
            System.Assert.areEqual(
                additionalField.operatorType,
                roundTrippedAdditionalField.operatorType,
                'Expected the operator type.'
            );
        }
    }
}
