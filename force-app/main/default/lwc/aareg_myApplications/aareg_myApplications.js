import { LightningElement, wire, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import Id from '@salesforce/user/Id';
import navLogo from '@salesforce/resourceUrl/logo';
import getUsersApplications from '@salesforce/apex/AAREG_MyApplicationsController.getUsersApplications';
import getDecisionPDF from '@salesforce/apex/AAREG_MyApplicationsController.getDecisionPDF';

const COLUMNS = [
  { label: 'Søknadsnummer', fieldName: 'Name', type: 'text', hideDefaultActions: true },
  { label: 'Dato innlevert', fieldName: 'ApplicationSubmittedDate__c', type: 'date', hideDefaultActions: true },
  { label: 'Forventet svarfrist', fieldName: 'ApplicationDeadlineForReply__c', type: 'date', hideDefaultActions: true},
  { label: 'Status', fieldName: 'Status__c', type: 'text', hideDefaultActions: true },
  {
    type: 'button',
    fixedWidth: 150,
    typeAttributes: {
      label: 'Se søknad',
      title: 'Se søknad',
      name: 'Søknad',
      variant: 'Brand Outline'
    }
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
    
  @wire(getUsersApplications, { userId: '$currentUser' })
  wiredGetUsersApplications(result) {
    if (result.data && result.data.length > 0) {
      this.initialApplications = result.data;
      this.applications = JSON.parse(JSON.stringify(this.initialApplications));
      this.applications.forEach(application => {
        application.disableButton = application.Status__c !== 'Innvilget' && application.Status__c !== 'Delvis Innvilget' && application.Status__c !== 'Avslag';
      });
    } else if (result.error) {
      console.error(result.error);
    }
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
    const applicationId = row.Id; //
    console.log('Application ID:', applicationId); 

    // Call the Apex method to get the PDF download URL
    getDecisionPDF({ applicationId })
        .then((url) => {
          console.log('Retrieved URL:', url);
          if (url) {
            // Prepend the domain to the URL
            const fullUrl = window.location.origin + url;
            console.log('Full URL:', fullUrl);

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

  /*siteURL = '';
  downloadDecision(event) {
    const row = event.detail.row;
    const siteOrigin = window.location.origin;
    if (siteOrigin === 'https://navdialog--preprod.sandbox.my.site.com') { // Preprod
      this.siteURL = siteOrigin + '/aaregisteret' + '/apex/AAREG_decisionPDF?Id=' + row.Id;
    } else { // Prod
      this.siteURL = siteOrigin + '/apex/AAREG_decisionPDF?Id=' + row.Id;
    }
    window.open = ('url', '_blank');
    window.open(this.siteURL);
  }*/
}
