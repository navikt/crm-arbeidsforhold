/**
 * Verifies the core SIF CaseDocumentResult DTO.
 *
 * @author Kenneth Sørensen
 * @since 2026-09
 * @group P360 DTO
 */
@IsTest
private class P360_CaseDocumentResultDtoTest {
    /**
     * Verifies that document-result fields and nested files survive JSON round-trip serialization.
     *
     * @since 2026-09
     */
    @IsTest
    static void caseDocumentResultPreservesContractFields() {
        User minimumAccessUser = P360_TestDataFactory.createMinimumAccessUser();

        System.runAs(minimumAccessUser) {
            P360_CaseDocumentFileResultDto file = new P360_CaseDocumentFileResultDto();
            file.recno = '800001';
            file.title = 'decision.pdf';

            P360_CaseDocumentResultDto document = new P360_CaseDocumentResultDto();
            document.recno = '700123';
            document.documentNumber = '26/00001-1';
            document.documentTitle = 'Decision document';
            document.importedDocumentNumber = 'imported-26-00001-1';
            document.files = new List<P360_CaseDocumentFileResultDto>{ file };

            P360_CaseDocumentResultDto roundTrippedDocument = (P360_CaseDocumentResultDto) JSON.deserialize(
                JSON.serialize(document),
                P360_CaseDocumentResultDto.class
            );

            System.Assert.areEqual(document.recno, roundTrippedDocument.recno, 'Expected the document recno.');
            System.Assert.areEqual(
                document.documentNumber,
                roundTrippedDocument.documentNumber,
                'Expected the document number.'
            );
            System.Assert.areEqual(
                document.documentTitle,
                roundTrippedDocument.documentTitle,
                'Expected the document title.'
            );
            System.Assert.areEqual(
                document.importedDocumentNumber,
                roundTrippedDocument.importedDocumentNumber,
                'Expected the imported document number.'
            );
            System.Assert.areEqual(1, roundTrippedDocument.files.size(), 'Expected one document file.');
            System.Assert.areEqual(file.title, roundTrippedDocument.files[0].title, 'Expected the nested file title.');
        }
    }
}
