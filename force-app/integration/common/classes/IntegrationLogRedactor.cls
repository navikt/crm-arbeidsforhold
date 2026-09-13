/**
 * Removes sensitive field values before technical integration fields are logged.
 *
 * Enforces the architecture principle that logging must never contain tokens, credentials,
 * or personal identifiers such as a Norwegian national identity number.
 *
 * @author Kenneth Sørensen
 * @since 2026-09 issue 1021
 * @group Integration Common
 */
public with sharing class IntegrationLogRedactor {
    private static final String REDACTED_VALUE = '[REDACTED]';

    private static final Set<String> SENSITIVE_KEY_FRAGMENTS = new Set<String>{
        'token',
        'password',
        'secret',
        'authorization',
        'cookie',
        'fnr',
        'ssn',
        'personnummer'
    };

    /**
     * Returns a copy of the supplied fields with sensitive values replaced.
     *
     * A key is treated as sensitive when its lowercase form contains a known sensitive
     * fragment. The supplied map is never mutated.
     *
     * @param fields Technical fields keyed by field name.
     * @return Map<String, Object> A new map with sensitive values replaced by a redaction marker.
     * @since 2026-09
     */
    public static Map<String, Object> redactFields(Map<String, Object> fields) {
        Map<String, Object> redactedFields = new Map<String, Object>();

        for (String key : fields.keySet()) {
            redactedFields.put(key, isSensitiveKey(key) ? REDACTED_VALUE : fields.get(key));
        }

        return redactedFields;
    }

    private static Boolean isSensitiveKey(String key) {
        String normalizedKey = key == null ? '' : key.toLowerCase();

        for (String fragment : SENSITIVE_KEY_FRAGMENTS) {
            if (normalizedKey.contains(fragment)) {
                return true;
            }
        }

        return false;
    }
}
