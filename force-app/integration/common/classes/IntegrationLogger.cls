/**
 * Builds a structured, redacted technical log entry for an integration flow and persists it via
 * the shared `LoggerUtility` / `Application_Event__e` pipeline, matching the Jira-named
 * `IntegrationLogger` helper (CRMAAREG-131). Complements `IntegrationLogContext`, which only
 * holds the technical fields.
 *
 * @author Kenneth Sørensen
 * @since 2026-09 issue 1021
 * @group Integration Common
 */
public with sharing class IntegrationLogger {
    /**
     * Builds the redacted, structured log payload without persisting it.
     *
     * Exposed separately from {@link #log} so the payload can be verified in tests without
     * depending on the platform-event pipeline.
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
     * Persists one structured, redacted log entry as an Application_Log__c, using the existing
     * `LoggerUtility` / `Application_Event__e` platform-event pipeline shared across the org.
     *
     * Uses the existing `CRM_ApplicationDomain.Domain.AAREG` value because no P360-specific
     * application domain is defined in the shared, package-owned value set.
     *
     * @param context Technical log context for the integration flow.
     * @param additionalFields Optional operation-specific fields; sensitive values are redacted.
     * @param logLevel Severity used by the shared `LoggerUtility` pipeline.
     * @since 2026-09
     */
    public static void log(
        IntegrationLogContext context,
        Map<String, Object> additionalFields,
        LoggerUtility.LogLevel logLevel
    ) {
        Map<String, Object> payload = buildLogPayload(context, additionalFields);

        LoggerUtility logger = new LoggerUtility(context.systemName);
        logger.logMessage(
            logLevel,
            null,
            context.operationName,
            context.operationName + ': ' + context.status,
            JSON.serialize(payload),
            null,
            CRM_ApplicationDomain.Domain.AAREG
        );
        logger.publish();
    }
}
