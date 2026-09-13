/**
 * Verifies the controlled behaviour of the P360 code table metadata service.
 *
 * @author Kenneth Sørensen
 * @since 2026-09 K2
 * @group P360 Code Table
 */
@IsTest
private class P360_CodeTableMetadataServiceTest {
    /**
     * Verifies that a missing mapping throws a controlled exception naming the table and key.
     *
     * @since 2026-09
     */
    @IsTest
    static void missingMappingThrowsControlledException() {
        User minimumAccessUser = P360_TestDataFactory.createMinimumAccessUser();
        PermissionSet codeTableAccess = [
            SELECT Id
            FROM PermissionSet
            WHERE Name = 'P360_Code_Table_Access'
            LIMIT 1
        ];
        insert new PermissionSetAssignment(AssigneeId = minimumAccessUser.Id, PermissionSetId = codeTableAccess.Id);

        System.runAs(minimumAccessUser) {
            P360_ICodeTableService service = new P360_CodeTableMetadataService();
            try {
                service.getValue('UnknownTable', 'UnknownKey');
                System.Assert.fail('Expected a missing mapping exception.');
            } catch (P360_MissingCodeTableMappingException ex) {
                System.Assert.isTrue(
                    ex.getMessage().contains('UnknownTable') && ex.getMessage().contains('UnknownKey'),
                    'Expected the exception message to name the table and key.'
                );
            }
        }
    }
}
