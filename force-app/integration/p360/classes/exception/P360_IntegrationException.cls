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
}
