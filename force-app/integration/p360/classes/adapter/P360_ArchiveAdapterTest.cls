/**
 * Verifies request validation at the P360 archive adapter boundary.
 *
 * @author Not available (new file)
 * @since 2026-09
 * @group P360 Adapter
 */
@IsTest
private class P360_ArchiveAdapterTest {
    /**
     * Verifies that a null archive request is rejected before the RPC client is used.
     *
     * @since 2026-09
     */
    @IsTest
    static void nullRequestIsRejectedBeforeTransport() {
        P360_ArchiveAdapter adapter = new P360_ArchiveAdapter(new P360_TestRpcClient());
        User minimumAccessUser = P360_TestDataFactory.createMinimumAccessUser();

        System.runAs(minimumAccessUser) {
            try {
                adapter.archive((P360_ArchiveRequestDto) null);
                System.Assert.fail('Expected a contract exception.');
            } catch (P360_ContractException caughtError) {
                System.Assert.areEqual(
                    'Archive request is required.',
                    caughtError.getMessage(),
                    'Expected the null request validation message.'
                );
            }
        }
    }

    /**
     * Verifies that an archive request without an external id is rejected before the RPC client is used.
     *
     * @since 2026-09
     */
    @IsTest
    static void missingExternalIdIsRejectedBeforeTransport() {
        P360_ArchiveRequestDto request = P360_TestDataFactory.archiveRequest().withExternalId(null).build();
        P360_ArchiveAdapter adapter = new P360_ArchiveAdapter(new P360_TestRpcClient());
        User minimumAccessUser = P360_TestDataFactory.createMinimumAccessUser();

        System.runAs(minimumAccessUser) {
            try {
                adapter.archive(request);
                System.Assert.fail('Expected a contract exception.');
            } catch (P360_ContractException caughtError) {
                System.Assert.areEqual(
                    'Archive request external id is required.',
                    caughtError.getMessage(),
                    'Expected the missing external id validation message.'
                );
            }
        }
    }
}
