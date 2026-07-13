import { LightningElement, track, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import Id from '@salesforce/user/Id';
import getUsersAgreements from '@salesforce/apex/AAREG_MyAgreementsController.getUsersAgreements';
import endAgreement from '@salesforce/apex/AAREG_MyAgreementsController.endAgreement';
import getDecisionPDF from '@salesforce/apex/AAREG_MyAgreementsController.getDecisionPDF';

import { refreshApex } from '@salesforce/apex';

const COLUMNS = [
  { label: 'Avtalenummer', fieldName: 'avtaleNummer', type: 'text', hideDefaultActions: true },
  { label: 'Avtale dato', fieldName: 'avtaleDato', type: 'date', hideDefaultActions: true },
  { label: 'Status', fieldName: 'status', type: 'text', hideDefaultActions: true },
  {
    type: 'button',
    fixedWidth: 200,
    typeAttributes: {
      label: 'Last ned vedtak',
      title: 'Last ned vedtak',
      name: 'LastNedVedtak',
      variant: 'brand',
      iconName: 'utility:download',
      iconPosition: 'right',
      iconAlternativeText: 'Last ned',

    }
  },
  {
    type: 'button',
    fixedWidth: 180,
    typeAttributes: {
      label: 'Avslutt avtale',
      title: 'Avslutt avtale',
      name: 'AvsluttAvtale',
      variant: 'brand-outline',
      disabled: {fieldName: 'disableEndAgreement'}
    }
  }
];

export default class Aareg_myAgreements extends NavigationMixin(LightningElement) {
  @track agreements;
  columns = COLUMNS;
  currentUser = Id;
  error;
  wiredResult;            // holder hele wire-resultatet for refreshApex
  selectedAgreement={};      // raden modalene jobber mot
  siteURL = '';

  breadcrumbs = [
    { label: 'Min side', href: '' },
    { label: 'Mine avtaler', href: 'mine-avtaler' },
    { label: 'Kontaktpersoner', href: 'kontaktpersoner' }
  ];

  get isMobile() {
    return window.screen.width < 576;
  }

  connectedCallback() {
    console.log('parent host tabindex:', this.template.host?.tabIndex);
    this.removeHostTabindex();
  }
  
  renderedCallback() {
    console.log('parent renderedCallback');
    this.removeHostTabindex();
  }

  removeHostTabindex() {
    const host = this.template.host;
    if (host?.getAttribute('tabindex') === '-1') {
      host.removeAttribute('tabindex');
    }
  }

  @wire(getUsersAgreements, { userId: '$currentUser' })
  agreementList(result) {
    this.wiredResult = result;
    if (result.data) {
      this.agreements = result.data.map((row) => ({
        ...row,
        // disabled = true når status IKKE er aktiv
        disableEndAgreement: row.status === 'Avsluttet'
      }));
      this.error = undefined;
    } else if (result.error) {
      console.error(result.error);
      this.error = result.error;
      this.agreements = undefined;
    }
  }

  /* ----------------- Row actions ----------------- */
  handleRowAction(event) {
     if(event.detail.action.name === 'LastNedVedtak') {
        this.downloadDecision(event);
        }else if (event.detail.action.name === 'AvsluttAvtale') {
          this.openEndAgreementModal();
        }
  }


  /* ----------------- Modal helpers ----------------- */
  openEndAgreementModal() {
    this.template.querySelector('c-aareg_modal.end-agreement-modal')?.toggle();
  }

  closeEndAgreementModal() {
    this.template.querySelector('c-aareg_modal.end-agreement-modal')?.toggle();
  }

   /* Avslutt avtale */
   async handleConfirmEndAgreement() {
    if (!this.selectedAgreement || !this.selectedAgreement.avtaleId) {
      return;
    }

    try {
      await endAgreement({ agreementId: this.selectedAgreement.avtaleId });
      await refreshApex(this.wiredResult);
      this.closeEndAgreementModal();
    } catch (err) {
      console.error('Kunne ikke avslutte avtale:', err);
    }
  }

  /* ----------------- Last ned vedtak (PDF) ----------------- */
  downloadDecision(event) {
    const row = event.detail.row;
    const agreementId = row.Id; 
   
    getDecisionPDF({ agreementId })
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
}