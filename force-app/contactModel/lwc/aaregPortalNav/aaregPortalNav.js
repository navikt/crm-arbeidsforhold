import { LightningElement, wire } from 'lwc';
import { NavigationMixin, CurrentPageReference } from 'lightning/navigation';
import basePath from '@salesforce/community/basePath';
import getPortal from '@salesforce/apex/AAREG_EntryPortalController.getPortal';
import { ROLES, buildTrail, clearContext, readContext, rememberContext } from 'c/aaregPortalContext';

const formatNumber = (value) => (value ?? '').replace(/^(\d{3})(\d{3})(\d{3})$/, '$1 $2 $3');

export default class AaregPortalNav extends NavigationMixin(LightningElement) {
    enabled = false;
    organization;
    context = {};
    trail = [];

    async connectedCallback() {
        try {
            const portal = await getPortal();
            this.enabled = Boolean(portal?.enabled);
            this.organization = portal?.organization ?? undefined;
        } catch (error) {
            this.enabled = false;
        }
        this.alignWithServer();
        this.refresh();
    }

    // The sub-pages act for the organization stored on the server, so the trail and context bar follow it.
    alignWithServer() {
        const context = readContext();
        const number = this.organization?.organizationNumber;
        if (this.enabled && number && ROLES[context.roleKey] && context.roleKey !== 'Private') {
            rememberContext({ organizationNumber: number });
        }
    }

    // Aura community navigation does not reload the page, so the trail is rebuilt on every page change.
    @wire(CurrentPageReference)
    setPageReference() {
        this.refresh();
    }

    refresh() {
        this.context = readContext();
        this.trail = buildTrail(window.location.pathname, basePath, this.context);
    }

    get visible() {
        return this.enabled && this.trail.length > 1;
    }

    get role() {
        return ROLES[this.context.roleKey];
    }

    get onRolePage() {
        return this.trail.length === 2 && this.trail[1].pageName === this.role?.pageName;
    }

    get showContext() {
        return Boolean(this.role) && !this.onRolePage;
    }

    get isPrivate() {
        return this.context.roleKey === 'Private';
    }

    get organizationChosen() {
        return Boolean(this.organization?.organizationNumber);
    }

    get organizationName() {
        const chosenName =
            this.context.organizationNumber === this.organization?.organizationNumber
                ? this.context.organizationName
                : undefined;
        return chosenName || this.organization?.name || 'Virksomhet';
    }

    get organizationNumber() {
        return formatNumber(this.organization?.organizationNumber);
    }

    get contextIcon() {
        return this.isPrivate ? 'Person' : 'Buildings3';
    }

    get roleHref() {
        const query = this.organizationChosen ? `?org=${this.organization.organizationNumber}` : '';
        return `${basePath}/${this.role?.path ?? ''}${query}`;
    }

    get homeHref() {
        return `${basePath}/`;
    }

    handleChangeOrganization(event) {
        if (event.ctrlKey || event.metaKey || event.shiftKey) {
            return;
        }
        event.preventDefault();
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: { name: this.role.pageName },
            state: this.organizationChosen ? { org: this.organization.organizationNumber } : {}
        });
    }

    handleChangeRole(event) {
        if (event.ctrlKey || event.metaKey || event.shiftKey) {
            return;
        }
        event.preventDefault();
        clearContext();
        this[NavigationMixin.Navigate]({ type: 'comm__namedPage', attributes: { name: 'Home' }, state: {} });
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
