/**
 * Holds technical fields used to correlate and classify an integration log event.
 *
 * @author Kenneth Sørensen
 * @since 2026-09
 * @group Integration Common
 */
public with sharing class IntegrationLogContext {
    /** Technical system or integration name. */
    public String systemName { get; private set; }

    /** Technical operation name. */
    public String operationName { get; private set; }

    /** Correlation id propagated through the integration flow. */
    public String correlationId { get; private set; }

    /** Technical lifecycle status for the event. */
    public String status { get; private set; }

    /**
     * Creates a technical log context without storing payload or personal data.
     *
     * @param systemName Technical system or integration name.
     * @param operationName Technical operation name.
     * @param status Technical lifecycle status for the event.
     * @since 2026-09
     */
    public IntegrationLogContext(String systemName, String operationName, String status) {
        this.systemName = systemName;
        this.operationName = operationName;
        this.correlationId = new CorrelationContext(null).correlationId;
        this.status = status;
    }

    /**
     * Replaces the generated correlation id with a caller-supplied id.
     *
     * @param suppliedCorrelationId Existing correlation id from the caller.
     * @return This context for fluent composition.
     * @since 2026-09
     */
    public IntegrationLogContext withCorrelationId(String suppliedCorrelationId) {
        this.correlationId = new CorrelationContext(suppliedCorrelationId).correlationId;
        return this;
    }
}
