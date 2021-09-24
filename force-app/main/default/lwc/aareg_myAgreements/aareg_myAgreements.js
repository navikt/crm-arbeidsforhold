import { LightningElement, track, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import Id from '@salesforce/user/Id';
import getUsersAgreements from '@salesforce/apex/AAREG_MyAgreementsController.getUsersAgreements';

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
      variant: 'base'
    }
  }
];

export default class Aareg_myAgreements extends NavigationMixin(LightningElement) {
  @track agreements;
  columns = COLUMNS;
  currentUser = Id;
  error;

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

  navigateToPage(event) {
    const page = event.target.name;
    this[NavigationMixin.Navigate]({
      type: 'comm__namedPage',
      attributes: {
        name: page
      }
    });
  }
}
