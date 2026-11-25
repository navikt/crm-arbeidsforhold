import { LightningElement } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getLaunchpad from '@salesforce/apex/AAREG_AdminNavigationController.getLaunchpad';

const pageReference = (item) => {
    switch (item.kind) {
        case 'object':
            return {
                type: 'standard__objectPage',
                attributes: { objectApiName: item.target, actionName: item.target === 'Report' ? 'home' : 'list' }
            };
        case 'navItem':
            return { type: 'standard__navItemPage', attributes: { apiName: item.target } };
        case 'app':
            return { type: 'standard__app', attributes: { appTarget: `c__${item.target}` } };
        case 'dashboard':
            return {
                type: 'standard__recordPage',
                attributes: { recordId: item.target, objectApiName: 'Dashboard', actionName: 'view' }
            };
        default:
            return { type: 'standard__webPage', attributes: { url: item.target } };
    }
};

export default class AaregAdminLaunchpad extends NavigationMixin(LightningElement) {
    groups = [];
    searchTerm = '';
    error;
    loading = true;

    connectedCallback() {
        this.load();
    }

    async load() {
        this.loading = true;
        this.error = undefined;
        try {
            this.groups = (await getLaunchpad()) ?? [];
        } catch (error) {
            this.error = error?.body?.message ?? error?.message ?? 'Ukjend feil';
        } finally {
            this.loading = false;
        }
    }

    get visibleGroups() {
        const term = this.searchTerm.trim().toLowerCase();
        return this.groups
            .map((group) => ({
                ...group,
                items: group.items
                    .filter(
                        (item) =>
                            !term ||
                            `${item.label} ${item.description ?? ''} ${group.label}`.toLowerCase().includes(term)
                    )
                    .map((item) => ({
                        ...item,
                        disabled: !item.available,
                        title: item.available ? item.description : item.reason,
                        itemClass: item.available ? 'tile' : 'tile tile_unavailable'
                    }))
            }))
            .filter((group) => group.items.length > 0);
    }

    get hasResults() {
        return this.visibleGroups.length > 0;
    }

    get showEmpty() {
        return !this.loading && !this.error && !this.hasResults;
    }

    handleSearch(event) {
        this.searchTerm = event.target.value ?? '';
    }

    handleOpen(event) {
        const key = event.currentTarget.dataset.key;
        const item = this.groups.flatMap((group) => group.items).find((candidate) => candidate.key === key);
        if (item?.available) {
            this[NavigationMixin.Navigate](pageReference(item));
        }
    }
}
