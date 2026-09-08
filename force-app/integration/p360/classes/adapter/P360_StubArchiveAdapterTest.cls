/**
 * Verifies the controlled local behaviour of the P360 stub archive adapter.
 *
 * @author Not available (new file)
 * @since 2026-09
 * @group P360 Adapter
 */
@IsTest
private class P360_StubArchiveAdapterTest {
    /**
     * Verifies that the stub returns a successful response without transport and preserves the external id.
     *
     * @since 2026-09
     */
    @IsTest
    static void validArchiveRequestReturnsControlledStubResponse() {
        User minimumAccessUser = P360_TestDataFactory.createMinimumAccessUser();
        P360_ArchiveRequestDto request = P360_TestDataFactory.archiveRequest().build();
        P360_StubArchiveAdapter adapter = new P360_StubArchiveAdapter();

        System.runAs(minimumAccessUser) {
            P360_ArchiveResponseDto response = adapter.archive(request);

            System.Assert.isTrue(response.success, 'Expected the stub archive response to be successful.');
            System.Assert.areEqual(
                request.externalId,
                response.externalCaseId,
                'Expected the external id to be preserved.'
            );
            System.Assert.areEqual(
                'Stub archive response. No callout was performed.',
                response.message,
                'Expected the controlled stub response message.'
            );
        }
    }
}
