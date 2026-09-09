/**
 * Verifies the internal DTO contract for SIF CreateCase requests.
 *
 * @author Kenneth Sørensen
 * @since 2026-09
 * @group P360 DTO
 */
@IsTest
private class P360_CreateCaseRequestDtoTest {
    /**
     * Verifies that CreateCase request fields and archive codes survive JSON round-trip serialization.
     *
     * @since 2026-09
     */
    @IsTest
    static void createCaseRequestPreservesContractFields() {
        User minimumAccessUser = P360_TestDataFactory.createMinimumAccessUser();

        System.runAs(minimumAccessUser) {
            P360_CreateCaseRequestDto request = new P360_CreateCaseRequestDto();
            request.adContextUser = 'no\\sif.integration';
            request.title = 'Aa-registeret case';
            request.unofficialTitle = 'Aa-registeret case short title';
            request.externalId = 'application-123';
            request.externalSystem = 'crm-arbeidsforhold';
            request.startDate = Date.newInstance(2026, 9, 9);
            request.caseType = 'recno:2';
            request.category = 'Leveranse';
            request.status = 'B';
            P360_ClassCodeParameterDto archiveCode = new P360_ClassCodeParameterDto();
            archiveCode.sortOrder = 1;
            archiveCode.archiveType = 'FAGKODE PRINSIPP';
            archiveCode.isManualText = false;
            archiveCode.archiveCode = 'B32';
            request.archiveCodes = new List<P360_ClassCodeParameterDto>{ archiveCode };

            P360_CreateCaseRequestDto roundTrippedRequest = (P360_CreateCaseRequestDto) JSON.deserialize(
                JSON.serialize(request),
                P360_CreateCaseRequestDto.class
            );

            System.Assert.areEqual(
                request.adContextUser,
                roundTrippedRequest.adContextUser,
                'Expected the context user.'
            );
            System.Assert.areEqual(request.title, roundTrippedRequest.title, 'Expected the title.');
            System.Assert.areEqual(request.externalId, roundTrippedRequest.externalId, 'Expected the external id.');
            System.Assert.areEqual(
                request.externalSystem,
                roundTrippedRequest.externalSystem,
                'Expected the external system.'
            );
            System.Assert.areEqual(request.startDate, roundTrippedRequest.startDate, 'Expected the start date.');
            System.Assert.areEqual(request.caseType, roundTrippedRequest.caseType, 'Expected the case type.');
            System.Assert.areEqual(
                request.archiveCodes.size(),
                roundTrippedRequest.archiveCodes.size(),
                'Expected archive codes.'
            );
            System.Assert.areEqual(
                'B32',
                roundTrippedRequest.archiveCodes[0].archiveCode,
                'Expected the archive code value.'
            );
        }
    }

    /**
     * Verifies that CreateCase response fields survive JSON round-trip serialization.
     *
     * @since 2026-09
     */
    @IsTest
    static void createCaseResponsePreservesResultFields() {
        User minimumAccessUser = P360_TestDataFactory.createMinimumAccessUser();

        System.runAs(minimumAccessUser) {
            P360_CreateCaseResponseDto response = new P360_CreateCaseResponseDto();
            response.recno = '600123';
            response.caseNumber = '26/00001';
            response.importedCaseNumber = 'imported-26-00001';
            response.uid = 'uid-26-00001';
            response.uidOrigin = '360';
            response.errorMessage = null;
            response.errorDetails = null;

            P360_CreateCaseResponseDto roundTrippedResponse = (P360_CreateCaseResponseDto) JSON.deserialize(
                JSON.serialize(response),
                P360_CreateCaseResponseDto.class
            );

            System.Assert.areEqual(response.recno, roundTrippedResponse.recno, 'Expected the case recno.');
            System.Assert.areEqual(response.caseNumber, roundTrippedResponse.caseNumber, 'Expected the case number.');
            System.Assert.areEqual(
                response.importedCaseNumber,
                roundTrippedResponse.importedCaseNumber,
                'Expected the imported case number.'
            );
            System.Assert.areEqual(response.uid, roundTrippedResponse.uid, 'Expected the UID.');
            System.Assert.areEqual(response.uidOrigin, roundTrippedResponse.uidOrigin, 'Expected the UID origin.');
        }
    }
}
