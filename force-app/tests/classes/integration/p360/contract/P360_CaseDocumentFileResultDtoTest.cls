/**
 * Verifies the SIF CaseDocumentFileResult DTO.
 *
 * @author Kenneth Sørensen
 * @since 2026-09
 * @group P360 DTO
 */
@IsTest
private class P360_CaseDocumentFileResultDtoTest {
    /**
     * Verifies that all documented file-result fields survive JSON round-trip serialization.
     *
     * @since 2026-09
     */
    @IsTest
    static void caseDocumentFileResultPreservesContractFields() {
        User minimumAccessUser = P360_TestDataFactory.createMinimumAccessUser();

        System.runAs(minimumAccessUser) {
            P360_CaseDocumentFileResultDto file = new P360_CaseDocumentFileResultDto();
            file.recno = '800001';
            file.title = 'decision.pdf';
            file.format = 'PDF';
            file.size = 2048;

            P360_CaseDocumentFileResultDto roundTrippedFile = (P360_CaseDocumentFileResultDto) JSON.deserialize(
                JSON.serialize(file),
                P360_CaseDocumentFileResultDto.class
            );

            System.Assert.areEqual(file.recno, roundTrippedFile.recno, 'Expected the file recno.');
            System.Assert.areEqual(file.title, roundTrippedFile.title, 'Expected the file title.');
            System.Assert.areEqual(file.format, roundTrippedFile.format, 'Expected the file format.');
            System.Assert.areEqual(file.size, roundTrippedFile.size, 'Expected the file size.');
        }
    }
}
