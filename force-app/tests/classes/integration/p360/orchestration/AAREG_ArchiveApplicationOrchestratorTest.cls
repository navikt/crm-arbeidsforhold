/**
 * Verifies archive-command validation at the P360 orchestration boundary.
 *
 * @author Kenneth Sørensen
 * @since 2026-09
 * @group AAREG P360 Orchestration
 */
@IsTest
private class AAREG_ArchiveApplicationOrchestratorTest {
    /**
     * Verifies that a null archive command is rejected before the adapter is used.
     *
     * @since 2026-09
     */
    @IsTest
    static void nullCommandIsRejectedBeforeAdapter() {
        User minimumAccessUser = P360_TestDataFactory.createMinimumAccessUser();
        AAREG_ArchiveApplicationOrchestrator orchestrator = new AAREG_ArchiveApplicationOrchestrator(
            new P360_StubArchiveAdapter()
        );

        System.runAs(minimumAccessUser) {
            try {
                orchestrator.archive(null);
                System.Assert.fail('Expected a contract exception.');
            } catch (P360_ContractException caughtError) {
                System.Assert.areEqual(
                    'Application id is required for archive operation.',
                    caughtError.getMessage(),
                    'Expected the null command validation message.'
                );
            }
        }
    }

    /**
     * Verifies that an archive command without an application id is rejected before the adapter is used.
     *
     * @since 2026-09
     */
    @IsTest
    static void missingApplicationIdIsRejectedBeforeAdapter() {
        User minimumAccessUser = P360_TestDataFactory.createMinimumAccessUser();
        AAREG_ArchiveApplicationCommand command = new AAREG_ArchiveApplicationCommand();
        AAREG_ArchiveApplicationOrchestrator orchestrator = new AAREG_ArchiveApplicationOrchestrator(
            new P360_StubArchiveAdapter()
        );

        System.runAs(minimumAccessUser) {
            try {
                orchestrator.archive(command);
                System.Assert.fail('Expected a contract exception.');
            } catch (P360_ContractException caughtError) {
                System.Assert.areEqual(
                    'Application id is required for archive operation.',
                    caughtError.getMessage(),
                    'Expected the missing application id validation message.'
                );
            }
        }
    }

    /**
     * Verifies that a valid command is mapped to the injected stub adapter and returns its controlled response.
     *
     * @since 2026-09
     */
    @IsTest
    static void validCommandIsRejectedUntilOrchestrationIsImplemented() {
        User minimumAccessUser = P360_TestDataFactory.createMinimumAccessUser();
        AAREG_ArchiveApplicationCommand command = new AAREG_ArchiveApplicationCommand();
        command.applicationId = UserInfo.getUserId();
        command.externalId = 'application-external-id';
        command.correlationId = 'orchestration-correlation-id';
        AAREG_ArchiveApplicationOrchestrator orchestrator = new AAREG_ArchiveApplicationOrchestrator(
            new P360_StubArchiveAdapter()
        );

        System.runAs(minimumAccessUser) {
            AAREG_ArchiveApplicationResult result = orchestrator.archive(command);

            System.Assert.areEqual(true, result.success, 'Expected the stub archive operation to succeed.');
            System.Assert.areEqual(
                'application-external-id',
                result.externalCaseId,
                'Expected the external id to be preserved by the stub adapter.'
            );
            System.Assert.areEqual(
                'orchestration-correlation-id',
                result.correlationId,
                'Expected the correlation id to be preserved.'
            );
        }
    }
}
