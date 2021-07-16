import { LightningElement, track } from 'lwc';
import Id from '@salesforce/user/Id';
import getLastUsersLastUsedOrganiation from '@salesforce/apex/AAREG_HomeController.getLastUsersLastUsedOrganiation';
import getOrganizationsWithRoles from '@salesforce/apex/AAREG_HomeController.getOrganizationsWithRoles';
import updateLastUsedOrganization from '@salesforce/apex/AAREG_HomeController.updateLastUsedOrganization';
import getUserRights from '@salesforce/apex/AAREG_CommunityUtils.getUserRights';

export default class Aareg_home extends LightningElement {
  @track organizations;
  @track error;
  hasAccess = false;
  isLoaded = false;
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
          throw `Failed to get Organizaions ${result.errorMessage}`;
        }
      });

      await getLastUsersLastUsedOrganiation({ userId: this.currentUser }).then((result) => {
        this.lastUsedOrganization = result;
      });

      this.sortOrganizations();
      await this.checkAccessToApplication();
    } catch (error) {
      console.log('Error! ', error);
      this.error = error;
    } finally {
      this.isLoaded = true;
    }
  }

  handleOrganizationChange(event) {
    this.isLoaded = false;
    this.hasAccess = false;
    this.lastUsedOrganization = event.target.value;
    updateLastUsedOrganization({ organizationNumber: this.lastUsedOrganization, userId: this.currentUser })
      .then((result) => {
        this.sortOrganizations();
        this.checkAccessToApplication();
      })
      .catch((error) => {
        this.error = error;
        console.log('Org Change Error: ', error);
      });
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

    if (typeof foundIndex !== 'undefined') {
      if (foundIndex != 0) {
        let placeholder = this.organizations[0];
        this.organizations[0] = this.organizations[foundIndex];
        this.organizations[foundIndex] = placeholder;
      }
    }
  }

  async checkAccessToApplication() {
    if (this.organizations === undefined) {
      this.hasAccess = false;
      return;
    }
    if (this.lastUsedOrganization === null || '') {
      this.hasAccess = false;
      return;
    }
    console.log(this.currentUser);
    console.log(this.lastUsedOrganization);
    getUserRights({ userId: this.currentUser, organizationNumber: this.lastUsedOrganization, serviceCode: '5719' })
      .then((result) => {
        if (result.success) {
          let privileges = JSON.parse(JSON.stringify(result.rights));

          privileges.forEach((privilege) => {
            console.log(privilege.ServiceCode);
            if (privilege.ServiceCode === '5719') {
              this.hasAccess = true;
              return;
            }
          });
        } else {
          throw `Failed to get rights ${result.errorMessage}`;
        }
      })
      .catch((error) => {
        this.hasAccess = false;
        this.error = true;
        console.log('Error: ', error);
      })
      .finally(() => {
        this.isLoaded = true;
      });
  }
}
