/**
 * Verifies the SIF multi-value additional-field parameter DTO.
 *
 * @author Kenneth Sørensen
 * @since 2026-09
 * @group P360 DTO
 */
@IsTest
private class P360_AdditionalFieldListParameterDtoTest {
    /**
     * Verifies that the documented name and value list survive JSON round-trip serialization.
     *
     * @since 2026-09
     */
    @IsTest
    static void additionalFieldListParameterPreservesContractFields() {
        User minimumAccessUser = P360_TestDataFactory.createMinimumAccessUser();

        System.runAs(minimumAccessUser) {
            P360_AdditionalFieldListParameterDto additionalFields = new P360_AdditionalFieldListParameterDto();
            additionalFields.name = 'CaseStatus';
            additionalFields.value = new List<String>{ 'recno:4', 'recno:5', 'recno:6' };

            P360_AdditionalFieldListParameterDto roundTrippedAdditionalFields = (P360_AdditionalFieldListParameterDto) JSON.deserialize(
                JSON.serialize(additionalFields),
                P360_AdditionalFieldListParameterDto.class
            );

            System.Assert.areEqual(
                additionalFields.name,
                roundTrippedAdditionalFields.name,
                'Expected the field name.'
            );
            System.Assert.areEqual(
                additionalFields.value.size(),
                roundTrippedAdditionalFields.value.size(),
                'Expected the number of field values.'
            );
            for (Integer index = 0; index < additionalFields.value.size(); index++) {
                System.Assert.areEqual(
                    additionalFields.value[index],
                    roundTrippedAdditionalFields.value[index],
                    'Expected the field value at index ' + index + '.'
                );
            }
        }
    }
}
