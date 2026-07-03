import { LightningElement, track } from 'lwc';
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

    render() {
        return this.representChoice ? userSupportTemplate : applicationAccessTemplate;
    }

    async init() {
        const queryValues = this.getQueryValues();
        this.selectedUserType = queryValues.userType;
        this.representChoice = this.selectedUserType !== 'Organization';
        this.lastUsedOrganization = queryValues.organizationNumber;

        sessionStorage.setItem(`${this.currentUser}_representingPerson`, 'false');
        console.log('Cache key set when representing a business is chosen:', `${this.currentUser}_representingPerson`, 'Cache value set to: false');

        if (this.representChoice) {
            this.hasAccess = true;
            this.hasApplicationAccess = false;
            this.updateUrl();
            this.isLoaded = true;
            sessionStorage.setItem(`${this.currentUser}_representingPerson`, 'true');
            console.log('Cache key set when representing a business is chosen:', `${this.currentUser}_representingPerson`, 'Cache value set to: true');
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

    getQueryValues() {
        const url = new URL(window.location.href);
        const userType = this.normalizeUserType(url.searchParams.get('userType'));
        const organizationNumber =
            (url.searchParams.get('organization-number') || '').trim() ||
            (url.searchParams.get('organizationNumber') || '').trim();

        return {
            userType,
            organizationNumber: organizationNumber || null
        };
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
            url.searchParams.set('organization-number', this.lastUsedOrganization);
        } else {
            url.searchParams.delete('organization-number');
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