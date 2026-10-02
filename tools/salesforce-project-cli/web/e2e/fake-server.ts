import path from 'node:path';
import { setTimeout as delay } from 'node:timers/promises';
import { EXIT_CODES } from '../../src/domain/events.js';
import { startWebServer, type WebServiceFacade } from '../../src/web/server.js';

const scratchOrg = {
    alias: 'scratch-e2e',
    username: 'developer@example.test',
    orgId: '00D000000000001',
    orgType: 'scratch' as const,
    connectionStatus: 'connected' as const,
    authStatus: 'authenticated' as const,
    instanceUrlClassification: 'scratch' as const,
    expirationDate: '2026-09-20',
    remainingLifetimeDays: 7,
    isDefaultOrg: true,
    isDefaultDevHub: false,
    sourceTracking: true,
    lastRefreshTimestamp: '2026-09-13T10:00:00.000Z',
    capabilities: { sourceTracking: true, mutationPolicy: 'allowed' as const }
};

const productionOrg = {
    ...scratchOrg,
    alias: 'production-e2e',
    orgType: 'production' as const,
    instanceUrlClassification: 'production' as const,
    expirationDate: null,
    remainingLifetimeDays: null,
    isDefaultOrg: false,
    sourceTracking: null,
    capabilities: { sourceTracking: null, mutationPolicy: 'read-only' as const }
};

const facade: WebServiceFacade = {
    getProjectInfo: async () => ({
        projectDirectory: process.cwd(),
        repositoryName: 'crm-arbeidsforhold-2',
        repositoryUrl: 'https://github.com/navikt/crm-arbeidsforhold-2',
        branch: 'main',
        status: 'clean',
        statusSummary: 'Ingen endringer',
        isGitRepository: true
    }),
    listOrgs: async () => ({ orgs: [scratchOrg, productionOrg] }),
    getOrgStatus: async (alias) => ({ org: alias === productionOrg.alias ? productionOrg : scratchOrg }),
    getOrgPackages: async (alias) => ({
        targetOrg: alias,
        packages: [
            {
                packageName: 'crm-platform-base',
                configuredVersion: '2.0.0.LATEST',
                installedVersion: '1.9.0.4',
                selectedVersion: '2.0.0.1',
                status: 'update-available'
            }
        ],
        summary: { total: 1, current: 0, updateAvailable: 1, higher: 0, missing: 0, unknown: 0 }
    }),
    getOrg: async (alias) => ({
        org: {
            ...(alias === productionOrg.alias ? productionOrg : scratchOrg),
            apiVersion: '65.0',
            edition: 'Developer',
            createdDate: '2026-09-01',
            devHubUsername: null
        }
    }),
    execute: async (request, emit) => {
        emit({
            kind: 'step-started',
            operationId: request.operationId,
            timestamp: new Date().toISOString(),
            stepId: 'fake',
            step: 'Kontroller lokal konfigurasjon',
            attempt: 1
        });
        await delay(150);
        emit({
            kind: 'progress',
            operationId: request.operationId,
            timestamp: new Date().toISOString(),
            stepId: 'fake',
            step: 'Kontroller lokal konfigurasjon',
            message: 'Deterministisk testoperasjon fullført'
        });
        return EXIT_CODES.SUCCESS;
    }
};

const server = await startWebServer({
    facade,
    port: 4178,
    webAssetsDirectory: path.resolve(import.meta.dirname, '../../web-dist')
});

const close = () => void server.close().finally(() => process.exit(0));
process.on('SIGINT', close);
process.on('SIGTERM', close);
