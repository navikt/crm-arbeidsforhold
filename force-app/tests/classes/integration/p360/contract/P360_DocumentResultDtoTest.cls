/**
 * Verifies the SIF DocumentResult DTO used by GetDocuments.
 *
 * @author Kenneth Sørensen
 * @since 2026-09
 * @group P360 DTO
 */
@IsTest
private class P360_DocumentResultDtoTest {
    /**
     * Verifies that document metadata fields survive JSON round-trip serialization.
     *
     * @since 2026-09
     */
    @IsTest
    static void documentResultPreservesContractFields() {
        User minimumAccessUser = P360_TestDataFactory.createMinimumAccessUser();

        System.runAs(minimumAccessUser) {
            P360_DocumentResultDto document = new P360_DocumentResultDto();
            document.recno = '700200';
            document.documentNumber = '26/00002';
            document.title = 'Decision document';
            document.archive = 'Saksdokument';
            document.category = 'Innsendt dokument';
            document.status = 'Journalført';
            document.documentDate = Date.newInstance(2026, 9, 5);
            document.journalDate = Date.newInstance(2026, 9, 10);
            document.caseNumber = '26/00001';
            document.caseExternalId = 'case-123';
            document.externalId = 'document-123';
            document.uid = 'uid-document-456';
            document.uidOrigin = '360';

            P360_DocumentResultDto roundTrippedDocument = (P360_DocumentResultDto) JSON.deserialize(
                JSON.serialize(document),
                P360_DocumentResultDto.class
            );

            System.Assert.areEqual(document.recno, roundTrippedDocument.recno, 'Expected the document recno.');
            System.Assert.areEqual(
                document.documentNumber,
                roundTrippedDocument.documentNumber,
                'Expected the document number.'
            );
            System.Assert.areEqual(document.title, roundTrippedDocument.title, 'Expected the document title.');
            System.Assert.areEqual(document.archive, roundTrippedDocument.archive, 'Expected the archive.');
            System.Assert.areEqual(document.category, roundTrippedDocument.category, 'Expected the category.');
            System.Assert.areEqual(document.status, roundTrippedDocument.status, 'Expected the status.');
            System.Assert.areEqual(
                document.documentDate,
                roundTrippedDocument.documentDate,
                'Expected the document date.'
            );
            System.Assert.areEqual(
                document.journalDate,
                roundTrippedDocument.journalDate,
                'Expected the journal date.'
            );
            System.Assert.areEqual(document.caseNumber, roundTrippedDocument.caseNumber, 'Expected the case number.');
            System.Assert.areEqual(
                document.caseExternalId,
                roundTrippedDocument.caseExternalId,
                'Expected the case external id.'
            );
            System.Assert.areEqual(document.externalId, roundTrippedDocument.externalId, 'Expected the external id.');
            System.Assert.areEqual(document.uid, roundTrippedDocument.uid, 'Expected the UID.');
            System.Assert.areEqual(document.uidOrigin, roundTrippedDocument.uidOrigin, 'Expected the UID origin.');
        }
    }
}
