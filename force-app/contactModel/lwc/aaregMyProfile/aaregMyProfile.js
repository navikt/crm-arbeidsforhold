import { LightningElement } from 'lwc';
import getSettings from '@salesforce/apex/AAREG_ContactModelPortalController.getSettings';
import getOrganizations from '@salesforce/apex/AAREG_ContactModelPortalController.getOrganizations';
import getProfile from '@salesforce/apex/AAREG_ContactModelPortalController.getProfile';
import saveAddress from '@salesforce/apex/AAREG_ContactModelPortalController.saveAddress';
import { readContext } from 'c/aaregPortalContext';

const message = (error, fallback) => error?.body?.message ?? fallback;

export default class AaregMyProfile extends LightningElement {
    settings;
    organizations = [];
    selection;
    profile;
    email = '';
    phone = '';
    loading = true;
    saving = false;
    error;
    organizationsError;
    saved;

    async connectedCallback() {
        try {
            this.settings = await getSettings();
            if (this.settings?.profile && this.settings?.orgSelector) {
                try {
                    this.organizations = await getOrganizations();
                } catch (error) {
                    this.organizationsError = message(error, 'Kunne ikkje hente organisasjonane dine.');
                }
            }
        } catch (error) {
            this.error = message(error, 'Kunne ikkje hente profilen.');
        } finally {
            this.loading = false;
        }
        const kept = this.enabled ? this.keptSelection() : undefined;
        if (kept) {
            await this.handleSelect({ detail: kept });
        }
    }

    // The role page has already checked this context in Altinn; getProfile checks it again.
    keptSelection() {
        const context = readContext();
        if (context.roleKey === 'Private') {
            return { organizationNumber: null, name: 'Meg selv', isSelf: true };
        }
        const organization = this.organizations.find(
            (candidate) => candidate.organizationNumber === context.organizationNumber
        );
        return organization
            ? { organizationNumber: organization.organizationNumber, name: organization.name, isSelf: false }
            : undefined;
    }

    get enabled() {
        return this.settings?.profile === true;
    }

    get disabled() {
        return !this.loading && !this.error && !this.enabled;
    }

    get selectedValue() {
        if (!this.selection) {
            return undefined;
        }
        return this.selection.isSelf ? 'SELF' : this.selection.organizationNumber;
    }

    get nothingSelected() {
        return !this.selection;
    }

    get isSelf() {
        return this.selection?.isSelf === true;
    }

    get organization() {
        return this.profile?.organization;
    }

    get organizationDenied() {
        return Boolean(this.selection && !this.isSelf && this.profile && !this.organization?.verified);
    }

    get organizationMissing() {
        return Boolean(this.organization?.verified && this.organization?.message);
    }

    get showForm() {
        if (!this.profile || !this.selection) {
            return false;
        }
        return this.isSelf || (this.organization?.verified === true && !this.organization?.message);
    }

    get contextHeading() {
        if (this.isSelf) {
            return 'Adressa di når du handlar på eigne vegner';
        }
        return `Adressa di for ${this.organization?.name ?? this.selection?.name}`;
    }

    get contextExplanation() {
        if (this.isSelf) {
            return 'Denne adressa blir berre brukt når du søkjer eller tek kontakt som deg sjølv. Ingen organisasjon ser henne.';
        }
        return 'Denne adressa blir berre brukt for denne organisasjonen. Ho endrar ikkje privatadressa di, adresser hos andre organisasjonar eller søknader som alt er sende.';
    }

    get organizationMessage() {
        return this.organization?.message;
    }

    async handleSelect(event) {
        this.selection = event.detail;
        this.profile = undefined;
        this.saved = undefined;
        this.error = undefined;
        this.loading = true;
        try {
            this.applyProfile(await getProfile({ organizationNumber: this.selection.organizationNumber }));
        } catch (error) {
            this.error = message(error, 'Kunne ikkje hente profilen.');
        } finally {
            this.loading = false;
        }
    }

    applyProfile(profile) {
        this.profile = profile;
        const source = this.isSelf
            ? { email: profile?.privateEmail, phone: profile?.privatePhone }
            : { email: profile?.organization?.email, phone: profile?.organization?.phone };
        this.email = source.email ?? '';
        this.phone = source.phone ?? '';
    }

    handleEmail(event) {
        this.email = event.target.value;
        this.saved = undefined;
    }

    handlePhone(event) {
        this.phone = event.target.value;
        this.saved = undefined;
    }

    async handleSave(event) {
        event.preventDefault();
        const emailField = this.template.querySelector('[data-id="email"]');
        if (emailField && !emailField.reportValidity()) {
            return;
        }
        this.saving = true;
        this.error = undefined;
        try {
            this.applyProfile(
                await saveAddress({
                    organizationNumber: this.selection.organizationNumber,
                    email: this.email,
                    phone: this.phone
                })
            );
            this.saved = 'Adressa er lagra. Andre adresser er ikkje endra.';
        } catch (error) {
            this.error = message(error, 'Kunne ikkje lagre adressa.');
        } finally {
            this.saving = false;
        }
    }
}
