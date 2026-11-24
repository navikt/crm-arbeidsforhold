import { LightningElement, api } from 'lwc';
import getOrganizations from '@salesforce/apex/AAREG_ContactModelPortalController.getOrganizations';
import selectApplicationOrganization from '@salesforce/apex/AAREG_ContactModelPortalController.selectApplicationOrganization';

export const ROLES = [
    {
        value: 'EMPLOYER',
        label: 'Som arbeidsgiver',
        description: 'Du søkjer på vegner av verksemda du representerer.'
    },
    {
        value: 'PARTNER',
        label: 'Som samarbeidspartner',
        description: 'Du søkjer på vegner av ein organisasjon som skal bruke opplysningar frå Aa-registeret.'
    },
    {
        value: 'PRIVATE',
        label: 'Som privatperson',
        description: 'Du handlar på eigne vegner.'
    }
];

const message = (error, fallback) => error?.body?.message ?? fallback;

export default class AaregApplicationStart extends LightningElement {
    @api profileUrl = 'min-profil';

    role;
    organizations = [];
    organizationsLoaded = false;
    loadingOrganizations = false;
    organizationsError;
    selection;
    submitting = false;
    error;

    get roles() {
        return ROLES.map((role) => ({
            ...role,
            id: `role-${role.value}`,
            descriptionId: `role-${role.value}-description`,
            checked: role.value === this.role
        }));
    }

    get isPrivate() {
        return this.role === 'PRIVATE';
    }

    get needsOrganization() {
        return Boolean(this.role) && !this.isPrivate;
    }

    get showSelector() {
        return this.needsOrganization && this.organizationsLoaded && !this.organizationsError;
    }

    get selectedValue() {
        return this.selection?.organizationNumber;
    }

    get continueDisabled() {
        return !this.selection || this.submitting;
    }

    async handleRole(event) {
        this.role = event.target.value;
        this.error = undefined;
        if (this.needsOrganization && !this.organizationsLoaded && !this.loadingOrganizations) {
            await this.loadOrganizations();
        }
    }

    async loadOrganizations() {
        this.loadingOrganizations = true;
        this.organizationsError = undefined;
        try {
            this.organizations = await getOrganizations();
            this.organizationsLoaded = true;
        } catch (error) {
            this.organizationsError = message(error, 'Kunne ikkje hente organisasjonane dine frå Altinn.');
        } finally {
            this.loadingOrganizations = false;
        }
    }

    handleSelect(event) {
        this.selection = event.detail?.isSelf ? undefined : event.detail;
        this.error = undefined;
    }

    async handleContinue(event) {
        event.preventDefault();
        if (!this.selection) {
            return;
        }
        this.submitting = true;
        this.error = undefined;
        try {
            const organizationNumber = await selectApplicationOrganization({
                organizationNumber: this.selection.organizationNumber
            });
            this.dispatchEvent(
                new CustomEvent('organizationselected', {
                    detail: { organizationNumber, name: this.selection.name, role: this.role }
                })
            );
        } catch (error) {
            this.error = message(error, 'Kunne ikkje velje organisasjonen.');
        } finally {
            this.submitting = false;
        }
    }
}
