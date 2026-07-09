import { LightningElement, track, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import applicationAccessTemplate from './aareg_applicationAccess.html';
import userSupportTemplate from './aareg_userSupport.html';
import Id from '@salesforce/user/Id';
import getLastUsersLastUsedOrganization from '@salesforce/apex/AAREG_HomeController.getLastUsersLastUsedOrganization';
import getOrganizationsWithRoles from '@salesforce/apex/AAREG_HomeController.getOrganizationsWithRoles';
import updateLastUsedOrganization from '@salesforce/apex/AAREG_HomeController.updateLastUsedOrganization';
import checkAndShareIfAuthorized from '@salesforce/apex/AAREG_HomeController.checkAndShareIfAuthorized';

export default class Aareg_home extends LightningElement {
    supportedUserTypes = ['Organization', 'Employer', 'Employee', 'Partner'];
    @track organizations;
    isLoaded = false;
    hasApplicationAccess = false;
    hasAccess = false;
    lastUsedOrganization;
    currentUser = Id;
    showError = false;
    representChoice = false;
    selectedUserType = 'Organization';
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
        this.init();
    }

    @wire(CurrentPageReference)
    handlePageRef(pageRef) {
        if (!pageRef) return;
        const state = pageRef.state;
        const rawUserType = state.userType || state.c__userType;
        const rawOrgNr = (state.orgNr || state.c__orgNr || state.organizationNumber || state.c__organizationNumber || '').trim();

        this.selectedUserType = this.normalizeUserType(rawUserType);
        this.representChoice = this.selectedUserType !== 'Organization';
        this.lastUsedOrganization = rawOrgNr || null;
        sessionStorage.setItem(`${this.currentUser}_userType`, this.selectedUserType);
        console.log('Cache key set when representing a business is chosen:', `${this.currentUser}_userType`, 'Cache value set to:', this.selectedUserType);
    }

    render() {
        return this.representChoice ? userSupportTemplate : applicationAccessTemplate;
    }

    async init() {

        if (this.representChoice) {
            this.hasAccess = true;
            this.hasApplicationAccess = false;
            this.updateUrl();
            this.isLoaded = true;
            return;
        }

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

            if (!this.lastUsedOrganization) {
                this.lastUsedOrganization = await getLastUsersLastUsedOrganization({
                    userId: this.currentUser
                });
            }
            this.sortOrganizations();
            this.updateUrl();

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
            this.updateUrl();
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

    normalizeUserType(userType) {
        if (!userType) {
            return 'Organization';
        }

        return (
            this.supportedUserTypes.find(
                (type) => type.toLowerCase() === userType.toLowerCase()
            ) || 'Organization'
        );
    }

    updateUrl() {
        const url = new URL(window.location.href);
        url.searchParams.set('userType', this.selectedUserType);

        if (this.lastUsedOrganization) {
            url.searchParams.set('orgNr', this.lastUsedOrganization);
        } else {
            url.searchParams.delete('orgNr');
        }

        window.history.replaceState({}, '', url.toString());
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