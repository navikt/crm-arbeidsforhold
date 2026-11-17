import { LightningElement, track, wire } from 'lwc';
import Id from '@salesforce/user/Id';
import getLastUsersLastUsedOrganization from '@salesforce/apex/AAREG_HomeController.getLastUsersLastUsedOrganization';
import getOrganizationsWithRoles from '@salesforce/apex/AAREG_HomeController.getOrganizationsWithRoles';
import refreshOrganizationsWithRoles from '@salesforce/apex/AAREG_HomeController.refreshOrganizationsWithRoles';
import updateLastUsedOrganization from '@salesforce/apex/AAREG_HomeController.updateLastUsedOrganization';
import checkAndShareIfAuthorized from '@salesforce/apex/AAREG_HomeController.checkAndShareIfAuthorized';
import getUsersThreads from '@salesforce/apex/AAREG_MyThreadsController.getUsersThreads';
import refreshOrganizationsLabel from '@salesforce/label/c.AAREG_Refresh_Organizations';
import noOrganizationsTitle from '@salesforce/label/c.AAREG_No_Organizations_Title';
import noOrganizationsDescription from '@salesforce/label/c.AAREG_No_Organizations_Description';
import noOrganizationsGuidance from '@salesforce/label/c.AAREG_No_Organizations_Guidance';

export default class Aareg_home extends LightningElement {
    @track organizations;
    isLoaded = false;
    isRefreshing = false;
    unreadThreadCount = 0;
    hasRequestedOrganizationRefresh = false;
    organizationVersion;
    organizationError;
    accessCheckFailed = false;
    initializationStarted = false;
    labels = {
        refreshOrganizations: refreshOrganizationsLabel,
        noOrganizationsTitle,
        noOrganizationsDescription,
        noOrganizationsGuidance
    };

    @wire(getUsersThreads, { userId: '$currentUser' })
    wiredThreads({ data }) {
        if (data) {
            this.unreadThreadCount = data.reduce((sum, t) => sum + (t.CRM_Number_of_unread_Messages__c || 0), 0);
        }
    }
    hasApplicationAccess = false;
    hasAccess = false;
    lastUsedOrganization;
    currentUser = Id;
    showError = false;
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

    @wire(getOrganizationsWithRoles, { userId: '$currentUser' })
    wiredOrganizations(result) {
        if (this.hasRequestedOrganizationRefresh) return;
        if (result.data) {
            try {
                this.setOrganizations(result.data);
                this.organizationError = null;
            } catch (error) {
                this.organizations = [];
                this.organizationError = error;
            }
        } else if (result.error) {
            this.organizations = [];
            this.organizationError = result.error;
        } else {
            return;
        }

        if (!this.initializationStarted) {
            this.initializationStarted = true;
            void this.init();
        }
    }

    setOrganizations(orgResult) {
        if (!orgResult.success) {
            throw new Error(`Failed to get organizations ${orgResult.errorMessage}`);
        }

        this.organizationVersion = orgResult.altinnVersion;
        if (orgResult.altinnVersion === 'v3') {
            const organizations = Array.isArray(orgResult.organizations) ? orgResult.organizations : [];
            this.organizations = organizations
                .filter((organization) => this.onlyOrganizations.includes(organization.type))
                .filter((organization) => !this.noAccessOrgForms.includes(organization.unitType));
        } else {
            this.organizations = undefined;
        }
    }

    async init() {
        try {
            if (this.organizationError) {
                throw this.organizationError;
            }
            this.lastUsedOrganization = await getLastUsersLastUsedOrganization({ userId: this.currentUser });
            this.sortOrganizations();
            await this.checkSelectedOrganization();
        } catch (error) {
            console.error(error);
            this.clearAccess();
            this.showErrorMessage('En feil oppstod. Vennligst prøv igjen eller refresh siden.');
        } finally {
            this.isLoaded = true;
        }
    }

    async handleRefresh() {
        if (this.isRefreshing) return;

        this.isRefreshing = true;
        this.hasRequestedOrganizationRefresh = true;
        this.clearAccess();
        this.showError = false;
        this.accessCheckFailed = false;

        try {
            const organizations = await refreshOrganizationsWithRoles({ userId: this.currentUser });
            this.setOrganizations(organizations);
            this.organizationError = null;

            this.lastUsedOrganization = await getLastUsersLastUsedOrganization({ userId: this.currentUser });
            this.sortOrganizations();
            await this.checkSelectedOrganization();
        } catch (error) {
            console.error(error);
            this.clearAccess();
            this.organizationError = error;
            this.organizations = [];
            this.lastUsedOrganization = null;
            this.showErrorMessage('Henting av organisasjoner feilet. Vennligst prøv igjen eller refresh siden.');
        } finally {
            this.isRefreshing = false;
        }
    }

    async handleOrganizationChange(event) {
        if (this.isRefreshing) return;
        this.isLoaded = false;
        this.clearAccess();
        this.showError = false;
        this.accessCheckFailed = false;
        const organizationNumber = event.target.value;
        this.lastUsedOrganization = organizationNumber;

        try {
            if (!organizationNumber || !this.isSelectedOrganizationAvailable() || this.organizationError) {
                this.lastUsedOrganization = null;
                return;
            }
            await updateLastUsedOrganization({
                organizationNumber: this.lastUsedOrganization,
                userId: this.currentUser
            });
            this.sortOrganizations();
            await this.secureAccessCheck();
        } catch (error) {
            console.error(error);
            this.accessCheckFailed = true;
            this.showErrorMessage('Valg av virksomhet feilet. Vennligst prøv igjen eller oppdater siden.');
        } finally {
            this.isLoaded = true;
        }
    }

    sortOrganizations() {
        if (!this.organizations) return;

        this.organizations = [...this.organizations].sort((first, second) => {
            const firstIsSelected = first.organizationNumber === this.lastUsedOrganization;
            const secondIsSelected = second.organizationNumber === this.lastUsedOrganization;
            if (firstIsSelected !== secondIsSelected) {
                return firstIsSelected ? -1 : 1;
            }
            return (
                first.name.localeCompare(second.name, 'nb') ||
                first.organizationNumber.localeCompare(second.organizationNumber)
            );
        });
    }

    async checkSelectedOrganization() {
        if (this.lastUsedOrganization && this.isSelectedOrganizationAvailable()) {
            await this.secureAccessCheck();
            return;
        }

        this.lastUsedOrganization = null;
        this.clearAccess();
    }

    isSelectedOrganizationAvailable() {
        if (this.organizationVersion !== 'v3') return true;
        return this.organizations?.some(
            (organization) => organization.organizationNumber === this.lastUsedOrganization
        );
    }

    clearAccess() {
        this.hasAccess = false;
        this.hasApplicationAccess = false;
    }

    async secureAccessCheck() {
        this.accessCheckFailed = false;
        try {
            const result = await checkAndShareIfAuthorized({
                userId: this.currentUser,
                orgNumber: this.lastUsedOrganization
            });

            this.hasApplicationAccess = result.hasApplicationAccess;
            this.hasAccess = result.hasAccess;
            this.showError = false;
        } catch (error) {
            this.accessCheckFailed = true;
            this.hasApplicationAccess = false;
            this.hasAccess = false;
            this.showErrorMessage(
                'Henting av brukerrettigheter fra Altinn feilet. Vennligst prøv igjen eller refresh siden.'
            );
            console.error(error);
        }
    }

    get hasNoSelectedOrganization() {
        return !this.lastUsedOrganization;
    }

    get organizationOptions() {
        return (this.organizations || []).map((organization) => ({
            ...organization,
            isSelected: organization.organizationNumber === this.lastUsedOrganization
        }));
    }

    get showMissingAccess() {
        return (
            !this.hasAccess &&
            !this.isRefreshing &&
            !this.organizationError &&
            !this.accessCheckFailed &&
            Boolean(this.lastUsedOrganization)
        );
    }

    get hasOrganizations() {
        return Array.isArray(this.organizations) && this.organizations.length > 0;
    }

    get hasNoOrganizations() {
        return (
            Array.isArray(this.organizations) &&
            this.organizations.length === 0 &&
            !this.organizationError &&
            !this.isRefreshing
        );
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
