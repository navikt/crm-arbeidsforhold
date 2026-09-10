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
                ((P360_ArchiveAdapter) archiveAdapter).getRpcClient(),
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
                ((P360_ArchiveAdapter) archiveAdapter).getRpcClient(),
                'Expected the default RPC client to be present.'
            );
        }
    }
}
