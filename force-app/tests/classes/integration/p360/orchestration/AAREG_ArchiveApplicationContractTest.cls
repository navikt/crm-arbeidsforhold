/**
 * Verifies the internal command and result contracts for the archive use case.
 *
 * @author Kenneth Sørensen
 * @since 2026-09
 * @group AAREG P360 Orchestration
 */
@IsTest
private class AAREG_ArchiveApplicationContractTest {
    /**
     * Verifies that archive command fields preserve the internal use-case context.
     *
     * @since 2026-09
     */
    @IsTest
    static void archiveCommandPreservesUseCaseContext() {
        User minimumAccessUser = P360_TestDataFactory.createMinimumAccessUser();

        System.runAs(minimumAccessUser) {
            AAREG_ArchiveApplicationCommand command = new AAREG_ArchiveApplicationCommand();
            command.applicationId = UserInfo.getUserId();
            command.agreementId = UserInfo.getUserId();
            command.correlationId = 'correlation-contract-test';
            command.externalId = 'external-contract-test';

            System.Assert.areEqual(UserInfo.getUserId(), command.applicationId, 'Expected the application id.');
            System.Assert.areEqual(UserInfo.getUserId(), command.agreementId, 'Expected the agreement id.');
            System.Assert.areEqual('correlation-contract-test', command.correlationId, 'Expected the correlation id.');
            System.Assert.areEqual('external-contract-test', command.externalId, 'Expected the external id.');
        }
    }

    /**
     * Verifies that archive result fields preserve internal and external outcome data.
     *
     * @since 2026-09
     */
    @IsTest
    static void archiveResultPreservesOutcomeContext() {
        User minimumAccessUser = P360_TestDataFactory.createMinimumAccessUser();

        System.runAs(minimumAccessUser) {
            AAREG_ArchiveApplicationResult result = new AAREG_ArchiveApplicationResult();
            result.success = true;
            result.message = 'Archive completed.';
            result.correlationId = 'correlation-result-test';
            result.externalCaseId = 'case-result-test';
            result.externalDocumentId = 'document-result-test';

            System.Assert.isTrue(result.success, 'Expected a successful result.');
            System.Assert.areEqual('Archive completed.', result.message, 'Expected the result message.');
            System.Assert.areEqual('correlation-result-test', result.correlationId, 'Expected the correlation id.');
            System.Assert.areEqual('case-result-test', result.externalCaseId, 'Expected the external case id.');
            System.Assert.areEqual(
                'document-result-test',
                result.externalDocumentId,
                'Expected the external document id.'
            );
        }
    }
}
