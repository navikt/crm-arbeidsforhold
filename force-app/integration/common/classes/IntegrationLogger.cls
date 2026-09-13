/**
 * Emits a structured technical log entry for an integration flow, matching the Jira-named
 * `IntegrationLogger` helper (CRMAAREG-131). This class complements `IntegrationLogContext`,
 * which only holds the technical fields; this class is responsible for redacting and emitting them.
 *
 * @author Kenneth Sørensen
 * @since 2026-09 issue 1021
 * @group Integration Common
 */
public with sharing class IntegrationLogger {
    /**
     * Builds the redacted, structured log payload without emitting it.
     *
     * Exposed separately from {@link #log} so the payload can be verified in tests without
     * depending on debug-log capture.
     *
     * @param context Technical log context for the integration flow.
     * @param additionalFields Optional operation-specific fields; sensitive values are redacted.
     * @return Map<String, Object> The structured, redacted log payload.
     * @since 2026-09
     */
    public static Map<String, Object> buildLogPayload(
        IntegrationLogContext context,
        Map<String, Object> additionalFields
    ) {
        Map<String, Object> payload = new Map<String, Object>{
            'systemName' => context.systemName,
            'operationName' => context.operationName,
            'correlationId' => context.correlationId,
            'status' => context.status
        };

        if (additionalFields != null) {
            payload.putAll(IntegrationLogRedactor.redactFields(additionalFields));
        }

        return payload;
    }

    /**
     * Emits one structured, redacted log entry to the debug log.
     *
     * This is a debug-log emitter, not a durable log store. Persistence of integration log
     * entries is a separate, not-yet-implemented decision.
     *
     * @param context Technical log context for the integration flow.
     * @param additionalFields Optional operation-specific fields; sensitive values are redacted.
     * @since 2026-09
     */
    public static void log(IntegrationLogContext context, Map<String, Object> additionalFields) {
        System.debug(LoggingLevel.INFO, JSON.serialize(buildLogPayload(context, additionalFields)));
    }
}
