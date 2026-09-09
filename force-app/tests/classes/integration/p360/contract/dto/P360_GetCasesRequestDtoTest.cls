/**
 * Verifies the core SIF GetCasesQuery DTO.
 *
 * @author Kenneth Sørensen
 * @since 2026-09
 * @group P360 DTO
 */
@IsTest
private class P360_GetCasesRequestDtoTest {
    /**
     * Verifies that GetCases query fields survive JSON round-trip serialization.
     *
     * @since 2026-09
     */
    @IsTest
    static void getCasesRequestPreservesCoreQueryFields() {
        User minimumAccessUser = P360_TestDataFactory.createMinimumAccessUser();

        System.runAs(minimumAccessUser) {
            P360_GetCasesRequestDto request = createRequest();

            P360_GetCasesRequestDto roundTrippedRequest = (P360_GetCasesRequestDto) JSON.deserialize(
                JSON.serialize(request),
                P360_GetCasesRequestDto.class
            );

            System.Assert.areEqual(
                request.adContextUser,
                roundTrippedRequest.adContextUser,
                'Expected the context user.'
            );
            System.Assert.areEqual(
                request.maxReturnedCases,
                roundTrippedRequest.maxReturnedCases,
                'Expected the maximum result count.'
            );
            System.Assert.areEqual(request.page, roundTrippedRequest.page, 'Expected the page.');
            System.Assert.areEqual(
                request.sortCriterion,
                roundTrippedRequest.sortCriterion,
                'Expected the sort criterion.'
            );
            System.Assert.areEqual(request.recno, roundTrippedRequest.recno, 'Expected the recno.');
            System.Assert.areEqual(request.caseNumber, roundTrippedRequest.caseNumber, 'Expected the case number.');
            System.Assert.areEqual(request.externalId, roundTrippedRequest.externalId, 'Expected the external id.');
            System.Assert.areEqual(
                request.externalSystem,
                roundTrippedRequest.externalSystem,
                'Expected the external system.'
            );
            System.Assert.areEqual(request.title, roundTrippedRequest.title, 'Expected the title.');
            System.Assert.areEqual(request.archiveCode, roundTrippedRequest.archiveCode, 'Expected the archive code.');
            System.Assert.areEqual(
                request.projectNumber,
                roundTrippedRequest.projectNumber,
                'Expected the project number.'
            );
            System.Assert.areEqual(
                request.categoryCode,
                roundTrippedRequest.categoryCode,
                'Expected the category code.'
            );
            System.Assert.areEqual(request.lastDate, roundTrippedRequest.lastDate, 'Expected the last date.');
            System.Assert.areEqual(request.subArchive, roundTrippedRequest.subArchive, 'Expected the subarchive.');
            System.Assert.areEqual(request.caseType, roundTrippedRequest.caseType, 'Expected the case type.');
            System.Assert.areEqual(
                request.onlyPublicInfo,
                roundTrippedRequest.onlyPublicInfo,
                'Expected the public-information flag.'
            );
            System.Assert.areEqual(
                request.includeReferringCases,
                roundTrippedRequest.includeReferringCases,
                'Expected the referring-cases flag.'
            );
            System.Assert.areEqual(
                request.includeReferringDocuments,
                roundTrippedRequest.includeReferringDocuments,
                'Expected the referring-documents flag.'
            );
            System.Assert.areEqual(
                request.includeCaseContacts,
                roundTrippedRequest.includeCaseContacts,
                'Expected the case-contacts flag.'
            );
        }
    }

    /**
     * Verifies that GetCases result flags and date criteria survive JSON round-trip serialization.
     *
     * @since 2026-09
     */
    @IsTest
    static void getCasesRequestPreservesResultOptions() {
        User minimumAccessUser = P360_TestDataFactory.createMinimumAccessUser();

        System.runAs(minimumAccessUser) {
            P360_GetCasesRequestDto request = createRequest();
            P360_GetCasesRequestDto roundTrippedRequest = (P360_GetCasesRequestDto) JSON.deserialize(
                JSON.serialize(request),
                P360_GetCasesRequestDto.class
            );

            System.Assert.areEqual(
                request.dateCriteria.dateName,
                roundTrippedRequest.dateCriteria.dateName,
                'Expected the date criteria name.'
            );
            System.Assert.areEqual(
                request.dateCriteria.operator,
                roundTrippedRequest.dateCriteria.operator,
                'Expected the date criteria operator.'
            );
            System.Assert.areEqual(
                request.dateCriteria.dateValue,
                roundTrippedRequest.dateCriteria.dateValue,
                'Expected the date criteria value.'
            );
            System.Assert.areEqual(
                request.onlyPublicInfo,
                roundTrippedRequest.onlyPublicInfo,
                'Expected the public-information flag.'
            );
            System.Assert.areEqual(
                request.includeReferringCases,
                roundTrippedRequest.includeReferringCases,
                'Expected the referring-cases flag.'
            );
            System.Assert.areEqual(
                request.includeReferringDocuments,
                roundTrippedRequest.includeReferringDocuments,
                'Expected the referring-documents flag.'
            );
            System.Assert.areEqual(
                request.includeCaseContacts,
                roundTrippedRequest.includeCaseContacts,
                'Expected the case-contacts flag.'
            );
        }
    }

    private static P360_GetCasesRequestDto createRequest() {
        P360_GetCasesRequestDto request = new P360_GetCasesRequestDto();
        request.adContextUser = 'no\\sif.integration';
        request.maxReturnedCases = 25;
        request.page = 2;
        request.sortCriterion = 'RecnoDescending';
        request.recno = '700123';
        request.caseNumber = '26/00001';
        request.externalId = 'case-123';
        request.externalSystem = 'crm-arbeidsforhold';
        request.title = '%employment%';
        request.archiveCode = 'AAREG';
        request.projectNumber = '13-37';
        request.categoryCode = 'Leveranse';
        request.lastDate = Date.newInstance(2026, 9, 9);
        request.subArchive = 'Sakarkiv';
        request.caseType = 'Sak';
        request.dateCriteria = new P360_DateCriteriaDto();
        request.dateCriteria.dateName = 'ModifiedDate';
        request.dateCriteria.operator = 'GT=';
        request.dateCriteria.dateValue = Date.newInstance(2026, 9, 1);
        request.onlyPublicInfo = true;
        request.includeReferringCases = true;
        request.includeReferringDocuments = true;
        request.includeCaseContacts = true;
        return request;
    }
}
