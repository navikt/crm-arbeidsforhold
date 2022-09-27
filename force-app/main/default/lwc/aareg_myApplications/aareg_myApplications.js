import { LightningElement, wire, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import Id from '@salesforce/user/Id';
import navLogo from '@salesforce/resourceUrl/logo';
import getUsersApplications from '@salesforce/apex/AAREG_MyApplicationsController.getUsersApplications';
import { loadScript } from 'lightning/platformResourceLoader';
import jspdf from '@salesforce/resourceUrl/jspdf';


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

  renderedCallback() {
    loadScript(this, jspdf)
    .then(() => {
      console.log('loaded jspdf')});
  }
    
  @wire(getUsersApplications, { userId: '$currentUser' })
  wiredGetUsersApplications(result) {
    if (result.data && result.data.length > 0) {
        this.initialApplications = result.data;
        this.applications = JSON.parse(JSON.stringify(this.initialApplications));
        this.applications.forEach(application => {
          application.disableButton = application.AA_CasehandlerDecisionTemplate__c === null || application.AA_CasehandlerDecisionTemplate__c === undefined;
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
    this[NavigationMixin.Navigate]({
      type: 'standard__recordPage',
      attributes: {
        recordId: row.Id,
        actionName: 'view',
      },
      state: {
        c__applicationType: 'view',
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
      this.decision = JSON.parse(subStr1 + subStr2);
      this.template.querySelector('c-aareg_modal[data-id="Decision-Modal"]').toggle();
    }
  }

  // Note: Downloading as application/pdf does not work. Downloads as .htm file
  // Could be solved by downloading and using jsPDF plugin through staticresources
  downloadFile(event) {
    const row = event.detail.row;
    const { jsPDF } = window.jspdf;
    const doc = new jsPDF();
    let blob = new Blob([row.AA_CasehandlerDecisionTemplate__c], {type: 'application/pdf'});
    let reader = new FileReader();
    reader.readAsDataURL(blob); // Converts blob to base64 and calls onload
    reader.onload = (() => {
      doc.text(reader.result, 5, 15);
      doc.save('Vedtak for søknad ' + row.Name + '.pdf');
    });
    
    
    
   
    /*const row = event.detail.row;
    let link = document.createElement('a');
    link.download = 'Vedtak for søknad ' + row.Name;
    let blob = new Blob([row.AA_CasehandlerDecisionTemplate__c], {type: 'text/html'});
    let reader = new FileReader();
    reader.readAsDataURL(blob); // Converts blob to base64 and calls onload
    reader.onload = (() => {
      link.href = reader.result;
      link.click();
    });*/
  }
}
