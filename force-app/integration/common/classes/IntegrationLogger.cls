/**
 * Persists bounded technical integration failure context through the shared log pipeline.
 *
 * @author Kenneth Sørensen
 * @since 2026-10
 * @group Integration Common
 */
public with sharing class IntegrationLogger {
    private static final String SAFE_LABEL_PATTERN = '^[A-Za-z][A-Za-z0-9_.-]{0,63}$';
    private static final String SAFE_CORRELATION_PATTERN = '^[A-Fa-f0-9]{32}$';
    private static final List<String> SENSITIVE_LABEL_FRAGMENTS = new List<String>{
        'token',
        'secret',
        'password',
        'authorization',
        'cookie',
        'fnr',
        'ssn',
        'personnummer'
    };

    /**
     * Persists only the four technical fields in the context; payloads and exception text are not accepted.
     *
     * @param context Technical context with non-sensitive labels and an opaque correlation id. Arbitrary payload data is not supported.
     * @example {@code
     * IntegrationLogContext context = new IntegrationLogContext('P360', 'CreateDocument', 'Failed');
     * IntegrationLogger.logFailure(context);
     * }
     * @since 2026-10
     */
    public static void logFailure(IntegrationLogContext context) {
        if (context == null) {
            return;
        }

        String systemName = normalizeLabel(context.systemName, 'Integration');
        String operationName = normalizeLabel(context.operationName, 'UnknownOperation');
        String status = normalizeLabel(context.status, 'Unknown');
        String correlationId = normalizeCorrelationId(context.correlationId);

        Map<String, Object> payload = new Map<String, Object>{
            'systemName' => systemName,
            'operationName' => operationName,
            'correlationId' => correlationId,
            'status' => status
        };

        LoggerUtility logger = new LoggerUtility(systemName);
        logger.logMessage(
            LoggerUtility.LogLevel.ERROR,
            null,
            operationName,
            operationName + ': ' + status,
            JSON.serialize(payload),
            null,
            CRM_ApplicationDomain.Domain.AAREG
        );
        logger.publish();
    }

    private static String normalizeLabel(String value, String fallback) {
        if (value == null || !Pattern.compile(SAFE_LABEL_PATTERN).matcher(value).matches()) {
            return fallback;
        }

        String normalizedValue = value.toLowerCase();
        for (String sensitiveFragment : SENSITIVE_LABEL_FRAGMENTS) {
            if (normalizedValue.contains(sensitiveFragment)) {
                return fallback;
            }
        }

        return value;
    }

    private static String normalizeCorrelationId(String value) {
        return value != null && Pattern.compile(SAFE_CORRELATION_PATTERN).matcher(value).matches()
            ? value
            : '[REDACTED]';
    }
}