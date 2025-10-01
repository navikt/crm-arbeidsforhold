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

  onlyOrganizations = ['Organization'];

  connectedCallback() {
    this.init();
  }

  async init() {
    try {
      await getOrganizationsWithRoles({ userId: this.currentUser }).then((result) => {
        console.log(result);
        if (result.success) {
          //Altinn 2
          this.organizations = result.organizations.filter(
            (el) => !this.noAccessOrgForms.includes(el.OrganizationForm)
          );
          //Altinn 3
          this.organizations = result.organizations.filter(
            (el) => this.onlyOrganizations.includes(el.Type)
          );
          this.organizations = result.organizations.filter(
            (el) => !this.noAccessOrgForms.includes(el.UnitType)
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
    
    await getUserRights({ userId: this.currentUser,
      organizationNumber: this.lastUsedOrganization,
      serviceCode: filterBy
    }).then((result) => {
      if (result.success) {
        let privileges = JSON.parse(JSON.stringify(result.rights));
        console.log(privileges);
        privileges.forEach((privilege) => {
          if (privilege.ServiceCode === '5719') {
            this.hasAccess = true;
            this.hasApplicationAccess = true;
          } else if (privilege.ServiceCode === '5441' && privilege.ServiceEditionCode === '2') {
            this.hasAccess = true;
          }
        });

        sessionStorage.setItem('currentUser', this.currentUser);
        sessionStorage.setItem('hasAccess', JSON.stringify(this.hasAccess));
        sessionStorage.setItem('hasApplicationAccess', JSON.stringify(this.hasApplicationAccess));
        this.showError = false;
      } else {
        this.hasAccess = false;
        this.hasApplicationAccess = false;
        sessionStorage.setItem('hasAccess', JSON.stringify(false));
        sessionStorage.setItem('hasApplicationAccess', JSON.stringify(false));
        this.showErrorMessage('Henting av brukerrettigheter fra Altinn feilet. Vennligst prøv igjen eller refresh siden.');
        throw `Failed to get rights to application ${result.errorMessage}`;
      }
    });
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
