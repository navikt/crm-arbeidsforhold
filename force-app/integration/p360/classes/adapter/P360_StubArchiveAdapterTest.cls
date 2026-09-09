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
            P360_ArchiveResponseDto expectedResponse = P360_TestDataFactory.archiveResponse()
                .withExternalCaseId(request.externalId)
                .withMessage('Stub archive response. No callout was performed.')
                .build();

            System.Assert.areEqual(
                expectedResponse.success,
                response.success,
                'Expected the stub archive response to be successful.'
            );
            System.Assert.areEqual(
                expectedResponse.externalCaseId,
                response.externalCaseId,
                'Expected the external id to be preserved.'
            );
            System.Assert.areEqual(
                expectedResponse.message,
                response.message,
                'Expected the controlled stub response message.'
            );
        }
    }

    /**
     * Verifies that the local stub accepts a null request and returns a controlled response without an external id.
     *
     * @since 2026-09
     */
    @IsTest
    static void nullArchiveRequestReturnsControlledStubResponse() {
        User minimumAccessUser = P360_TestDataFactory.createMinimumAccessUser();
        P360_StubArchiveAdapter adapter = new P360_StubArchiveAdapter();

        System.runAs(minimumAccessUser) {
            P360_ArchiveResponseDto response = adapter.archive(null);

            System.Assert.isTrue(response.success, 'Expected the stub archive response to be successful.');
            System.Assert.isNull(response.externalCaseId, 'Expected no external case id for a null request.');
            System.Assert.areEqual(
                'Stub archive response. No callout was performed.',
                response.message,
                'Expected the controlled stub response message.'
            );
        }
    }
}
