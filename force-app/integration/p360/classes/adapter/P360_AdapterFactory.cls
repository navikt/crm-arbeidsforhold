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
    private final P360_IArchiveAdapter archiveAdapter;

    /**
     * Creates a factory with a supplied RPC client.
     *
     * @param rpcClient RPC client to inject into the archive adapter.
     */
    public P360_AdapterFactory(P360_IRpcClient rpcClient) {
        this.rpcClient = rpcClient;
        this.archiveAdapter = new P360_ArchiveAdapter(rpcClient);
    }

    /**
     * Creates the default factory wiring. Org defaults choose the mock adapter, a configured
     * `Rpc_Client_Class__c`, or the standard HTTP RPC client, in that order.
     *
     * @throws P360_ConfigException When the configured RPC client class is missing or has the wrong type.
     */
    public P360_AdapterFactory() {
        this(resolveDefaultAdapter());
    }

    private P360_AdapterFactory(P360_IArchiveAdapter archiveAdapter) {
        this.rpcClient = null;
        this.archiveAdapter = archiveAdapter;
    }

    /**
     * Creates the archive adapter using constructor injection.
     *
     * @return P360 archive adapter instance.
     */
    public P360_IArchiveAdapter createArchiveAdapter() {
        return archiveAdapter;
    }

    private static P360_IArchiveAdapter resolveDefaultAdapter() {
        P360_Integration_Setting__c settings = P360_Integration_Setting__c.getOrgDefaults();
        if (settings != null && settings.Use_Mock_Transport__c == true) {
            return new P360_StubArchiveAdapter();
        }
        String configuredClass = settings == null ? null : settings.Rpc_Client_Class__c;
        if (String.isBlank(configuredClass)) {
            return new P360_ArchiveAdapter(new P360_RpcClient());
        }
        return new P360_ArchiveAdapter(instantiateRpcClient(configuredClass.trim()));
    }

    private static P360_IRpcClient instantiateRpcClient(String className) {
        System.Type clientType = System.Type.forName(className);
        Object instance;
        try {
            instance = clientType == null ? null : clientType.newInstance();
        } catch (System.TypeException instantiationError) {
            instance = null;
        }
        if (!(instance instanceof P360_IRpcClient)) {
            throw new P360_ConfigException('Configured P360 RPC client class is not a P360_IRpcClient: ' + className);
        }
        return (P360_IRpcClient) instance;
    }
}
