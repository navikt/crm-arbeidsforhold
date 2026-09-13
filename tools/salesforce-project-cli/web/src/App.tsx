/**
 * Renders the operational dashboard for org inspection, package status, and controlled project workflows.
 * The component consumes an injected API and releases active event subscriptions during lifecycle changes.
 */
import { ArrowCirclepathIcon, Buildings2Icon, PlayIcon, TrashIcon } from '@navikt/aksel-icons';
import {
    BodyLong,
    BodyShort,
    Box,
    Button,
    Detail,
    Dialog,
    Heading,
    HGrid,
    HStack,
    Label,
    Loader,
    LocalAlert,
    Page,
    Select,
    Table,
    TextField,
    VStack
} from '@navikt/ds-react';
import { useEffect, useState, type FormEvent } from 'react';
import type {
    DashboardApi,
    Operation,
    OperationEvent,
    OrgDetail,
    OrgPackageStatusKind,
    OrgPackageStatusResult,
    OrgSummary,
    WebOperationCommand
} from './api';

const orgTypeLabels: Record<OrgSummary['orgType'], string> = {
    scratch: 'Scratch',
    development: 'Utvikling',
    sandbox: 'Sandbox',
    'dev-hub': 'Dev Hub',
    production: 'Produksjon',
    unknown: 'Ukjend'
};

const authLabels: Record<OrgSummary['authStatus'], string> = {
    authenticated: 'Autentisert',
    unauthenticated: 'Ikkje autentisert',
    inaccessible: 'Utilgjengeleg',
    expired: 'Utgått',
    unknown: 'Ukjend'
};

const connectionLabels: Record<OrgSummary['connectionStatus'], string> = {
    connected: 'Tilkobla',
    disconnected: 'Fråkopla',
    unknown: 'Ukjend'
};

const packageStatusLabels: Record<OrgPackageStatusKind, string> = {
    missing: 'Manglar',
    current: 'Oppdatert',
    'update-available': 'Kan oppdaterast',
    higher: 'Nyare enn valt',
    unknown: 'Ukjend'
};

const commandLabels: Record<Exclude<WebOperationCommand, 'org.delete'>, string> = {
    'dependencies.clear': 'Tøm avhengigheitskjelder',
    'dependencies.refresh': 'Oppdater avhengigheitskjelder',
    'packages.plan': 'Planlegg pakkar',
    'packages.install': 'Installer pakkar',
    'packages.update': 'Oppdater pakkar',
    'org.create': 'Opprett scratch-organisasjon',
    'project.configure': 'Konfigurer prosjekt'
};

const operationLabels: Record<WebOperationCommand, string> = {
    'dependencies.clear': 'Tømming av avhengigheitskjelder',
    'dependencies.refresh': 'Oppdatering av avhengigheitskjelder',
    'packages.plan': 'Pakkeplanlegging',
    'packages.install': 'Pakkeinstallasjon',
    'packages.update': 'Pakkeoppdatering',
    'org.create': 'Oppretting av scratch-organisasjon',
    'org.delete': 'Sletting av organisasjon',
    'project.configure': 'Prosjektkonfigurasjon'
};

function orgTarget(org: OrgSummary): string {
    return org.alias ?? org.username ?? 'Organisasjon utan alias';
}

function duration(milliseconds: number): string {
    return `${new Intl.NumberFormat('nn-NO', { maximumFractionDigits: 1 }).format(milliseconds / 1000)} s`;
}

function eventText(event: OperationEvent): string {
    if (event.error) return event.error;
    if (event.message) return event.message;
    if (event.kind === 'operation-started') return 'Operasjonen starta';
    if (event.kind === 'operation-completed')
        return event.exitCode === 0 ? 'Operasjonen er fullført' : 'Operasjonen feila';
    return event.step ?? event.kind;
}

function operationTitle(operation: Operation): string {
    const label = operationLabels[operation.command];
    if (operation.status === 'running') return `${label} køyrer`;
    if (operation.status === 'failed') return `${label} feila`;
    return `${label} er fullført`;
}

interface AppProps {
    api: DashboardApi;
}

/**
 * Renders the operational dashboard using an injected browser/server API boundary.
 *
 * Injecting {@link DashboardApi} keeps transport, authentication, and SSE lifecycle handling out of
 * the component and allows tests or alternate hosts to supply the same read, mutation, and
 * subscription contract.
 */
export function App({ api }: AppProps) {
    const [orgs, setOrgs] = useState<OrgSummary[]>([]);
    const [selectedOrg, setSelectedOrg] = useState<OrgDetail | null>(null);
    const [packageStatus, setPackageStatus] = useState<OrgPackageStatusResult | null>(null);
    const [packageStatusLoading, setPackageStatusLoading] = useState(false);
    const [packageStatusError, setPackageStatusError] = useState<string | null>(null);
    const [operations, setOperations] = useState<Operation[]>([]);
    const [loading, setLoading] = useState(true);
    const [loadError, setLoadError] = useState<string | null>(null);
    const [announcement, setAnnouncement] = useState('');
    const [deleteOpen, setDeleteOpen] = useState(false);

    const loadDashboard = async () => {
        setLoading(true);
        setLoadError(null);
        try {
            const [nextOrgs, nextOperations] = await Promise.all([api.listOrgs(), api.listOperations()]);
            setOrgs(nextOrgs);
            setOperations(nextOperations);
            const firstTarget = nextOrgs[0] ? orgTarget(nextOrgs[0]) : null;
            if (firstTarget) {
                setSelectedOrg(await api.getOrg(firstTarget));
                setPackageStatusLoading(true);
                setPackageStatusError(null);
                try {
                    setPackageStatus(await api.getOrgPackages(firstTarget));
                } catch (error) {
                    setPackageStatus(null);
                    setPackageStatusError(error instanceof Error ? error.message : 'Ukjend feil');
                } finally {
                    setPackageStatusLoading(false);
                }
            } else {
                setSelectedOrg(null);
                setPackageStatus(null);
            }
            setAnnouncement(`${nextOrgs.length} organisasjonar er henta`);
        } catch (error) {
            setLoadError(error instanceof Error ? error.message : 'Ukjend feil');
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        void loadDashboard();
    }, [api]);

    useEffect(() => {
        const active = operations.filter((operation) => operation.status === 'running');
        return active.length === 0
            ? undefined
            : (() => {
                  const unsubscribe = active.map((operation) =>
                      api.subscribe(operation.id, (event) => {
                          setOperations((current) =>
                              current.map((item) =>
                                  item.id === operation.id
                                      ? {
                                            ...item,
                                            status:
                                                event.kind === 'operation-completed'
                                                    ? event.exitCode === 0
                                                        ? 'completed'
                                                        : 'failed'
                                                    : item.status,
                                            events: [...item.events, event]
                                        }
                                      : item
                              )
                          );
                          setAnnouncement(eventText(event));
                      })
                  );
                  return () => unsubscribe.forEach((stop) => stop());
              })();
    }, [api, operations.map(({ id, status }) => `${id}:${status}`).join('|')]);

    const selectOrg = async (org: OrgSummary) => {
        try {
            const target = orgTarget(org);
            setSelectedOrg(await api.getOrg(target));
            setPackageStatus(null);
            setPackageStatusError(null);
            setPackageStatusLoading(true);
            try {
                setPackageStatus(await api.getOrgPackages(target));
            } catch (error) {
                setPackageStatusError(error instanceof Error ? error.message : 'Ukjend feil');
            } finally {
                setPackageStatusLoading(false);
            }
        } catch (error) {
            setLoadError(error instanceof Error ? error.message : 'Kunne ikkje hente organisasjonen');
        }
    };

    const registerOperation = (operation: Operation) => {
        setOperations((current) => [operation, ...current.filter(({ id }) => id !== operation.id)]);
        setAnnouncement(`${operationTitle(operation)}.`);
    };

    const startCommand = async (command: WebOperationCommand, payload: Record<string, unknown>) => {
        const { id } = await api.startOperation(command, payload);
        registerOperation({ id, command, status: 'running', createdAt: new Date().toISOString(), events: [] });
    };

    const confirmDelete = async () => {
        if (!selectedOrg) return;
        const alias = orgTarget(selectedOrg);
        await startCommand('org.delete', { alias, confirmed: true, dryRun: false });
        setDeleteOpen(false);
    };

    return (
        <Page className="dashboard-page">
            <header className="app-header">
                <Page.Block width="2xl" gutters>
                    <HStack align="center" gap="space-12">
                        <Buildings2Icon aria-hidden fontSize="1.75rem" />
                        <div>
                            <Heading level="1" size="medium">
                                Salesforce-prosjekt
                            </Heading>
                            <Detail>Lokalt operasjonspanel</Detail>
                        </div>
                    </HStack>
                </Page.Block>
            </header>
            <Page.Block as="main" width="2xl" gutters>
                <VStack gap={{ xs: 'space-16', md: 'space-24' }} paddingBlock="space-24">
                    <span className="sr-only" role="status" aria-live="polite">
                        {loading ? 'Hentar organisasjonar' : announcement}
                    </span>
                    {loadError && (
                        <LocalAlert status="error" as="div">
                            <LocalAlert.Header>
                                <LocalAlert.Title as="h2">Kunne ikkje hente organisasjonar</LocalAlert.Title>
                            </LocalAlert.Header>
                            <LocalAlert.Content>
                                <VStack gap="space-12">
                                    <BodyShort>{loadError}. Kontroller at den lokale tenesta køyrer.</BodyShort>
                                    <Button variant="secondary" size="small" onClick={() => void loadDashboard()}>
                                        Prøv på nytt
                                    </Button>
                                </VStack>
                            </LocalAlert.Content>
                        </LocalAlert>
                    )}
                    <HStack justify="space-between" align="end" gap="space-16" wrap>
                        <div>
                            <Heading level="2" size="large">
                                Salesforce-organisasjonar
                            </Heading>
                            <BodyShort textColor="subtle">Status frå den lokale Salesforce CLI-en</BodyShort>
                        </div>
                        <Button
                            variant="secondary"
                            size="small"
                            icon={<ArrowCirclepathIcon aria-hidden />}
                            loading={loading}
                            onClick={() => void loadDashboard()}
                        >
                            Oppdater
                        </Button>
                    </HStack>
                    {loading && orgs.length === 0 ? (
                        <HStack align="center" gap="space-12" className="loading-region">
                            <Loader title="Hentar organisasjonar" />
                            <BodyShort>Hentar organisasjonar</BodyShort>
                        </HStack>
                    ) : (
                        <div
                            className="table-scroll"
                            role="region"
                            aria-label="Tilgjengelege organisasjonar"
                            tabIndex={0}
                        >
                            <Table size="small" zebraStripes>
                                <caption>Tilgjengelege organisasjonar</caption>
                                <Table.Header>
                                    <Table.Row>
                                        <Table.HeaderCell scope="col">Alias</Table.HeaderCell>
                                        <Table.HeaderCell scope="col">Type</Table.HeaderCell>
                                        <Table.HeaderCell scope="col">Tilkobling</Table.HeaderCell>
                                        <Table.HeaderCell scope="col">Autentisering</Table.HeaderCell>
                                        <Table.HeaderCell scope="col">Utløp</Table.HeaderCell>
                                        <Table.HeaderCell scope="col">Standard</Table.HeaderCell>
                                    </Table.Row>
                                </Table.Header>
                                <Table.Body>
                                    {orgs.map((org) => (
                                        <Table.Row
                                            key={`${org.alias}:${org.username}`}
                                            selected={orgTarget(org) === selectedOrg?.alias}
                                        >
                                            <Table.HeaderCell scope="row">
                                                <Button
                                                    variant="tertiary"
                                                    size="xsmall"
                                                    onClick={() => void selectOrg(org)}
                                                >
                                                    {orgTarget(org)}
                                                </Button>
                                            </Table.HeaderCell>
                                            <Table.DataCell>{orgTypeLabels[org.orgType]}</Table.DataCell>
                                            <Table.DataCell>{connectionLabels[org.connectionStatus]}</Table.DataCell>
                                            <Table.DataCell>{authLabels[org.authStatus]}</Table.DataCell>
                                            <Table.DataCell>
                                                {org.expirationDate ?? 'Ikkje aktuelt'}
                                                {org.remainingLifetimeDays !== null
                                                    ? ` (${org.remainingLifetimeDays} dagar)`
                                                    : ''}
                                            </Table.DataCell>
                                            <Table.DataCell>
                                                {org.isDefaultOrg
                                                    ? 'Standardorganisasjon'
                                                    : org.isDefaultDevHub
                                                      ? 'Standard Dev Hub'
                                                      : 'Nei'}
                                            </Table.DataCell>
                                        </Table.Row>
                                    ))}
                                </Table.Body>
                            </Table>
                        </div>
                    )}
                    <HGrid columns={{ xs: 1, lg: 'minmax(0, 2fr) minmax(20rem, 1fr)' }} gap="space-24" align="start">
                        <VStack gap="space-24">
                            <OrgDetails
                                org={selectedOrg}
                                packageStatus={packageStatus}
                                packageStatusLoading={packageStatusLoading}
                                packageStatusError={packageStatusError}
                                onDelete={() => setDeleteOpen(true)}
                            />
                            <Operations operations={operations} />
                        </VStack>
                        <CommandPanel orgs={orgs} onStart={startCommand} />
                    </HGrid>
                </VStack>
            </Page.Block>
            <DeleteDialog
                org={selectedOrg}
                open={deleteOpen}
                onOpenChange={setDeleteOpen}
                onConfirm={() => void confirmDelete()}
            />
        </Page>
    );
}

function OrgDetails({
    org,
    packageStatus,
    packageStatusLoading,
    packageStatusError,
    onDelete
}: {
    org: OrgDetail | null;
    packageStatus: OrgPackageStatusResult | null;
    packageStatusLoading: boolean;
    packageStatusError: string | null;
    onDelete: () => void;
}) {
    if (!org) return null;
    const readOnly = org.capabilities.mutationPolicy === 'read-only';
    return (
        <section className="surface" aria-labelledby="org-detail-heading">
            <VStack gap="space-16">
                <HStack justify="space-between" align="start" gap="space-12" wrap>
                    <div>
                        <Heading id="org-detail-heading" level="2" size="medium">
                            {orgTarget(org)}
                        </Heading>
                        <BodyShort>{org.username ?? 'Brukarnamn er ikkje tilgjengeleg'}</BodyShort>
                    </div>
                    {!readOnly && (
                        <Button
                            variant="secondary"
                            data-color="danger"
                            size="small"
                            icon={<TrashIcon aria-hidden />}
                            onClick={onDelete}
                        >
                            Slett organisasjon
                        </Button>
                    )}
                </HStack>
                {readOnly && (
                    <LocalAlert status="warning" size="small" as="div" role={undefined}>
                        <LocalAlert.Header>
                            <LocalAlert.Title as="h3">Skriveverna organisasjon</LocalAlert.Title>
                        </LocalAlert.Header>
                        <LocalAlert.Content>
                            Produksjon og ukjend type er skriveverna. Berre lesing og tørre køyringar er tillatne.
                        </LocalAlert.Content>
                    </LocalAlert>
                )}
                <dl className="detail-grid">
                    <DetailItem label="Type" value={orgTypeLabels[org.orgType]} />
                    <DetailItem label="Tilkobling" value={connectionLabels[org.connectionStatus]} />
                    <DetailItem label="Autentisering" value={authLabels[org.authStatus]} />
                    <DetailItem label="API-versjon" value={org.apiVersion ?? 'Ukjend'} />
                    <DetailItem label="Utgåingsdato" value={org.expirationDate ?? 'Ikkje aktuelt'} />
                    <DetailItem
                        label="Kjeldesporing"
                        value={org.sourceTracking === null ? 'Ukjend' : org.sourceTracking ? 'Ja' : 'Nei'}
                    />
                    <DetailItem label="Sist oppdatert" value={org.lastRefreshTimestamp ?? 'Ikkje oppdatert'} />
                </dl>
                <PackageStatus
                    org={org}
                    status={packageStatus}
                    loading={packageStatusLoading}
                    error={packageStatusError}
                />
            </VStack>
        </section>
    );
}

function PackageStatus({
    org,
    status,
    loading,
    error
}: {
    org: OrgDetail;
    status: OrgPackageStatusResult | null;
    loading: boolean;
    error: string | null;
}) {
    if (loading) {
        return (
            <HStack align="center" gap="space-8">
                <Loader size="small" title="Hentar pakkestatus" />
                <BodyShort>Hentar pakkestatus</BodyShort>
            </HStack>
        );
    }
    if (error) {
        return (
            <LocalAlert status="error" size="small" as="div">
                <LocalAlert.Header>
                    <LocalAlert.Title as="h3">Kunne ikkje hente pakkestatus</LocalAlert.Title>
                </LocalAlert.Header>
                <LocalAlert.Content>{error}</LocalAlert.Content>
            </LocalAlert>
        );
    }
    if (status === null) return null;
    const summary = status.summary;
    return (
        <section aria-labelledby="package-status-heading">
            <VStack gap="space-12">
                <div>
                    <Heading id="package-status-heading" level="3" size="small">
                        Pakkestatus
                    </Heading>
                    <BodyShort>
                        {summary.total} pakkar, {summary.updateAvailable} kan oppdaterast, {summary.unknown} med ukjend
                        status
                    </BodyShort>
                </div>
                <div
                    className="table-scroll"
                    role="region"
                    aria-label={`Pakkestatus for ${orgTarget(org)}`}
                    tabIndex={0}
                >
                    <Table size="small" zebraStripes>
                        <caption>Pakkestatus for {orgTarget(org)}</caption>
                        <Table.Header>
                            <Table.Row>
                                <Table.HeaderCell scope="col">Pakke</Table.HeaderCell>
                                <Table.HeaderCell scope="col">Installert</Table.HeaderCell>
                                <Table.HeaderCell scope="col">Valt</Table.HeaderCell>
                                <Table.HeaderCell scope="col">Status</Table.HeaderCell>
                            </Table.Row>
                        </Table.Header>
                        <Table.Body>
                            {status.packages.map((item) => (
                                <Table.Row key={item.packageName}>
                                    <Table.HeaderCell scope="row">{item.packageName}</Table.HeaderCell>
                                    <Table.DataCell>{item.installedVersion ?? 'Ukjend'}</Table.DataCell>
                                    <Table.DataCell>{item.selectedVersion ?? 'Ukjend'}</Table.DataCell>
                                    <Table.DataCell>{packageStatusLabels[item.status]}</Table.DataCell>
                                </Table.Row>
                            ))}
                        </Table.Body>
                    </Table>
                </div>
            </VStack>
        </section>
    );
}

function DetailItem({ label, value }: { label: string; value: string }) {
    return (
        <div>
            <dt>
                <Detail>{label}</Detail>
            </dt>
            <dd>{value}</dd>
        </div>
    );
}

function Operations({ operations }: { operations: Operation[] }) {
    return (
        <section aria-labelledby="operations-heading">
            <VStack gap="space-12">
                <Heading id="operations-heading" level="2" size="medium">
                    Aktive og nylege operasjonar
                </Heading>
                {operations.length === 0 ? (
                    <BodyShort>Ingen operasjonar i denne økta.</BodyShort>
                ) : (
                    operations.map((operation) => (
                        <article className={`operation operation--${operation.status}`} key={operation.id}>
                            <VStack gap="space-8">
                                <HStack justify="space-between" align="center" gap="space-12" wrap>
                                    <Heading level="3" size="small">
                                        {operationTitle(operation)}
                                    </Heading>
                                    <Detail>{new Date(operation.createdAt).toLocaleString('nn-NO')}</Detail>
                                </HStack>
                                {operation.events.length === 0 ? (
                                    <BodyShort>Vent på første statusoppdatering.</BodyShort>
                                ) : (
                                    <ol className="event-list">
                                        {operation.events.map((event, index) => (
                                            <li key={`${event.timestamp}:${event.kind}:${index}`}>
                                                <BodyShort
                                                    weight={event.kind === 'step-failed' ? 'semibold' : 'regular'}
                                                >
                                                    {eventText(event)}
                                                </BodyShort>
                                                {event.durationMs !== undefined && (
                                                    <Detail>Varigheit: {duration(event.durationMs)}</Detail>
                                                )}
                                                {event.nextAction && (
                                                    <BodyShort>Neste steg: {event.nextAction}</BodyShort>
                                                )}
                                            </li>
                                        ))}
                                    </ol>
                                )}
                            </VStack>
                        </article>
                    ))
                )}
            </VStack>
        </section>
    );
}

function CommandPanel({
    orgs,
    onStart
}: {
    orgs: OrgSummary[];
    onStart: (command: WebOperationCommand, payload: Record<string, unknown>) => Promise<void>;
}) {
    const [command, setCommand] = useState<Exclude<WebOperationCommand, 'org.delete'>>('packages.plan');
    const [target, setTarget] = useState('');
    const [alias, setAlias] = useState('');
    const [submitting, setSubmitting] = useState(false);
    const [error, setError] = useState<string | null>(null);
    const needsTarget = ['dependencies.refresh', 'packages.install', 'packages.update', 'project.configure'].includes(
        command
    );
    const createsOrg = command === 'org.create';
    const selectedTarget = target;
    const targetOrg = orgs.find((org) => orgTarget(org) === selectedTarget);
    const readOnly = targetOrg?.capabilities.mutationPolicy === 'read-only';

    const submit = async (event: FormEvent<HTMLFormElement>) => {
        event.preventDefault();
        setError(null);
        const dryRun = readOnly === true;
        let payload: Record<string, unknown> = { dryRun };
        if (needsTarget && selectedTarget) {
            payload =
                command === 'project.configure'
                    ? { alias: selectedTarget, dryRun }
                    : { targetOrg: selectedTarget, dryRun };
        }
        if (command === 'packages.plan')
            payload = selectedTarget ? { targetOrg: selectedTarget, dryRun: true } : { dryRun: true };
        if (command === 'org.create') payload = { alias, durationDays: 14, dryRun: false };
        try {
            setSubmitting(true);
            await onStart(command, payload);
        } catch (submissionError) {
            setError(submissionError instanceof Error ? submissionError.message : 'Operasjonen kunne ikkje startast');
        } finally {
            setSubmitting(false);
        }
    };

    return (
        <aside className="command-panel" aria-labelledby="command-heading">
            <VStack gap="space-16">
                <div>
                    <Heading id="command-heading" level="2" size="medium">
                        Kommandoar
                    </Heading>
                    <BodyShort textColor="subtle">Berre godkjende API-kommandoar</BodyShort>
                </div>
                {error && (
                    <LocalAlert status="error" size="small" as="div">
                        <LocalAlert.Header>
                            <LocalAlert.Title as="h3">Kunne ikkje starte</LocalAlert.Title>
                        </LocalAlert.Header>
                        <LocalAlert.Content>{error}</LocalAlert.Content>
                    </LocalAlert>
                )}
                <form onSubmit={(event) => void submit(event)}>
                    <VStack gap="space-16">
                        <Select
                            label="Kommando"
                            value={command}
                            onChange={(event) => setCommand(event.target.value as typeof command)}
                        >
                            {Object.entries(commandLabels).map(([value, label]) => (
                                <option value={value} key={value}>
                                    {label}
                                </option>
                            ))}
                        </Select>
                        {createsOrg ? (
                            <TextField
                                label="Nytt alias"
                                value={alias}
                                onChange={(event) => setAlias(event.target.value)}
                                required
                            />
                        ) : (
                            <Select
                                label="Målorganisasjon"
                                value={selectedTarget}
                                onChange={(event) => setTarget(event.target.value)}
                            >
                                <option value="">Konfigurert/standard organisasjon</option>
                                {orgs.map((org) => (
                                    <option value={orgTarget(org)} key={orgTarget(org)}>
                                        {orgTarget(org)} ({orgTypeLabels[org.orgType]})
                                    </option>
                                ))}
                            </Select>
                        )}
                        {readOnly && (
                            <BodyShort className="read-only-note">
                                Målet er skriveverna. Kommandoen blir køyrd som tørrkøyring.
                            </BodyShort>
                        )}
                        <Button type="submit" icon={<PlayIcon aria-hidden />} loading={submitting}>
                            Start kommando
                        </Button>
                    </VStack>
                </form>
            </VStack>
        </aside>
    );
}

function DeleteDialog({
    org,
    open,
    onOpenChange,
    onConfirm
}: {
    org: OrgDetail | null;
    open: boolean;
    onOpenChange: (open: boolean) => void;
    onConfirm: () => void;
}) {
    const alias = org ? orgTarget(org) : '';
    return (
        <Dialog open={open} onOpenChange={onOpenChange}>
            <Dialog.Popup role="alertdialog" closeOnOutsideClick={false} width="small">
                <Dialog.Header withClosebutton={false}>
                    <Dialog.Title>Slett {alias}?</Dialog.Title>
                    <Dialog.Description>
                        Denne handlinga slettar scratch-organisasjonen og kan ikkje angrast.
                    </Dialog.Description>
                </Dialog.Header>
                <Dialog.Body>
                    <BodyLong>
                        <Label as="span">Mål:</Label> {alias}
                    </BodyLong>
                </Dialog.Body>
                <Dialog.Footer>
                    <Dialog.CloseTrigger>
                        <Button variant="secondary" data-color="neutral">
                            Avbryt
                        </Button>
                    </Dialog.CloseTrigger>
                    <Button variant="primary" data-color="danger" onClick={onConfirm}>
                        Ja, slett {alias}
                    </Button>
                </Dialog.Footer>
            </Dialog.Popup>
        </Dialog>
    );
}
