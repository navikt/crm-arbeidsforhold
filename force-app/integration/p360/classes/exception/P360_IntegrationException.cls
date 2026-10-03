/**
 * Base exception for P360-specific integration errors.
 *
 * @author Kenneth Sørensen
 * @since 2026-04 F2 foundation
 * @group P360 Exception
 */
public virtual class P360_IntegrationException extends Exception {
    /** Correlation id propagated from the originating integration log context, when attached. */
    public String correlationId { get; private set; }

    /** Whether a higher layer may safely retry the operation that produced this error. Defaults to false. */
    public Boolean isRetryable { get; private set; }

    {
        isRetryable = false;
    }

    /**
     * Attaches a correlation id so it propagates with this exception across a catch boundary.
     *
     * @param suppliedCorrelationId Correlation id from the originating log context.
     * @return P360_IntegrationException This exception for fluent composition.
     * @since 2026-09
     */
    public P360_IntegrationException withCorrelationId(String suppliedCorrelationId) {
        correlationId = suppliedCorrelationId;
        return this;
    }

    /**
     * Classifies whether this error may be safely retried, independent of its runtime type.
     *
     * Classification is decided by the caller (for example, from an HTTP status code or P360
     * error code) rather than assumed from the exception's class alone.
     *
     * @param retryable Whether a higher layer may safely retry the failed operation.
     * @return P360_IntegrationException This exception for fluent composition.
     * @since 2026-09 issue 993
     */
    public P360_IntegrationException withRetryable(Boolean retryable) {
        isRetryable = retryable;
        return this;
    }
}
