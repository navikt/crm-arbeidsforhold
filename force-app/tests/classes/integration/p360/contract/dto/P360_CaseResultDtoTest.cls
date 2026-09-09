/**
 * Verifies the core SIF CaseResult DTO used by GetCases.
 *
 * @author Kenneth Sørensen
 * @since 2026-09
 * @group P360 DTO
 */
@IsTest
private class P360_CaseResultDtoTest {
    /**
     * Verifies that primitive CaseResult fields survive JSON round-trip serialization.
     *
     * @since 2026-09
     */
    @IsTest
    static void caseResultPreservesCoreFields() {
        User minimumAccessUser = P360_TestDataFactory.createMinimumAccessUser();

        System.runAs(minimumAccessUser) {
            P360_CaseResultDto result = new P360_CaseResultDto();
            result.recno = '700123';
            result.title = 'Employment case';
            result.caseNumber = '26/00001';
            result.externalId = 'case-123';
            result.startDate = Date.newInstance(2026, 9, 1);
            result.statusDescription = 'In progress';
            result.responsibleEnterpriseName = 'Example enterprise';
            result.responsiblePersonName = 'Example person';
            result.lastChangedDate = Date.newInstance(2026, 9, 9);
            result.subArchive = '60001';
            result.subArchiveCode = 'Sakarkiv';
            result.accessCodeCode = 'U';
            result.accessCodeDescription = 'Unclassified';
            result.paragraph = 'OFL 11';
            result.notes = 'Case notes';
            result.caseTypeCode = 'Sak';
            result.uid = 'uid-case-123';
            result.uidOrigin = '360';

            P360_CaseResultDto roundTrippedResult = (P360_CaseResultDto) JSON.deserialize(
                JSON.serialize(result),
                P360_CaseResultDto.class
            );

            System.Assert.areEqual(result.recno, roundTrippedResult.recno, 'Expected the recno.');
            System.Assert.areEqual(result.title, roundTrippedResult.title, 'Expected the title.');
            System.Assert.areEqual(result.caseNumber, roundTrippedResult.caseNumber, 'Expected the case number.');
            System.Assert.areEqual(result.externalId, roundTrippedResult.externalId, 'Expected the external id.');
            System.Assert.areEqual(result.startDate, roundTrippedResult.startDate, 'Expected the start date.');
            System.Assert.areEqual(
                result.statusDescription,
                roundTrippedResult.statusDescription,
                'Expected the status description.'
            );
            System.Assert.areEqual(
                result.responsibleEnterpriseName,
                roundTrippedResult.responsibleEnterpriseName,
                'Expected the responsible enterprise name.'
            );
            System.Assert.areEqual(
                result.responsiblePersonName,
                roundTrippedResult.responsiblePersonName,
                'Expected the responsible person name.'
            );
            System.Assert.areEqual(
                result.lastChangedDate,
                roundTrippedResult.lastChangedDate,
                'Expected the last changed date.'
            );
            System.Assert.areEqual(result.subArchive, roundTrippedResult.subArchive, 'Expected the subarchive.');
            System.Assert.areEqual(
                result.subArchiveCode,
                roundTrippedResult.subArchiveCode,
                'Expected the subarchive code.'
            );
            System.Assert.areEqual(
                result.accessCodeCode,
                roundTrippedResult.accessCodeCode,
                'Expected the access code.'
            );
            System.Assert.areEqual(
                result.accessCodeDescription,
                roundTrippedResult.accessCodeDescription,
                'Expected the access code description.'
            );
            System.Assert.areEqual(result.paragraph, roundTrippedResult.paragraph, 'Expected the paragraph.');
            System.Assert.areEqual(result.notes, roundTrippedResult.notes, 'Expected the notes.');
            System.Assert.areEqual(result.caseTypeCode, roundTrippedResult.caseTypeCode, 'Expected the case type.');
            System.Assert.areEqual(result.uid, roundTrippedResult.uid, 'Expected the UID.');
            System.Assert.areEqual(result.uidOrigin, roundTrippedResult.uidOrigin, 'Expected the UID origin.');
        }
    }
}
