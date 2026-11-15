import { LightningElement } from 'lwc';
import getMonitor from '@salesforce/apex/AAREG_AdminMonitorController.getMonitor';

const DATE = { year: 'numeric', month: '2-digit', day: '2-digit', hour: '2-digit', minute: '2-digit' };

const JOB_COLUMNS = [
    {
        label: 'Jobb',
        fieldName: 'jobUrl',
        type: 'url',
        initialWidth: 130,
        typeAttributes: { label: { fieldName: 'name' } }
    },
    { label: 'Status', fieldName: 'status', initialWidth: 130 },
    { label: 'Type', fieldName: 'eventType', initialWidth: 200 },
    { label: 'Forsøk', fieldName: 'attempts', type: 'number', initialWidth: 90 },
    { label: 'Neste forsøk', fieldName: 'nextAttempt', type: 'date', typeAttributes: DATE, initialWidth: 160 },
    {
        label: 'Lease',
        fieldName: 'leaseText',
        initialWidth: 100,
        cellAttributes: { class: { fieldName: 'leaseClass' } }
    },
    { label: 'Korrelasjons-ID', fieldName: 'correlationId', initialWidth: 340 },
    { label: 'Feilkode', fieldName: 'lastErrorCode', initialWidth: 160 },
    { label: 'Feilmelding', fieldName: 'lastErrorMessage', wrapText: true, initialWidth: 360 },
    { label: 'Søknad', fieldName: 'applicationUrl', type: 'url', typeAttributes: { label: 'Opne' }, initialWidth: 100 },
    { label: 'Vedtak', fieldName: 'decisionUrl', type: 'url', typeAttributes: { label: 'Opne' }, initialWidth: 100 },
    { label: 'Scratch-mottak', fieldName: 'captureText', initialWidth: 140 }
];

const SOURCE_COLUMNS = [
    { label: 'Kjelde (klasse)', fieldName: 'sourceClass', wrapText: true },
    { label: 'Loggar 7 dagar', fieldName: 'total', type: 'number' },
    { label: 'Feil', fieldName: 'errors', type: 'number', cellAttributes: { class: { fieldName: 'errorClass' } } },
    { label: 'Sist aktiv', fieldName: 'lastActivity', type: 'date', typeAttributes: DATE },
    { label: 'Siste feil', fieldName: 'lastErrorAt', type: 'date', typeAttributes: DATE },
    { label: 'Siste feilmelding', fieldName: 'lastErrorMessage', wrapText: true }
];

const recordUrl = (objectApiName, id) => (id ? `/lightning/r/${objectApiName}/${id}/view` : undefined);

function leaseText(job) {
    if (job.status !== 'In Progress') {
        return '';
    }
    if (job.leaseExpired) {
        return 'Utgått';
    }
    return job.leaseExpires ? 'Aktiv' : '';
}

export default class AaregAdminIntegrationMonitor extends LightningElement {
    jobColumns = JOB_COLUMNS;
    sourceColumns = SOURCE_COLUMNS;
    monitor;
    jobs = [];
    sources = [];
    error;
    loading = true;

    connectedCallback() {
        this.load();
    }

    async load() {
        this.loading = true;
        this.error = undefined;
        try {
            const monitor = await getMonitor();
            this.monitor = monitor;
            this.jobs = (monitor.jobs ?? []).map((job) => ({
                ...job,
                jobUrl: recordUrl('P360_Archive_Job__c', job.id),
                applicationUrl: recordUrl('Application__c', job.applicationId),
                decisionUrl: recordUrl('Application_Decision__c', job.decisionId),
                leaseText: leaseText(job),
                leaseClass: job.leaseExpired ? 'slds-text-color_error' : '',
                captureText: monitor.scratchCaptureAvailable ? String(job.captureCount ?? 0) : 'Ikkje i denne orga'
            }));
            this.sources = (monitor.sources ?? []).map((source) => ({
                ...source,
                errorClass: source.errors > 0 ? 'slds-text-color_error' : ''
            }));
        } catch (error) {
            this.error = error?.body?.message ?? error?.message ?? 'Ukjend feil';
        } finally {
            this.loading = false;
        }
    }

    handleRefresh() {
        this.load();
    }

    get jobsUnavailable() {
        return this.monitor && !this.monitor.jobsAvailable;
    }

    get logsUnavailable() {
        return this.monitor && !this.monitor.logsAvailable;
    }

    get showJobs() {
        return this.monitor?.jobsAvailable && this.jobs.length > 0;
    }

    get noJobs() {
        return this.monitor?.jobsAvailable && this.jobs.length === 0;
    }

    get showSources() {
        return this.monitor?.logsAvailable && this.sources.length > 0;
    }

    get noSources() {
        return this.monitor?.logsAvailable && this.sources.length === 0;
    }
}
