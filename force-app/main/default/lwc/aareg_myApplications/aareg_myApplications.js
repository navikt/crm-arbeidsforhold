import { LightningElement, wire, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import Id from '@salesforce/user/Id';
import navLogo from '@salesforce/resourceUrl/logo';
import getUsersApplications from '@salesforce/apex/AAREG_MyApplicationsController.getUsersApplications';

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
    fixedWidth: 150,
    typeAttributes: {
      label: 'Se vedtak',
      title: 'Se vedtak',
      name: 'Vedtak',
      variant: 'Brand Outline',
      disabled: {fieldName: 'disableButton'}
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
    } else if (event.detail.action.name === 'Vedtak') {
        this.viewDecision(event);
    } else if (event.detail.action.name === 'Last ned') {
      this.downloadFile(event);
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

  @track decision;
  viewDecision(event) {
    const row = event.detail.row;
    if (row.AA_CasehandlerDecisionTemplate__c !== null && row.AA_CasehandlerDecisionTemplate__c !== undefined) {
      this.decision = row.AA_CasehandlerDecisionTemplate__c;
      // Remove first image (NAV Logo) from decision (can't be loaded - violates the Content Security Policy)
      let decisionString = JSON.stringify(this.decision);
      let subStr1 = decisionString.substring(0, decisionString.indexOf('<img'));
      let subStr2 = decisionString.substring(decisionString.indexOf('</img>')+6, decisionString.length);
      if (subStr1 !== '' && subStr2 !== '') {
        this.decision = JSON.parse(subStr1 + subStr2);
      }
      this.template.querySelector('c-aareg_modal[data-id="Decision-Modal"]').toggle();
    }
  }

  siteURL = '';
  downloadFile(event) {
    const row = event.detail.row;
    const siteOrigin = window.location.origin;
    if (siteOrigin === 'https://navdialog--preprod.sandbox.my.site.com') { // Preprod
      this.siteURL = siteOrigin + '/aaregisteret' + '/apex/AAREG_decisionPDF?Id=' + row.Id;
    } else { // Prod
      this.siteURL = siteOrigin + '/apex/AAREG_decisionPDF?Id=' + row.Id;
    }
    console.log(this.siteURL);
    window.open(this.siteURL);
  }
}
