/**
 * Contract for archiving Aa-registeret data in Public 360.
 * Implementations hide transport details from orchestration.
 *
 * @author Kenneth Sørensen
 * @since 2026-04 F2 foundation
 * @group P360 Adapter
 */
public interface P360_IArchiveAdapter {
    /**
     * Archives one Aa-registeret archive request in Public 360.
     *
     * @param request P360 archive request DTO.
     * @return Controlled archive response from the P360 adapter.
     * @throws P360_ContractException When the request or contract is invalid.
     * @throws P360_IntegrationException When the archive operation fails.
     */
    P360_ArchiveResponseDto archive(P360_ArchiveRequestDto request);
}
