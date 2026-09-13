import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { browserApi, type DashboardApi, type OperationEvent } from './api';

const sessionToken = 'ephemeral-session-token';

beforeEach(() => {
    document.head.innerHTML = `<meta name="sf-project-session-token" content="${sessionToken}">`;
});

afterEach(() => {
    vi.unstubAllGlobals();
});

describe('browser API authentication', () => {
    it('authenticates every read with the bootstrapped bearer token', async () => {
        const fetchMock = vi
            .fn()
            .mockResolvedValueOnce(new Response(JSON.stringify({ orgs: [] })))
            .mockResolvedValueOnce(new Response(JSON.stringify({ org: { alias: 'scratch' } })))
            .mockResolvedValueOnce(
                new Response(JSON.stringify({ targetOrg: 'scratch', packages: [], summary: { total: 0 } }))
            )
            .mockResolvedValueOnce(new Response(JSON.stringify([])));
        vi.stubGlobal('fetch', fetchMock);

        await browserApi.listOrgs();
        await browserApi.getOrg('scratch');
        await (browserApi as DashboardApi & { getOrgPackages(alias: string): Promise<unknown> }).getOrgPackages(
            'scratch'
        );
        await browserApi.listOperations();

        for (const [, init] of fetchMock.mock.calls) {
            expect(new Headers(init?.headers).get('authorization')).toBe(`Bearer ${sessionToken}`);
        }
        expect(fetchMock.mock.calls[2]?.[0]).toBe('/api/v1/orgs/scratch/packages');
    });

    it('streams authenticated SSE replay and live events and aborts on cleanup', async () => {
        const replay: OperationEvent = {
            kind: 'progress',
            operationId: 'operation-1',
            timestamp: '2026-09-13T10:00:00.000Z',
            message: 'replay'
        };
        const live: OperationEvent = { ...replay, timestamp: '2026-09-13T10:00:01.000Z', message: 'live' };
        let streamController: ReadableStreamDefaultController<Uint8Array> | undefined;
        const stream = new ReadableStream<Uint8Array>({
            start(controller) {
                streamController = controller;
                controller.enqueue(new TextEncoder().encode(`event: operation\ndata: ${JSON.stringify(replay)}\n\n`));
            }
        });
        const fetchMock = vi.fn(async (_input: RequestInfo | URL, init?: RequestInit) => {
            expect(new Headers(init?.headers).get('authorization')).toBe(`Bearer ${sessionToken}`);
            expect(init?.signal).toBeInstanceOf(AbortSignal);
            return new Response(stream, { status: 200, headers: { 'content-type': 'text/event-stream' } });
        });
        vi.stubGlobal('fetch', fetchMock);
        const received: OperationEvent[] = [];

        const unsubscribe = browserApi.subscribe('operation-1', (event) => received.push(event));
        await vi.waitFor(() => expect(received).toEqual([replay]));
        streamController?.enqueue(new TextEncoder().encode(`event: operation\ndata: ${JSON.stringify(live)}\n\n`));
        await vi.waitFor(() => expect(received).toEqual([replay, live]));
        unsubscribe();

        expect((fetchMock.mock.calls[0]?.[1]?.signal as AbortSignal).aborted).toBe(true);
    });
});
