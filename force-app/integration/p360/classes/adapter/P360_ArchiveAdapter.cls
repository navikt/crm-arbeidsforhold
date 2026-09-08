/**
 * Default P360 archive adapter skeleton.
 * This class will later coordinate P360 archive RPC operations.
 *
 * @author Kenneth Sørensen
 * @since 2026-04 F2 foundation
 * @group P360 Adapter
 */
public with sharing class P360_ArchiveAdapter implements P360_IArchiveAdapter {
    private final P360_IRpcClient rpcClient;

    /**
     * Creates a new adapter instance.
     *
     * @param rpcClient Low-level RPC client used for P360 transport.
     */
    public P360_ArchiveAdapter(P360_IRpcClient rpcClient) {
        this.rpcClient = rpcClient;
    }

    /**
     * Archives one request in P360.
     *
     * @param request P360 archive request DTO.
     * @return Archive response from P360.
     * @throws P360_ContractException Until implementation is completed.
     */
    public P360_ArchiveResponseDto archive(P360_ArchiveRequestDto request) {
        throw new P360_ContractException('P360_ArchiveAdapter.archive is not implemented yet. TODO F3/F4/S1.');
    }
}
