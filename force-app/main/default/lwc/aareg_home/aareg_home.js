import { LightningElement, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import applicationAccessTemplate from './aareg_applicationAccess.html';
import userSupportTemplate from './aareg_userSupport.html';
import Id from '@salesforce/user/Id';
import getLastUsersLastUsedOrganization from '@salesforce/apex/AAREG_HomeController.getLastUsersLastUsedOrganization';
import getOrganizationsWithRoles from '@salesforce/apex/AAREG_HomeController.getOrganizationsWithRoles';
import updateLastUsedOrganization from '@salesforce/apex/AAREG_HomeController.updateLastUsedOrganization';
import checkAndShareIfAuthorized from '@salesforce/apex/AAREG_HomeController.checkAndShareIfAuthorized';

const USER_TYPE_HEADER_CONFIG = {
    organization: {
        header: 'Min side - Brukerstøtte og søknad om tilgang til Aa-registeret'
    },
    usersupport: {
        header: 'Min side - Brukerstøtte til Aa-registeret'
    },
    partner: {
        header: 'Min side - Brukerstøtte til Aa-registeret'
    },
    employer: {
        header: 'Min side - Brukerstøtte til Aa-registeret'
    },
    employee: {
        header: 'Min side - Brukerstøtte til Aa-registeret'
    },
    default: {
        header: 'Min side - Brukerstøtte og søknad om tilgang til Aa-registeret'
    }
};

export default class Aareg_home extends LightningElement {
    supportedUserTypes = ['organization', 'usersupport', 'employer', 'employee', 'partner'];
    organizations;
    isLoaded = false;
    hasApplicationAccess = false;
    hasRepresentationAccess = false;
    lastUsedOrganization;
    currentUser = Id;
    showError = false;
    selectedUserType;
    headerText = USER_TYPE_HEADER_CONFIG.default.header;
    // Initialize only once. URL changes after initialization are ignored.
    isInitialized = false;
    get representsPrivatePerson() {
        console.log('User type in cache in aareg_home.js at line number 24:', sessionStorage.getItem(`${this.currentUser}_userType`));
        return this.selectedUserType !== 'organization';
    }
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

    onlyOrganizations = ['organization'];

    @wire(CurrentPageReference)
    handlePageRef(pageRef) {
        console.log('Page reference in aareg_home.js at line number 56:', pageRef);
        if (!pageRef || this.isInitialized) {
            console.log('Page reference is not available or already initialized in aareg_home.js at line number 58:', pageRef, this.isInitialized);
            return;
        }

        const state = pageRef.state || {};

        const rawUserType =
            state.userType || state.usertype || state.c__userType;

        const rawOrgNr = (
            state.orgNr || state.c__orgNr || state.organizationNumber || state.c__organizationNumber ||
            ''
        ).trim();

        const storageKey = `${this.currentUser}_userType`;

        // URL parameter takes precedence over sessionStorage.
        // If there is no URL parameter, restore the previous selection.
        const storedUserType = sessionStorage.getItem(storageKey);

        if (rawUserType) {
            this.selectedUserType = this.normalizeUserType(rawUserType);
        } else if (storedUserType) {
            this.selectedUserType = this.normalizeUserType(storedUserType);
        } else {
            this.selectedUserType = 'organization';
        }
        console.log('Selected user type in aareg_home.js at line number 89:', this.selectedUserType);

        this.lastUsedOrganization = rawOrgNr || null;
        if (!this.lastUsedOrganization) {
            const storedOrgNr = sessionStorage.getItem(`${this.currentUser}_orgNr`);  
            this.lastUsedOrganization = storedOrgNr || null;
        }

        // Store the resolved user type for subsequent visits.
        sessionStorage.setItem(storageKey, this.selectedUserType);
        sessionStorage.setItem(`${this.currentUser}_orgNr`, this.lastUsedOrganization || '');
        console.log('User type in cache on handlePageRef in aareg_home.js at line number 91:', sessionStorage.getItem(storageKey));

        this.headerText = (USER_TYPE_HEADER_CONFIG[this.selectedUserType] || USER_TYPE_HEADER_CONFIG.default).header;

        // 
        this.isInitialized = true;
        // Initialize the component after page reference has been processed.
        this.init();
    }

    render() {
        console.log('Render method called in aareg_home.js at line number 106:', this.representsPrivatePerson);
        return this.representsPrivatePerson ? userSupportTemplate : applicationAccessTemplate;
    }

    async init() {
        console.log('Init method called in aareg_home.js at line number 111:', this.representsPrivatePerson);

        if (this.representsPrivatePerson) {
            console.log('representsPrivatePerson is true in init in aareg_home.js at line number 108:', this.representsPrivatePerson);
            this.hasApplicationAccess = false;
            this.hasRepresentationAccess = false;
            this.showError = false;

            // if user type is employer or partner, we need to check whether the user has access to the application. If not, we will show the user support template.
            if (this.selectedUserType === 'employer' || this.selectedUserType === 'partner') {
                console.log('Going to secureAccessCheck in init in aareg_home.js at line number 117:', this.representsPrivatePerson);
                await this.secureAccessCheck();
                if (!this.hasRepresentationAccess) {
                    this.showErrorMessage(
                        'Du har ikke tilgang til å representere en arbeidsgiver eller samarbeidspartner. Vennligst send inn en brukerstøtte sak for å få tilgang.'
                    );
                }         
            } else  this.hasRepresentationAccess = true;
            console.log('In init in aareg_home.js at line number 126:', this.representsPrivatePerson);
            this.hasApplicationAccess = false; // We don't need to check for application access for user types other than 'organization'.
            this.updateUrl();
            this.isLoaded = true;
            console.log('Exiting init in aareg_home.js at line number 130:', this.representsPrivatePerson);
            return;
        }

        console.log('representsPrivatePerson is false in init in aareg_home.js at line number 137:', this.representsPrivatePerson);

        try {
            console.log('Going to getOrganizationsWithRoles in init in aareg_home.js at line number 140:', this.representsPrivatePerson);
            const orgResult = await getOrganizationsWithRoles({ userId: this.currentUser });
            if (orgResult.success) {
                console.log('Organizations fetched successfully in init in aareg_home.js at line number 143:', orgResult);
                if (orgResult.altinnVersion === 'v3') {
                    this.organizations = orgResult.organizations.filter(
                        (el) => this.onlyOrganizations.includes(el.type)
                    );
                    this.organizations = this.organizations.filter(
                        (el) => !this.noAccessOrgForms.includes(el.unitType)
                    );
                }
            } else {
                console.error(`Failed to get organizations in init in aareg_home.js at line number 152: ${orgResult.errorMessage}`);
                throw new Error(`Failed to get organizations ${orgResult.errorMessage}`);
            }

            if (!this.lastUsedOrganization) {
                this.lastUsedOrganization = await getLastUsersLastUsedOrganization({
                    userId: this.currentUser
                });
                sessionStorage.setItem(`${this.currentUser}_orgNr`, this.lastUsedOrganization || '');
                console.log('Last used organization fetched successfully in init in aareg_home.js at line number 170:', this.lastUsedOrganization);
            }
            this.sortOrganizations();
            this.updateUrl();

            if (this.lastUsedOrganization) {
                console.log('Going to secureAccessCheck in init in aareg_home.js at line number 156:', this.representsPrivatePerson);
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
        console.log('Organization changed in handleOrganizationChange in aareg_home.js at line number 178:', event.target.value);
        this.isLoaded = false;
        this.hasRepresentationAccess = false;
        this.hasApplicationAccess = false;
        this.lastUsedOrganization = event.target.value;

        try {
            await updateLastUsedOrganization({
                organizationNumber: this.lastUsedOrganization,
                userId: this.currentUser
            });
            sessionStorage.setItem(`${this.currentUser}_orgNr`, this.lastUsedOrganization || '');
            this.sortOrganizations();
            this.updateUrl();
            console.log('Going to secureAccessCheck in handleOrganizationChange in aareg_home.js at line number 191:', this.representsPrivatePerson);
            await this.secureAccessCheck();
        } catch (error) {
            console.log('Error occurred in handleOrganizationChange in aareg_home.js at line number 194:', error);
            console.error(error);
            this.showErrorMessage('En feil oppstod. Vennligst prøv igjen eller refresh siden.');
        } finally {
            this.isLoaded = true;
        }
    }

    sortOrganizations() {
        console.log('Sorting organizations in sortOrganizations in aareg_home.js at line number 203:', this.organizations, this.lastUsedOrganization);
        if (!this.organizations) {
            return;
        }

        const organizations = this.organizations.filter(
            (org) => org.type !== 'Person'
        );

        if (!this.lastUsedOrganization) {
            this.organizations = organizations;
            return;
        }

        const selected = organizations.find(
            (org) => org.organizationNumber === this.lastUsedOrganization
        );

        const others = organizations.filter(
            (org) => org.organizationNumber !== this.lastUsedOrganization
        );

        this.organizations = selected
            ? [selected, ...others]
            : organizations;
    }

    async secureAccessCheck() {
        console.log('Going to checkAndShareIfAuthorized in secureAccessCheck in aareg_home.js at line number 218:', this.representsPrivatePerson);
        try {
            const result = await checkAndShareIfAuthorized({
                userId: this.currentUser,
                orgNumber: this.lastUsedOrganization
            });

            this.hasApplicationAccess = result.hasApplicationAccess;
            this.hasRepresentationAccess = result.hasAccess;
            this.showError = false;
            console.log('At line number 227 hasApplicationAccess:', this.hasApplicationAccess, 'hasRepresentationAccess:', this.hasRepresentationAccess);
            
        } catch (error) {
            console.log('Error occurred in secureAccessCheck in aareg_home.js at line number 244:', error);
            this.hasApplicationAccess = false;
            this.hasRepresentationAccess = false;
            console.log('At line number 232 hasApplicationAccess:', this.hasApplicationAccess, 'hasRepresentationAccess:', this.hasRepresentationAccess);
            this.showErrorMessage(
                'Henting av brukerrettigheter fra Altinn feilet. Vennligst prøv igjen eller refresh siden.'
            );
            console.error(error);
        }
    }

    get hasPreviouslySelectedOrganization() {
        console.log('Checking if user has previously selected organization in hasPreviouslySelectedOrganization in aareg_home.js at line number 248:', this.lastUsedOrganization);
        return this.lastUsedOrganization;
    }

    normalizeUserType(userType) {
        console.log('Normalizing user type in normalizeUserType in aareg_home.js at line number 261:', userType);
        if (!userType) {
            return 'organization';
        }

        return (
            this.supportedUserTypes.find(
                (type) => type.toLowerCase() === userType.toLowerCase()
            ) || 'organization'
        );
    }

    updateUrl() {
        console.log('Updating URL in updateUrl in aareg_home.js at line number 273:', this.selectedUserType, this.lastUsedOrganization);
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
        console.log('Closing error message in closeErrorMessage in aareg_home.js at line number 288');
        this.showError = false;
    }

    errorMsg = 'En feil oppstod. Vennligst prøv igjen eller refresh siden.';
    showErrorMessage(errorMsg) {
        console.log('Showing error message in showErrorMessage in aareg_home.js at line number 293:', errorMsg);
        this.showError = true;
        this.errorMsg = errorMsg;
    }
}