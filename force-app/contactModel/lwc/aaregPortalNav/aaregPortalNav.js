import { LightningElement, wire } from 'lwc';
import { NavigationMixin, CurrentPageReference } from 'lightning/navigation';
import basePath from '@salesforce/community/basePath';
import getPortal from '@salesforce/apex/AAREG_EntryPortalController.getPortal';
import { buildTrail, readContext } from 'c/aaregPortalContext';

export default class AaregPortalNav extends NavigationMixin(LightningElement) {
    enabled = false;
    trail = [];

    async connectedCallback() {
        try {
            const portal = await getPortal();
            this.enabled = Boolean(portal?.enabled);
        } catch (error) {
            this.enabled = false;
        }
        this.refresh();
    }

    // Aura community navigation does not reload the page, so the trail is rebuilt on every page change.
    @wire(CurrentPageReference)
    setPageReference() {
        this.refresh();
    }

    refresh() {
        this.trail = buildTrail(window.location.pathname, basePath, readContext());
    }

    get visible() {
        return this.enabled && this.trail.length > 1;
    }

    get parent() {
        return this.trail[this.trail.length - 2];
    }

    handleClick(event) {
        const item = this.trail.find((candidate) => candidate.key === event.currentTarget.dataset.key);
        if (!item?.pageName || event.ctrlKey || event.metaKey || event.shiftKey) {
            return;
        }
        event.preventDefault();
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: { name: item.pageName },
            state: item.state
        });
    }
}
