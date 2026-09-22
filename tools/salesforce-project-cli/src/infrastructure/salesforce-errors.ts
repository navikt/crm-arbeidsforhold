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

const TRANSIENT_COMMAND_FAILURE_SIGNATURES = [
    'TypeError: terminated',
    'ECONNRESET',
    'socket hang up',
    'ETIMEDOUT',
    'ENOTFOUND',
    'UND_ERR_'
] as const;

/**
 * Identifies command failures eligible for a bounded transport retry: recognized transient
 * network/timeout signatures, shared by every mutating `sf` invocation's retry policy.
 *
 * @param result - Captured command output and optional normalized error text.
 * @returns `true` only when output contains a recognized transient network signature.
 */
export function isTransientCommandFailure(result: { stdout: string; stderr: string; error?: string }): boolean {
    const output = `${result.stdout}\n${result.stderr}\n${result.error ?? ''}`;
    return TRANSIENT_COMMAND_FAILURE_SIGNATURES.some((signature) => output.includes(signature));
}

/**
 * Renders a human-readable failure message that distinguishes a canceled command from any other
 * failure, instead of reporting a canceled command with the same wording as a real error.
 *
 * @param result - Captured command output, cancellation state, and optional normalized error text.
 * @param fallback - Message used when the command failed for a reason other than cancellation and
 * neither `error` nor `stderr` is available.
 * @returns `'Operation was canceled'` when `result.canceled` is `true`; otherwise the command's error,
 * stderr, or the given fallback.
 */
export function describeCommandFailure(
    result: { canceled: boolean; error?: string; stderr: string },
    fallback: string
): string {
    if (result.canceled) return 'Operation was canceled';
    return result.error ?? result.stderr ?? fallback;
}
