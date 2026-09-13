/**
 * Exception used when a P360 transport failure may be retried by a higher layer.
 *
 * Convenience subclass that always classifies itself as retryable; use the flexible
 * `withRetryable(Boolean)` on `P360_IntegrationException` when retryability instead depends on a
 * runtime signal such as an HTTP status code or P360 error code.
 *
 * @author Kenneth Sørensen
 * @since 2026-09 issue 993
 * @group P360 Exception
 */
public class P360_RetryableException extends P360_TransportException {
    {
        this.withRetryable(true);
    }
}
