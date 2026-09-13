/**
 * Sanitizes configured secrets and recognized Salesforce credentials across text and structured events.
 * Recursive redaction preserves value shape and replaces longer overlapping secrets first.
 */
import type { EventSink } from '../domain/events.js';

const REDACTED_VALUE = '[REDACTED]';
const SALESFORCE_ACCESS_TOKEN = /00D[A-Za-z0-9]{12}(?:[A-Za-z0-9]{3})?![A-Za-z0-9._~-]+/g;
const SALESFORCE_AUTH_URL = /\bforce:\/\/[^\s"'<>]+/gi;

/** Redacts secrets consistently from text, errors, and structured values. */
export interface Redactor {
    /** Replaces configured and recognized Salesforce credentials in arbitrary text. */
    redact(value: string): string;
    /** Extracts a safe message from an unknown error value and redacts it. */
    redactError(error: unknown): string;
    /** Recursively redacts string values while preserving the value's TypeScript shape. */
    redactValue<T>(value: T): T;
}

function redactValue<T>(value: T, redact: (text: string) => string): T {
    if (typeof value === 'string') {
        return redact(value) as T;
    }
    if (Array.isArray(value)) {
        return value.map((item) => redactValue(item, redact)) as T;
    }
    if (value !== null && typeof value === 'object') {
        return Object.fromEntries(Object.entries(value).map(([key, item]) => [key, redactValue(item, redact)])) as T;
    }
    return value;
}

/**
 * Creates a reusable redactor for configured secrets and recognized Salesforce credentials.
 *
 * @param secretValues - Additional literal secret values to replace; empty values are ignored.
 * @returns A redactor that substitutes every match with `[REDACTED]`.
 */
export function createRedactor(secretValues: readonly string[] = []): Redactor {
    // Replace longer overlapping secrets first so shorter values cannot expose a suffix.
    const secrets = [...new Set(secretValues.filter((secret) => secret.length > 0))].sort(
        (left, right) => right.length - left.length
    );
    const redact = (value: string): string => {
        const withoutConfiguredSecrets = secrets.reduce(
            (redacted, secret) => redacted.split(secret).join(REDACTED_VALUE),
            value
        );
        return withoutConfiguredSecrets
            .replace(SALESFORCE_ACCESS_TOKEN, REDACTED_VALUE)
            .replace(SALESFORCE_AUTH_URL, REDACTED_VALUE);
    };

    return {
        redact,
        redactError: (error) => redact(error instanceof Error ? error.message : String(error)),
        redactValue: (value) => redactValue(value, redact)
    };
}

/**
 * Wraps an event sink so no event is forwarded before recursive redaction.
 *
 * @param redactor - Redactor applied to the complete event payload.
 * @param sink - Destination that receives sanitized events.
 * @returns An event sink preserving input order and event shape.
 */
export function createRedactingEventSink(redactor: Redactor, sink: EventSink): EventSink {
    return (event) => sink(redactor.redactValue(event));
}
