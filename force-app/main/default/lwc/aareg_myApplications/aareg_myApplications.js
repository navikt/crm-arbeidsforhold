import { LightningElement, wire, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import Id from '@salesforce/user/Id';
import getUsersApplications from '@salesforce/apex/AAREG_MyApplicationsController.getUsersApplications';

const COLUMNS = [
  { label: 'Søknadsnummer', fieldName: 'Name', type: 'text', hideDefaultActions: true },
  { label: 'Innlevertdato', fieldName: 'ApplicationSubmittedDate__c', type: 'date', hideDefaultActions: true },
  { label: 'Status', fieldName: 'Status__c', type: 'text', hideDefaultActions: true },
  {
    type: 'button',
    fixedWidth: 150,
    typeAttributes: {
      label: 'Se søknad',
      title: 'Se søknad',
      name: 'Søknad',
      variant: 'base'
    }
  }
];

export default class Aareg_myApplications extends NavigationMixin(LightningElement) {
  @track applications;
  columns = COLUMNS;
  currentUser = Id;
  error;

  @wire(getUsersApplications, { userId: '$currentUser' })
  applications(result) {
    if (result.data) {
      if (result.data.length > 0) {
        this.applications = result.data;
      }
      this.error = undefined;
    } else if (result.error) {
      console.error(error);
      this.error = error;
    }
  }

  viewApplication(event) {
    const row = event.detail.row;
    this[NavigationMixin.Navigate]({
      type: 'standard__recordPage',
      attributes: {
        recordId: row.Id,
        actionName: 'view'
      }
    });
  }
}
