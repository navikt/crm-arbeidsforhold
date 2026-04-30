/**
 * Tests AAREG_ArchiveApplicationOrchestrator skeleton behavior.
 *
 * @author Kenneth Sørensen
 * @since 2026-04 F2 foundation
 * @group AAREG P360 Orchestration
 */
@IsTest
private class AAREG_ArchiveApplicationOrchestratorTest {
    /**
     * Verifies that archive rejects null commands.
     */
    @IsTest
    static void archiveThrowsWhenCommandIsNull() {
        AAREG_ArchiveApplicationOrchestrator orchestrator = new AAREG_ArchiveApplicationOrchestrator(
            new FakeArchiveAdapter()
        );

        try {
            System.Test.startTest();
            orchestrator.archive(null);
            System.Test.stopTest();

            System.Assert.fail('Expected P360_ContractException.');
        } catch (P360_ContractException e) {
            System.Assert.areEqual(
                'Application id is required for archive operation.',
                e.getMessage(),
                'Unexpected exception message.'
            );
        }
    }

    /**
     * Verifies that archive rejects commands without application id.
     */
    @IsTest
    static void archiveThrowsWhenApplicationIdIsMissing() {
        AAREG_ArchiveApplicationCommand command = new AAREG_ArchiveApplicationCommand();
        AAREG_ArchiveApplicationOrchestrator orchestrator = new AAREG_ArchiveApplicationOrchestrator(
            new FakeArchiveAdapter()
        );

        try {
            System.Test.startTest();
            orchestrator.archive(command);
            System.Test.stopTest();

            System.Assert.fail('Expected P360_ContractException.');
        } catch (P360_ContractException e) {
            System.Assert.areEqual(
                'Application id is required for archive operation.',
                e.getMessage(),
                'Unexpected exception message.'
            );
        }
    }

    /**
     * Verifies that archive throws a controlled not implemented exception for valid commands.
     */
    @IsTest
    static void archiveThrowsNotImplementedForValidCommand() {
        AAREG_ArchiveApplicationCommand command = new AAREG_ArchiveApplicationCommand();
        command.applicationId = Id.valueOf('001000000000003AAA');

        AAREG_ArchiveApplicationOrchestrator orchestrator = new AAREG_ArchiveApplicationOrchestrator(
            new FakeArchiveAdapter()
        );

        try {
            System.Test.startTest();
            orchestrator.archive(command);
            System.Test.stopTest();

            System.Assert.fail('Expected P360_ContractException.');
        } catch (P360_ContractException e) {
            System.Assert.isTrue(
                e.getMessage().contains('AAREG_ArchiveApplicationOrchestrator.archive is not implemented yet'),
                'Unexpected exception message: ' + e.getMessage()
            );
        }
    }

    /**
     * Fake archive adapter used to construct the orchestrator without real P360 dependencies.
     */
    private class FakeArchiveAdapter implements P360_IArchiveAdapter {
        /**
         * Returns a controlled fake archive response.
         *
         * @param request P360 archive request DTO.
         * @return Fake archive response.
         */
        public P360_ArchiveResponseDto archive(P360_ArchiveRequestDto request) {
            P360_ArchiveResponseDto response = new P360_ArchiveResponseDto();
            response.success = true;
            return response;
        }
    }
}
