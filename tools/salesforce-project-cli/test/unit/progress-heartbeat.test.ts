import { afterEach, describe, expect, it, vi } from 'vitest';
import type { OperationEvent } from '../../src/domain/events.js';
import { DEFAULT_HEARTBEAT_INTERVAL_MS, withProgressHeartbeat } from '../../src/infrastructure/progress-heartbeat.js';

afterEach(() => {
    vi.useRealTimers();
});

function pendingPromise<T>(): { promise: Promise<T>; resolve: (value: T) => void; reject: (error: unknown) => void } {
    let resolve!: (value: T) => void;
    let reject!: (error: unknown) => void;
    const promise = new Promise<T>((res, rej) => {
        resolve = res;
        reject = rej;
    });
    return { promise, resolve, reject };
}

describe('withProgressHeartbeat', () => {
    it('emits a progress event on every tick while the operation is pending', async () => {
        vi.useFakeTimers();
        const events: OperationEvent[] = [];
        const { promise, resolve } = pendingPromise<string>();

        const resultPromise = withProgressHeartbeat(
            {
                emit: (event) => events.push(event),
                operationId: 'operation-1',
                stepId: 'install:shared-package',
                step: 'Install package',
                message: (elapsedSeconds) => `Installing shared-package (${elapsedSeconds}s)`
            },
            () => promise
        );

        await vi.advanceTimersByTimeAsync(DEFAULT_HEARTBEAT_INTERVAL_MS * 2);
        expect(events).toEqual([
            expect.objectContaining({
                kind: 'progress',
                stepId: 'install:shared-package',
                step: 'Install package',
                message: 'Installing shared-package (15s)'
            }),
            expect.objectContaining({ message: 'Installing shared-package (30s)' })
        ]);

        resolve('done');
        await expect(resultPromise).resolves.toBe('done');
    });

    it('stops ticking once the operation settles', async () => {
        vi.useFakeTimers();
        const events: OperationEvent[] = [];
        const { promise, resolve } = pendingPromise<string>();

        const resultPromise = withProgressHeartbeat(
            {
                emit: (event) => events.push(event),
                operationId: 'operation-1',
                stepId: 'step-1',
                step: 'Step',
                message: (elapsedSeconds) => `Still running (${elapsedSeconds}s)`
            },
            () => promise
        );

        await vi.advanceTimersByTimeAsync(DEFAULT_HEARTBEAT_INTERVAL_MS);
        expect(events).toHaveLength(1);

        resolve('done');
        await resultPromise;
        const countAfterSettle = events.length;

        await vi.advanceTimersByTimeAsync(DEFAULT_HEARTBEAT_INTERVAL_MS * 3);
        expect(events).toHaveLength(countAfterSettle);
    });

    it('honors a custom interval', async () => {
        vi.useFakeTimers();
        const events: OperationEvent[] = [];
        const { promise, resolve } = pendingPromise<string>();

        const resultPromise = withProgressHeartbeat(
            {
                emit: (event) => events.push(event),
                operationId: 'operation-1',
                stepId: 'step-1',
                step: 'Step',
                message: (elapsedSeconds) => `Still running (${elapsedSeconds}s)`,
                intervalMs: 1_000
            },
            () => promise
        );

        await vi.advanceTimersByTimeAsync(2_500);
        expect(events).toHaveLength(2);

        resolve('done');
        await resultPromise;
    });

    it('propagates a rejection and still clears the timer', async () => {
        vi.useFakeTimers();
        const events: OperationEvent[] = [];
        const { promise, reject } = pendingPromise<string>();
        const failure = new Error('command failed');

        const resultPromise = withProgressHeartbeat(
            {
                emit: (event) => events.push(event),
                operationId: 'operation-1',
                stepId: 'step-1',
                step: 'Step',
                message: (elapsedSeconds) => `Still running (${elapsedSeconds}s)`
            },
            () => promise
        );
        resultPromise.catch(() => undefined);

        await vi.advanceTimersByTimeAsync(DEFAULT_HEARTBEAT_INTERVAL_MS);
        expect(events).toHaveLength(1);

        reject(failure);
        await expect(resultPromise).rejects.toThrow('command failed');

        const countAfterSettle = events.length;
        await vi.advanceTimersByTimeAsync(DEFAULT_HEARTBEAT_INTERVAL_MS * 3);
        expect(events).toHaveLength(countAfterSettle);
    });

    it('resolves immediately without emitting when the operation settles before the first tick', async () => {
        vi.useFakeTimers();
        const events: OperationEvent[] = [];

        const result = await withProgressHeartbeat(
            {
                emit: (event) => events.push(event),
                operationId: 'operation-1',
                stepId: 'step-1',
                step: 'Step',
                message: () => 'Still running'
            },
            () => Promise.resolve('fast')
        );

        expect(result).toBe('fast');
        expect(events).toEqual([]);
    });
});
