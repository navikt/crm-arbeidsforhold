import { LightningElement, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import Id from '@salesforce/user/Id';
import setCacheValue from '@salesforce/apex/AAREG_CacheController.setCacheValue';
import getLastUsersLastUsedOrganization from '@salesforce/apex/AAREG_HomeController.getLastUsersLastUsedOrganization';
import getOrganizationsWithRoles from '@salesforce/apex/AAREG_HomeController.getOrganizationsWithRoles';
import updateLastUsedOrganization from '@salesforce/apex/AAREG_HomeController.updateLastUsedOrganization';
import checkAndShareIfAuthorized from '@salesforce/apex/AAREG_HomeController.checkAndShareIfAuthorized';
import AaregRepresentModal from 'c/aareg_representModal';

export default class Aareg_home extends NavigationMixin(LightningElement) {
    @track organizations;
    isLoaded = false;
    hasApplicationAccess = false;
    hasAccess = false;
    lastUsedOrganization;
    currentUser = Id;
    showError = false;
    representChoice = '';
    messages =
        'Avtaler er for øyeblikket ikke tilgjengelig. Send inn en brukerstøtte sak, hvis tilgang til avtale haster.';

    noAccessOrgForms = [
        'AAFY',
        'ADOS',
        'BEDR',
        'OPMV',
        'BRL',
        'ENK',
        'ESEK',
        'IKJP',
        'KTRF',
        'PERS',
        'REGN',
        'REV',
        'SAM',
        'SÆR',
        'TVAM',
        'UDEF',
        'UTBG',
        'UTLA',
        'VIFE'
    ];

    onlyOrganizations = ['Organization'];

    connectedCallback() {
        this.showRepresentModal();
    }

    /**
     * Opens the representation-choice modal as the mandatory first step.
     * Re-opens if dismissed without a selection (e.g. ESC key) to ensure
     * the user always makes a choice before entering the application.
     * Navigates to logout if the user clicks "Avbryt" inside the modal.
     */
    async showRepresentModal() {
        let result;
        do {
            // eslint-disable-next-line no-await-in-loop
            result = await AaregRepresentModal.open({
                label: 'Velg hvem du ønsker å representere',
                size: 'small',
                description: 'Velg om du ønsker å representere en virksomhet eller deg selv'
            });
        } while (!result);

        this.representChoice = result;
        if (this.representChoice === 'megSelv') {
            console.log('User chose to represent themselves, skipping organization fetch and access check. # 1');
            // set a cache value to be used in the MyThreads component to filter on Person threads
            try {
                await setCacheValue({ key: `${this.currentUser}_representingPerson`, value: 'true' });
                this[NavigationMixin.Navigate](
                    {
                        type: 'standard__navItemPage',
                        attributes: {
                            apiName: 'Mine_Meldinger_c'
                        }
                    },
                    true
                );
            } catch (error) {
                console.error('Failed to set cache value', error);
            }
            return;
        } else {
            // set a cache value to be used in the MyThreads component to filter on Person threads
            try {
                await setCacheValue({ key: `${this.currentUser}_representingPerson`, value: 'false' });
            } catch (error) {
                console.error('Failed to set cache value', error);
            }
        }
        this.init();
    }

    async init() {
        console.log('Initializing with representChoice:', this.representChoice);
        try {
            const orgResult = await getOrganizationsWithRoles({ userId: this.currentUser });
            if (orgResult.success) {
                if (orgResult.altinnVersion === 'v3') {
                    this.organizations = orgResult.organizations.filter(
                        (el) => this.onlyOrganizations.includes(el.type)
                    );
                    this.organizations = this.organizations.filter(
                        (el) => !this.noAccessOrgForms.includes(el.unitType)
                    );
                }
            } else {
                throw `Failed to get organizations ${orgResult.errorMessage}`;
            }

            this.lastUsedOrganization = await getLastUsersLastUsedOrganization({
                userId: this.currentUser
            });
            this.sortOrganizations();

            if (this.lastUsedOrganization) {
                await this.secureAccessCheck();
            }
        } catch (error) {
            console.error(error);
            this.showErrorMessage('En feil oppstod. Vennligst prøv igjen eller refresh siden.');
        } finally {
            this.isLoaded = true;
        }
    }

    async handleOrganizationChange(event) {
        this.isLoaded = false;
        this.hasAccess = false;
        this.hasApplicationAccess = false;
        this.lastUsedOrganization = event.target.value;

        try {
            await updateLastUsedOrganization({
                organizationNumber: this.lastUsedOrganization,
                userId: this.currentUser
            });
            this.sortOrganizations();
            await this.secureAccessCheck();
        } catch (error) {
            console.error(error);
        } finally {
            this.isLoaded = true;
        }
    }

    sortOrganizations() {
        if (!this.organizations || !this.lastUsedOrganization) return;

        let foundIndex;
        this.organizations.forEach((org, i) => {
            if (org.type === 'Person') {
                this.organizations.splice(i, 1);
            }
            if (org.organizationNumber === this.lastUsedOrganization) {
                foundIndex = i;
            }
        });

        if (typeof foundIndex !== 'undefined' && foundIndex !== 0) {
            const placeholder = this.organizations[0];
            this.organizations[0] = this.organizations[foundIndex];
            this.organizations[foundIndex] = placeholder;
        }
    }

    async secureAccessCheck() {
        try {
            const result = await checkAndShareIfAuthorized({
                userId: this.currentUser,
                orgNumber: this.lastUsedOrganization
            });

            this.hasApplicationAccess = result.hasApplicationAccess;
            this.hasAccess = result.hasAccess;
            this.showError = false;
        } catch (error) {
            this.hasApplicationAccess = false;
            this.hasAccess = false;
            this.showErrorMessage(
                'Henting av brukerrettigheter fra Altinn feilet. Vennligst prøv igjen eller refresh siden.'
            );
            console.error(error);
        }
    }

    get hasPreviouslySelectedOrganization() {
        return this.lastUsedOrganization;
    }

    closeErrorMessage() {
        this.showError = false;
    }

    errorMsg = 'En feil oppstod. Vennligst prøv igjen eller refresh siden.';
    showErrorMessage(errorMsg) {
        this.showError = true;
        this.errorMsg = errorMsg;
    }
}