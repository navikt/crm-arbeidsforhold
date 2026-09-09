/**
 * Verifies the SIF row-permission parameter DTO used by Case and Document contracts.
 *
 * @author Kenneth Sørensen
 * @since 2026-09
 * @group P360 DTO
 */
@IsTest
private class P360_PermissionParameterDtoTest {
    /**
     * Verifies that all documented permission fields survive JSON round-trip serialization.
     *
     * @since 2026-09
     */
    @IsTest
    static void permissionParameterPreservesContractFields() {
        User minimumAccessUser = P360_TestDataFactory.createMinimumAccessUser();

        System.runAs(minimumAccessUser) {
            P360_PermissionParameterDto permission = new P360_PermissionParameterDto();
            permission.accessGroup = 'Restricted';
            permission.contactExternalId = 'contact-123';
            permission.accessLevel = 'Edit';
            permission.grant = true;
            permission.viewFile = true;
            permission.insertFile = true;
            permission.modifyFile = true;
            permission.insertRev = true;
            permission.modifyRev = true;
            permission.insertDoc = true;
            permission.reference = 'SIF';

            P360_PermissionParameterDto roundTrippedPermission = (P360_PermissionParameterDto) JSON.deserialize(
                JSON.serialize(permission),
                P360_PermissionParameterDto.class
            );

            System.Assert.areEqual(
                permission.accessGroup,
                roundTrippedPermission.accessGroup,
                'Expected the access group.'
            );
            System.Assert.areEqual(
                permission.contactExternalId,
                roundTrippedPermission.contactExternalId,
                'Expected the contact external id.'
            );
            System.Assert.areEqual(
                permission.accessLevel,
                roundTrippedPermission.accessLevel,
                'Expected the access level.'
            );
            System.Assert.areEqual(permission.grant, roundTrippedPermission.grant, 'Expected the grant flag.');
            System.Assert.areEqual(
                permission.viewFile,
                roundTrippedPermission.viewFile,
                'Expected the view file flag.'
            );
            System.Assert.areEqual(
                permission.insertFile,
                roundTrippedPermission.insertFile,
                'Expected the insert file flag.'
            );
            System.Assert.areEqual(
                permission.modifyFile,
                roundTrippedPermission.modifyFile,
                'Expected the modify file flag.'
            );
            System.Assert.areEqual(
                permission.insertRev,
                roundTrippedPermission.insertRev,
                'Expected the insert revision flag.'
            );
            System.Assert.areEqual(
                permission.modifyRev,
                roundTrippedPermission.modifyRev,
                'Expected the modify revision flag.'
            );
            System.Assert.areEqual(
                permission.insertDoc,
                roundTrippedPermission.insertDoc,
                'Expected the insert document flag.'
            );
            System.Assert.areEqual(permission.reference, roundTrippedPermission.reference, 'Expected the reference.');
        }
    }
}
