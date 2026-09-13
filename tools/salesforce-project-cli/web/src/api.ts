/**
 * Defines browser-safe dashboard contracts and the authenticated REST and SSE client.
 * Mutation policy remains server-authoritative, and subscriptions expose cleanup that aborts their connection.
 */
/** Server-classified Salesforce organization types exposed to the browser dashboard. */
export type OrgType = 'scratch' | 'development' | 'sandbox' | 'dev-hub' | 'production' | 'unknown';

/** Server-enforced policy describing whether an organization accepts mutating operations. */
export type MutationPolicy = 'allowed' | 'read-only';

/** Browser DTO containing the server's safe, summarized view of a Salesforce organization. */
export interface OrgSummary {
    /** Local Salesforce CLI alias, or `null` when the organization has no alias. */
    alias: string | null;
    /** Authenticated username, or `null` when it is unavailable to the local server. */
    username: string | null;
    /** Salesforce organization identifier, or `null` when it cannot be resolved. */
    orgId: string | null;
    /** Organization type classified by the server. */
    orgType: OrgType;
    /** Current connection state reported by the local Salesforce CLI. */
    connectionStatus: 'connected' | 'disconnected' | 'unknown';
    /** Current authentication state reported by the local Salesforce CLI. */
    authStatus: 'authenticated' | 'unauthenticated' | 'inaccessible' | 'expired' | 'unknown';
    /** Server classification of the instance URL without exposing the URL itself. */
    instanceUrlClassification: 'scratch' | 'sandbox' | 'development' | 'production' | 'custom' | 'unknown';
    /** ISO date on which the organization expires, or `null` when it does not expire. */
    expirationDate: string | null;
    /** Whole days until expiration, or `null` when no lifetime applies. */
    remainingLifetimeDays: number | null;
    /** Whether this organization is the Salesforce CLI default target organization. */
    isDefaultOrg: boolean;
    /** Whether this organization is the Salesforce CLI default Dev Hub. */
    isDefaultDevHub: boolean;
    /** Whether source tracking is available, or `null` when its state is unknown. */
    sourceTracking: boolean | null;
    /** ISO timestamp of the most recent server refresh, or `null` before the first refresh. */
    lastRefreshTimestamp: string | null;
    /** Server-derived capabilities used to constrain operations in the dashboard. */
    capabilities: { sourceTracking: boolean | null; mutationPolicy: MutationPolicy };
}

/** Browser DTO with detailed server-provided fields for one organization. */
export interface OrgDetail extends OrgSummary {
    /** Organization API version, or `null` when unavailable. */
    apiVersion: string | null;
    /** Salesforce edition, or `null` when unavailable. */
    edition: string | null;
    /** ISO creation date, or `null` when unavailable. */
    createdDate: string | null;
    /** Username of the creating Dev Hub, or `null` when not applicable or unavailable. */
    devHubUsername: string | null;
}

/** Comparison state between an installed package and the project-selected version. */
export type OrgPackageStatusKind = 'missing' | 'current' | 'update-available' | 'higher' | 'unknown';

/** Browser DTO containing package-version comparisons calculated by the server for one organization. */
export interface OrgPackageStatusResult {
    /** Alias or username used by the server to resolve the target organization. */
    targetOrg: string;
    /** Per-package comparison results. */
    packages: Array<{
        /** Project package name. */
        packageName: string;
        /** Version configured by the project, or `null` when no version is configured. */
        configuredVersion: string | null;
        /** Version installed in the target organization, or `null` when none is found. */
        installedVersion: string | null;
        /** Concrete version selected after resolving project configuration, or `null` when unresolved. */
        selectedVersion: string | null;
        /** Comparison between the installed and selected versions. */
        status: OrgPackageStatusKind;
    }>;
    /** Counts of package comparison states for dashboard presentation. */
    summary: {
        /** Total packages included in the comparison. */
        total: number;
        /** Packages whose installed version matches the selected version. */
        current: number;
        /** Packages for which a newer selected version is available. */
        updateAvailable: number;
        /** Packages installed at a version higher than the selected version. */
        higher: number;
        /** Packages not installed in the target organization. */
        missing: number;
        /** Packages whose comparison state could not be determined. */
        unknown: number;
    };
}

/** Operation commands accepted by the web server; read-only targets may only execute safe dry runs. */
export type WebOperationCommand =
    | 'dependencies.clear'
    | 'dependencies.refresh'
    | 'packages.plan'
    | 'packages.install'
    | 'packages.update'
    | 'org.create'
    | 'org.delete'
    | 'project.configure';

/** Browser DTO for one replayed or live operation event from the server's SSE stream. */
export interface OperationEvent {
    /** Event discriminator emitted by the operation runner. */
    kind: string;
    /** Identifier of the operation that emitted the event. */
    operationId: string;
    /** ISO timestamp recorded by the server. */
    timestamp: string;
    /** Stable step identifier when the event belongs to a command step. */
    stepId?: string;
    /** Human-readable step name when the event belongs to a command step. */
    step?: string;
    /** Informational event text safe for display. */
    message?: string;
    /** Failure text safe for display when a step or operation fails. */
    error?: string;
    /** Suggested recovery action supplied by the server. */
    nextAction?: string;
    /** Elapsed event or step duration in milliseconds. */
    durationMs?: number;
    /** Process exit code, or `null` when no code is available. */
    exitCode?: number | null;
    /** Operation name included by lifecycle events. */
    operation?: string;
}

/** Browser DTO representing the current server-side state and event history of an operation. */
export interface Operation {
    /** Server-generated operation identifier. */
    id: string;
    /** Command executed by the operation. */
    command: WebOperationCommand;
    /** Current lifecycle state. */
    status: 'running' | 'completed' | 'failed';
    /** ISO timestamp at which the server created the operation. */
    createdAt: string;
    /** ISO timestamp at which the operation finished, when available. */
    completedAt?: string;
    /** Final process exit code, when available. */
    exitCode?: number;
    /** Replayed and live events recorded for the operation. */
    events: OperationEvent[];
}

/**
 * Injectable browser-facing contract for dashboard reads, mutations, and operation subscriptions.
 *
 * Read methods do not mutate Salesforce or project state. `startOperation` delegates mutation and
 * dry-run enforcement to the server, including its authoritative {@link MutationPolicy} checks.
 */
export interface DashboardApi {
    /** Returns summarized organizations visible to the local server. */
    listOrgs(): Promise<OrgSummary[]>;
    /** Returns server details for the organization identified by an alias or username. */
    getOrg(alias: string): Promise<OrgDetail>;
    /** Returns the server-calculated package status for an organization without changing it. */
    getOrgPackages(alias: string): Promise<OrgPackageStatusResult>;
    /** Returns recent server-side operations and their recorded events. */
    listOperations(): Promise<Operation[]>;
    /**
     * Requests a server-side command and returns its operation identifier.
     *
     * The payload may request a dry run, but the server remains responsible for validating the
     * command and preventing mutations against read-only targets.
     */
    startOperation(command: WebOperationCommand, payload: Record<string, unknown>): Promise<{ id: string }>;
    /**
     * Subscribes to replayed and live operation events.
     *
     * @returns A cleanup function that aborts the authenticated SSE request. Call it when the
     * subscription is no longer needed.
     */
    subscribe(operationId: string, onEvent: (event: OperationEvent) => void): () => void;
}

async function readJson<T>(response: Response): Promise<T> {
    const body = (await response.json()) as T | { error?: string };
    if (!response.ok) {
        throw new Error(
            'error' in (body as object) ? String((body as { error?: string }).error) : 'Førespurnaden feila'
        );
    }
    return body as T;
}

function sessionToken(): string {
    const token = document.querySelector<HTMLMetaElement>('meta[name="sf-project-session-token"]')?.content;
    if (!token) throw new Error('Manglar trygg lokal økt');
    return token;
}

function authenticatedHeaders(headers?: HeadersInit): Headers {
    const authenticated = new Headers(headers);
    // The server bootstraps this short-lived token into same-origin HTML; never source it from user input or storage.
    authenticated.set('authorization', `Bearer ${sessionToken()}`);
    return authenticated;
}

function authenticatedFetch(input: RequestInfo | URL, init: RequestInit = {}): Promise<Response> {
    return fetch(input, { ...init, headers: authenticatedHeaders(init.headers) });
}

async function streamOperationEvents(
    operationId: string,
    onEvent: (event: OperationEvent) => void,
    signal: AbortSignal
): Promise<void> {
    const response = await authenticatedFetch(`/api/v1/operations/${encodeURIComponent(operationId)}/events`, {
        signal
    });
    if (!response.ok || response.body === null) {
        throw new Error(`Straumen feila med status ${response.status}`);
    }
    const reader = response.body.getReader();
    const decoder = new TextDecoder();
    let pending = '';
    while (!signal.aborted) {
        const { done, value } = await reader.read();
        pending += decoder.decode(value, { stream: !done });
        const messages = pending.split(/\r?\n\r?\n/);
        // Keep the final partial SSE frame until a later chunk supplies its record separator.
        pending = messages.pop() ?? '';
        for (const message of messages) {
            const lines = message.split(/\r?\n/);
            const eventName = lines
                .find((line) => line.startsWith('event:'))
                ?.slice('event:'.length)
                .trim();
            const data = lines
                .filter((line) => line.startsWith('data:'))
                .map((line) => line.slice('data:'.length).trimStart())
                .join('\n');
            if (eventName === 'operation' && data.length > 0) onEvent(JSON.parse(data) as OperationEvent);
        }
        if (done) break;
    }
}

/**
 * Same-origin {@link DashboardApi} implementation used by the browser application.
 *
 * Every request is authenticated with the ephemeral session token injected by the local server in
 * the `sf-project-session-token` meta element. Reads and mutations use relative `/api/v1` URLs, and
 * subscriptions return an abort-based cleanup function for their authenticated SSE stream.
 */
export const browserApi: DashboardApi = {
    async listOrgs() {
        const result = await readJson<{ orgs: OrgSummary[] }>(await authenticatedFetch('/api/v1/orgs'));
        return result.orgs;
    },
    async getOrg(alias) {
        const result = await readJson<{ org: OrgDetail }>(
            await authenticatedFetch(`/api/v1/orgs/${encodeURIComponent(alias)}`)
        );
        return result.org;
    },
    async getOrgPackages(alias) {
        return readJson<OrgPackageStatusResult>(
            await authenticatedFetch(`/api/v1/orgs/${encodeURIComponent(alias)}/packages`)
        );
    },
    async listOperations() {
        return readJson<Operation[]>(await authenticatedFetch('/api/v1/operations'));
    },
    async startOperation(command, payload) {
        return readJson<{ id: string }>(
            await authenticatedFetch('/api/v1/operations', {
                method: 'POST',
                headers: {
                    'content-type': 'application/json'
                },
                body: JSON.stringify({ command, payload })
            })
        );
    },
    subscribe(operationId, onEvent) {
        const abortController = new AbortController();
        void streamOperationEvents(operationId, onEvent, abortController.signal).catch((error: unknown) => {
            if (!abortController.signal.aborted) console.error('Operation event stream failed', error);
        });
        return () => abortController.abort();
    }
};
