Skip to content
Search or jump to…
Pull requests
Issues
Marketplace
Explore
 
@annolse 
navikt
/
crm-arbeidsforhold
Public
generated from navikt/crm-shared-template
3
0
0
Code
Issues
Pull requests
2
Actions
Projects
Wiki
Security
4
Insights
Settings
We found potential security vulnerabilities in your dependencies.
You can see this message because you have been granted access to Dependabot alerts for this repository.

crm-arbeidsforhold/force-app/main/default/lwc/aareg_home/aareg_home.js
@jordan-mathews
jordan-mathews Home page tab access updates
Latest commit 29e0716 4 hours ago
 History
 2 contributors
@annolse@jordan-mathews
158 lines (142 sloc)  4.31 KB
   
import { LightningElement, track } from 'lwc';
import Id from '@salesforce/user/Id';
import getLastUsersLastUsedOrganiation from '@salesforce/apex/AAREG_HomeController.getLastUsersLastUsedOrganiation';
import getOrganizationsWithRoles from '@salesforce/apex/AAREG_HomeController.getOrganizationsWithRoles';
import updateLastUsedOrganization from '@salesforce/apex/AAREG_HomeController.updateLastUsedOrganization';
import getUserRights from '@salesforce/apex/AAREG_CommunityUtils.getUserRights';

export default class Aareg_home extends LightningElement {
  @track organizations;
  @track error;
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
          throw `Failed to get Organizaions ${result.errorMessage}`;
        }
      });

      await getLastUsersLastUsedOrganiation({ userId: this.currentUser }).then((result) => {
        this.lastUsedOrganization = result;
      });

      this.sortOrganizations();

      await this.checkAccessToApplication('5719');

      if (this.hasApplicationAccess === false) await this.checkAccessToApplication('5411');
    } catch (error) {
      this.error = error;
      console.error(error);
    } finally {
      this.isLoaded = true;
    }
  }

  async handleOrganizationChange(event) {
    this.isLoaded = false;
    this.hasAccess = false;
    this.lastUsedOrganization = event.target.value;
    updateLastUsedOrganization({ organizationNumber: this.lastUsedOrganization, userId: this.currentUser })
      .then((result) => {
        this.sortOrganizations();
      })
      .catch((error) => {
        this.error = error;
        console.error(error);
      })
      .finally(() => {
        this.isLoaded = true;
      });
    await this.checkAccessToApplication('5717');
    if (this.hasApplicationAccess === false) await this.checkAccessToApplication('5411');
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

  async checkAccessToApplication(filterBy) {
    if (this.organizations === undefined) {
      this.hasAccess = false;
      this.hasApplicationAccess = false;
      return;
    }
    if (this.lastUsedOrganization === null || '') {
      this.hasAccess = false;
      this.hasApplicationAccess = false;
      return;
    }

    await getUserRights({
      userId: this.currentUser,
      organizationNumber: this.lastUsedOrganization,
      serviceCode: filterBy
    })
      .then((result) => {
        if (result.success) {
          let privileges = JSON.parse(JSON.stringify(result.rights));

          privileges.forEach((privilege) => {
            if (privilege.ServiceCode === '5719') {
              this.hasAccess = true;
              this.hasApplicationAccess = true;
            } else if (privilege.ServiceCode === '5411' && privilege.ServiceEditionCode === '2') {
              this.hasAccess = true;
            }
          });
        } else {
          throw `Failed to get rights to application ${result.errorMessage}`;
        }
      })
      .catch((error) => {
        this.hasAccess = false;
        this.error = true;
        console.error(error);
      });
  }

  get hasPreviouslySelectedOrganization() {
    return this.lastUsedOrganization;
  }
}
