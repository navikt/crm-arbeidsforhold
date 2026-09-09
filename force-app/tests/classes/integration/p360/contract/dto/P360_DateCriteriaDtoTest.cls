/**
 * Verifies the SIF DateCriteriaType DTO used by GetCases.
 *
 * @author Kenneth Sørensen
 * @since 2026-09
 * @group P360 DTO
 */
@IsTest
private class P360_DateCriteriaDtoTest {
    /**
     * Verifies that all documented date-criteria fields survive JSON round-trip serialization.
     *
     * @since 2026-09
     */
    @IsTest
    static void dateCriteriaPreservesContractFields() {
        User minimumAccessUser = P360_TestDataFactory.createMinimumAccessUser();

        System.runAs(minimumAccessUser) {
            P360_DateCriteriaDto criteria = new P360_DateCriteriaDto();
            criteria.dateName = 'ModifiedDate';
            criteria.operator = 'GT=';
            criteria.dateValue = Date.newInstance(2026, 9, 9);

            P360_DateCriteriaDto roundTrippedCriteria = (P360_DateCriteriaDto) JSON.deserialize(
                JSON.serialize(criteria),
                P360_DateCriteriaDto.class
            );

            System.Assert.areEqual(criteria.dateName, roundTrippedCriteria.dateName, 'Expected the date name.');
            System.Assert.areEqual(criteria.operator, roundTrippedCriteria.operator, 'Expected the operator.');
            System.Assert.areEqual(criteria.dateValue, roundTrippedCriteria.dateValue, 'Expected the date value.');
        }
    }
}
