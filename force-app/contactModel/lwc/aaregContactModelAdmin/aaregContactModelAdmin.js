import { LightningElement } from 'lwc';
import getOverview from '@salesforce/apex/AAREG_ContactModelAdminController.getOverview';
import startRun from '@salesforce/apex/AAREG_ContactModelAdminController.startRun';
import setUpPrimaryAccount from '@salesforce/apex/AAREG_ContactModelAdminController.setUpPrimaryAccount';

const POLL_MS = 5000;
const ACTIVE = ['Queued', 'Running'];

const MODE_TEXT = {
    PLAN: {
        label: 'Planlegg (PLAN)',
        confirm: 'PLAN klassifiserer alle innsende søknader i klasse A–E og endrar ingenting.'
    },
    APPLY: {
        label: 'Migrer klasse A (APPLY)',
        confirm:
            'APPLY lagrar backup og koplar berre klasse A til domenekontakt, organisasjon og kontaktpunkt. Andre klassar blir ikkje endra.'
    },
    VERIFY: {
        label: 'Verifiser (VERIFY)',
        confirm: 'VERIFY stemmer av den valde APPLY-køyringa mot dataa og rapporterer avvik. Ingenting blir endra.'
    },
    ROLLBACK: {
        label: 'Rull tilbake (ROLLBACK)',
        confirm:
            'ROLLBACK slettar det den valde APPLY-køyringa oppretta og set tilbake verdiane frå backup. Dette kan ikkje angrast.'
    }
};

const RUN_COLUMNS = [
    { label: 'Køyring', fieldName: 'url', type: 'url', typeAttributes: { label: { fieldName: 'Name' } } },
    { label: 'Modus', fieldName: 'Mode__c' },
    { label: 'Status', fieldName: 'Status__c' },
    { label: 'Kjelde', fieldName: 'sourceName' },
    { label: 'Rader', fieldName: 'Total__c', type: 'number' },
    { label: 'A', fieldName: 'Class_A__c', type: 'number' },
    { label: 'B–E', fieldName: 'otherClasses', type: 'number' },
    { label: 'Kopla', fieldName: 'Linked__c', type: 'number' },
    { label: 'Avvik/feil', fieldName: 'problems', type: 'number' },
    { label: 'Samandrag', fieldName: 'Summary__c', wrapText: true }
];

const message = (error) => error?.body?.message ?? error?.message ?? 'Ukjend feil';

export default class AaregContactModelAdmin extends LightningElement {
    overview;
    error;
    notice;
    loading = true;
    busy = false;
    pendingMode;
    selectedApplyRunId;
    runColumns = RUN_COLUMNS;
    pollHandle;

    connectedCallback() {
        this.load();
    }

    disconnectedCallback() {
        this.stopPolling();
    }

    async load() {
        this.error = undefined;
        try {
            this.overview = await getOverview();
            this.schedulePolling();
        } catch (error) {
            this.error = message(error);
        } finally {
            this.loading = false;
        }
    }

    schedulePolling() {
        this.stopPolling();
        if (this.hasActiveRun) {
            // eslint-disable-next-line @lwc/lwc/no-async-operation
            this.pollHandle = setTimeout(() => this.load(), POLL_MS);
        }
    }

    stopPolling() {
        if (this.pollHandle) {
            clearTimeout(this.pollHandle);
            this.pollHandle = undefined;
        }
    }

    get hasActiveRun() {
        return (this.overview?.runs ?? []).some((run) => ACTIVE.includes(run.Status__c));
    }

    get flags() {
        return (this.overview?.flags ?? []).map((flag) => ({
            ...flag,
            stateLabel: !flag.exists
                ? 'Manglar'
                : flag.activeForCurrentUser
                  ? 'På for deg'
                  : flag.enabledInOrg
                    ? 'På (krev løyve)'
                    : 'Av',
            badgeClass: flag.activeForCurrentUser
                ? 'slds-badge slds-theme_success'
                : flag.enabledInOrg
                  ? 'slds-badge slds-theme_warning'
                  : 'slds-badge',
            permissionText: flag.requiredPermission || 'Alle'
        }));
    }

    get metrics() {
        return this.overview?.metrics ?? [];
    }

    get runs() {
        return (this.overview?.runs ?? []).map((run) => ({
            ...run,
            url: `/${run.Id}`,
            sourceName: run.Source_Run__r?.Name,
            otherClasses: (run.Class_B__c ?? 0) + (run.Class_C__c ?? 0) + (run.Class_D__c ?? 0) + (run.Class_E__c ?? 0),
            problems: (run.Deviations__c ?? 0) + (run.Failed__c ?? 0)
        }));
    }

    get hasRuns() {
        return this.runs.length > 0;
    }

    get applyRunOptions() {
        return this.runs
            .filter((run) => run.Mode__c === 'APPLY' && run.Status__c === 'Completed')
            .map((run) => ({ label: `${run.Name} (kopla ${run.Linked__c ?? 0})`, value: run.Id }));
    }

    get noApplyRuns() {
        return this.applyRunOptions.length === 0;
    }

    get applyPlaceholder() {
        return this.noApplyRuns ? 'Ingen fullførte APPLY-køyringar' : 'Vel APPLY-køyring';
    }

    get canMigrate() {
        return this.overview?.canMigrate === true;
    }

    get primaryAccountMissing() {
        return this.overview && this.overview.primaryAccountReady !== true;
    }

    get actionsDisabled() {
        return !this.canMigrate || this.busy || this.hasActiveRun;
    }

    get applyDisabled() {
        return this.actionsDisabled || this.primaryAccountMissing;
    }

    get followUpDisabled() {
        return this.actionsDisabled || !this.selectedApplyRunId;
    }

    get setupDisabled() {
        return !this.canMigrate || this.busy;
    }

    get pendingText() {
        return this.pendingMode ? MODE_TEXT[this.pendingMode].confirm : '';
    }

    get pendingLabel() {
        return this.pendingMode ? MODE_TEXT[this.pendingMode].label : '';
    }

    get pendingIsDestructive() {
        return this.pendingMode === 'ROLLBACK';
    }

    get confirmVariant() {
        return this.pendingIsDestructive ? 'destructive' : 'brand';
    }

    handleRefresh() {
        this.notice = undefined;
        this.load();
    }

    handleApplyRunChange(event) {
        this.selectedApplyRunId = event.detail.value;
    }

    handleRequest(event) {
        this.notice = undefined;
        this.pendingMode = event.currentTarget.dataset.mode;
    }

    handleCancel() {
        this.pendingMode = undefined;
    }

    async handleConfirm() {
        const mode = this.pendingMode;
        this.pendingMode = undefined;
        this.busy = true;
        this.error = undefined;
        try {
            const needsSource = mode === 'VERIFY' || mode === 'ROLLBACK';
            await startRun({ mode, sourceRunId: needsSource ? this.selectedApplyRunId : null });
            this.notice = `${MODE_TEXT[mode].label} er starta. Sida oppdaterer seg sjølv til køyringa er ferdig.`;
            await this.load();
        } catch (error) {
            this.error = message(error);
        } finally {
            this.busy = false;
        }
    }

    async handleSetUp() {
        this.busy = true;
        this.error = undefined;
        try {
            await setUpPrimaryAccount();
            this.notice = 'Primærkontoen er klar.';
            await this.load();
        } catch (error) {
            this.error = message(error);
        } finally {
            this.busy = false;
        }
    }
}
