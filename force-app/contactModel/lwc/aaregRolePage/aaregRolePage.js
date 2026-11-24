import { LightningElement, api, wire } from 'lwc';
import { NavigationMixin, CurrentPageReference } from 'lightning/navigation';
import decide from '@salesforce/apex/AAREG_EntryPortalController.decide';
import getOrganizations from '@salesforce/apex/AAREG_EntryPortalController.getOrganizations';

export const ROLE_TITLES = {
    Employer: 'Arbeidsgiver',
    Partner: 'Samarbeidspartner / fullmektig',
    Private: 'Privatperson / arbeidstaker'
};

const SELECTOR_LABELS = {
    Partner: 'Hvilken virksomhet handler du for?'
};

export const CAPABILITY_PANELS = {
    APPLICATION: [
        {
            key: 'new-application',
            title: 'Ny søknad',
            subTitle: 'Her kan du opprette en ny søknad.',
            page: 'custom_ny_soknad_aa_registret__c'
        },
        {
            key: 'my-applications',
            title: 'Mine søknader',
            subTitle: 'Oversikt over innsendte søknader, også utkast og avslåtte eller henlagte søknader.',
            page: 'custom_mine_soknader__c'
        }
    ],
    AGREEMENTS: [
        {
            key: 'agreements',
            title: 'Mine avtaler',
            subTitle: 'Godkjente avtaler, nedlasting av vedtak, kontaktpersoner og avslutning av avtale.',
            page: 'Mine_Avtaler__c'
        }
    ],
    SUPPORT: [
        {
            key: 'support',
            title: 'Brukerstøtte vedrørende Aa-registeret',
            subTitle: 'Har du spørsmål knyttet til Aa-registeret kan du kontakte oss ved å sende en melding.',
            page: 'Ny_Melding__c'
        }
    ],
    MESSAGES: [
        {
            key: 'messages',
            title: 'Mine meldinger',
            subTitle: 'Her finner du svar på henvendelser som du har sendt vedrørende Aa-registeret.',
            page: 'Mine_Meldinger__c'
        }
    ]
};

const PROFILE_PANEL = {
    key: 'profile',
    title: 'Min profil',
    subTitle: 'Her ser og endrer du e-postadressene dine: den private og den du bruker for hver virksomhet.',
    page: 'Min_Profil__c'
};

const PANEL_COLUMNS = [
    { key: 'services', label: 'Søknad og avtaler', capabilities: ['APPLICATION', 'AGREEMENTS'] },
    { key: 'support', label: 'Brukerstøtte og meldinger', capabilities: ['SUPPORT', 'MESSAGES'] }
];
const ORGANIZATION_NUMBER = /^\d{9}$/;
const REDIRECT_REASONS = ['role-not-active', 'unknown-role'];

export default class AaregRolePage extends NavigationMixin(LightningElement) {
    @api roleKey;

    state = 'loading';
    decision;
    organizations = [];
    organizationsError;
    loadingOrganizations = false;
    message;
    requestedOrganization;
    selectedOrganization;
    initialised = false;

    @wire(CurrentPageReference)
    setPageReference(pageReference) {
        const org = pageReference?.state?.org;
        this.requestedOrganization = ORGANIZATION_NUMBER.test(org ?? '') ? org : undefined;
        if (!this.initialised) {
            this.initialised = true;
            this.evaluate(this.requestedOrganization, true);
        }
    }

    get roleTitle() {
        return ROLE_TITLES[this.roleKey] ?? 'Aa-registeret';
    }

    get isLoading() {
        return this.state === 'loading';
    }

    get isGranted() {
        return this.state === 'granted';
    }

    get isSelecting() {
        return this.state === 'select';
    }

    get isError() {
        return this.state === 'error';
    }

    get isOrganizationRole() {
        return this.decision?.contextType === 'Organization';
    }

    get isPrivate() {
        return this.decision?.contextType === 'Person';
    }

    get selectorLabel() {
        return SELECTOR_LABELS[this.roleKey] ?? 'Velg virksomhet';
    }

    get showSelector() {
        return this.isOrganizationRole || this.state === 'select';
    }

    get showSelectHint() {
        return this.state === 'select' && !this.selectedOrganization && !this.message;
    }

    get panelColumns() {
        const capabilities = new Set(this.decision?.capabilities ?? []);
        const columns = PANEL_COLUMNS.map((column) => ({
            key: column.key,
            label: column.label,
            panels: column.capabilities
                .filter((capability) => capabilities.has(capability))
                .flatMap((capability) => CAPABILITY_PANELS[capability])
        }));
        if (this.isPrivate) {
            columns[1].panels.push(PROFILE_PANEL);
        }
        return columns.filter((column) => column.panels.length > 0);
    }

    get showPrivateOutlook() {
        return this.isPrivate && (this.decision?.capabilities ?? []).length === 0;
    }

    async evaluate(organizationNumber, fromLink) {
        this.state = 'loading';
        this.message = undefined;
        let decision;
        try {
            decision = await decide({ roleKey: this.roleKey, organizationNumber });
        } catch (error) {
            decision = { outcome: 'TECHNICAL_ERROR' };
        }
        this.decision = { ...decision, contextType: decision.contextType ?? this.decision?.contextType };
        if (decision.outcome === 'GRANTED') {
            this.state = 'granted';
            this.selectedOrganization = decision.organizationNumber ?? this.selectedOrganization;
            if (this.isOrganizationRole && this.organizations.length === 0) {
                this.loadOrganizations();
            }
            return;
        }
        if (decision.outcome === 'TECHNICAL_ERROR') {
            this.state = 'error';
            return;
        }
        if (REDIRECT_REASONS.includes(decision.reason)) {
            this.goHome(decision.reason);
            return;
        }
        if (decision.reason === 'invalid-context' && decision.contextType === 'Organization') {
            await this.openSelector();
            return;
        }
        if (fromLink) {
            this.goHome('no-access');
            return;
        }
        this.message = 'Du har ikke tilgang til denne tjenesten for virksomheten du valgte. Velg en annen virksomhet.';
        this.state = 'select';
    }

    async openSelector() {
        this.selectedOrganization = undefined;
        this.state = 'select';
        if (this.organizations.length === 0) {
            await this.loadOrganizations();
        }
    }

    async loadOrganizations() {
        this.loadingOrganizations = true;
        this.organizationsError = undefined;
        try {
            this.organizations = await getOrganizations({ roleKey: this.roleKey });
        } catch (error) {
            this.organizationsError =
                error?.body?.message ?? 'Kunne ikke hente virksomhetene dine fra Altinn. Prøv igjen senere.';
        } finally {
            this.loadingOrganizations = false;
        }
    }

    async handleRefresh() {
        this.organizations = [];
        await this.loadOrganizations();
    }

    async handleSelect(event) {
        this.selectedOrganization = event.detail?.isSelf ? undefined : event.detail?.organizationNumber;
        this.message = undefined;
        if (this.selectedOrganization) {
            await this.evaluate(this.selectedOrganization, false);
        }
    }

    handleRetry() {
        this.evaluate(this.decision?.organizationNumber ?? this.requestedOrganization, false);
    }

    handleChangeRole(event) {
        event.preventDefault();
        this.goHome();
    }

    goHome(message) {
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: { name: 'Home' },
            state: message ? { c__message: message } : {}
        });
    }
}
