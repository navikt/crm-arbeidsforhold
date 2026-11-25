import { LightningElement } from 'lwc';
import getCatalog from '@salesforce/apex/AAREG_AdminPermissionController.getCatalog';

const ALL = 'all';

export default class AaregAdminPermissionCatalog extends LightningElement {
    entries = [];
    audience = ALL;
    searchTerm = '';
    selectedName;
    error;
    loading = true;

    connectedCallback() {
        this.load();
    }

    async load() {
        this.loading = true;
        this.error = undefined;
        try {
            this.entries = (await getCatalog()) ?? [];
        } catch (error) {
            this.error = error?.body?.message ?? error?.message ?? 'Ukjend feil';
        } finally {
            this.loading = false;
        }
    }

    get audienceOptions() {
        const labels = [...new Set(this.entries.map((entry) => entry.audienceLabel))];
        return [{ label: 'Alle målgrupper', value: ALL }, ...labels.map((label) => ({ label, value: label }))];
    }

    get filteredEntries() {
        const term = this.searchTerm.trim().toLowerCase();
        return this.entries
            .filter((entry) => this.audience === ALL || entry.audienceLabel === this.audience)
            .filter(
                (entry) =>
                    !term || `${entry.apiName} ${entry.label} ${entry.explanation ?? ''}`.toLowerCase().includes(term)
            )
            .map((entry) => ({
                ...entry,
                rowClass: entry.apiName === this.selectedName ? 'row row_selected' : 'row',
                badgeClass: entry.documented ? 'slds-badge' : 'slds-badge slds-theme_warning',
                assigneeText: `${entry.directAssignees} aktive`
            }));
    }

    get hasEntries() {
        return this.filteredEntries.length > 0;
    }

    get showEmpty() {
        return !this.loading && !this.error && !this.hasEntries;
    }

    get selected() {
        const entry = this.entries.find((candidate) => candidate.apiName === this.selectedName);
        if (!entry) {
            return undefined;
        }
        return {
            ...entry,
            hasRecommended: entry.recommendedWith?.length > 0,
            recommendedText: (entry.recommendedWith ?? []).join(', '),
            hasMembers: entry.members?.length > 0,
            membersText: (entry.members ?? []).join(', '),
            hasMemberOf: entry.memberOf?.length > 0,
            memberOfText: (entry.memberOf ?? []).join(', '),
            appsText: entry.apps?.length ? [...new Set(entry.apps)].join(', ') : 'Ingen',
            customPermissionsText: entry.customPermissions?.length
                ? [...new Set(entry.customPermissions)].join(', ')
                : 'Ingen',
            hasObjects: entry.objects?.length > 0,
            objects: (entry.objects ?? []).map((grant, index) => ({ ...grant, key: `${grant.apiName}-${index}` }))
        };
    }

    handleAudience(event) {
        this.audience = event.detail.value;
    }

    handleSearch(event) {
        this.searchTerm = event.target.value ?? '';
    }

    handleSelect(event) {
        this.selectedName = event.currentTarget.dataset.name;
    }

    handleClose() {
        this.selectedName = undefined;
    }
}
