import { LightningElement, wire } from 'lwc';
import { NavigationMixin, CurrentPageReference } from 'lightning/navigation';
import getPortal from '@salesforce/apex/AAREG_EntryPortalController.getPortal';
import getSettings from '@salesforce/apex/AAREG_ContactModelPortalController.getSettings';
import basePath from '@salesforce/community/basePath';
import { clearContext, hrefFor } from 'c/aaregPortalContext';

export const ROLE_TEXT = {
    Employer: {
        title: 'Arbeidsgiver',
        icon: 'Buildings3',
        description: 'Du representerer en virksomhet og vil søke om tilgang, se avtaler eller kontakte brukerstøtte.'
    },
    Partner: {
        title: 'Samarbeidspartner / fullmektig',
        icon: 'Handshake',
        description: 'Du handler på vegne av en virksomhet som samarbeidspartner eller fullmektig.'
    },
    Private: {
        title: 'Privatperson / arbeidstaker',
        icon: 'Person',
        description: 'Du har spørsmål om dine egne opplysninger i Aa-registeret.'
    }
};

export const MESSAGES = {
    'no-access': 'Du har ikke tilgang til denne siden. Velg en annen rolle.',
    'role-not-active': 'Tjenesten er ikke tilgjengelig akkurat nå.'
};

const DIRECT_LINK_ROLES = { employer: 'Employer', agent: 'Partner', 'private-person': 'Private' };
const ORGANIZATION_NUMBER = /^\d{9}$/;

export default class AaregEntryPortal extends NavigationMixin(LightningElement) {
    loaded = false;
    enabled = false;
    roles = [];
    showProfile = false;
    message;
    pageState = {};

    @wire(CurrentPageReference)
    setPageReference(pageReference) {
        this.pageState = pageReference?.state ?? {};
        this.message = MESSAGES[this.pageState.c__message];
    }

    async connectedCallback() {
        try {
            const portal = await getPortal();
            this.enabled = Boolean(portal?.enabled);
            this.roles = (portal?.roles ?? [])
                .filter((role) => ROLE_TEXT[role.roleKey])
                .map((role) => ({ ...role, ...ROLE_TEXT[role.roleKey], href: hrefFor(basePath, role.pageApiName) }));
        } catch (error) {
            this.enabled = false;
        }
        if (this.enabled && this.followDirectLink()) {
            return;
        }
        if (this.enabled) {
            clearContext();
            await this.loadProfileSetting();
        }
        this.loaded = true;
    }

    async loadProfileSetting() {
        try {
            const settings = await getSettings();
            this.showProfile = Boolean(settings?.profile);
        } catch (error) {
            this.showProfile = false;
        }
    }

    followDirectLink() {
        const roleKey = DIRECT_LINK_ROLES[this.pageState.type];
        const role = this.roles.find((candidate) => candidate.roleKey === roleKey);
        if (!role) {
            return false;
        }
        const state = {};
        if (role.contextType === 'Organization' && ORGANIZATION_NUMBER.test(this.pageState.org ?? '')) {
            state.org = this.pageState.org;
        }
        this.navigateTo(role.pageApiName, state);
        return true;
    }

    get showPortal() {
        return this.loaded && this.enabled;
    }

    get showCurrentHome() {
        return this.loaded && !this.enabled;
    }

    get hasRoles() {
        return this.roles.length > 0;
    }

    handleRole(event) {
        if (event.ctrlKey || event.metaKey || event.shiftKey) {
            return;
        }
        event.preventDefault();
        const role = this.roles.find((candidate) => candidate.roleKey === event.currentTarget.dataset.role);
        if (role) {
            this.navigateTo(role.pageApiName, {});
        }
    }

    navigateTo(pageApiName, state) {
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: { name: pageApiName },
            state
        });
    }
}
