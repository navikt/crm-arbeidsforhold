/**
 * Holds the correlation id for a shared integration flow.
 *
 * @author Kenneth Sørensen
 * @since 2026-09
 * @group Integration Common
 */
public with sharing class CorrelationContext {
    /** Correlation id propagated through an integration flow. */
    public String correlationId { get; private set; }

    /**
     * Creates a context, preserving a supplied id or generating one when absent.
     *
     * @param suppliedCorrelationId Existing correlation id from the caller.
     * @since 2026-09
     */
    public CorrelationContext(String suppliedCorrelationId) {
        correlationId = String.isBlank(suppliedCorrelationId)
            ? EncodingUtil.convertToHex(Crypto.generateAesKey(128))
            : suppliedCorrelationId;
    }
}
