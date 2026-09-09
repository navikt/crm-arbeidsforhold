/**
 * Verifies the core SIF UpdateCaseParameter DTO.
 *
 * @author Kenneth Sørensen
 * @since 2026-09
 * @group P360 DTO
 */
@IsTest
private class P360_UpdateCaseRequestDtoTest {
    /**
     * Verifies that UpdateCase identity, core fields and control flags survive JSON round-trip serialization.
     *
     * @since 2026-09
     */
    @IsTest
    static void updateCaseRequestPreservesCoreContractFields() {
        User minimumAccessUser = P360_TestDataFactory.createMinimumAccessUser();

        System.runAs(minimumAccessUser) {
            P360_UpdateCaseRequestDto request = new P360_UpdateCaseRequestDto();
            request.adContextUser = 'no\\sif.integration';
            request.caseNumber = '26/00001';
            request.externalId = 'case-123';
            request.externalSystem = 'crm-arbeidsforhold';
            request.title = 'Updated case title';
            request.unofficialTitle = 'Screened case title';
            request.startDate = Date.newInstance(2026, 9, 9);
            request.status = 'recno:2';
            request.journalUnit = 'Sentralarkiv';
            request.subArchive = 'Sakarkiv';
            request.filedOnPaper = false;
            request.removeResponsiblePerson = true;
            request.syncCaseContacts = true;
            request.syncCaseEstates = true;
            request.syncArchiveCodes = true;

            P360_UpdateCaseRequestDto roundTrippedRequest = (P360_UpdateCaseRequestDto) JSON.deserialize(
                JSON.serialize(request),
                P360_UpdateCaseRequestDto.class
            );

            System.Assert.areEqual(
                request.adContextUser,
                roundTrippedRequest.adContextUser,
                'Expected the context user.'
            );
            System.Assert.areEqual(request.caseNumber, roundTrippedRequest.caseNumber, 'Expected the case number.');
            System.Assert.areEqual(request.externalId, roundTrippedRequest.externalId, 'Expected the external id.');
            System.Assert.areEqual(
                request.externalSystem,
                roundTrippedRequest.externalSystem,
                'Expected the external system.'
            );
            System.Assert.areEqual(request.title, roundTrippedRequest.title, 'Expected the title.');
            System.Assert.areEqual(
                request.unofficialTitle,
                roundTrippedRequest.unofficialTitle,
                'Expected the unofficial title.'
            );
            System.Assert.areEqual(request.startDate, roundTrippedRequest.startDate, 'Expected the start date.');
            System.Assert.areEqual(request.status, roundTrippedRequest.status, 'Expected the status.');
            System.Assert.areEqual(request.journalUnit, roundTrippedRequest.journalUnit, 'Expected the journal unit.');
            System.Assert.areEqual(request.subArchive, roundTrippedRequest.subArchive, 'Expected the subarchive.');
            System.Assert.areEqual(request.filedOnPaper, roundTrippedRequest.filedOnPaper, 'Expected the paper flag.');
            System.Assert.areEqual(
                request.removeResponsiblePerson,
                roundTrippedRequest.removeResponsiblePerson,
                'Expected the remove responsible person flag.'
            );
            System.Assert.areEqual(
                request.syncCaseContacts,
                roundTrippedRequest.syncCaseContacts,
                'Expected the contacts sync flag.'
            );
            System.Assert.areEqual(
                request.syncCaseEstates,
                roundTrippedRequest.syncCaseEstates,
                'Expected the estates sync flag.'
            );
            System.Assert.areEqual(
                request.syncArchiveCodes,
                roundTrippedRequest.syncArchiveCodes,
                'Expected the archive codes sync flag.'
            );
        }
    }

    /**
     * Verifies that UpdateCase response fields survive JSON round-trip serialization.
     *
     * @since 2026-09
     */
    @IsTest
    static void updateCaseResponsePreservesResultFields() {
        User minimumAccessUser = P360_TestDataFactory.createMinimumAccessUser();

        System.runAs(minimumAccessUser) {
            P360_UpdateCaseResponseDto response = new P360_UpdateCaseResponseDto();
            response.recno = '700123';
            response.caseNumber = '26/00001';
            response.successful = true;
            response.errorMessage = null;
            response.errorDetails = null;

            P360_UpdateCaseResponseDto roundTrippedResponse = (P360_UpdateCaseResponseDto) JSON.deserialize(
                JSON.serialize(response),
                P360_UpdateCaseResponseDto.class
            );

            System.Assert.areEqual(response.recno, roundTrippedResponse.recno, 'Expected the case recno.');
            System.Assert.areEqual(response.caseNumber, roundTrippedResponse.caseNumber, 'Expected the case number.');
            System.Assert.areEqual(response.successful, roundTrippedResponse.successful, 'Expected the success flag.');
            System.Assert.isNull(roundTrippedResponse.errorMessage, 'Expected no error message.');
            System.Assert.isNull(roundTrippedResponse.errorDetails, 'Expected no error details.');
        }
    }
}
