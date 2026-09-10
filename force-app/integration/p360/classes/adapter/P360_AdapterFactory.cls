/**
 * Composition root for the P360 adapter layer.
 * Keeps wiring explicit and allows constructor injection instead of service-location logic.
 *
 * @author Kenneth Sørensen
 * @since 2026-09
 * @group P360 Adapter
 */
public with sharing class P360_AdapterFactory {
    private final P360_IRpcClient rpcClient;

    /**
     * Creates a factory with a supplied RPC client.
     *
     * @param rpcClient RPC client to inject into the archive adapter.
     */
    public P360_AdapterFactory(P360_IRpcClient rpcClient) {
        this.rpcClient = rpcClient;
    }

    /**
     * Creates the default factory wiring using a standard RPC client.
     */
    public P360_AdapterFactory() {
        this(new P360_RpcClient());
    }

    /**
     * Creates the archive adapter using constructor injection.
     *
     * @return P360 archive adapter instance.
     */
    public P360_IArchiveAdapter createArchiveAdapter() {
        return new P360_ArchiveAdapter(rpcClient);
    }
}
