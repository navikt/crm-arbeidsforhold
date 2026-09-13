/**
 * Verifies Salesforce application context mapping to the P360 CreateCase request.
 *
 * @author Kenneth Sørensen
 * @since 2026-09
 * @group P360 Mapper
 */
@IsTest
private class AAREG_ApplicationToP360CaseMapperTest {
    /**
     * Verifies that application input and approved Default code-table values produce a complete case request.
     *
     * @since 2026-09
     */
    @IsTest
    static void mapsApplicationContextToCreateCaseRequest() {
        User minimumAccessUser = P360_TestDataFactory.createMinimumAccessUser();
        PermissionSet codeTableAccess = [
            SELECT Id
            FROM PermissionSet
            WHERE Name = 'P360_Code_Table_Access'
            LIMIT 1
        ];
        insert new PermissionSetAssignment(AssigneeId = minimumAccessUser.Id, PermissionSetId = codeTableAccess.Id);

        System.runAs(minimumAccessUser) {
            AAREG_ApplicationToP360CaseMapper.Input input = new AAREG_ApplicationToP360CaseMapper.Input();
            input.title = 'Søknad - tilgang til Aa-registeret - S111001';
            input.externalId = 'S111001';
            input.externalSystem = 'crm-arbeidsforhold';

            P360_CreateCaseRequestDto request = new AAREG_ApplicationToP360CaseMapper(
                    new P360_CodeTableMetadataService()
                )
                .mapToCreateCase(input);

            System.Assert.areEqual(input.title, request.title, 'Expected the application title.');
            System.Assert.areEqual(input.externalId, request.externalId, 'Expected the external application id.');
            System.Assert.areEqual(input.externalSystem, request.externalSystem, 'Expected the source system.');
            System.Assert.areEqual(
                'Aa-registerSalesForce',
                request.defaultValueSet,
                'Expected the approved value set.'
            );
            System.Assert.areEqual('B', request.status, 'Expected the approved case status.');
            System.Assert.areEqual('Sak', request.caseType, 'Expected the approved case type.');
            System.Assert.areEqual('U', request.accessCode, 'Expected the approved access code.');
            System.Assert.areEqual('Alle ansatte i Nav', request.accessGroup, 'Expected the approved access group.');
            System.Assert.areEqual(
                'bu700k',
                request.responsibleEnterpriseNumber,
                'Expected the approved responsible enterprise.'
            );
            System.Assert.areEqual(1, request.archiveCodes.size(), 'Expected one primary archive code.');
            System.Assert.areEqual('359', request.archiveCodes[0].archiveCode, 'Expected the approved archive code.');
            System.Assert.areEqual(
                1,
                request.archiveCodes[0].sortOrder,
                'Expected the primary archive-code sort order.'
            );
        }
    }
}
