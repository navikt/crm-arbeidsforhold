/**
 * Tests temporary P360 archive DTO field behavior.
 *
 * @author Kenneth Sørensen
 * @since 2026-04 F2 foundation
 * @group P360 DTO
 */
@IsTest
private class P360_ArchiveDtoTest {
    /**
     * Verifies that all archive request fields can be set and read.
     */
    @IsTest
    static void archiveRequestFieldsCanBeSetAndRead() {
        P360_ArchiveRequestDto request = new P360_ArchiveRequestDto();

        System.Test.startTest();
        request.correlationId = 'corr-123';
        request.externalId = 'external-123';
        request.title = 'Archive title';
        System.Test.stopTest();

        System.Assert.areEqual('corr-123', request.correlationId, 'Unexpected correlation id.');
        System.Assert.areEqual('external-123', request.externalId, 'Unexpected external id.');
        System.Assert.areEqual('Archive title', request.title, 'Unexpected title.');
    }

    /**
     * Verifies that all archive response fields can be set and read.
     */
    @IsTest
    static void archiveResponseFieldsCanBeSetAndRead() {
        P360_ArchiveResponseDto response = new P360_ArchiveResponseDto();

        System.Test.startTest();
        response.success = true;
        response.message = 'OK';
        response.externalCaseId = 'case-123';
        response.externalDocumentId = 'document-123';
        System.Test.stopTest();

        System.Assert.areEqual(true, response.success, 'Unexpected success value.');
        System.Assert.areEqual('OK', response.message, 'Unexpected message.');
        System.Assert.areEqual('case-123', response.externalCaseId, 'Unexpected external case id.');
        System.Assert.areEqual('document-123', response.externalDocumentId, 'Unexpected external document id.');
    }
}
