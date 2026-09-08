/**
 * Orchestrates the archive application use case from Aa-registeret context to P360.
 *
 * @author Kenneth Sørensen
 * @since 2026-04 F2 foundation
 * @group AAREG P360 Orchestration
 */
public with sharing class AAREG_ArchiveApplicationOrchestrator {
    private final P360_IArchiveAdapter archiveAdapter;

    /**
     * Creates a new orchestrator instance.
     *
     * @param archiveAdapter Adapter used to perform archive operations against P360.
     */
    public AAREG_ArchiveApplicationOrchestrator(P360_IArchiveAdapter archiveAdapter) {
        this.archiveAdapter = archiveAdapter;
    }

    /**
     * Starts the archive application use case.
     *
     * @param command Archive application command.
     * @return Internal archive application result.
     * @throws P360_ContractException When required command data is missing or implementation is incomplete.
     */
    public AAREG_ArchiveApplicationResult archive(AAREG_ArchiveApplicationCommand command) {
        if (command == null || command.applicationId == null) {
            throw new P360_ContractException('Application id is required for archive operation.');
        }

        throw new P360_ContractException(
            'AAREG_ArchiveApplicationOrchestrator.archive is not implemented yet. TODO F3/F4.'
        );
    }
}
