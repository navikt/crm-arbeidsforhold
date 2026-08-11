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
      disabled: { fieldName: 'disableDownloadDecision' }
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
  selectedStatusFilter = 'ALL';
  statusFilterOptions = [{ label: 'Alle statuser', value: 'ALL' }];
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

  get hasAgreements() {
    return Array.isArray(this.agreements) && this.agreements.length > 0;
  }

  get filteredAgreements() {
    if (!Array.isArray(this.agreements)) {
      return [];
    }
    if (this.selectedStatusFilter === 'ALL') {
      return this.agreements;
    }
    return this.agreements.filter((row) => row.status === this.selectedStatusFilter);
  }

  get hasFilteredAgreements() {
    return this.filteredAgreements.length > 0;
  }

  get showNoFilteredResults() {
    return this.hasAgreements && !this.hasFilteredAgreements;
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
      this.processAgreements(result.data);
      this.error = undefined;
    } else if (result.error) {
      console.error(result.error);
      this.error = result.error;
      this.agreements = undefined;
    }
  }

  async processAgreements(data) {
    const agreementsWithPdfStatus = await Promise.all(
      data.map(async (row) => {
        let hasPdf = false;
        try {
          const pdfUrl = await getDecisionPDF({ agreementId: row.avtaleId });
          hasPdf = !!pdfUrl;
        } catch (err) {
          // Ingen PDF funnet, hold hasPdf som false
          hasPdf = false;
        }
        return {
          ...row,
          disableEndAgreement: row.status === 'Avsluttet',
          disableDownloadDecision: !hasPdf
        };
      })
    );
    this.agreements = agreementsWithPdfStatus;
    this.updateStatusFilterOptions(agreementsWithPdfStatus);
  }

  updateStatusFilterOptions(rows) {
    const uniqueStatuses = [...new Set((rows || [])
      .map((row) => row.status)
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



  /* ----------------- Row actions ----------------- */
  handleRowAction(event) {
      this.selectedAgreement = event.detail.row;

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
      console.error('Mangler valgt avtale ved avslutting av avtale.', this.selectedAgreement);
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
    const agreementId = row?.avtaleId;

    if (!agreementId) {
      console.error('Mangler avtaleId i valgt rad ved nedlasting av vedtak.', row);
      return;
    }
   
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