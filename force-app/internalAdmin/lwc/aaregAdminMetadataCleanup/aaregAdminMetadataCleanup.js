import { LightningElement } from 'lwc';
import getOverview from '@salesforce/apex/AAREG_AdminMetadataCleanupController.getOverview';

const ALL = 'all';
const STATE_ORDER = { present: 0, manual: 1, absent: 2 };
const STATE_LABEL = { present: 'Finst – må ryddast', manual: 'Sjekk manuelt', absent: 'Finst ikkje' };
const STATE_CLASS = {
    present: 'slds-badge slds-theme_warning',
    manual: 'slds-badge',
    absent: 'slds-badge slds-theme_success'
};
const STAGE_LABEL = {
    Removed: 'Fjerna frå repoet',
    Deprecated: 'Utfasa',
    Scheduled_Deletion: 'Planlagt sletting',
    Deleted_Verified: 'Sletting verifisert'
};

export default class AaregAdminMetadataCleanup extends LightningElement {
    overview;
    error;
    loading = true;
    stateFilter = ALL;
    typeFilter = ALL;
    searchTerm = '';

    connectedCallback() {
        this.load();
    }

    async load() {
        this.loading = true;
        this.error = undefined;
        try {
            this.overview = await getOverview();
        } catch (error) {
            this.error = error?.body?.message ?? error?.message ?? 'Ukjend feil';
        } finally {
            this.loading = false;
        }
    }

    get hasOverview() {
        return Boolean(this.overview);
    }

    get orgKind() {
        return this.overview?.isSandbox ? 'Sandbox eller scratch' : 'Produksjon';
    }

    get generatedOn() {
        return this.overview?.generatedAt?.slice(0, 10);
    }

    get stateOptions() {
        return [
            { label: 'Alle', value: ALL },
            { label: STATE_LABEL.present, value: 'present' },
            { label: STATE_LABEL.manual, value: 'manual' },
            { label: STATE_LABEL.absent, value: 'absent' }
        ];
    }

    get typeOptions() {
        const types = [...new Set((this.overview?.items ?? []).map((item) => item.type))].sort();
        return [{ label: 'Alle typar', value: ALL }, ...types.map((type) => ({ label: type, value: type }))];
    }

    get orphanCount() {
        return this.overview?.orphans?.length ?? 0;
    }

    get rows() {
        const term = this.searchTerm.trim().toLowerCase();
        return (this.overview?.items ?? [])
            .filter((item) => this.stateFilter === ALL || item.state === this.stateFilter)
            .filter((item) => this.typeFilter === ALL || item.type === this.typeFilter)
            .filter((item) => !term || item.name.toLowerCase().includes(term))
            .map((item) => ({
                ...item,
                stateLabel: STATE_LABEL[item.state] ?? item.state,
                stateClass: STATE_CLASS[item.state] ?? STATE_CLASS.manual,
                stageLabel: STAGE_LABEL[item.stage] ?? item.stage,
                note: [item.reason, item.replacement ? `Erstatta av ${item.replacement}.` : null, item.guidance]
                    .filter(Boolean)
                    .join(' ')
            }))
            .sort(
                (left, right) =>
                    STATE_ORDER[left.state] - STATE_ORDER[right.state] ||
                    left.type.localeCompare(right.type) ||
                    left.name.localeCompare(right.name)
            );
    }

    get hasRows() {
        return this.rows.length > 0;
    }

    get rowSummary() {
        return `Viser ${this.rows.length} av ${this.overview?.items?.length ?? 0} komponentar.`;
    }

    get hasOrphans() {
        return this.orphanCount > 0;
    }

    get prefixes() {
        return (this.overview?.ownedPrefixes ?? []).join(' og ');
    }

    handleStateChange(event) {
        this.stateFilter = event.detail.value;
    }

    handleTypeChange(event) {
        this.typeFilter = event.detail.value;
    }

    handleSearch(event) {
        this.searchTerm = event.target.value ?? '';
    }

    handleRefresh() {
        this.load();
    }
}
