import { render, screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { axe } from 'jest-axe';
import { describe, expect, it, vi } from 'vitest';
import { App } from './App';
import type { DashboardApi, Operation, OperationEvent, OrgDetail, OrgSummary } from './api';

const scratchOrg: OrgSummary = {
    alias: 'scratch-a',
    username: 'developer@example.test',
    orgId: '00D000000000001',
    orgType: 'scratch',
    connectionStatus: 'connected',
    authStatus: 'authenticated',
    instanceUrlClassification: 'scratch',
    expirationDate: '2026-09-20',
    remainingLifetimeDays: 7,
    isDefaultOrg: true,
    isDefaultDevHub: false,
    sourceTracking: true,
    lastRefreshTimestamp: null,
    capabilities: { sourceTracking: true, mutationPolicy: 'allowed' }
};

const productionOrg: OrgSummary = {
    ...scratchOrg,
    alias: 'production-a',
    orgType: 'production',
    instanceUrlClassification: 'production',
    expirationDate: null,
    remainingLifetimeDays: null,
    isDefaultOrg: false,
    sourceTracking: null,
    capabilities: { sourceTracking: null, mutationPolicy: 'read-only' }
};

function detail(org: OrgSummary): OrgDetail {
    return {
        ...org,
        apiVersion: '65.0',
        edition: 'Developer',
        createdDate: '2026-09-01',
        devHubUsername: null
    };
}

function createApi(options: { orgs?: OrgSummary[]; operations?: Operation[] } = {}) {
    let eventListener: ((event: OperationEvent) => void) | undefined;
    const api: DashboardApi = {
        listProjectInfo: vi.fn(async () => ({
            projectDirectory: '/repo/arbeidsforhold',
            repositoryName: 'crm-arbeidsforhold-2',
            repositoryUrl: 'https://github.com/navikt/crm-arbeidsforhold-2',
            branch: 'main',
            status: 'clean' as const,
            statusSummary: 'Ingen endringer',
            isGitRepository: true
        })),
        listOrgs: vi.fn(async () => options.orgs ?? [scratchOrg, productionOrg]),
        getOrg: vi.fn(async (alias) => detail(alias === productionOrg.alias ? productionOrg : scratchOrg)),
        getOrgPackages: vi.fn(async (alias: string) => ({
            targetOrg: alias,
            packages: [
                {
                    packageName: 'crm-platform-base',
                    configuredVersion: '2.0.0.LATEST',
                    installedVersion: '1.9.0.4',
                    selectedVersion: '2.0.0.1',
                    status: 'update-available' as const
                },
                {
                    packageName: 'unconfigured-package',
                    configuredVersion: null,
                    installedVersion: null,
                    selectedVersion: null,
                    status: 'unknown' as const
                }
            ],
            summary: { total: 2, current: 0, updateAvailable: 1, higher: 0, missing: 0, unknown: 1 }
        })),
        listOperations: vi.fn(async () => options.operations ?? []),
        startOperation: vi.fn(async () => ({ id: 'operation-new' })),
        subscribe: vi.fn((_operationId, onEvent) => {
            eventListener = onEvent;
            return () => undefined;
        })
    };
    return { api: api as DashboardApi, emit: (event: OperationEvent) => eventListener?.(event) };
}

describe('operational dashboard', () => {
    it('renders org status and factual selected-org package status', async () => {
        const { api } = createApi();
        const { container } = render(<App api={api} />);

        expect(await screen.findByRole('heading', { name: 'Salesforce-organisasjonar' })).toBeInTheDocument();
        expect(screen.getByRole('table', { name: 'Tilgjengelege organisasjonar' })).toBeInTheDocument();
        expect(screen.getByRole('button', { name: /scratch-a/ })).toBeInTheDocument();
        expect(await screen.findByRole('heading', { name: 'scratch-a' })).toBeInTheDocument();
        expect(screen.getAllByText('Autentisert')).toHaveLength(3);
        expect(screen.getByText('Standardorganisasjon')).toBeInTheDocument();
        expect(await screen.findByRole('heading', { name: 'Pakkestatus' })).toBeInTheDocument();
        expect(screen.getByText('2 pakkar, 1 kan oppdaterast, 1 med ukjend status')).toBeInTheDocument();
        expect(screen.getByRole('table', { name: 'Pakkestatus for scratch-a' })).toBeInTheDocument();
        expect(screen.getByText('crm-platform-base')).toBeInTheDocument();
        expect(screen.getAllByText('Ukjend').length).toBeGreaterThan(0);
        expect(await axe(container)).toHaveNoViolations();
    });

    it('shows a package-specific error while preserving selected org details', async () => {
        const { api } = createApi();
        vi.mocked(
            (api as DashboardApi & { getOrgPackages(alias: string): Promise<unknown> }).getOrgPackages
        ).mockRejectedValue(new Error('package lookup failed'));

        render(<App api={api} />);

        expect(await screen.findByRole('heading', { name: 'scratch-a' })).toBeInTheDocument();
        expect(await screen.findByText('Kunne ikkje hente pakkestatus')).toBeInTheDocument();
        expect(screen.getByText(/package lookup failed/)).toBeInTheDocument();
    });

    it('shows package loading independently from selected org details', async () => {
        const { api } = createApi();
        vi.mocked(api.getOrgPackages).mockImplementation(() => new Promise(() => undefined));

        render(<App api={api} />);

        expect(await screen.findByRole('heading', { name: 'scratch-a' })).toBeInTheDocument();
        expect(screen.getAllByText('Hentar pakkestatus').length).toBeGreaterThan(0);
    });

    it('announces loading and shows an actionable load failure', async () => {
        const api = createApi().api;
        vi.mocked(api.listOrgs).mockRejectedValueOnce(new Error('offline'));
        render(<App api={api} />);

        expect(screen.getByRole('status')).toHaveTextContent('Hentar organisasjonar');
        expect(await screen.findByRole('alert')).toHaveTextContent('Kunne ikkje hente organisasjonar');
        expect(screen.getByRole('button', { name: 'Prøv på nytt' })).toBeInTheDocument();
    });

    it('keeps production controls read-only and explains why', async () => {
        const { api } = createApi({ orgs: [productionOrg] });
        render(<App api={api} />);

        expect(await screen.findByText('Skriveverna organisasjon')).toBeInTheDocument();
        expect(screen.getByText(/produksjon og ukjend type/i)).toBeInTheDocument();
        expect(screen.queryByRole('button', { name: 'Slett organisasjon' })).not.toBeInTheDocument();
    });

    it.each([
        ['Oppdater avhengigheitskjelder', 'dependencies.refresh'],
        ['Installer pakkar', 'packages.install'],
        ['Oppdater pakkar', 'packages.update'],
        ['Konfigurer prosjekt', 'project.configure']
    ] as const)('submits %s without an explicit target when the default option is selected', async (label, command) => {
        const user = userEvent.setup();
        const { api } = createApi();
        render(<App api={api} />);
        await screen.findByRole('heading', { name: 'scratch-a' });

        await user.selectOptions(screen.getByRole('combobox', { name: 'Kommando' }), command);
        const target = screen.getByRole('combobox', { name: 'Målorganisasjon' });
        expect(target).toHaveValue('');
        expect(screen.getByRole('option', { name: 'Konfigurert/standard organisasjon' })).toBeInTheDocument();
        expect(target).not.toBeRequired();

        await user.click(screen.getByRole('button', { name: 'Start kommando' }));

        await waitFor(() => expect(api.startOperation).toHaveBeenCalledWith(command, { dryRun: false }));
    });

    it('keeps an explicitly selected production target read-only', async () => {
        const user = userEvent.setup();
        const { api } = createApi();
        render(<App api={api} />);
        await screen.findByRole('heading', { name: 'scratch-a' });

        await user.selectOptions(screen.getByRole('combobox', { name: 'Kommando' }), 'packages.install');
        await user.selectOptions(screen.getByRole('combobox', { name: 'Målorganisasjon' }), 'production-a');
        expect(screen.getByText(/skriveverna.*tørrkøyring/i)).toBeInTheDocument();
        await user.click(screen.getByRole('button', { name: 'Start kommando' }));

        await waitFor(() =>
            expect(api.startOperation).toHaveBeenCalledWith('packages.install', {
                targetOrg: 'production-a',
                dryRun: true
            })
        );
    });

    it('requires an alertdialog naming the target before submitting org deletion', async () => {
        const user = userEvent.setup();
        const { api } = createApi({ orgs: [scratchOrg] });
        render(<App api={api} />);
        await screen.findByRole('heading', { name: 'scratch-a' });

        await user.click(screen.getByRole('button', { name: 'Slett organisasjon' }));
        const dialog = screen.getByRole('alertdialog', { name: 'Slett scratch-a?' });
        expect(dialog).toHaveTextContent('Mål: scratch-a');
        expect(api.startOperation).not.toHaveBeenCalled();

        await user.click(screen.getByRole('button', { name: 'Ja, slett scratch-a' }));
        await waitFor(() =>
            expect(api.startOperation).toHaveBeenCalledWith('org.delete', {
                alias: 'scratch-a',
                confirmed: true,
                dryRun: false
            })
        );
    });

    it('shows a dedicated scratch-org creation form with project metadata and effective values', async () => {
        const user = userEvent.setup();
        const { api } = createApi();
        const projectInfo = {
            projectDirectory: '/repo/arbeidsforhold',
            repositoryName: 'crm-arbeidsforhold-2',
            repositoryUrl: 'https://github.com/navikt/crm-arbeidsforhold-2',
            branch: 'main',
            status: 'clean' as const,
            statusSummary: 'Ingen endringer',
            isGitRepository: true
        };
        vi.mocked(api.listProjectInfo).mockResolvedValue(projectInfo);

        render(<App api={api} />);

        expect(await screen.findByRole('heading', { name: 'Opprett ny scratch org' })).toBeInTheDocument();
        expect(screen.getByText('crm-arbeidsforhold-2')).toBeInTheDocument();
        expect(screen.getByText('Ingen endringer')).toBeInTheDocument();
        expect(screen.getByRole('link', { name: /crm-arbeidsforhold-2/i })).toHaveAttribute(
            'href',
            'https://github.com/navikt/crm-arbeidsforhold-2'
        );

        const alias = screen.getByRole('textbox', { name: 'Alias' });
        await user.clear(alias);
        await user.type(alias, 'ny-scratch');
        await user.click(screen.getByRole('button', { name: 'Opprett scratch org' }));

        await waitFor(() =>
            expect(api.startOperation).toHaveBeenCalledWith('org.create', {
                alias: 'ny-scratch',
                durationDays: 14,
                dryRun: false,
                usePool: false,
                poolTag: 'dev',
                fallbackToCreate: true,
                postSteps: ['deploy']
            })
        );
    });

    it('renders live SSE failures with text, duration, and next action', async () => {
        const operation: Operation = {
            id: 'operation-live',
            command: 'packages.update',
            status: 'running',
            createdAt: '2026-09-13T10:00:00.000Z',
            events: []
        };
        const { api, emit } = createApi({ operations: [operation] });
        render(<App api={api} />);
        await screen.findByText('Pakkeoppdatering køyrer');

        emit({
            kind: 'step-failed',
            operationId: operation.id,
            timestamp: '2026-09-13T10:00:02.500Z',
            stepId: 'install',
            step: 'Installer pakkar',
            exitCode: 1,
            durationMs: 2500,
            error: 'Installasjonen feila',
            nextAction: 'Kontroller pakkeversjonen og prøv igjen'
        });

        expect(await screen.findAllByText('Installasjonen feila')).toHaveLength(2);
        expect(screen.getByText('Varigheit: 2,5 s')).toBeInTheDocument();
        expect(screen.getByText('Neste steg: Kontroller pakkeversjonen og prøv igjen')).toBeInTheDocument();

        emit({
            kind: 'operation-completed',
            operationId: operation.id,
            timestamp: '2026-09-13T10:00:03.000Z',
            operation: operation.command,
            exitCode: 1,
            durationMs: 3000
        });
        expect(await screen.findByRole('heading', { name: 'Pakkeoppdatering feila' })).toBeInTheDocument();
    });
});
