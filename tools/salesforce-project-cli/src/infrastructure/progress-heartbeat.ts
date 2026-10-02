/**
 * Emits a periodic, non-diagnostic progress event while a long-running command executes, so
 * non-verbose output shows the operation is still active instead of going silent until it settles.
 */
import type { EventSink } from '../domain/events.js';

/** Inputs for a periodic progress heartbeat around one long-running operation step. */
export interface HeartbeatOptions {
    /** Event sink receiving one `progress` event per tick. */
    emit: EventSink;
    /** Correlation identifier copied to every emitted event. */
    operationId: string;
    /** Step identifier the heartbeat is reported against. */
    stepId: string;
    /** Human-readable step label. */
    step: string;
    /** Builds the message for one tick from the elapsed time since the heartbeat started. */
    message: (elapsedSeconds: number) => string;
    /** Delay between ticks, in milliseconds. Defaults to 15 seconds. */
    intervalMs?: number;
}

/** Default delay between heartbeat ticks, in milliseconds. */
export const DEFAULT_HEARTBEAT_INTERVAL_MS = 15_000;

/**
 * Runs `run` while periodically emitting a `progress` event so a slow command does not appear
 * silent between its `step-started` and terminal event.
 *
 * @param options - Event sink, correlation, step identity, message builder, and tick interval.
 * @param run - The awaited operation the heartbeat surrounds.
 * @returns The settled value of `run`.
 * @throws Propagates any rejection from `run` unchanged; the heartbeat timer is always cleared.
 */
export async function withProgressHeartbeat<T>(options: HeartbeatOptions, run: () => Promise<T>): Promise<T> {
    const startedAt = Date.now();
    const intervalMs = options.intervalMs ?? DEFAULT_HEARTBEAT_INTERVAL_MS;
    const timer = setInterval(() => {
        const elapsedSeconds = Math.round((Date.now() - startedAt) / 1000);
        options.emit({
            kind: 'progress',
            operationId: options.operationId,
            timestamp: new Date().toISOString(),
            stepId: options.stepId,
            step: options.step,
            message: options.message(elapsedSeconds),
            heartbeat: true
        });
    }, intervalMs);
    // An unref'd timer never keeps the Node.js process alive on its own.
    timer.unref?.();
    try {
        return await run();
    } finally {
        clearInterval(timer);
    }
}
