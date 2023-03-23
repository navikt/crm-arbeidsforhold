import { LightningElement, track } from 'lwc';
import Id from '@salesforce/user/Id';
import getLastUsersLastUsedOrganization from '@salesforce/apex/AAREG_HomeController.getLastUsersLastUsedOrganization';
import getOrganizationsWithRoles from '@salesforce/apex/AAREG_HomeController.getOrganizationsWithRoles';
import updateLastUsedOrganization from '@salesforce/apex/AAREG_HomeController.updateLastUsedOrganization';
import shareAgreementsWithUser from '@salesforce/apex/AAREG_HomeController.shareAgreementsWithUser';
import getUserRights from '@salesforce/apex/AAREG_CommunityUtils.getUserRights';

export default class Aareg_home extends LightningElement {
  @track organizations;
  isLoaded = false;
  hasApplicationAccess = false;
  hasAccess = false;
  lastUsedOrganization;
  currentUser = Id;
  showError = false;

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

  connectedCallback() {
    this.init();
  }

  async init() {
    try {
      await getOrganizationsWithRoles({ userId: this.currentUser }).then((result) => {
        if (result.success) {
          this.organizations = result.organizations.filter(
            (el) => !this.noAccessOrgForms.includes(el.OrganizationForm)
          );
        } else {
          throw `Failed to get organizations ${result.errorMessage}`;
        }
      });

      await getLastUsersLastUsedOrganization({ userId: this.currentUser }).then((result) => {
        this.lastUsedOrganization = result;
        this.sortOrganizations();
      });
      // Avoid doing callout on every ConnectedCallback
      // Check current user as well to avoid user being logged in on two different users in same session to get access
      if (sessionStorage.getItem('currentUser') === this.currentUser && (sessionStorage.getItem('hasApplicationAccess') === 'true' || sessionStorage.getItem('hasAccess') === 'true')) {
        if (sessionStorage.getItem('hasApplicationAccess') === 'true') {
          this.hasApplicationAccess = true;
        }
        if (sessionStorage.getItem('hasAccess') === 'true') {
          this.hasAccess = true;
        }
        return;
      }

      await this.checkAccessToApplication('5719');
      if (this.hasApplicationAccess === false) await this.checkAccessToApplication('5441');
    } catch (error) {
      console.error(error);
    } finally {
      if (this.hasAccess) {
        shareAgreementsWithUser({ userId: this.currentUser });
      }
      this.isLoaded = true;
    }
  }

  async handleOrganizationChange(event) {
    this.isLoaded = false;
    this.hasAccess = false;
    this.hasApplicationAccess = false;
    this.lastUsedOrganization = event.target.value;
    try {
      await updateLastUsedOrganization({ organizationNumber: this.lastUsedOrganization, userId: this.currentUser }).then(() => {
        this.sortOrganizations();
      });
      // Check access rights on new org number (this.lastUsedOrganization)
      await this.checkAccessToApplication('5719');
      if (this.hasApplicationAccess === false) await this.checkAccessToApplication('5441');
    } catch (error) {
      console.error(error);
    } finally {
      this.isLoaded = true;
      if (this.hasAccess) {
        shareAgreementsWithUser({ userId: this.currentUser });
      }
    }    
  }

  sortOrganizations() {
    if (this.organizations === undefined || this.lastUsedOrganization === null) {
      return;
    }

    let foundIndex;
    this.organizations.forEach((org, i) => {
      if (org.Type === 'Person') {
        this.organizations.splice(i, 1);
      }
      if (org.OrganizationNumber === this.lastUsedOrganization) {
        foundIndex = i;
      }
    });

    if (typeof foundIndex !== 'undefined' && foundIndex !== 0) {
      let placeholder = this.organizations[0];
      this.organizations[0] = this.organizations[foundIndex];
      this.organizations[foundIndex] = placeholder;
    }
  }

  async checkAccessToApplication(filterBy) {
    if (this.organizations === undefined || this.lastUsedOrganization === null || this.lastUsedOrganization ==='') {
      this.hasAccess = false;
      this.hasApplicationAccess = false;
      return;
    }

    try{

      const { userId, organizationNumber } = this;
      const { success, rights, errorMessage } = await getUserRights({ userId, organizationNumber, serviceCode: filterBy });

      if(result.success){
        let hasAccess = false;
        let hasApplicationAccess = false;

        rights.forEach(({ ServiceCode, ServiceEditionCode }) => {
          if (ServiceCode === '5719') {
            hasAccess = true;
            hasApplicationAccess = true;
          } else if (ServiceCode === '5441' && ServiceEditionCode === '2') {
            hasAccess = true;
          }
        });

      this.hasAccess = hasAccess;
      this.hasApplicationAccess = hasApplicationAccess;
      this.showError = false;

      sessionStorage.setItem('currentUser', this.currentUser);
      sessionStorage.setItem('hasAccess', hasAccess);
      sessionStorage.setItem('hasApplicationAccess', hasApplicationAccess);
      } else {
        this.hasAccess = false;
        this.hasApplicationAccess = false;
        this.showError = true;
  
        sessionStorage.setItem('hasAccess', false);
        sessionStorage.setItem('hasApplicationAccess', false);
        throw new Error('Failed to get rights to application. ${errorMessage}');
      }
    } catch(error){
      console.error(error);
      this.showErrorMessage('Henting av brukerrettigheter fra Altinn feilet. Vennligst prøv igjen eller refresh siden.');
    }

  }

  get hasPreviouslySelectedOrganization() {
    return this.lastUsedOrganization;
  }

  closeErrorMessage() {
    this.showError = false;
  }

  errorMsg = 'En feil oppstod. Vennligst prøv igjen eller refresh siden.'
  showErrorMessage(errorMsg) {
    this.showError = true;
    this.errorMsg = errorMsg;
  }
}
