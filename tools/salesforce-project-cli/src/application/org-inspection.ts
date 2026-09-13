/**
 * Normalizes Salesforce CLI org responses into stable summaries, details, and capabilities.
 * Org mutation classification fails closed, and instance URLs are represented only by safe categories.
 */
import type { OrgClassification } from '../domain/org-policy.js';
import { isOrgMutationAllowed } from '../domain/org-policy.js';
import type { CommandResult } from '../infrastructure/command-runner.js';
import { isSalesforceAuthFailure } from '../infrastructure/salesforce-errors.js';
import type { CommandRunner } from './refresh-dependencies.js';

/** Normalized reachability state reported for an org. */
export type ConnectionStatus = 'connected' | 'disconnected' | 'unknown';
/** Normalized authentication state, including inaccessible and expired orgs. */
export type AuthStatus = 'authenticated' | 'unauthenticated' | 'inaccessible' | 'expired' | 'unknown';
/** Classification derived from a parsed Salesforce instance URL. */
export type InstanceUrlClassification = 'scratch' | 'sandbox' | 'development' | 'production' | 'custom' | 'unknown';
/** Whether application workflows may mutate the classified org. */
export type MutationPolicy = 'allowed' | 'read-only';

/** Capabilities derived from Salesforce response fields and the local org mutation policy. */
export interface OrgCapabilities {
    /** Whether source tracking is supported, or `null` when Salesforce did not report it. */
    sourceTracking: boolean | null;
    /** Local policy decision controlling whether mutating workflows may target the org. */
    mutationPolicy: MutationPolicy;
}

/** Stable, normalized org summary independent of Salesforce CLI response variants. */
export interface OrgSummary {
    /** Configured org alias, or `null` when absent from the response. */
    alias: string | null;
    /** Authenticated username, or `null` when unavailable. */
    username: string | null;
    /** Salesforce organization identifier, or `null` when unavailable. */
    orgId: string | null;
    /** Org classification used by local mutation policy. */
    orgType: OrgClassification;
    /** Normalized CLI connection status. */
    connectionStatus: ConnectionStatus;
    /** Authentication/access state inferred from connection, expiry, and command failure details. */
    authStatus: AuthStatus;
    /** Environment classification derived from the instance URL without exposing the URL. */
    instanceUrlClassification: InstanceUrlClassification;
    /** Salesforce expiration timestamp, or `null` for non-expiring or unknown orgs. */
    expirationDate: string | null;
    /** Ceiling of days until expiration, or `null` when expiration cannot be calculated. */
    remainingLifetimeDays: number | null;
    /** Whether Salesforce marks this org as the default target org. */
    isDefaultOrg: boolean;
    /** Whether Salesforce marks this org as the default Dev Hub. */
    isDefaultDevHub: boolean;
    /** Source-tracking capability, or `null` when not reported. */
    sourceTracking: boolean | null;
    /** Timestamp of the display-based refresh, or `null` for list-only data. */
    lastRefreshTimestamp: string | null;
    /** Derived operational capabilities for consumers. */
    capabilities: OrgCapabilities;
}

/** Collection returned by org listing operations. */
export interface OrgListResult {
    /** Normalized orgs in Salesforce CLI source-group order. */
    orgs: OrgSummary[];
}

/** Detailed org snapshot returned by a display operation. */
export interface OrgInfo extends OrgSummary {
    /** Reported Salesforce API version, or `null` when unavailable. */
    apiVersion: string | null;
    /** Reported Salesforce edition, or `null` when unavailable. */
    edition: string | null;
    /** Reported creation timestamp, or `null` when unavailable. */
    createdDate: string | null;
    /** Associated Dev Hub username, or `null` when unavailable. */
    devHubUsername: string | null;
}

/** Wrapper used by single-org inspection endpoints. */
export interface OrgResult<T extends OrgSummary = OrgSummary> {
    /** Normalized org snapshot. */
    org: T;
}

/** Inputs and injected dependencies for listing orgs. */
export interface ListOrgsOptions {
    /** Project working directory for Salesforce CLI commands. */
    projectDirectory: string;
    /** Injected command runner used for every Salesforce CLI query. */
    runCommand: CommandRunner;
    /** Whether each listed org should be enriched with a separate display query. */
    refresh?: boolean;
    /** Injectable clock used for deterministic expiry and refresh timestamps. */
    now?: Date;
}

/** Inputs for resolving and optionally refreshing one org status. */
export interface GetOrgStatusOptions extends ListOrgsOptions {
    /** Explicit alias or username; when omitted, the configured default target org is queried. */
    alias?: string;
}

/** Inputs and injected dependencies for retrieving detailed org information. */
export interface GetOrgInfoOptions {
    /** Project working directory for Salesforce CLI commands. */
    projectDirectory: string;
    /** Required org alias or username passed to the display query. */
    alias: string;
    /** Injected command runner used for display and default-org queries. */
    runCommand: CommandRunner;
    /** Injectable clock used for expiry and refresh timestamps. */
    now?: Date;
}

type UnknownRecord = Record<string, unknown>;

function isRecord(value: unknown): value is UnknownRecord {
    return value !== null && typeof value === 'object' && !Array.isArray(value);
}

function stringValue(record: UnknownRecord, ...keys: string[]): string | null {
    for (const key of keys) {
        const value = record[key];
        if (typeof value === 'string' && value.length > 0) return value;
    }
    return null;
}

function booleanValue(record: UnknownRecord, ...keys: string[]): boolean | null {
    for (const key of keys) {
        const value = record[key];
        if (typeof value === 'boolean') return value;
    }
    return null;
}

function parseJsonOutput(stdout: string): UnknownRecord {
    // Salesforce and wrappers may prefix JSON with diagnostics; normalize the last viable object payload.
    const candidates = [stdout.trim(), ...stdout.trim().split(/\r?\n/).reverse()];
    for (let index = 0; index < stdout.length; index += 1) {
        if (stdout[index] === '{') candidates.push(stdout.slice(index).trim());
    }
    for (const candidate of candidates) {
        try {
            const value: unknown = JSON.parse(candidate);
            if (isRecord(value)) return value;
        } catch {
            continue;
        }
    }
    throw new SyntaxError('Salesforce CLI returned invalid JSON');
}

function commandFailed(result: CommandResult, payload: UnknownRecord): boolean {
    return result.failed || result.exitCode !== 0 || (typeof payload.status === 'number' && payload.status !== 0);
}

function classifyInstanceUrl(instanceUrl: string | null): InstanceUrlClassification {
    if (instanceUrl === null) return 'unknown';
    let hostname: string;
    try {
        hostname = new URL(instanceUrl).hostname.toLowerCase();
    } catch {
        return 'unknown';
    }
    if (hostname.includes('.scratch.')) return 'scratch';
    if (hostname.includes('.sandbox.') || /^cs\d+\./.test(hostname)) return 'sandbox';
    if (hostname.includes('.develop.') || hostname.includes('.developer.')) return 'development';
    if (hostname === 'login.salesforce.com' || hostname.endsWith('.my.salesforce.com')) return 'production';
    return 'custom';
}

function classifyOrg(record: UnknownRecord, source: string): OrgClassification {
    if (source === 'scratchOrgs') return 'scratch';
    if (source === 'sandboxes') return 'sandbox';
    if (source === 'devHubs' || booleanValue(record, 'isDevHub') === true) return 'dev-hub';
    const orgType = stringValue(record, 'orgType', 'edition')?.toLowerCase() ?? '';
    if (orgType.includes('scratch')) return 'scratch';
    if (orgType.includes('sandbox')) return 'sandbox';
    if (orgType.includes('developer')) return 'development';
    if (orgType.includes('production')) return 'production';
    const instanceClassification = classifyInstanceUrl(stringValue(record, 'instanceUrl'));
    if (instanceClassification === 'sandbox' || instanceClassification === 'development') {
        return instanceClassification;
    }
    if (instanceClassification === 'production') return 'production';
    return 'unknown';
}

function normalizeConnectionStatus(record: UnknownRecord): ConnectionStatus {
    const status = stringValue(record, 'connectedStatus')?.toLowerCase();
    if (status === 'connected') return 'connected';
    if (status !== null && status !== undefined) return 'disconnected';
    return 'unknown';
}

function remainingLifetimeDays(expirationDate: string | null, now: Date): number | null {
    if (expirationDate === null) return null;
    const expiration = Date.parse(expirationDate);
    if (Number.isNaN(expiration)) return null;
    return Math.ceil((expiration - now.getTime()) / 86_400_000);
}

function normalizeOrg(record: UnknownRecord, source: string, now: Date): OrgSummary {
    const orgType = classifyOrg(record, source);
    const connectionStatus = normalizeConnectionStatus(record);
    const expirationDate = stringValue(record, 'expirationDate');
    const remainingDays = remainingLifetimeDays(expirationDate, now);
    const expired =
        (remainingDays !== null && remainingDays <= 0) || stringValue(record, 'status')?.toLowerCase() === 'expired';
    const sourceTracking = booleanValue(record, 'tracksSource', 'sourceTracking');
    return {
        alias: stringValue(record, 'alias'),
        username: stringValue(record, 'username'),
        orgId: stringValue(record, 'orgId', 'id'),
        orgType,
        connectionStatus,
        authStatus: expired
            ? 'expired'
            : connectionStatus === 'connected'
                ? 'authenticated'
                : connectionStatus === 'disconnected'
                    ? 'unauthenticated'
                    : 'unknown',
        instanceUrlClassification: classifyInstanceUrl(stringValue(record, 'instanceUrl')),
        expirationDate,
        remainingLifetimeDays: remainingDays,
        isDefaultOrg: booleanValue(record, 'isDefaultUsername', 'isDefaultOrg') ?? false,
        isDefaultDevHub: booleanValue(record, 'isDefaultDevHubUsername', 'isDefaultDevHub') ?? false,
        sourceTracking,
        lastRefreshTimestamp: null,
        capabilities: {
            sourceTracking,
            mutationPolicy: isOrgMutationAllowed(orgType) ? 'allowed' : 'read-only'
        }
    };
}

function orgIdentity(org: OrgSummary): string | null {
    if (org.orgId !== null) return `org-id:${org.orgId}`;
    if (org.username !== null) return `username:${org.username}`;
    if (org.alias !== null) return `alias:${org.alias}`;
    return null;
}

function orgSourcePriority(source: string): number {
    if (source === 'scratchOrgs') return 4;
    if (source === 'sandboxes') return 3;
    if (source === 'devHubs') return 2;
    return 1;
}

function normalizeDisplayOrg(
    record: UnknownRecord,
    alias: string,
    now: Date,
    classification?: OrgClassification
): OrgInfo {
    const summary = normalizeOrg(record, classification === 'scratch' ? 'scratchOrgs' : 'display', now);
    const orgType = classification ?? summary.orgType;
    return {
        ...summary,
        alias: summary.alias ?? alias,
        orgType,
        lastRefreshTimestamp: now.toISOString(),
        capabilities: {
            sourceTracking: summary.sourceTracking,
            mutationPolicy: isOrgMutationAllowed(orgType) ? 'allowed' : 'read-only'
        },
        apiVersion: stringValue(record, 'apiVersion'),
        edition: stringValue(record, 'edition'),
        createdDate: stringValue(record, 'createdDate', 'created'),
        devHubUsername: stringValue(record, 'devHubUsername')
    };
}

function normalizeDisplayFailure(alias: string, result: CommandResult, now: Date): OrgInfo {
    let payload: UnknownRecord = {};
    try {
        payload = parseJsonOutput(result.stdout);
    } catch {
        payload = {};
    }
    const unauthenticated = isSalesforceAuthFailure({ ...result, message: payload.message });
    return {
        alias,
        username: null,
        orgId: null,
        orgType: 'unknown',
        connectionStatus: 'disconnected',
        authStatus: unauthenticated ? 'unauthenticated' : 'inaccessible',
        instanceUrlClassification: 'unknown',
        expirationDate: null,
        remainingLifetimeDays: null,
        isDefaultOrg: false,
        isDefaultDevHub: false,
        sourceTracking: null,
        lastRefreshTimestamp: now.toISOString(),
        capabilities: { sourceTracking: null, mutationPolicy: 'read-only' },
        apiVersion: null,
        edition: null,
        createdDate: null,
        devHubUsername: null
    };
}

async function displayOrg(
    projectDirectory: string,
    alias: string,
    runCommand: CommandRunner,
    now: Date,
    classification?: OrgClassification
): Promise<OrgInfo> {
    const result = await runCommand({
        executable: 'sf',
        arguments: ['org', 'display', '--target-org', alias, '--json'],
        cwd: projectDirectory
    });
    let payload: UnknownRecord;
    try {
        payload = parseJsonOutput(result.stdout);
    } catch {
        return normalizeDisplayFailure(alias, result, now);
    }
    if (commandFailed(result, payload)) return normalizeDisplayFailure(alias, result, now);
    return normalizeDisplayOrg(isRecord(payload.result) ? payload.result : {}, alias, now, classification);
}

async function getDefaultOrg(projectDirectory: string, runCommand: CommandRunner): Promise<string | null> {
    const result = await runCommand({
        executable: 'sf',
        arguments: ['config', 'get', 'target-org', '--json'],
        cwd: projectDirectory
    });
    let payload: UnknownRecord;
    try {
        payload = parseJsonOutput(result.stdout);
    } catch {
        return null;
    }
    if (commandFailed(result, payload) || !Array.isArray(payload.result)) return null;
    for (const item of payload.result) {
        if (!isRecord(item) || stringValue(item, 'key') !== 'target-org') continue;
        return stringValue(item, 'value');
    }
    return null;
}

function mergeRefreshedSummary(summary: OrgSummary, refreshed: OrgInfo): OrgSummary {
    const sourceTracking = refreshed.sourceTracking ?? summary.sourceTracking;
    return {
        ...summary,
        ...refreshed,
        username: refreshed.username ?? summary.username,
        orgId: refreshed.orgId ?? summary.orgId,
        orgType: summary.orgType === 'unknown' ? refreshed.orgType : summary.orgType,
        expirationDate: refreshed.expirationDate ?? summary.expirationDate,
        remainingLifetimeDays: refreshed.remainingLifetimeDays ?? summary.remainingLifetimeDays,
        isDefaultOrg: summary.isDefaultOrg || refreshed.isDefaultOrg,
        isDefaultDevHub: summary.isDefaultDevHub || refreshed.isDefaultDevHub,
        sourceTracking,
        capabilities: {
            sourceTracking,
            mutationPolicy: summary.capabilities.mutationPolicy
        }
    };
}

/**
 * Lists configured Salesforce orgs and normalizes response-shape differences.
 *
 * With `refresh: true`, one display query is issued per org that has an alias or username;
 * display failures are represented in the returned snapshots. The operation does not mutate orgs.
 *
 * @param options - Project path, injected command runner, optional refresh flag, and clock.
 * @returns Normalized org summaries in Salesforce CLI source-group order.
 * @throws `SyntaxError` When the list command does not contain a parseable JSON object.
 * @throws `Error` When the list command reports failure or the injected runner rejects.
 */
export async function listOrgs(options: ListOrgsOptions): Promise<OrgListResult> {
    const result = await options.runCommand({
        executable: 'sf',
        arguments: ['org', 'list', '--json'],
        cwd: options.projectDirectory
    });
    const payload = parseJsonOutput(result.stdout);
    if (commandFailed(result, payload)) {
        throw new Error('Unable to list Salesforce orgs');
    }
    const rawResult = isRecord(payload.result) ? payload.result : {};
    const now = options.now ?? new Date();
    const orgsByIdentity = new Map<string, { org: OrgSummary; priority: number }>();
    const unidentifiableOrgs: OrgSummary[] = [];
    for (const source of ['scratchOrgs', 'nonScratchOrgs', 'sandboxes', 'devHubs']) {
        const records = rawResult[source];
        if (!Array.isArray(records)) continue;
        for (const record of records) {
            if (!isRecord(record)) continue;
            const org = normalizeOrg(record, source, now);
            const identity = orgIdentity(org);
            if (identity === null) {
                unidentifiableOrgs.push(org);
                continue;
            }
            const priority = orgSourcePriority(source);
            const existing = orgsByIdentity.get(identity);
            if (existing === undefined || priority > existing.priority) {
                orgsByIdentity.set(identity, { org, priority });
            }
        }
    }
    const orgs = [...orgsByIdentity.values()].map(({ org }) => org).concat(unidentifiableOrgs);
    if (options.refresh !== true) return { orgs };
    const refreshedOrgs = await Promise.all(
        orgs.map(async (org) => {
            const target = org.alias ?? org.username;
            if (target === null) return org;
            const refreshed = await displayOrg(options.projectDirectory, target, options.runCommand, now, org.orgType);
            return mergeRefreshedSummary(org, refreshed);
        })
    );
    return { orgs: refreshedOrgs };
}

/**
 * Resolves one org from the org list, optionally enriching it with a display query.
 *
 * When no alias is supplied, the Salesforce default target-org configuration is used. Display
 * failures during refresh are normalized into the returned status and do not throw.
 *
 * @param options - List options plus an optional explicit alias and refresh flag.
 * @returns A normalized org status, marked as default when selected through target-org config.
 * @throws `Error` When no explicit or default target org exists, org listing fails, JSON is
 * invalid, or the injected runner rejects.
 */
export async function getOrgStatus(options: GetOrgStatusOptions): Promise<OrgResult> {
    const defaultOrg =
        options.alias === undefined ? await getDefaultOrg(options.projectDirectory, options.runCommand) : null;
    const alias = options.alias ?? defaultOrg;
    if (alias === null) throw new Error('No target org is configured');
    const listed = await listOrgs({
        projectDirectory: options.projectDirectory,
        runCommand: options.runCommand,
        ...(options.now === undefined ? {} : { now: options.now })
    });
    const base =
        listed.orgs.find((org) => org.alias === alias || org.username === alias) ??
        normalizeOrg({ alias }, 'unknown', options.now ?? new Date());
    const org =
        options.refresh === true
            ? mergeRefreshedSummary(
                base,
                await displayOrg(
                    options.projectDirectory,
                    alias,
                    options.runCommand,
                    options.now ?? new Date(),
                    base.orgType
                )
            )
            : base;
    return { org: { ...org, isDefaultOrg: org.isDefaultOrg || alias === defaultOrg } };
}

/**
 * Retrieves a detailed org snapshot and resolves whether it is the default target org.
 *
 * Salesforce display failures are normalized to unauthenticated or inaccessible information;
 * malformed successful data is likewise represented as an inaccessible snapshot.
 *
 * @param options - Project path, org alias, injected command runner, and optional clock.
 * @returns Detailed normalized org information.
 * @throws `Error` When the injected command runner rejects.
 */
export async function getOrgInfo(options: GetOrgInfoOptions): Promise<OrgResult<OrgInfo>> {
    const now = options.now ?? new Date();
    const org = await displayOrg(options.projectDirectory, options.alias, options.runCommand, now);
    const defaultOrg = await getDefaultOrg(options.projectDirectory, options.runCommand);
    return { org: { ...org, isDefaultOrg: org.isDefaultOrg || options.alias === defaultOrg } };
}

/**
 * Formats a normalized org summary for human-readable terminal output.
 *
 * @param org - Normalized org summary to render.
 * @returns A newline-delimited summary with explicit `unknown` placeholders.
 */
export function renderOrgSummary(org: OrgSummary): string {
    return [
        `Alias: ${org.alias ?? 'unknown'}`,
        `Username: ${org.username ?? 'unknown'}`,
        `Org ID: ${org.orgId ?? 'unknown'}`,
        `Org type: ${org.orgType}`,
        `Connection status: ${org.connectionStatus}`,
        `Auth status: ${org.authStatus}`,
        `Instance URL classification: ${org.instanceUrlClassification}`,
        `Expiration: ${org.expirationDate ?? 'unknown'}`,
        `Remaining lifetime days: ${org.remainingLifetimeDays ?? 'unknown'}`,
        `Default org: ${org.isDefaultOrg}`,
        `Default Dev Hub: ${org.isDefaultDevHub}`,
        `Source tracking: ${org.sourceTracking ?? 'unknown'}`,
        `Last refresh: ${org.lastRefreshTimestamp ?? 'unknown'}`,
        `Mutation policy: ${org.capabilities.mutationPolicy}`
    ].join('\n');
}

/**
 * Formats detailed org information for human-readable terminal output.
 *
 * @param org - Detailed normalized org information to render.
 * @returns The summary fields followed by API, edition, creation, and Dev Hub details.
 */
export function renderOrgInfo(org: OrgInfo): string {
    return [
        renderOrgSummary(org),
        `API version: ${org.apiVersion ?? 'unknown'}`,
        `Edition: ${org.edition ?? 'unknown'}`,
        `Created: ${org.createdDate ?? 'unknown'}`,
        `Dev Hub username: ${org.devHubUsername ?? 'unknown'}`
    ].join('\n');
}
