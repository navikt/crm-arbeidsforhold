import { LightningElement, track, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import Id from '@salesforce/user/Id';
import getUsersAgreements from '@salesforce/apex/AAREG_MyAgreementsController.getUsersAgreements';
import { refreshApex } from '@salesforce/apex';

const COLUMNS = [
  { label: 'Avtalenummer', fieldName: 'Name', type: 'text', hideDefaultActions: true },
  { label: 'Status', fieldName: 'Status__c', type: 'text', hideDefaultActions: true },
  {
    type: 'button',
    fixedWidth: 150,
    typeAttributes: {
      label: 'Se avtale',
      title: 'Se søknad',
      name: 'Avtale',
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
      iconName: 'utility:download',
      iconPosition: 'right',
      iconAlternativeText: 'Last ned',
    }
  }
];

export default class Aareg_myAgreements extends NavigationMixin(LightningElement) {
  @track agreements;
  columns = COLUMNS;
  currentUser = Id;
  error;
  breadcrumbs = [
    {
      label: 'Min side',
      href: ''
    },
    {
      label: 'Mine avtaler',
      href: 'mine-avtaler'
    }
  ];

  get isMobile() {
    return window.screen.width < 576;
  }

  renderedCallback() {
    refreshApex(this.agreements);
  }

  @wire(getUsersAgreements, { userId: '$currentUser' })
  agreementList(result) {
    if (result.data) {
      if (result.data.length > 0) {
        this.agreements = result.data;
      }
      this.error = undefined;
    } else if (result.error) {
      console.error(error);
      this.error = error;
    }
  }

  handleRowAction(event) {
    if(event.detail.action.name === 'Avtale') {
      this.viewAgreement(event);
    } else if (event.detail.action.name === 'Last ned') {
      this.downloadFile(event);
    }
  }

  viewAgreement(event) {
    const row = event.detail.row;
    this[NavigationMixin.Navigate]({
      type: 'standard__recordPage',
      attributes: {
        recordId: row.Id,
        actionName: 'view'
      }
    });
  }

  siteURL = '';
  downloadFile(event) {
    const row = event.detail.row;
    const siteOrigin = window.location.origin;
    if (siteOrigin === 'https://navdialog--preprod.sandbox.my.site.com') { // Preprod
      this.siteURL = siteOrigin + '/aaregisteret' + '/apex/AAREG_decisionPDF?Id=' + row.Application__c;
    } else { // Prod
      this.siteURL = siteOrigin + '/apex/AAREG_decisionPDF?Id=' + row.Id;
    }
    console.log(this.siteURL);
    window.open(this.siteURL);
  }
}
