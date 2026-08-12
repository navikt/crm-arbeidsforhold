import { LightningElement, wire, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { generateUrl } from 'lightning/fileDownload';
import Id from '@salesforce/user/Id';
import navLogo from '@salesforce/resourceUrl/logo';
import getUsersApplications from '@salesforce/apex/AAREG_MyApplicationsController.getUsersApplications';
import getDecisionPDF from '@salesforce/apex/AAREG_MyApplicationsController.getDecisionPDF';

const COLUMNS = [
  { label: 'Søknadsnummer', fieldName: 'Name', type: 'text', hideDefaultActions: true },
  { label: 'Dato innlevert', fieldName: 'ApplicationSubmittedDate__c', type: 'date', hideDefaultActions: true },
  { label: 'Forventet svar', fieldName: 'ApplicationDeadlineForReply__c', type: 'date', hideDefaultActions: true},
  { label: 'Vedtaksdato', fieldName: 'DecisionDate__c ', type: 'date', hideDefaultActions: true },
  { label: 'Status', fieldName: 'Status__c', type: 'text', hideDefaultActions: true },
  {
    type: 'button',
    fixedWidth: 150,
    typeAttributes: {
      label: 'Se søknad',
      title: 'Se søknad',
      name: 'Søknad',
      variant: 'Brand Outline',
      disabled: {fieldName: 'disableApplication'}    }
  },
  {
    type: 'button',
    fixedWidth: 190,
    typeAttributes: {
      label: 'Last ned vedtak',
      title: 'Last ned vedtak',
      name: 'Last ned',
      variant: 'Brand',
      disabled: {fieldName: 'disableButton'},
      iconName: 'utility:download',
      iconPosition: 'right',
      iconAlternativeText: 'Last ned',
    }
  }
];  

export default class Aareg_myApplications extends NavigationMixin(LightningElement) {
  initialApplications;
  @track applications;
  columns = COLUMNS;
  currentUser = Id;
  navLogoUrl = navLogo;
  selectedStatusFilter = 'ALL';
  statusFilterOptions = [{ label: 'Alle statuser', value: 'ALL' }];
  breadcrumbs = [
    {
      label: 'Min side',
      href: ''
    },
    {
      label: 'Mine søknader',
      href: 'mine-soknader'
    }
  ];

  get isMobile() {
    return window.screen.width < 576;
  }

  get hasApplications() {
    return Array.isArray(this.applications) && this.applications.length > 0;
  }

  get filteredApplications() {
    if (!Array.isArray(this.applications)) {
      return [];
    }
    if (this.selectedStatusFilter === 'ALL') {
      return this.applications;
    }
    return this.applications.filter((row) => row.Status__c === this.selectedStatusFilter);
  }

  get showNoFilteredResults() {
    return this.hasApplications && this.filteredApplications.length === 0;
  }
    
  @wire(getUsersApplications, { userId: '$currentUser' })
  wiredGetUsersApplications(result) {
    if (result.data && result.data.length > 0) {
      this.initialApplications = result.data;
      this.applications = JSON.parse(JSON.stringify(this.initialApplications));
      this.applications.forEach(application => {
        application.disableButton = application.Status__c !== 'Avslag';
        application.disableApplication = !['Venter på svar', 'Utkast'].includes(application.Status__c);
      });
      this.updateStatusFilterOptions(this.applications);
    } else if (result.error) {
      console.error(result.error);
    }
  }

  updateStatusFilterOptions(rows) {
    const uniqueStatuses = [...new Set((rows || [])
      .map((row) => row.Status__c)
      .filter((status) => typeof status === 'string' && status.trim().length > 0))].sort();

    this.statusFilterOptions = [
      { label: 'Alle statuser', value: 'ALL' },
      ...uniqueStatuses.map((status) => ({ label: status, value: status }))
    ];

    const selectedExists = this.statusFilterOptions.some((opt) => opt.value === this.selectedStatusFilter);
    if (!selectedExists) {
      this.selectedStatusFilter = 'ALL';
    }
  }

  handleStatusFilterChange(event) {
    this.selectedStatusFilter = event.detail.value;
  }

  handleRowAction(event) {
    if(event.detail.action.name === 'Søknad') {
        this.viewApplication(event);
    } else if (event.detail.action.name === 'Last ned') {
      this.downloadDecision(event);
    }
  }

  viewApplication(event) {
    const row = event.detail.row;
    let applicationType = 'view';
    let isDraft = false;
    if (row.Status__c === 'Venter på svar' || row.Status__c === 'Utkast') {
      if (row.Status__c === 'Utkast') {
        isDraft = true;
      }
      applicationType = 'edit';
    }
    this[NavigationMixin.Navigate]({
      type: 'standard__recordPage',
      attributes: {
        recordId: row.Id,
        actionName: 'view',
      },
      state: {
        c__applicationType: applicationType,
        c__isDraft: isDraft
      }
    });
  }

  downloadDecision(event) {
    const row = event.detail.row;
    const applicationId = row.Id; 
   
    getDecisionPDF({ applicationId })
    .then((url) => {
      let fullUrl='';
      if (url) {
          // Prepend the domain to the URL
          const siteOrigin = window.location.origin;
          if(siteOrigin === 'https://navdialog--sit2.sandbox.my.site.com') {
              fullUrl = siteOrigin + '/aaregisteret' + url;
          }else{
            fullUrl = siteOrigin + url;
          }

          // Use NavigationMixin to navigate to the URL
          this[NavigationMixin.Navigate]({
              type: 'standard__webPage',
              attributes: {
                  url: fullUrl
              }
          });
      } else {
          console.error('No PDF found for the given Application Decision.');
      }
  })
  .catch((error) => {
      console.error('Error retrieving the PDF:', error);
  });
  }

  navigateToNyMelding(event) {
    event.preventDefault();
    this[NavigationMixin.Navigate]({
      type: 'comm__namedPage',
      attributes: {
        name: 'Mine_Meldinger__c'
      }
    });
  }
}
