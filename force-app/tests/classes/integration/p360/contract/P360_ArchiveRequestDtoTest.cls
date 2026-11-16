/**
 * Verifies the temporary archive request DTO.
 *
 * @author Kenneth Sørensen
 * @since 2026-09
 * @group P360 DTO
 */
@IsTest
private class P360_ArchiveRequestDtoTest {
    /**
     * Verifies that archive request fields survive JSON round-trip serialization.
     *
     * @since 2026-09
     */
    @IsTest
    static void archiveRequestPreservesContractFields() {
        User minimumAccessUser = P360_TestDataFactory.createMinimumAccessUser();

        System.runAs(minimumAccessUser) {
            P360_ArchiveRequestDto request = new P360_ArchiveRequestDto();
            request.correlationId = 'corr-123';
            request.externalId = 'doc-ext-123';
            request.title = 'Archive title';

            P360_ArchiveRequestDto roundTrippedRequest = (P360_ArchiveRequestDto) JSON.deserialize(
                JSON.serialize(request),
                P360_ArchiveRequestDto.class
            );

            System.Assert.areEqual(
                request.correlationId,
                roundTrippedRequest.correlationId,
                'Expected the correlation id.'
            );
            System.Assert.areEqual(request.externalId, roundTrippedRequest.externalId, 'Expected the external id.');
            System.Assert.areEqual(request.title, roundTrippedRequest.title, 'Expected the title.');
        }
    }

    /**
     * Preserves the optional nested requests while keeping the existing archive identity.
     *
     * @since 2026-11
     */
    @IsTest
    static void nestedRequestsPreserveIdentityAndExplicitEmptyTitle() {
        User minimumAccessUser = P360_TestDataFactory.createMinimumAccessUser();

        System.runAs(minimumAccessUser) {
            System.Test.startTest();
            P360_ArchiveRequestDto request = new P360_ArchiveRequestDto();
            request.externalId = 'archive-123';
            request.createCase = new P360_CreateCaseRequestDto();
            request.createCase.externalId = 'case-123';
            request.createDocument = new P360_CreateDocumentRequestDto();
            request.createDocument.title = '';
            P360_ArchiveRequestDto result = (P360_ArchiveRequestDto) JSON.deserialize(
                JSON.serialize(request),
                P360_ArchiveRequestDto.class
            );
            System.Test.stopTest();

            System.Assert.areEqual('archive-123', result.externalId);
            System.Assert.areEqual('case-123', result.createCase.externalId);
            System.Assert.areEqual('', result.createDocument.title);
            System.Assert.isNull(result.createDocument.caseNumber, 'The carrier must not fill a case number.');
        }
    }
}
