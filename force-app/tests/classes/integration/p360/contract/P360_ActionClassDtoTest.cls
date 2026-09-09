/**
 * Verifies the SIF ActionClass result DTO used by CaseContactResult.
 *
 * @author Kenneth Sørensen
 * @since 2026-09
 * @group P360 DTO
 */
@IsTest
private class P360_ActionClassDtoTest {
    /**
     * Verifies that all documented action-class fields survive JSON round-trip serialization.
     *
     * @since 2026-09
     */
    @IsTest
    static void actionClassPreservesContractFields() {
        User minimumAccessUser = P360_TestDataFactory.createMinimumAccessUser();

        System.runAs(minimumAccessUser) {
            P360_ActionClassDto actionClass = new P360_ActionClassDto();
            actionClass.code = 'ACT';
            actionClass.description = 'Follow-up';
            actionClass.recno = '400001';

            P360_ActionClassDto roundTrippedActionClass = (P360_ActionClassDto) JSON.deserialize(
                JSON.serialize(actionClass),
                P360_ActionClassDto.class
            );

            System.Assert.areEqual(actionClass.code, roundTrippedActionClass.code, 'Expected the action-class code.');
            System.Assert.areEqual(
                actionClass.description,
                roundTrippedActionClass.description,
                'Expected the action-class description.'
            );
            System.Assert.areEqual(
                actionClass.recno,
                roundTrippedActionClass.recno,
                'Expected the action-class recno.'
            );
        }
    }
}
