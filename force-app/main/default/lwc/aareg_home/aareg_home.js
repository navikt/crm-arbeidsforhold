import { LightningElement, track } from 'lwc';
import Id from '@salesforce/user/Id';
import getLastUsersLastUsedOrganiation from '@salesforce/apex/AAREG_HomeController.getLastUsersLastUsedOrganiation';
import getOrganizationsWithRoles from '@salesforce/apex/AAREG_HomeController.getOrganizationsWithRoles';
import updateLastUsedOrganization from '@salesforce/apex/AAREG_HomeController.updateLastUsedOrganization';
import getUserRights from '@salesforce/apex/AAREG_CommunityUtils.getUserRights';

export default class Aareg_home extends LightningElement {
  @track organizations;
  isLoaded = false;
  hasApplicationAccess = false;
  hasAccess = false;
  lastUsedOrganization;
  currentUser = Id;

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

      await getLastUsersLastUsedOrganiation({ userId: this.currentUser }).then((result) => {
        this.lastUsedOrganization = result;
        this.sortOrganizations();
      });
      // Only do callout when doing it for the first time or if no rights saved in session
      if (sessionStorage.getItem('hasApplicationAccess') === 'true' || sessionStorage.getItem('hasAccess') === 'true') {
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
      this.isLoaded = true;
    }
  }

  async handleOrganizationChange(event) {
    this.isLoaded = false;
    this.hasAccess = false;
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
    if (this.organizations === undefined || this.lastUsedOrganization === null || '') {
      this.hasAccess = false;
      this.hasApplicationAccess = false;
      return;
    }

    await getUserRights({
      userId: this.currentUser,
      organizationNumber: this.lastUsedOrganization,
      serviceCode: filterBy
    }).then((result) => {
      if (result.success) {
        let privileges = JSON.parse(JSON.stringify(result.rights));
        privileges.forEach((privilege) => {
          if (privilege.ServiceCode === '5719') {
            this.hasAccess = true;
            this.hasApplicationAccess = true;
            
          } else if (privilege.ServiceCode === '5441' && privilege.ServiceEditionCode === '2') {
            this.hasAccess = true;
          }
          sessionStorage.setItem('hasAccess', JSON.stringify(this.hasAccess));
          sessionStorage.setItem('hasApplicationAccess', JSON.stringify(this.hasApplicationAccess));
        });
      } else {
        this.hasAccess = false;
        sessionStorage.setItem('hasAccess', JSON.stringify(false));
        sessionStorage.setItem('hasApplicationAccess', JSON.stringify(false));
        throw `Failed to get rights to application ${result.errorMessage}`;
      }
    });
  }

  get hasPreviouslySelectedOrganization() {
    return this.lastUsedOrganization;
  }
}
