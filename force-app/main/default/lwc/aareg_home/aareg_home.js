import { LightningElement, api, track, wire } from 'lwc';
import Id from '@salesforce/user/Id';
import getLastUsersLastUsedOrganiation from '@salesforce/apex/AAREG_HomeController.getLastUsersLastUsedOrganiation';
import getOrganizationsWithRoles from '@salesforce/apex/AAREG_HomeController.getOrganizationsWithRoles';
import updateLastUsedOrganization from '@salesforce/apex/AAREG_HomeController.updateLastUsedOrganization';
import getUserRights from '@salesforce/apex/AAREG_CommunityUtils.getUserRights';

export default class Aareg_home extends LightningElement {
  @track organizations;
  @track error;
  hasAccess = false;
  lastUsedOrganization;
  currentUser = Id;

  connectedCallback() {
    this.getLastUsedOrganization();
  }

  getLastUsedOrganization() {
    getLastUsersLastUsedOrganiation({ userId: this.currentUser })
      .then((result) => {
        this.lastUsedOrganization = result;
      })
      .catch((error) => {
        console.log('Error!!!', error);
      });
  }

  @wire(getOrganizationsWithRoles, { userId: '$currentUser' })
  wiredOrganizations({ error, data }) {
    if (data) {
      this.organizations = JSON.parse(JSON.stringify(data.organizations));
      this.error = undefined;
      this.sortOrganizations();
      this.checkAccessToApplication();
    } else if (error) {
      this.error = error;
      this.organizations = undefined;
      console.log('Get Org With roles Error:  ', error);
    }
  }

  handleOrganizationChange(event) {
    let recentOrganization = event.target.value;
    this.lastUsedOrganization = recentOrganization;
    updateLastUsedOrganization({ organizationNumber: recentOrganization, userId: this.currentUser })
      .then((result) => {
        this.checkAccessToApplication();
      })
      .catch((error) => {
        this.error = error;
        console.log('Handle Organization Change Error: ', error);
      });
  }

  sortOrganizations() {
    if (this.organizations === undefined || this.lastUsedOrganization === null) {
      return;
    }

    let foundIndex;
    this.organizations.forEach((org, i) => {
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

  checkAccessToApplication() {
    console.log('UserId: ', this.userId);
    console.log('Last Used Organization: ', this.lastUsedOrganization);
    if (this.organizations === undefined) {
      this.hasAccess = false;
      return;
    }
    if (this.lastUsedOrganization === null || '') {
      this.hasAccess = false;
      return;
    }
    getUserRights({ userId: this.userId, organizationNumber: this.lastUsedOrganization })
      .then((result) => {
        let privileges = JSON.parse(JSON.stringify(result.rights));

        privileges.forEach((privilege) => {
          if (privilege.ServiceCode === '5719') {
            this.hasAccess = true;
            return;
          }
        });
      })
      .catch((error) => {
        this.hasAccess = false;
        console.log('Get rights error: ', error);
      });
  }
}
