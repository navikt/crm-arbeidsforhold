/**
 * Hosts the authenticated loopback HTTP and SSE adapter for application services and dashboard assets.
 * Requests are token-protected and allowlisted, while operation history and subscribers remain bounded in memory.
 */
import { randomBytes, randomUUID, timingSafeEqual } from 'node:crypto';
import { readFile, realpath } from 'node:fs/promises';
import { createServer, type IncomingMessage, type Server, type ServerResponse } from 'node:http';
import type { AddressInfo } from 'node:net';
import path from 'node:path';
import type { OrgListResult, OrgResult } from '../application/org-inspection.js';
import type { OrgPackageStatusResult } from '../domain/packages.js';
import { EXIT_CODES, type EventSink, type ExitCode, type OperationEvent } from '../domain/events.js';
import { isOrgMutationConfirmed } from '../domain/org-policy.js';
import { createRedactor } from '../infrastructure/redactor.js';

/** Commands accepted by the local web API for asynchronous execution. */
export type WebOperationCommand =
    | 'dependencies.clear'
    | 'dependencies.refresh'
    | 'packages.plan'
    | 'packages.install'
    | 'packages.update'
    | 'org.create'
    | 'org.delete'
    | 'project.configure';

/** Validated operation passed from the HTTP boundary to the application facade. */
export interface WebOperationRequest {
    /** Server-generated identifier shared by the response, emitted events, history, and cancellation. */
    operationId: string;
    /** Allowlisted application command to execute. */
    command: WebOperationCommand;
    /** Command-specific, validated input with sensitive or unknown fields rejected at the HTTP boundary. */
    payload: Readonly<Record<string, unknown>>;
}

/** Injected application boundary used by the HTTP server for reads, mutations, events, and cancellation. */
export interface WebServiceFacade {
    /** @returns The normalized org list exposed by the authenticated API. */
    listOrgs(): Promise<OrgListResult>;
    /**
     * @param alias - Org alias or username selected by the caller.
     * @returns Normalized details for the selected org.
     */
    getOrg(alias: string): Promise<OrgResult>;
    /**
     * Resolves the org and its mutation policy before a state-changing operation is dispatched.
     *
     * @param alias - Explicit org alias or username, or `undefined` to resolve the configured default.
     * @returns Normalized org details including mutation capabilities.
     */
    getOrgStatus(alias?: string): Promise<OrgResult>;
    /**
     * @param alias - Org alias or username whose installed packages are inspected.
     * @returns Normalized package status for the selected org.
     */
    getOrgPackages(alias: string): Promise<OrgPackageStatusResult>;
    /**
     * Executes an accepted operation and emits progress through the supplied sink. Implementations own all
     * command, filesystem, and Salesforce side effects and must not emit a terminal `operation-completed` event.
     *
     * @param request - Server-identified and validated operation request.
     * @param emit - Sink for non-terminal operation events; the server redacts, stores, and broadcasts them.
     * @returns The stable exit code used to derive the operation's terminal state.
     * @throws When execution cannot return an exit code; the server converts rejection into failed terminal events.
     */
    execute(request: WebOperationRequest, emit: EventSink): Promise<ExitCode>;
    /**
     * Requests cancellation of an in-flight operation when supported by the facade.
     *
     * @param operationId - Server-generated operation identifier.
     * @returns `true` when cancellation was accepted, otherwise `false`.
     */
    cancel?(operationId: string): Promise<boolean>;
}

/** Security, retention, capacity, asset, and application dependencies for the local web server. */
export interface StartWebServerOptions {
    /** Application facade that performs reads and side effects after HTTP validation and authorization. */
    facade: WebServiceFacade;
    /** Bind host; only `127.0.0.1` is accepted and omission uses that loopback address. */
    host?: string;
    /** TCP port from 0 through 65535; `0` or omission allows the operating system to choose an available port. */
    port?: number;
    /** Maximum operations retained in memory before the oldest operation and its subscribers are removed. */
    maxOperations?: number;
    /** Maximum redacted events retained and replayed for each operation. */
    maxEventsPerOperation?: number;
    /** Maximum simultaneous SSE subscribers across all operations. */
    maxSubscribers?: number;
    /** Maximum simultaneous SSE subscribers for one operation. */
    maxSubscribersPerOperation?: number;
    /** Additional secret values removed from responses, stored history, SSE events, and reported errors. */
    redactionSecrets?: readonly string[];
    /** Static asset root; resolved paths and symlink targets must remain contained within this directory. */
    webAssetsDirectory?: string;
}

/** Running loopback server resources and the bearer credential required by its private API. */
export interface StartedWebServer {
    /** Listening Node.js HTTP server owned by this handle. */
    server: Server;
    /** Per-process bearer token injected into the bootstrap document; callers must not log or persist it. */
    sessionToken: string;
    /** Loopback origin containing the actual bound port. */
    url: string;
    /**
     * Counts active SSE clients after pruning closed responses.
     *
     * @param operationId - Operation whose subscribers are counted.
     * @returns The number of active subscribers for the operation.
     */
    subscriberCount(operationId: string): number;
    /** Ends all SSE responses and stops accepting connections. Safe lifecycle ownership requires awaiting completion. */
    close(): Promise<void>;
}

type OperationStatus = 'running' | 'completed' | 'failed';

interface StoredOperation {
    id: string;
    command: WebOperationCommand;
    status: OperationStatus;
    createdAt: string;
    completedAt?: string;
    exitCode?: ExitCode;
    events: OperationEvent[];
}

const LOOPBACK_HOST = '127.0.0.1';
const MAX_BODY_BYTES = 64 * 1024;
const DEFAULT_MAX_OPERATIONS = 100;
const DEFAULT_MAX_EVENTS = 500;
const DEFAULT_MAX_SUBSCRIBERS = 32;
const DEFAULT_MAX_SUBSCRIBERS_PER_OPERATION = 4;
const MAX_STRING_LENGTH = 1024;
const SENSITIVE_KEYS = new Set([
    'accesstoken',
    'token',
    'refreshtoken',
    'installationkey',
    'packageinstallkey',
    'authfile',
    'authurl',
    'authorization',
    'environment',
    'env'
]);
const ALLOWED_COMMANDS = new Set<WebOperationCommand>([
    'dependencies.clear',
    'dependencies.refresh',
    'packages.plan',
    'packages.install',
    'packages.update',
    'org.create',
    'org.delete',
    'project.configure'
]);
const POST_STEPS = new Set(['deploy', 'permsets', 'data', 'community']);
const CONTENT_SECURITY_POLICY = [
    "default-src 'self'",
    "script-src 'self'",
    "style-src 'self' 'unsafe-inline'",
    "font-src 'self'",
    "img-src 'self' data:",
    "connect-src 'self'",
    "object-src 'none'",
    "base-uri 'none'",
    "frame-ancestors 'none'",
    "form-action 'self'"
].join('; ');
const ASSET_CONTENT_TYPES = new Map([
    ['.css', 'text/css; charset=utf-8'],
    ['.js', 'text/javascript; charset=utf-8'],
    ['.map', 'application/json; charset=utf-8'],
    ['.svg', 'image/svg+xml'],
    ['.woff', 'font/woff'],
    ['.woff2', 'font/woff2']
]);

function securityHeaders(): Record<string, string> {
    return {
        'content-security-policy': CONTENT_SECURITY_POLICY,
        'cross-origin-opener-policy': 'same-origin',
        'referrer-policy': 'no-referrer',
        'x-content-type-options': 'nosniff',
        'x-frame-options': 'DENY'
    };
}

function sendJson(response: ServerResponse, statusCode: number, value: unknown): void {
    response.writeHead(statusCode, {
        'cache-control': 'no-store',
        'content-type': 'application/json; charset=utf-8',
        ...securityHeaders()
    });
    response.end(JSON.stringify(value));
}

function tokenMatches(header: string | undefined, sessionToken: string): boolean {
    if (header === undefined || !header.startsWith('Bearer ')) return false;
    const candidate = Buffer.from(header.slice('Bearer '.length));
    const expected = Buffer.from(sessionToken);
    // Equal-length comparison avoids leaking token bytes through ordinary string comparison timing.
    return candidate.length === expected.length && timingSafeEqual(candidate, expected);
}

function hasAllowedHost(request: IncomingMessage): boolean {
    const localPort = request.socket.localPort;
    return localPort !== undefined && request.headers.host === `${LOOPBACK_HOST}:${localPort}`;
}

function isSameOrigin(request: IncomingMessage): boolean {
    const host = request.headers.host;
    const origin = request.headers.origin;
    if (host === undefined || origin === undefined) return false;
    try {
        const parsedOrigin = new URL(origin);
        const parsedHost = new URL(`http://${host}`);
        return (
            parsedOrigin.protocol === 'http:' &&
            parsedOrigin.host === parsedHost.host &&
            parsedHost.hostname === LOOPBACK_HOST
        );
    } catch {
        return false;
    }
}

async function readJson(request: IncomingMessage): Promise<unknown> {
    const chunks: Buffer[] = [];
    let size = 0;
    for await (const chunk of request) {
        const buffer = Buffer.isBuffer(chunk) ? chunk : Buffer.from(chunk);
        size += buffer.length;
        if (size > MAX_BODY_BYTES) throw new RangeError('Request body is too large');
        chunks.push(buffer);
    }
    return JSON.parse(Buffer.concat(chunks).toString('utf8')) as unknown;
}

function isRecord(value: unknown): value is Record<string, unknown> {
    return value !== null && typeof value === 'object' && !Array.isArray(value);
}

function hasOnlyKeys(record: Record<string, unknown>, keys: readonly string[]): boolean {
    const allowed = new Set(keys);
    return Object.keys(record).every((key) => allowed.has(key));
}

function optionalBoolean(record: Record<string, unknown>, key: string): boolean {
    return record[key] === undefined || typeof record[key] === 'boolean';
}

function validString(value: unknown): value is string {
    return (
        typeof value === 'string' &&
        value.length > 0 &&
        value.length <= MAX_STRING_LENGTH &&
        ![...value].some((character) => {
            const codePoint = character.codePointAt(0) ?? 0;
            return codePoint <= 31 || codePoint === 127;
        })
    );
}

function optionalString(record: Record<string, unknown>, key: string): boolean {
    return record[key] === undefined || validString(record[key]);
}

function requiredString(record: Record<string, unknown>, key: string): boolean {
    return validString(record[key]);
}

function validPostSteps(value: unknown): boolean {
    return (
        value === undefined ||
        (Array.isArray(value) && value.every((step) => validString(step) && POST_STEPS.has(step)))
    );
}

function validPayload(command: WebOperationCommand, payload: Record<string, unknown>): boolean {
    switch (command) {
        case 'dependencies.clear':
            return hasOnlyKeys(payload, ['dryRun']) && optionalBoolean(payload, 'dryRun');
        case 'dependencies.refresh':
            return (
                hasOnlyKeys(payload, ['targetOrg', 'dryRun']) &&
                optionalString(payload, 'targetOrg') &&
                optionalBoolean(payload, 'dryRun')
            );
        case 'packages.plan':
            return (
                hasOnlyKeys(payload, ['targetOrg', 'installLatest', 'dryRun']) &&
                optionalString(payload, 'targetOrg') &&
                optionalBoolean(payload, 'installLatest') &&
                optionalBoolean(payload, 'dryRun')
            );
        case 'packages.install':
        case 'packages.update':
            return (
                hasOnlyKeys(payload, ['targetOrg', 'installLatest', 'dryRun', 'confirmMutation']) &&
                optionalString(payload, 'targetOrg') &&
                optionalBoolean(payload, 'installLatest') &&
                optionalBoolean(payload, 'dryRun') &&
                optionalString(payload, 'confirmMutation')
            );
        case 'org.create':
            return (
                hasOnlyKeys(payload, [
                    'alias',
                    'durationDays',
                    'postSteps',
                    'usePool',
                    'poolTag',
                    'poolDevHub',
                    'fallbackToCreate',
                    'clearDependencySources',
                    'refreshDependencySources',
                    'dryRun'
                ]) &&
                requiredString(payload, 'alias') &&
                (payload.durationDays === undefined ||
                    (Number.isInteger(payload.durationDays) &&
                        Number(payload.durationDays) >= 1 &&
                        Number(payload.durationDays) <= 30)) &&
                validPostSteps(payload.postSteps) &&
                optionalBoolean(payload, 'usePool') &&
                optionalString(payload, 'poolTag') &&
                optionalString(payload, 'poolDevHub') &&
                optionalBoolean(payload, 'fallbackToCreate') &&
                optionalBoolean(payload, 'clearDependencySources') &&
                optionalBoolean(payload, 'refreshDependencySources') &&
                optionalBoolean(payload, 'dryRun')
            );
        case 'org.delete':
            return (
                hasOnlyKeys(payload, ['alias', 'confirmed', 'dryRun', 'confirmMutation']) &&
                requiredString(payload, 'alias') &&
                optionalBoolean(payload, 'confirmed') &&
                optionalBoolean(payload, 'dryRun') &&
                optionalString(payload, 'confirmMutation') &&
                (payload.dryRun === true || payload.confirmed === true || payload.confirmMutation !== undefined)
            );
        case 'project.configure':
            return (
                hasOnlyKeys(payload, ['alias', 'postSteps', 'refreshDependencySources', 'dryRun', 'confirmMutation']) &&
                optionalString(payload, 'alias') &&
                validPostSteps(payload.postSteps) &&
                optionalBoolean(payload, 'refreshDependencySources') &&
                optionalBoolean(payload, 'dryRun') &&
                optionalString(payload, 'confirmMutation')
            );
    }
}

function parseOperationRequest(value: unknown): Omit<WebOperationRequest, 'operationId'> | null {
    if (!isRecord(value) || !hasOnlyKeys(value, ['command', 'payload'])) return null;
    if (typeof value.command !== 'string' || !ALLOWED_COMMANDS.has(value.command as WebOperationCommand)) return null;
    if (!isRecord(value.payload)) return null;
    const command = value.command as WebOperationCommand;
    return validPayload(command, value.payload) ? { command, payload: value.payload } : null;
}

function mutationTarget(request: Omit<WebOperationRequest, 'operationId'>): string | null | undefined {
    if (request.payload.dryRun === true) return null;
    if (request.command === 'dependencies.refresh' || request.command.startsWith('packages.')) {
        if (request.command === 'packages.plan') return null;
        return typeof request.payload.targetOrg === 'string' ? request.payload.targetOrg : undefined;
    }
    if (request.command === 'org.delete') {
        return String(request.payload.alias);
    }
    if (request.command === 'project.configure') {
        return typeof request.payload.alias === 'string' ? request.payload.alias : undefined;
    }
    return null;
}

function omitSensitiveFields(value: unknown): unknown {
    if (Array.isArray(value)) return value.map(omitSensitiveFields);
    if (!isRecord(value)) return value;
    return Object.fromEntries(
        Object.entries(value)
            .filter(([key]) => !SENSITIVE_KEYS.has(key.replace(/[^a-z0-9]/gi, '').toLowerCase()))
            .map(([key, item]) => [key, omitSensitiveFields(item)])
    );
}

function publicOperation(operation: StoredOperation): StoredOperation {
    return { ...operation, events: [...operation.events] };
}

/**
 * Starts an authenticated HTTP and SSE API that is restricted to the IPv4 loopback interface.
 *
 * The server creates a fresh bearer token, validates mutation origins and org mutation policy, redacts API output,
 * keeps bounded in-memory operation history, and serves only contained static assets. Starting the server opens a
 * listening socket; operation requests may trigger the injected facade's side effects.
 *
 * @param options - Facade, bind settings, retention limits, redaction secrets, and optional static asset root.
 * @returns A handle containing the listening server, private session token, URL, subscriber inspection, and cleanup.
 * @throws If bind or capacity options are invalid, the host is not `127.0.0.1`, or the server cannot listen.
 */
export async function startWebServer(options: StartWebServerOptions): Promise<StartedWebServer> {
    const host = options.host ?? LOOPBACK_HOST;
    if (host !== LOOPBACK_HOST) throw new Error('Web server host must be 127.0.0.1');
    const port = options.port ?? 0;
    if (!Number.isInteger(port) || port < 0 || port > 65_535) throw new Error('Web server port must be 0-65535');
    const maxOperations = options.maxOperations ?? DEFAULT_MAX_OPERATIONS;
    const maxEvents = options.maxEventsPerOperation ?? DEFAULT_MAX_EVENTS;
    const maxSubscribers = options.maxSubscribers ?? DEFAULT_MAX_SUBSCRIBERS;
    const maxSubscribersPerOperation = options.maxSubscribersPerOperation ?? DEFAULT_MAX_SUBSCRIBERS_PER_OPERATION;
    if (!Number.isInteger(maxOperations) || maxOperations < 1) throw new Error('maxOperations must be positive');
    if (!Number.isInteger(maxEvents) || maxEvents < 1) throw new Error('maxEventsPerOperation must be positive');
    if (!Number.isInteger(maxSubscribers) || maxSubscribers < 1) throw new Error('maxSubscribers must be positive');
    if (!Number.isInteger(maxSubscribersPerOperation) || maxSubscribersPerOperation < 1) {
        throw new Error('maxSubscribersPerOperation must be positive');
    }

    const sessionToken = randomBytes(32).toString('hex');
    const redactor = createRedactor([sessionToken, ...(options.redactionSecrets ?? [])]);
    const webAssetsDirectory = options.webAssetsDirectory ?? path.resolve(import.meta.dirname, '../web-dist');
    const operations = new Map<string, StoredOperation>();
    const subscribers = new Map<string, Set<ServerResponse>>();

    const subscriberTotal = (): number =>
        [...subscribers.values()].reduce((total, operationSubscribers) => total + operationSubscribers.size, 0);
    const readContainedAsset = async (relativePath: string): Promise<Buffer> => {
        // Real paths contain both traversal and symlink targets beneath the configured static root.
        const assetsRealPath = await realpath(webAssetsDirectory);
        const assetRealPath = await realpath(path.resolve(webAssetsDirectory, relativePath));
        const relativeAssetPath = path.relative(assetsRealPath, assetRealPath);
        if (relativeAssetPath.startsWith('..') || path.isAbsolute(relativeAssetPath)) {
            throw new Error('Asset path escapes web root');
        }
        return readFile(assetRealPath);
    };

    const sanitize = <T>(value: T): T => redactor.redactValue(omitSensitiveFields(value)) as T;
    const publish = (operation: StoredOperation, event: OperationEvent): void => {
        const safeEvent = sanitize(event);
        // Persist exactly what SSE clients receive, with bounded history for replay and API inspection.
        operation.events.push(safeEvent);
        if (operation.events.length > maxEvents) operation.events.splice(0, operation.events.length - maxEvents);
        for (const subscriber of subscribers.get(operation.id) ?? []) {
            subscriber.write(`event: operation\ndata: ${JSON.stringify(safeEvent)}\n\n`);
        }
    };
    const removeOperation = (operationId: string): void => {
        for (const subscriber of subscribers.get(operationId) ?? []) subscriber.end();
        subscribers.delete(operationId);
        operations.delete(operationId);
    };
    const retainOperation = (operation: StoredOperation): void => {
        operations.set(operation.id, operation);
        while (operations.size > maxOperations) {
            const oldestId = operations.keys().next().value as string | undefined;
            if (oldestId !== undefined) removeOperation(oldestId);
        }
    };
    const authorizeMutation = (request: IncomingMessage, response: ServerResponse): boolean => {
        // Bearer authentication is checked globally; mutation routes additionally require browser same-origin proof.
        if (!isSameOrigin(request)) {
            sendJson(response, 403, { error: 'Origin does not match Host' });
            return false;
        }
        return true;
    };
    const beginOperation = (request: Omit<WebOperationRequest, 'operationId'>, response: ServerResponse): void => {
        const operationId = randomUUID();
        const createdAt = new Date().toISOString();
        const operation: StoredOperation = {
            id: operationId,
            command: request.command,
            status: 'running',
            createdAt,
            events: []
        };
        retainOperation(operation);
        publish(operation, {
            kind: 'operation-started',
            operationId,
            operation: request.command,
            timestamp: createdAt,
            dryRun: request.payload.dryRun === true
        });
        const startedAt = Date.now();
        void options.facade
            .execute({ ...request, operationId }, (event) => publish(operation, event))
            .then((exitCode) => {
                operation.status = exitCode === EXIT_CODES.SUCCESS ? 'completed' : 'failed';
                operation.exitCode = exitCode;
                operation.completedAt = new Date().toISOString();
                publish(operation, {
                    kind: 'operation-completed',
                    operationId,
                    operation: request.command,
                    timestamp: operation.completedAt,
                    exitCode,
                    durationMs: Date.now() - startedAt,
                    dryRun: request.payload.dryRun === true
                });
            })
            .catch((error: unknown) => {
                operation.status = 'failed';
                operation.exitCode = EXIT_CODES.OPERATION_FAILURE;
                operation.completedAt = new Date().toISOString();
                const durationMs = Date.now() - startedAt;
                publish(operation, {
                    kind: 'step-failed',
                    operationId,
                    timestamp: operation.completedAt,
                    stepId: 'web-operation',
                    step: request.command,
                    exitCode: EXIT_CODES.OPERATION_FAILURE,
                    durationMs,
                    error: redactor.redactError(error)
                });
                // Every accepted operation ends with one replayable terminal event, including rejected executions.
                publish(operation, {
                    kind: 'operation-completed',
                    operationId,
                    operation: request.command,
                    timestamp: operation.completedAt,
                    exitCode: EXIT_CODES.OPERATION_FAILURE,
                    durationMs,
                    dryRun: request.payload.dryRun === true
                });
            });
        sendJson(response, 202, { id: operationId });
    };

    const server = createServer(async (request, response) => {
        const url = new URL(request.url ?? '/', `http://${LOOPBACK_HOST}`);
        if (!hasAllowedHost(request)) {
            sendJson(response, 421, { error: 'Invalid Host' });
            return;
        }
        if (
            url.pathname.startsWith('/api/v1/') &&
            url.pathname !== '/api/v1/health' &&
            !tokenMatches(request.headers.authorization, sessionToken)
        ) {
            sendJson(response, 401, { error: 'Unauthorized' });
            return;
        }
        if (request.method === 'GET' && url.pathname === '/') {
            try {
                const index = (await readContainedAsset('index.html')).toString('utf8');
                const bootstrap = `<meta name="sf-project-session-token" content="${sessionToken}">`;
                response.writeHead(200, {
                    'cache-control': 'no-store',
                    'content-type': 'text/html; charset=utf-8',
                    ...securityHeaders()
                });
                response.end(index.replace('</head>', `${bootstrap}</head>`));
            } catch {
                sendJson(response, 404, { error: 'Web application is not built' });
            }
            return;
        }
        if (request.method === 'GET' && url.pathname === '/api/v1/health') {
            sendJson(response, 200, { status: 'ok', apiVersion: 'v1' });
            return;
        }
        if (request.method === 'GET' && url.pathname === '/api/v1/orgs') {
            try {
                sendJson(response, 200, sanitize(await options.facade.listOrgs()));
            } catch (error) {
                sendJson(response, 500, { error: redactor.redactError(error) });
            }
            return;
        }
        const orgPackagesMatch = url.pathname.match(/^\/api\/v1\/orgs\/([^/]+)\/packages$/);
        if (request.method === 'GET' && orgPackagesMatch !== null) {
            try {
                sendJson(
                    response,
                    200,
                    sanitize(await options.facade.getOrgPackages(decodeURIComponent(orgPackagesMatch[1] ?? '')))
                );
            } catch (error) {
                sendJson(response, 500, { error: redactor.redactError(error) });
            }
            return;
        }
        const orgMatch = url.pathname.match(/^\/api\/v1\/orgs\/([^/]+)$/);
        if (request.method === 'GET' && orgMatch !== null) {
            try {
                sendJson(response, 200, sanitize(await options.facade.getOrg(decodeURIComponent(orgMatch[1] ?? ''))));
            } catch (error) {
                sendJson(response, 404, { error: redactor.redactError(error) });
            }
            return;
        }
        if (request.method === 'GET' && url.pathname === '/api/v1/operations') {
            sendJson(response, 200, [...operations.values()].reverse().map(publicOperation));
            return;
        }
        const eventsMatch = url.pathname.match(/^\/api\/v1\/operations\/([^/]+)\/events$/);
        if (request.method === 'GET' && eventsMatch !== null) {
            const operationId = eventsMatch[1] ?? '';
            const operation = operations.get(operationId);
            if (operation === undefined) {
                sendJson(response, 404, { error: 'Operation not found' });
                return;
            }
            const operationSubscribers = subscribers.get(operationId) ?? new Set<ServerResponse>();
            if (subscriberTotal() >= maxSubscribers || operationSubscribers.size >= maxSubscribersPerOperation) {
                sendJson(response, 429, { error: 'Too many event subscribers' });
                return;
            }
            response.writeHead(200, {
                'cache-control': 'no-store',
                connection: 'keep-alive',
                'content-type': 'text/event-stream; charset=utf-8',
                'x-accel-buffering': 'no',
                ...securityHeaders()
            });
            response.flushHeaders();
            // Replay retained history before registering for live events to preserve event ordering.
            for (const event of operation.events) {
                response.write(`event: operation\ndata: ${JSON.stringify(event)}\n\n`);
            }
            operationSubscribers.add(response);
            subscribers.set(operationId, operationSubscribers);
            const removeSubscriber = (): void => {
                operationSubscribers.delete(response);
                if (operationSubscribers.size === 0) subscribers.delete(operationId);
            };
            request.once('aborted', removeSubscriber);
            response.once('close', removeSubscriber);
            response.socket?.once('close', removeSubscriber);
            return;
        }
        const cancellationMatch = url.pathname.match(/^\/api\/v1\/operations\/([^/]+)\/cancel$/);
        if (request.method === 'POST' && cancellationMatch !== null) {
            if (!authorizeMutation(request, response)) return;
            if (options.facade.cancel === undefined) {
                sendJson(response, 409, { error: 'Cancellation is not supported' });
                return;
            }
            const cancelled = await options.facade.cancel(cancellationMatch[1] ?? '');
            sendJson(response, cancelled ? 202 : 409, { cancelled });
            return;
        }
        const detailMatch = url.pathname.match(/^\/api\/v1\/operations\/([^/]+)$/);
        if (request.method === 'GET' && detailMatch !== null) {
            const operation = operations.get(detailMatch[1] ?? '');
            sendJson(
                response,
                operation === undefined ? 404 : 200,
                operation === undefined ? { error: 'Operation not found' } : publicOperation(operation)
            );
            return;
        }
        if (request.method === 'POST' && url.pathname === '/api/v1/operations') {
            if (!authorizeMutation(request, response)) return;
            try {
                const operationRequest = parseOperationRequest(await readJson(request));
                if (operationRequest === null) {
                    sendJson(response, 400, { error: 'Invalid operation request' });
                    return;
                }
                const target = mutationTarget(operationRequest);
                if (target !== null) {
                    const org =
                        target === undefined
                            ? await options.facade.getOrgStatus()
                            : await options.facade.getOrg(target);
                    const resolvedTarget = org.org.alias ?? org.org.username ?? target;
                    const confirmation =
                        typeof operationRequest.payload.confirmMutation === 'string'
                            ? operationRequest.payload.confirmMutation
                            : undefined;
                    if (
                        resolvedTarget === undefined ||
                        !isOrgMutationConfirmed(org.org.orgType, operationRequest.command, resolvedTarget, confirmation)
                    ) {
                        sendJson(response, 403, { error: 'Mutation is not allowed for this org' });
                        return;
                    }
                }
                beginOperation(operationRequest, response);
            } catch (error) {
                sendJson(response, error instanceof RangeError ? 413 : 400, {
                    error: error instanceof RangeError ? 'Request body is too large' : 'Invalid JSON request body'
                });
            }
            return;
        }
        if (request.method === 'GET' && !url.pathname.startsWith('/api/')) {
            try {
                const relativePath = decodeURIComponent(url.pathname).replace(/^\/+/, '');
                // Reject lexical traversal before the realpath check catches symlink-based escapes.
                const assetPath = path.resolve(webAssetsDirectory, relativePath);
                const relativeAssetPath = path.relative(webAssetsDirectory, assetPath);
                if (relativeAssetPath.startsWith('..') || path.isAbsolute(relativeAssetPath)) {
                    sendJson(response, 404, { error: 'Not found' });
                    return;
                }
                const contentType = ASSET_CONTENT_TYPES.get(path.extname(assetPath).toLowerCase());
                if (contentType === undefined) {
                    sendJson(response, 404, { error: 'Not found' });
                    return;
                }
                const asset = await readContainedAsset(relativePath);
                response.writeHead(200, {
                    'cache-control': 'public, max-age=31536000, immutable',
                    'content-type': contentType,
                    ...securityHeaders()
                });
                response.end(asset);
            } catch {
                sendJson(response, 404, { error: 'Not found' });
            }
            return;
        }
        sendJson(response, 404, { error: 'Not found' });
    });

    await new Promise<void>((resolve, reject) => {
        server.once('error', reject);
        server.listen(port, host, () => {
            server.off('error', reject);
            resolve();
        });
    });
    const address = server.address() as AddressInfo;
    return {
        server,
        sessionToken,
        url: `http://${host}:${address.port}`,
        subscriberCount: (operationId) => {
            const operationSubscribers = subscribers.get(operationId);
            if (operationSubscribers === undefined) return 0;
            for (const subscriber of operationSubscribers) {
                if (subscriber.destroyed || subscriber.writableEnded) operationSubscribers.delete(subscriber);
            }
            if (operationSubscribers.size === 0) subscribers.delete(operationId);
            return operationSubscribers.size;
        },
        close: () =>
            new Promise<void>((resolve, reject) => {
                for (const responses of subscribers.values()) {
                    for (const subscriber of responses) subscriber.end();
                }
                subscribers.clear();
                server.close((error) => (error === undefined ? resolve() : reject(error)));
            })
    };
}
