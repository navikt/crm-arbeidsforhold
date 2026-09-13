import type { AddressInfo } from 'node:net';
import { mkdtemp, rm, symlink, writeFile } from 'node:fs/promises';
import { request as httpRequest } from 'node:http';
import { tmpdir } from 'node:os';
import path from 'node:path';
import { afterEach, describe, expect, it, vi } from 'vitest';
import { EXIT_CODES } from '../../src/domain/events.js';
import { startWebServer, type WebServiceFacade } from '../../src/web/server.js';

const servers: Array<{ close: () => Promise<void> }> = [];
const temporaryDirectories: string[] = [];

afterEach(async () => {
    await Promise.all(servers.splice(0).map((server) => server.close()));
    await Promise.all(
        temporaryDirectories.splice(0).map((directory) => rm(directory, { force: true, recursive: true }))
    );
});

function createFacade(): WebServiceFacade {
    return {
        listOrgs: vi.fn(async () => ({ orgs: [] })),
        getOrgStatus: vi.fn(async (alias) => createFacade().getOrg(alias ?? 'scratch')),
        getOrgPackages: vi.fn(async (alias) => ({
            targetOrg: alias,
            packages: [],
            summary: { total: 0, current: 0, updateAvailable: 0, higher: 0, missing: 0, unknown: 0 }
        })),
        getOrg: vi.fn(async () => ({
            org: {
                alias: 'scratch',
                username: null,
                orgId: null,
                orgType: 'scratch' as const,
                connectionStatus: 'connected' as const,
                authStatus: 'authenticated' as const,
                instanceUrlClassification: 'scratch' as const,
                expirationDate: null,
                remainingLifetimeDays: null,
                isDefaultOrg: false,
                isDefaultDevHub: false,
                sourceTracking: true,
                lastRefreshTimestamp: null,
                capabilities: { sourceTracking: true, mutationPolicy: 'allowed' as const }
            }
        })),
        execute: vi.fn(async (request, emit) => {
            emit({
                kind: 'progress',
                operationId: request.operationId,
                timestamp: new Date().toISOString(),
                stepId: 'fake',
                step: 'Fake operation',
                message: 'completed'
            });
            return EXIT_CODES.SUCCESS;
        })
    };
}

async function start(
    facade = createFacade(),
    options: {
        maxOperations?: number;
        maxEventsPerOperation?: number;
        maxSubscribers?: number;
        maxSubscribersPerOperation?: number;
        redactionSecrets?: string[];
        webAssetsDirectory?: string;
    } = {}
) {
    const started = await startWebServer({ port: 0, facade, ...options });
    servers.push(started);
    const address = started.server.address() as AddressInfo;
    return { ...started, baseUrl: `http://127.0.0.1:${address.port}`, facade };
}

async function requestWithHost(url: string, host: string, authorization?: string): Promise<number> {
    return new Promise((resolve, reject) => {
        const request = httpRequest(url, {
            headers: { host, ...(authorization === undefined ? {} : { authorization }) }
        });
        request.once('response', (response) => {
            response.resume();
            response.once('end', () => resolve(response.statusCode ?? 0));
        });
        request.once('error', reject);
        request.end();
    });
}

describe('web server', () => {
    it('serves the web app with a same-origin session bootstrap and security headers', async () => {
        const webAssetsDirectory = await mkdtemp(path.join(tmpdir(), 'sf-project-web-'));
        temporaryDirectories.push(webAssetsDirectory);
        await writeFile(
            path.join(webAssetsDirectory, 'index.html'),
            '<!doctype html><html><head></head><body><div id="root"></div></body></html>'
        );
        const started = await start(createFacade(), { webAssetsDirectory });

        const response = await fetch(`${started.baseUrl}/`);
        const html = await response.text();

        expect(response.status).toBe(200);
        expect(response.headers.get('content-security-policy')).toContain("default-src 'self'");
        expect(response.headers.get('referrer-policy')).toBe('no-referrer');
        expect(response.headers.get('x-frame-options')).toBe('DENY');
        expect(html).toContain(`<meta name="sf-project-session-token" content="${started.sessionToken}">`);
        expect(html).toContain('<div id="root"></div>');
    });

    it('serves built frontend assets with safe paths and content types', async () => {
        const webAssetsDirectory = await mkdtemp(path.join(tmpdir(), 'sf-project-web-'));
        temporaryDirectories.push(webAssetsDirectory);
        await writeFile(path.join(webAssetsDirectory, 'app.js'), 'globalThis.__webLoaded = true;');
        const started = await start(createFacade(), { webAssetsDirectory });

        const asset = await fetch(`${started.baseUrl}/app.js`);
        expect(asset.status).toBe(200);
        expect(asset.headers.get('content-type')).toBe('text/javascript; charset=utf-8');
        await expect(asset.text()).resolves.toContain('__webLoaded');

        const traversal = await fetch(`${started.baseUrl}/..%2Fpackage.json`);
        expect(traversal.status).toBe(404);
    });

    it('rejects static assets whose symlink target escapes the asset directory', async () => {
        const webAssetsDirectory = await mkdtemp(path.join(tmpdir(), 'sf-project-web-'));
        const outsideDirectory = await mkdtemp(path.join(tmpdir(), 'sf-project-outside-'));
        temporaryDirectories.push(webAssetsDirectory, outsideDirectory);
        const outsideAsset = path.join(outsideDirectory, 'outside.js');
        await writeFile(outsideAsset, 'globalThis.__escaped = true;');
        await symlink(outsideAsset, path.join(webAssetsDirectory, 'escaped.js'));
        const started = await start(createFacade(), { webAssetsDirectory });

        const response = await fetch(`${started.baseUrl}/escaped.js`);

        expect(response.status).toBe(404);
        await expect(response.text()).resolves.not.toContain('__escaped');
    });

    it('binds to loopback and exposes versioned health without disclosing the session token', async () => {
        const started = await start();

        expect((started.server.address() as AddressInfo).address).toBe('127.0.0.1');
        expect(started.sessionToken).toMatch(/^[a-f0-9]{64}$/);

        const response = await fetch(`${started.baseUrl}/api/v1/health`);
        const body = await response.json();

        expect(response.status).toBe(200);
        expect(body).toEqual({ status: 'ok', apiVersion: 'v1' });
        expect(JSON.stringify(body)).not.toContain(started.sessionToken);
    });

    it('rejects hostile Host headers on health and requires Host plus bearer authentication on every API read', async () => {
        const started = await start();
        const hostileHealthStatus = await requestWithHost(`${started.baseUrl}/api/v1/health`, 'attacker.example');
        const hostileBootstrapStatus = await requestWithHost(`${started.baseUrl}/`, 'attacker.example');
        const unauthenticatedRead = await fetch(`${started.baseUrl}/api/v1/orgs`);
        const hostileAuthenticatedReadStatus = await requestWithHost(
            `${started.baseUrl}/api/v1/operations`,
            'attacker.example',
            `Bearer ${started.sessionToken}`
        );
        const authenticatedRead = await fetch(`${started.baseUrl}/api/v1/orgs`, {
            headers: { authorization: `Bearer ${started.sessionToken}` }
        });

        expect(hostileHealthStatus).toBe(421);
        expect(hostileBootstrapStatus).toBe(421);
        expect(unauthenticatedRead.status).toBe(401);
        expect(hostileAuthenticatedReadStatus).toBe(421);
        expect(authenticatedRead.status).toBe(200);
    });

    it('requires bearer authentication and same-origin headers before dispatching an allowlisted operation', async () => {
        const started = await start();
        const request = {
            command: 'dependencies.clear',
            payload: { dryRun: true }
        };

        const unauthenticated = await fetch(`${started.baseUrl}/api/v1/operations`, {
            method: 'POST',
            headers: { 'content-type': 'application/json', origin: started.baseUrl },
            body: JSON.stringify(request)
        });
        expect(unauthenticated.status).toBe(401);

        const response = await fetch(`${started.baseUrl}/api/v1/operations`, {
            method: 'POST',
            headers: {
                authorization: `Bearer ${started.sessionToken}`,
                'content-type': 'application/json',
                origin: started.baseUrl
            },
            body: JSON.stringify(request)
        });
        const body = (await response.json()) as { id: string };

        expect(response.status).toBe(202);
        expect(body.id).toEqual(expect.any(String));
        expect(started.facade.execute).toHaveBeenCalledWith(
            expect.objectContaining({ command: 'dependencies.clear', payload: { dryRun: true } }),
            expect.any(Function)
        );
    });

    it.each(['dependencies.refresh', 'packages.install', 'packages.update'] as const)(
        'accepts %s without an explicit target org',
        async (command) => {
            const started = await start();
            const response = await fetch(`${started.baseUrl}/api/v1/operations`, {
                method: 'POST',
                headers: {
                    authorization: `Bearer ${started.sessionToken}`,
                    'content-type': 'application/json',
                    origin: started.baseUrl
                },
                body: JSON.stringify({ command, payload: { dryRun: true } })
            });

            expect(response.status).toBe(202);
            expect(started.facade.execute).toHaveBeenCalledWith(
                expect.objectContaining({ command, payload: { dryRun: true } }),
                expect.any(Function)
            );
        }
    );

    it('accepts project.configure without an explicit alias and checks the resolved default org policy', async () => {
        const facade = createFacade();
        const started = await start(facade);
        const response = await fetch(`${started.baseUrl}/api/v1/operations`, {
            method: 'POST',
            headers: {
                authorization: `Bearer ${started.sessionToken}`,
                'content-type': 'application/json',
                origin: started.baseUrl
            },
            body: JSON.stringify({ command: 'project.configure', payload: { dryRun: false } })
        });

        expect(response.status).toBe(202);
        expect(facade.getOrgStatus).toHaveBeenCalledWith();
        expect(facade.execute).toHaveBeenCalledWith(
            expect.objectContaining({ command: 'project.configure', payload: { dryRun: false } }),
            expect.any(Function)
        );
    });

    it('rejects a package mutation when the resolved default org is read-only', async () => {
        const facade = createFacade();
        facade.getOrgStatus = vi.fn(async () => ({
            org: {
                ...(await createFacade().getOrg('production')).org,
                alias: 'production',
                orgType: 'production' as const,
                capabilities: { sourceTracking: null, mutationPolicy: 'read-only' as const }
            }
        }));
        const started = await start(facade);

        const response = await fetch(`${started.baseUrl}/api/v1/operations`, {
            method: 'POST',
            headers: {
                authorization: `Bearer ${started.sessionToken}`,
                'content-type': 'application/json',
                origin: started.baseUrl
            },
            body: JSON.stringify({ command: 'packages.install', payload: {} })
        });

        expect(response.status).toBe(403);
        expect(facade.getOrgStatus).toHaveBeenCalledWith();
        expect(facade.execute).not.toHaveBeenCalled();
    });

    it('rejects cross-origin, unknown, and malformed mutation requests before facade dispatch', async () => {
        const started = await start();
        const post = (body: unknown, origin = started.baseUrl) =>
            fetch(`${started.baseUrl}/api/v1/operations`, {
                method: 'POST',
                headers: {
                    authorization: `Bearer ${started.sessionToken}`,
                    'content-type': 'application/json',
                    origin
                },
                body: JSON.stringify(body)
            });

        await expect(
            post({ command: 'dependencies.clear', payload: {} }, 'http://example.test')
        ).resolves.toMatchObject({ status: 403 });
        await expect(post({ command: 'doctor', payload: {} })).resolves.toMatchObject({ status: 400 });
        await expect(post({ command: 'dependencies.clear', payload: { unexpected: true } })).resolves.toMatchObject({
            status: 400
        });
        expect(started.facade.execute).not.toHaveBeenCalled();
    });

    it('exposes normalized org reads and blocks production or unknown org mutation', async () => {
        const facade = createFacade();
        const readOnlyOrg = async (alias: string) => ({
            org: {
                ...(await createFacade().getOrg(alias)).org,
                alias,
                orgType: alias === 'production' ? ('production' as const) : ('unknown' as const),
                capabilities: { sourceTracking: null, mutationPolicy: 'read-only' as const }
            }
        });
        vi.mocked(facade.getOrg).mockImplementation(readOnlyOrg);
        vi.mocked(facade.getOrgStatus).mockImplementation((alias) => readOnlyOrg(alias ?? 'mystery'));
        const started = await start(facade);

        const headers = { authorization: `Bearer ${started.sessionToken}` };
        const listResponse = await fetch(`${started.baseUrl}/api/v1/orgs`, { headers });
        const detailResponse = await fetch(`${started.baseUrl}/api/v1/orgs/production`, { headers });
        expect(listResponse.status).toBe(200);
        expect(detailResponse.status).toBe(200);

        for (const alias of ['production', 'mystery']) {
            const response = await fetch(`${started.baseUrl}/api/v1/operations`, {
                method: 'POST',
                headers: {
                    authorization: `Bearer ${started.sessionToken}`,
                    'content-type': 'application/json',
                    origin: started.baseUrl
                },
                body: JSON.stringify({ command: 'org.delete', payload: { alias, confirmed: true } })
            });
            expect(response.status).toBe(403);
        }
        expect(facade.execute).not.toHaveBeenCalled();
    });

    it('exposes selected-org package status through an authenticated endpoint', async () => {
        const facade = createFacade();
        facade.getOrgPackages = vi.fn(async (alias) => ({
            targetOrg: alias,
            packages: [
                {
                    packageName: 'shared-package',
                    configuredVersion: '1.0.0.LATEST',
                    installedVersion: '1.0.0.2',
                    selectedVersion: '1.0.0.3',
                    status: 'update-available' as const
                }
            ],
            summary: { total: 1, current: 0, updateAvailable: 1, higher: 0, missing: 0, unknown: 0 }
        }));
        const started = await start(facade);

        const response = await fetch(`${started.baseUrl}/api/v1/orgs/scratch%20org/packages`, {
            headers: { authorization: `Bearer ${started.sessionToken}` }
        });

        expect(response.status).toBe(200);
        await expect(response.json()).resolves.toMatchObject({
            targetOrg: 'scratch org',
            summary: { total: 1, updateAvailable: 1 }
        });
        expect(facade.getOrgPackages).toHaveBeenCalledWith('scratch org');
    });

    it('lists operations, returns details, and bounds redacted event history', async () => {
        const salesforceToken = `00D${'A'.repeat(12)}!secret-token-value`;
        const installationKey = 'package-installation-secret';
        const facade = createFacade();
        vi.mocked(facade.execute).mockImplementation(async (request, emit) => {
            emit({
                kind: 'progress',
                operationId: request.operationId,
                timestamp: new Date().toISOString(),
                stepId: 'secret',
                step: 'Secret output',
                message: `${salesforceToken} ${installationKey}`,
                environment: { PACKAGE_INSTALL_KEY: installationKey },
                authFile: '/tmp/auth.json'
            } as never);
            emit({
                kind: 'progress',
                operationId: request.operationId,
                timestamp: new Date().toISOString(),
                stepId: 'latest',
                step: 'Latest output',
                message: 'retained'
            });
            return 0;
        });
        const started = await start(facade, {
            maxOperations: 2,
            maxEventsPerOperation: 2,
            redactionSecrets: [installationKey]
        });

        const operationIds: string[] = [];
        for (let index = 0; index < 3; index += 1) {
            const response = await fetch(`${started.baseUrl}/api/v1/operations`, {
                method: 'POST',
                headers: {
                    authorization: `Bearer ${started.sessionToken}`,
                    'content-type': 'application/json',
                    origin: started.baseUrl
                },
                body: JSON.stringify({ command: 'dependencies.clear', payload: { dryRun: true } })
            });
            operationIds.push(((await response.json()) as { id: string }).id);
        }
        await new Promise((resolve) => setImmediate(resolve));

        const headers = { authorization: `Bearer ${started.sessionToken}` };
        const list = await fetch(`${started.baseUrl}/api/v1/operations`, { headers });
        const operations = (await list.json()) as Array<{ id: string }>;
        expect(operations).toHaveLength(2);
        expect(operations.map(({ id }) => id)).toEqual(operationIds.slice(1).reverse());
        await expect(
            fetch(`${started.baseUrl}/api/v1/operations/${operationIds[0]}`, { headers })
        ).resolves.toMatchObject({ status: 404 });

        const detail = await fetch(`${started.baseUrl}/api/v1/operations/${operationIds[2]}`, { headers });
        const serialized = JSON.stringify(await detail.json());
        expect(serialized).toContain('retained');
        expect(serialized).not.toContain(salesforceToken);
        expect(serialized).not.toContain(installationKey);
        expect(serialized).not.toContain('PACKAGE_INSTALL_KEY');
        expect(serialized).not.toContain('auth.json');
    });

    it('replays stored events over SSE, streams live events, and removes disconnected subscribers', async () => {
        let emitLive: ((message: string) => void) | undefined;
        let finish: (() => void) | undefined;
        const facade = createFacade();
        vi.mocked(facade.execute).mockImplementation(
            (request, emit) =>
                new Promise((resolve) => {
                    emit({
                        kind: 'progress',
                        operationId: request.operationId,
                        timestamp: new Date().toISOString(),
                        stepId: 'replay',
                        step: 'Replay',
                        message: 'stored event'
                    });
                    emitLive = (message) =>
                        emit({
                            kind: 'progress',
                            operationId: request.operationId,
                            timestamp: new Date().toISOString(),
                            stepId: 'live',
                            step: 'Live',
                            message
                        });
                    finish = () => resolve(0);
                })
        );
        const started = await start(facade);
        const createResponse = await fetch(`${started.baseUrl}/api/v1/operations`, {
            method: 'POST',
            headers: {
                authorization: `Bearer ${started.sessionToken}`,
                'content-type': 'application/json',
                origin: started.baseUrl
            },
            body: JSON.stringify({ command: 'dependencies.clear', payload: { dryRun: true } })
        });
        const { id } = (await createResponse.json()) as { id: string };
        const abortController = new AbortController();
        const eventsResponse = await fetch(`${started.baseUrl}/api/v1/operations/${id}/events`, {
            headers: { authorization: `Bearer ${started.sessionToken}` },
            signal: abortController.signal
        });
        const reader = eventsResponse.body?.getReader();
        expect(eventsResponse.headers.get('content-type')).toContain('text/event-stream');
        expect(started.subscriberCount(id)).toBe(1);

        const decoder = new TextDecoder();
        let received = decoder.decode((await reader?.read())?.value);
        emitLive?.('live event');
        while (!received.includes('live event')) {
            received += decoder.decode((await reader?.read())?.value);
        }
        expect(received).toContain('stored event');
        expect(received).toContain('live event');

        abortController.abort();
        await reader?.cancel().catch(() => undefined);
        await vi.waitFor(() => expect(started.subscriberCount(id)).toBe(0));
        finish?.();
    });

    it('replays a terminal completion after a rejected operation', async () => {
        const facade = createFacade();
        vi.mocked(facade.execute).mockRejectedValue(new Error('operation failed'));
        const started = await start(facade);
        const authorization = { authorization: `Bearer ${started.sessionToken}` };
        const createResponse = await fetch(`${started.baseUrl}/api/v1/operations`, {
            method: 'POST',
            headers: {
                ...authorization,
                'content-type': 'application/json',
                origin: started.baseUrl
            },
            body: JSON.stringify({ command: 'dependencies.clear', payload: { dryRun: true } })
        });
        const { id } = (await createResponse.json()) as { id: string };

        await vi.waitFor(async () => {
            const response = await fetch(`${started.baseUrl}/api/v1/operations/${id}`, { headers: authorization });
            const operation = (await response.json()) as {
                status: string;
                exitCode: number;
                events: Array<{ kind: string; exitCode: number; durationMs: number }>;
            };
            expect(operation.status).toBe('failed');
            expect(operation.exitCode).toBe(EXIT_CODES.OPERATION_FAILURE);
            expect(operation.events.map(({ kind }) => kind)).toEqual([
                'operation-started',
                'step-failed',
                'operation-completed'
            ]);
            expect(operation.events.at(-1)).toMatchObject({
                kind: 'operation-completed',
                exitCode: EXIT_CODES.OPERATION_FAILURE,
                durationMs: expect.any(Number)
            });
        });

        const abortController = new AbortController();
        const replay = await fetch(`${started.baseUrl}/api/v1/operations/${id}/events`, {
            headers: authorization,
            signal: abortController.signal
        });
        const replayText = new TextDecoder().decode((await replay.body?.getReader().read())?.value);
        abortController.abort();
        await replay.body?.cancel().catch(() => undefined);
        expect(replayText).toContain('step-failed');
        expect(replayText).toContain('operation-completed');
    });

    it('rejects unauthenticated SSE and bounds subscribers globally and per operation', async () => {
        const facade = createFacade();
        vi.mocked(facade.execute).mockImplementation(() => new Promise(() => undefined));
        const started = await start(facade, { maxSubscribers: 2, maxSubscribersPerOperation: 1 });
        const createOperation = async (): Promise<string> => {
            const response = await fetch(`${started.baseUrl}/api/v1/operations`, {
                method: 'POST',
                headers: {
                    authorization: `Bearer ${started.sessionToken}`,
                    'content-type': 'application/json',
                    origin: started.baseUrl
                },
                body: JSON.stringify({ command: 'dependencies.clear', payload: { dryRun: true } })
            });
            return ((await response.json()) as { id: string }).id;
        };
        const authorization = { authorization: `Bearer ${started.sessionToken}` };
        const firstId = await createOperation();
        const firstStreamUrl = `${started.baseUrl}/api/v1/operations/${firstId}/events`;

        await expect(fetch(firstStreamUrl)).resolves.toMatchObject({ status: 401 });
        const firstAbort = new AbortController();
        const first = await fetch(firstStreamUrl, {
            headers: authorization,
            signal: firstAbort.signal
        });
        expect(first.status).toBe(200);
        await expect(fetch(firstStreamUrl, { headers: authorization })).resolves.toMatchObject({ status: 429 });

        const secondAbort = new AbortController();
        const secondId = await createOperation();
        const second = await fetch(`${started.baseUrl}/api/v1/operations/${secondId}/events`, {
            headers: authorization,
            signal: secondAbort.signal
        });
        expect(second.status).toBe(200);

        const thirdId = await createOperation();
        await expect(
            fetch(`${started.baseUrl}/api/v1/operations/${thirdId}/events`, { headers: authorization })
        ).resolves.toMatchObject({ status: 429 });

        firstAbort.abort();
        secondAbort.abort();
        await first.body?.cancel().catch(() => undefined);
        await second.body?.cancel().catch(() => undefined);
    });

    it('omits sensitive key variants and redacts auth URLs and refresh tokens from structures and errors', async () => {
        const refreshToken = '5Aep861refresh-token-secret';
        const authUrl = `force://client:${refreshToken}@login.salesforce.com`;
        const facade = createFacade();
        vi.mocked(facade.listOrgs).mockResolvedValue({
            orgs: [],
            REFRESH_TOKEN: refreshToken,
            AuthUrl: authUrl,
            nested: { authorization: authUrl }
        } as never);
        vi.mocked(facade.getOrg).mockRejectedValue(new Error(`Authentication failed for ${authUrl}`));
        const started = await start(facade);
        const headers = { authorization: `Bearer ${started.sessionToken}` };

        const list = JSON.stringify(await (await fetch(`${started.baseUrl}/api/v1/orgs`, { headers })).json());
        const detail = JSON.stringify(
            await (await fetch(`${started.baseUrl}/api/v1/orgs/missing`, { headers })).json()
        );

        expect(list).not.toMatch(/refresh_token|authurl|authorization/i);
        expect(list).not.toContain(refreshToken);
        expect(list).not.toContain(authUrl);
        expect(detail).not.toContain(refreshToken);
        expect(detail).not.toContain(authUrl);
        expect(detail).toContain('[REDACTED]');
    });

    it('rejects overlong strings and strings containing control characters', async () => {
        const started = await start();
        const post = (alias: string) =>
            fetch(`${started.baseUrl}/api/v1/operations`, {
                method: 'POST',
                headers: {
                    authorization: `Bearer ${started.sessionToken}`,
                    'content-type': 'application/json',
                    origin: started.baseUrl
                },
                body: JSON.stringify({ command: 'org.create', payload: { alias, dryRun: true } })
            });

        await expect(post(`unsafe\nvalue`)).resolves.toMatchObject({ status: 400 });
        await expect(post('a'.repeat(1025))).resolves.toMatchObject({ status: 400 });
        expect(started.facade.execute).not.toHaveBeenCalled();
    });

    it('rejects cancellation when the facade does not support it', async () => {
        const started = await start();
        const response = await fetch(`${started.baseUrl}/api/v1/operations/missing/cancel`, {
            method: 'POST',
            headers: {
                authorization: `Bearer ${started.sessionToken}`,
                origin: started.baseUrl
            }
        });

        expect(response.status).toBe(409);
        await expect(response.json()).resolves.toEqual({ error: 'Cancellation is not supported' });
    });

    it('rejects non-loopback binding', async () => {
        await expect(startWebServer({ host: '0.0.0.0', port: 0, facade: createFacade() })).rejects.toThrow('127.0.0.1');
    });
});
