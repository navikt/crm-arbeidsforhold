/**
 * Tests AAREG_ArchiveApplicationResult field behavior.
 *
 * @author Kenneth Sørensen
 * @since 2026-04 F2 foundation
 * @group AAREG P360 Orchestration
 */
@IsTest
private class AAREG_ArchiveApplicationResultTest {
    /**
     * Verifies that all result fields can be set and read.
     */
    @IsTest
    static void fieldsCanBeSetAndRead() {
        AAREG_ArchiveApplicationResult result = new AAREG_ArchiveApplicationResult();

        System.Test.startTest();
        result.success = true;
        result.message = 'Archived';
        result.correlationId = 'corr-123';
        result.externalCaseId = 'case-123';
        result.externalDocumentId = 'document-123';
        System.Test.stopTest();

        System.Assert.areEqual(true, result.success, 'Unexpected success value.');
        System.Assert.areEqual('Archived', result.message, 'Unexpected message.');
        System.Assert.areEqual('corr-123', result.correlationId, 'Unexpected correlation id.');
        System.Assert.areEqual('case-123', result.externalCaseId, 'Unexpected external case id.');
        System.Assert.areEqual('document-123', result.externalDocumentId, 'Unexpected external document id.');
    }
}
