/**
 * Fake archive adapter that always throws a retryable transport error, for worker retry tests.
 *
 * @author Kenneth Sørensen
 * @since 2026-09 R2
 * @group P360 Test Utility
 */
@IsTest
public class P360_TestRetryableArchiveAdapter implements P360_IArchiveAdapter {
    private final String failureMessage;

    /**
     * Creates the retryable adapter fake with its standard failure message.
     */
    public P360_TestRetryableArchiveAdapter() {
        failureMessage = 'Simulated retryable transport failure.';
    }

    /**
     * Creates the retryable adapter fake with a specified failure message.
     *
     * @param failureMessage Message to include in the simulated retryable exception.
     */
    public P360_TestRetryableArchiveAdapter(String failureMessage) {
        this.failureMessage = failureMessage;
    }

    /**
     * Always throws a retryable transport error to simulate a temporary P360 failure.
     *
     * @param request Archive request DTO, unused.
     * @return Never returns.
     * @since 2026-09
     */
    public P360_ArchiveResponseDto archive(P360_ArchiveRequestDto request) {
        throw new P360_RetryableException(failureMessage);
    }
}