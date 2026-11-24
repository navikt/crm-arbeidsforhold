/**
 * Verifies the P360 adapter composition root.
 *
 * @author Kenneth Sørensen
 * @since 2026-09
 * @group P360 Adapter
 */
@IsTest
private class P360_AdapterFactoryTest {
    /**
     * Verifies that the factory composes a real archive adapter with a provided RPC client.
     *
     * @since 2026-09
     */
    @IsTest
    static void factoryCreatesArchiveAdapterWithInjectedClient() {
        User minimumAccessUserRecord = P360_TestDataFactory.createMinimumAccessUser();
        P360_IRpcClient rpcClient = new P360_TestRpcClient();

        System.runAs(minimumAccessUserRecord) {
            P360_AdapterFactory factory = new P360_AdapterFactory(rpcClient);
            P360_IArchiveAdapter archiveAdapter = factory.createArchiveAdapter();

            System.Assert.isInstanceOfType(
                archiveAdapter,
                P360_ArchiveAdapter.class,
                'Expected a concrete archive adapter.'
            );
            System.Assert.areEqual(
                rpcClient,
                ((P360_ArchiveAdapter) archiveAdapter).rpcClient,
                'Expected the injected client to be used.'
            );
        }
    }

    /**
     * Verifies that the default factory creates a standard archive adapter using the default RPC client.
     *
     * @since 2026-09
     */
    @IsTest
    static void defaultFactoryBuildsStandardArchiveAdapter() {
        User minimumAccessUserRecord = P360_TestDataFactory.createMinimumAccessUser();

        System.runAs(minimumAccessUserRecord) {
            P360_AdapterFactory factory = new P360_AdapterFactory();
            P360_IArchiveAdapter archiveAdapter = factory.createArchiveAdapter();

            System.Assert.isInstanceOfType(
                archiveAdapter,
                P360_ArchiveAdapter.class,
                'Expected a concrete archive adapter.'
            );
            System.Assert.isNotNull(
                ((P360_ArchiveAdapter) archiveAdapter).rpcClient,
                'Expected the default RPC client to be present.'
            );
        }
    }

    /**
     * Verifies that an explicit org-level mock setting selects the stub adapter without making a callout.
     *
     * @since 2026-09
     */
    @IsTest
    static void mockSettingBuildsStubArchiveAdapter() {
        insert new P360_Integration_Setting__c(
            SetupOwnerId = UserInfo.getOrganizationId(),
            Use_Mock_Transport__c = true
        );

        P360_AdapterFactory factory = new P360_AdapterFactory();
        P360_IArchiveAdapter archiveAdapter = factory.createArchiveAdapter();

        System.Assert.isInstanceOfType(
            archiveAdapter,
            P360_StubArchiveAdapter.class,
            'Expected the explicit mock setting to select the stub adapter.'
        );
    }

    /**
     * Verifies that a configured RPC client class is wired into the real archive adapter.
     *
     * @since 2026-11
     */
    @IsTest
    static void configuredRpcClientClassIsUsedByArchiveAdapter() {
        insert new P360_Integration_Setting__c(
            SetupOwnerId = UserInfo.getOrganizationId(),
            Rpc_Client_Class__c = 'P360_CapturingRpcClient'
        );

        P360_IArchiveAdapter archiveAdapter = new P360_AdapterFactory().createArchiveAdapter();

        System.Assert.isInstanceOfType(archiveAdapter, P360_ArchiveAdapter.class);
        System.Assert.isInstanceOfType(
            ((P360_ArchiveAdapter) archiveAdapter).rpcClient,
            P360_CapturingRpcClient.class,
            'Expected the configured RPC client class.'
        );
    }

    /**
     * Verifies that a configured class which is missing or not an RPC client fails closed.
     *
     * @since 2026-11
     */
    @IsTest
    static void invalidRpcClientClassIsRejected() {
        P360_Integration_Setting__c settings = new P360_Integration_Setting__c(
            SetupOwnerId = UserInfo.getOrganizationId()
        );
        insert settings;

        for (String configuredClass : new List<String>{ 'P360_NoSuchClient', 'P360_RpcRequest' }) {
            settings.Rpc_Client_Class__c = configuredClass;
            update settings;
            try {
                new P360_AdapterFactory();
                System.Assert.fail('Expected a configuration exception for ' + configuredClass);
            } catch (P360_ConfigException caughtError) {
                System.Assert.areEqual(
                    'Configured P360 RPC client class is not a P360_IRpcClient: ' + configuredClass,
                    caughtError.getMessage()
                );
            }
        }
    }
}
