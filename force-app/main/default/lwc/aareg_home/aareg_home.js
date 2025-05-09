import { LightningElement, track } from 'lwc';
import Id from '@salesforce/user/Id';
import getLastUsersLastUsedOrganization from '@salesforce/apex/AAREG_HomeController.getLastUsersLastUsedOrganization';
import getOrganizationsWithRoles from '@salesforce/apex/AAREG_HomeController.getOrganizationsWithRoles';
import updateLastUsedOrganization from '@salesforce/apex/AAREG_HomeController.updateLastUsedOrganization';
import checkAndShareIfAuthorized from '@salesforce/apex/AAREG_HomeController.checkAndShareIfAuthorized';

export default class Aareg_home extends LightningElement {
  @track organizations;
  isLoaded = false;
  hasApplicationAccess = false;
  hasAccess = false;
  lastUsedOrganization;
  currentUser = Id;
  showError = false;

  noAccessOrgForms = [
    'AAFY', 'ADOS', 'BEDR', 'OPMV', 'BRL', 'ENK', 'ESEK', 'IKJP', 'KTRF',
    'PERS', 'REGN', 'REV', 'SAM', 'SÆR', 'TVAM', 'UDEF', 'UTBG', 'UTLA', 'VIFE'
  ];

  connectedCallback() {
    this.init();
  }

  async init() {
    try {
      const orgResult = await getOrganizationsWithRoles({ userId: this.currentUser });
      if (orgResult.success) {
        this.organizations = orgResult.organizations.filter(
          (el) => !this.noAccessOrgForms.includes(el.OrganizationForm)
        );
      } else {
        throw `Failed to get organizations ${orgResult.errorMessage}`;
      }

      this.lastUsedOrganization = await getLastUsersLastUsedOrganization({ userId: this.currentUser });
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
    this.organizations = this.organizations.filter((org, i) => {
      if (org.Type === 'Person') return false;
      if (org.OrganizationNumber === this.lastUsedOrganization) foundIndex = i;
      return true;
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

      this.hasApplicationAccess = result;
      this.hasAccess = result;
      this.showError = false;
    } catch (error) {
      this.hasApplicationAccess = false;
      this.hasAccess = false;
      this.showErrorMessage('Henting av brukerrettigheter fra Altinn feilet. Vennligst prøv igjen eller refresh siden.');
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
