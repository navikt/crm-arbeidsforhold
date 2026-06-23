import { LightningElement, track, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import Id from '@salesforce/user/Id';
import getUsersAgreements from '@salesforce/apex/AAREG_MyAgreementsController.getUsersAgreements';
import endAgreement from '@salesforce/apex/AAREG_MyAgreementsController.endAgreement';

import { refreshApex } from '@salesforce/apex';

const COLUMNS = [
  { label: 'Avtalenummer', fieldName: 'avtaleNummer', type: 'text', hideDefaultActions: true },
  { label: 'Avtale dato', fieldName: 'avtaleDato', type: 'date', hideDefaultActions: true },
  { label: 'Status', fieldName: 'status', type: 'text', hideDefaultActions: true },
  {
    type: 'button',
    fixedWidth: 200,
    typeAttributes: {
      label: 'Se kontaktpersoner',
      title: 'Se kontaktpersoner',
      name: 'Kontaktpersoner',
      variant: 'brand-outline'
    }
  },
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
    const actionName = event.detail.action.name;
    this.selectedAgreement = event.detail.row;

    switch (actionName) {
      case 'Kontaktpersoner':
        this[NavigationMixin.Navigate]({
          type: 'comm__namedPage',
          attributes: { name: 'kontaktpersoner__c' },
          state: {
            agreementId: this.selectedAgreement.avtaleId,
            agreementNumber: this.selectedAgreement.avtaleNummer
          }
        });
        break;
      case 'LastNedVedtak':
        this.downloadFile(this.selectedAgreement);
        break;
      case 'AvsluttAvtale':
        this.openEndAgreementModal();
        break;
      default:
        break;
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
  downloadFile(row) {
    if (!row || !row.soknadsNummer) {
      return;
    }
    const siteOrigin = window.location.origin;
   

  }
}