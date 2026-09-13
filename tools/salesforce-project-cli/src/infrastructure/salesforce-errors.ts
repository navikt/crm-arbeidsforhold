/**
 * Classifies Salesforce authentication and authorization diagnostics into stable CLI outcomes.
 * Unrecognized failures retain the caller's fallback exit code.
 */
import { EXIT_CODES, type ExitCode } from '../domain/events.js';

const AUTH_FAILURE_PATTERN =
    /no authorization information|not authenticated|authentication (?:failed|required)|authorization failed|expired access token|invalid_session_id|session (?:has )?expired|insufficient[_ ]access|not authorized|permission denied|does not have access/i;

function failureText(value: unknown): string {
    if (typeof value === 'string') return value;
    if (value instanceof Error) return value.message;
    if (value === null || typeof value !== 'object') return '';
    const record = value as Record<string, unknown>;
    return ['message', 'stdout', 'stderr', 'error']
        .map((key) => failureText(record[key]))
        .filter(Boolean)
        .join('\n');
}

/**
 * Detects explicit Salesforce authentication or authorization failures in nested diagnostics.
 *
 * @param value - Error, command result, or nested diagnostic value to inspect.
 * @returns `true` only when recognized authentication or authorization language is present.
 */
export function isSalesforceAuthFailure(value: unknown): boolean {
    return AUTH_FAILURE_PATTERN.test(failureText(value));
}

/**
 * Maps recognized Salesforce access failures to the stable authentication exit code.
 *
 * @param value - Failure details to classify.
 * @param fallback - Exit code retained when the failure is unrelated to access.
 * @returns The authentication exit code or the caller-provided fallback.
 */
export function classifySalesforceFailure(value: unknown, fallback: ExitCode): ExitCode {
    return isSalesforceAuthFailure(value) ? EXIT_CODES.AUTH_OR_AUTHORIZATION_FAILURE : fallback;
}
