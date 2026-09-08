/**
 * Verifies archive-command validation at the P360 orchestration boundary.
 *
 * @author Not available (new file)
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
}
