/**
 * Verifies the SIF GetDocumentsQuery DTO.
 *
 * @author Kenneth Sørensen
 * @since 2026-09
 * @group P360 DTO
 */
@IsTest
private class P360_GetDocumentsRequestDtoTest {
    /**
     * Verifies that GetDocuments query fields survive JSON round-trip serialization.
     *
     * @since 2026-09
     */
    @IsTest
    static void getDocumentsRequestPreservesCoreQueryFields() {
        User minimumAccessUser = P360_TestDataFactory.createMinimumAccessUser();

        System.runAs(minimumAccessUser) {
            P360_GetDocumentsRequestDto request = new P360_GetDocumentsRequestDto();
            request.adContextUser = 'no\\sif.integration';
            request.maxReturnedDocuments = 50;
            request.page = 3;
            request.sortCriterion = 'RecnoDescending';
            request.documentNumber = '26/00002';
            request.title = '%decision%';
            request.documentArchive = 'Saksdokument';
            request.caseNumber = '26/00001';
            request.caseExternalId = 'case-123';
            request.externalSystem = 'crm-arbeidsforhold';
            request.lastDate = Date.newInstance(2026, 9, 9);
            request.contactReferenceNumber = '123456789';
            request.contactExternalId = 'person-456';
            request.includeFileMetadata = true;
            request.onlyPublicInfo = true;

            P360_GetDocumentsRequestDto roundTrippedRequest = (P360_GetDocumentsRequestDto) JSON.deserialize(
                JSON.serialize(request),
                P360_GetDocumentsRequestDto.class
            );

            System.Assert.areEqual(
                request.adContextUser,
                roundTrippedRequest.adContextUser,
                'Expected the context user.'
            );
            System.Assert.areEqual(
                request.maxReturnedDocuments,
                roundTrippedRequest.maxReturnedDocuments,
                'Expected the maximum result count.'
            );
            System.Assert.areEqual(request.page, roundTrippedRequest.page, 'Expected the page.');
            System.Assert.areEqual(
                request.sortCriterion,
                roundTrippedRequest.sortCriterion,
                'Expected the sort criterion.'
            );
            System.Assert.areEqual(
                request.documentNumber,
                roundTrippedRequest.documentNumber,
                'Expected the document number.'
            );
            System.Assert.areEqual(request.title, roundTrippedRequest.title, 'Expected the title.');
            System.Assert.areEqual(
                request.documentArchive,
                roundTrippedRequest.documentArchive,
                'Expected the document archive.'
            );
            System.Assert.areEqual(request.caseNumber, roundTrippedRequest.caseNumber, 'Expected the case number.');
            System.Assert.areEqual(
                request.caseExternalId,
                roundTrippedRequest.caseExternalId,
                'Expected the case external id.'
            );
            System.Assert.areEqual(
                request.externalSystem,
                roundTrippedRequest.externalSystem,
                'Expected the external system.'
            );
            System.Assert.areEqual(request.lastDate, roundTrippedRequest.lastDate, 'Expected the last date.');
            System.Assert.areEqual(
                request.contactReferenceNumber,
                roundTrippedRequest.contactReferenceNumber,
                'Expected the contact reference number.'
            );
            System.Assert.areEqual(
                request.contactExternalId,
                roundTrippedRequest.contactExternalId,
                'Expected the contact external id.'
            );
            System.Assert.areEqual(
                request.includeFileMetadata,
                roundTrippedRequest.includeFileMetadata,
                'Expected the file metadata flag.'
            );
            System.Assert.areEqual(
                request.onlyPublicInfo,
                roundTrippedRequest.onlyPublicInfo,
                'Expected the public information flag.'
            );
        }
    }
}
