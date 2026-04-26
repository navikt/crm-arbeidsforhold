/**
 * Tests P360_StubArchiveAdapter controlled stub behavior.
 *
 * @author Kenneth Sørensen
 * @since 2026-04 F2 foundation
 * @group P360 Adapter
 */
@IsTest
private class P360_StubArchiveAdapterTest {
    /**
     * Verifies that the stub adapter returns a controlled successful response.
     */
    @IsTest
    static void archiveReturnsControlledStubResponse() {
        P360_ArchiveRequestDto request = new P360_ArchiveRequestDto();
        request.externalId = 'AAREG-APP-123';

        P360_StubArchiveAdapter adapter = new P360_StubArchiveAdapter();

        System.Test.startTest();
        P360_ArchiveResponseDto response = adapter.archive(request);
        System.Test.stopTest();

        System.Assert.areEqual(true, response.success, 'Stub response should be successful.');
        System.Assert.areEqual(
            'Stub archive response. No callout was performed.',
            response.message,
            'Unexpected stub message.'
        );
        System.Assert.areEqual('AAREG-APP-123', response.externalCaseId, 'Unexpected external case id.');
    }

    /**
     * Verifies that the stub adapter handles null requests without throwing.
     */
    @IsTest
    static void archiveHandlesNullRequest() {
        P360_StubArchiveAdapter adapter = new P360_StubArchiveAdapter();

        System.Test.startTest();
        P360_ArchiveResponseDto response = adapter.archive(null);
        System.Test.stopTest();

        System.Assert.areEqual(true, response.success, 'Stub response should be successful.');
        System.Assert.isNull(response.externalCaseId, 'External case id should be null for null request.');
    }
}
