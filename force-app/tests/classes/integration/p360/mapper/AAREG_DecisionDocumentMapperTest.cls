/**
 * Verifies Salesforce decision mapping to the P360 outgoing decision document request.
 *
 * @author Kenneth Sørensen
 * @since 2026-09
 * @group P360 Mapper
 */
@IsTest
private class AAREG_DecisionDocumentMapperTest {
    /**
     * Verifies that a decision document uses approved outgoing-document defaults and preserves identity fields.
     *
     * @since 2026-09
     */
    @IsTest
    static void mapsDecisionDocumentToCreateDocumentRequest() {
        User minimumAccessUser = P360_TestDataFactory.createMinimumAccessUser();
        PermissionSet codeTableAccess = [
            SELECT Id
            FROM PermissionSet
            WHERE Name = 'P360_Code_Table_Access'
            LIMIT 1
        ];
        insert new PermissionSetAssignment(AssigneeId = minimumAccessUser.Id, PermissionSetId = codeTableAccess.Id);

        System.runAs(minimumAccessUser) {
            AAREG_DecisionToP360DocumentMapper.Input input = new AAREG_DecisionToP360DocumentMapper.Input();
            input.title = 'Vedtak - Tilgang til Aa-registeret - S111001';
            input.documentDate = Date.newInstance(2024, 12, 8);
            input.caseNumber = '25/204';
            input.externalId = 'S111001-decision-document';
            input.externalSystem = 'crm-arbeidsforhold';

            P360_CreateDocumentRequestDto request = new AAREG_DecisionToP360DocumentMapper(
                    new P360_CodeTableMetadataService()
                )
                .mapToCreateDocument(input);

            System.Assert.areEqual(input.title, request.title, 'Expected the decision title.');
            System.Assert.areEqual(input.documentDate, request.documentDate, 'Expected the decision document date.');
            System.Assert.areEqual(input.caseNumber, request.caseNumber, 'Expected the case number.');
            System.Assert.areEqual(input.externalId, request.externalId, 'Expected the external document id.');
            System.Assert.areEqual('Sak', request.archive, 'Expected the approved decision archive.');
            System.Assert.areEqual('Dokument ut', request.category, 'Expected the approved decision category.');
            System.Assert.areEqual('J', request.status, 'Expected the approved journal status.');
            System.Assert.areEqual('U', request.accessCode, 'Expected the approved access code.');
            System.Assert.areEqual('Alle ansatte i Nav', request.accessGroup, 'Expected the approved access group.');
            System.Assert.isNull(request.files, 'Expected file transport to remain a separate slice.');
        }
    }
}
