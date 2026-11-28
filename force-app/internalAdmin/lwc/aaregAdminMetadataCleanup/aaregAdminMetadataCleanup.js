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
    Scheduled_Deletion: 'Planlagt sletting'
};
const ARCHIVED_CLASS = 'slds-badge slds-badge_lightest';
const REAPPEARED_LABEL = 'Finst igjen – må ryddast';
const REAPPEARED_CLASS = 'slds-badge slds-theme_error';

export default class AaregAdminMetadataCleanup extends LightningElement {
    overview;
    error;
    loading = true;
    stateFilter = ALL;
    typeFilter = ALL;
    searchTerm = '';
    showArchived = false;
    exportText;

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

    get environments() {
        return this.overview?.environments ?? [];
    }

    get currentEnvironmentLabel() {
        const current = this.environments.find((environment) => environment.name === this.overview?.currentEnvironment);
        return current?.label ?? this.overview?.currentEnvironment;
    }

    get environmentDescription() {
        const overview = this.overview ?? {};
        if (overview.currentEnvironment) {
            return `${this.currentEnvironmentLabel}. Komponentar som ikkje finst her, kan registrerast som verifisert sletta.`;
        }
        if (overview.orgKind === 'Scratch') {
            return 'Scratch-org. Blir ikkje registrert som miljø, så sletting kan ikkje verifiserast herifrå.';
        }
        if (overview.orgKind === 'Sandbox') {
            return (
                `Sandkasse «${overview.sandboxName ?? 'ukjend'}» er ikkje kopla til eit miljø. ` +
                'Legg namnet inn i Sandbox_Name__c på rett post i AAREG_Cleanup_Environment__mdt.'
            );
        }
        return 'Produksjon er ikkje registrert som miljø i AAREG_Cleanup_Environment__mdt.';
    }

    get requiredEnvironments() {
        return this.environments
            .filter((environment) => environment.requiredForArchive)
            .map((environment) => environment.label)
            .join(' og ');
    }

    get archivedCount() {
        return this.overview?.archivedCount ?? 0;
    }

    get readyToVerify() {
        return (this.overview?.items ?? []).filter((item) => item.readyToVerify && !item.archived);
    }

    get canExport() {
        return Boolean(this.overview?.currentEnvironment) && this.readyToVerify.length > 0;
    }

    get exportLabel() {
        return `Lag verifikasjon for ${this.currentEnvironmentLabel} (${this.readyToVerify.length})`;
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
            .filter((item) => this.showArchived || !item.archived)
            .map((item) => ({
                ...item,
                stateLabel: this.stateLabel(item),
                stateClass: this.stateClass(item),
                verificationList: this.verificationList(item),
                stageLabel: STAGE_LABEL[item.stage] ?? item.stage,
                note: [item.reason, item.replacement ? `Erstatta av ${item.replacement}.` : null, item.guidance]
                    .filter(Boolean)
                    .join(' ')
            }))
            .sort(
                (left, right) =>
                    Number(Boolean(right.reappeared)) - Number(Boolean(left.reappeared)) ||
                    Number(Boolean(left.archived)) - Number(Boolean(right.archived)) ||
                    STATE_ORDER[left.state] - STATE_ORDER[right.state] ||
                    left.type.localeCompare(right.type) ||
                    left.name.localeCompare(right.name)
            );
    }

    stateLabel(item) {
        if (item.reappeared) {
            return REAPPEARED_LABEL;
        }
        return item.archived ? 'Arkivert' : (STATE_LABEL[item.state] ?? item.state);
    }

    stateClass(item) {
        if (item.reappeared) {
            return REAPPEARED_CLASS;
        }
        return item.archived ? ARCHIVED_CLASS : (STATE_CLASS[item.state] ?? STATE_CLASS.manual);
    }

    verificationList(item) {
        const byEnvironment = new Map((item.verifications ?? []).map((entry) => [entry.environment, entry]));
        return this.environments
            .filter((environment) => environment.requiredForArchive || byEnvironment.has(environment.name))
            .map((environment) => {
                const verification = byEnvironment.get(environment.name);
                return {
                    key: `${item.key}:${environment.name}`,
                    text: `${environment.label}: ${verification?.verifiedOn ?? '–'}`,
                    evidenceUrl: verification?.evidenceUrl,
                    className: verification ? 'slds-text-color_success' : 'slds-text-color_weak'
                };
            });
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

    handleArchivedToggle(event) {
        this.showArchived = Boolean(event.target.checked);
    }

    async handleExport() {
        this.exportText = JSON.stringify(
            {
                environment: this.overview.currentEnvironment,
                sandboxName: this.overview.sandboxName ?? null,
                checkedOn: new Date().toISOString().slice(0, 10),
                components: this.readyToVerify.map(({ type, name }) => ({ type, name }))
            },
            null,
            2
        );
        try {
            await navigator.clipboard?.writeText(this.exportText);
        } catch {
            // Kopiering kan vere blokkert; teksten står likevel i feltet.
        }
    }

    handleRefresh() {
        this.exportText = undefined;
        this.load();
    }
}
