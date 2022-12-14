import { LightningElement, wire, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import Id from '@salesforce/user/Id';
import getUsersThreads from '@salesforce/apex/AAREG_MyThreadsController.getUsersThreads';
import { refreshApex } from '@salesforce/apex';

const COLUMNS = [
  { 
    label: 'Henvendelsesnummer', 
    fieldName: 'CRM_HenvendelseId__c', 
    type: 'text', 
    hideDefaultActions: true },
    { 
      label: 'Opprettet dato', 
      fieldName: 'CreatedDate', 
      type: 'date', 
      hideDefaultActions: true },
    { 
        label: 'Siste meldings dato', 
        fieldName: 'CRM_Latest_Message_Datetime__c', 
        type: 'date', 
        hideDefaultActions: true },
  { 
    label: 'Meldingen gjelder', 
    fieldName: 'AAREG_Thread_Subject__c', 
    type: 'text', 
    hideDefaultActions: true },
    
  {
    label: 'Antall uleste meldinger',
    fieldName: 'CRM_Number_of_unread_Messages__c',
    type: 'text',
    hideDefaultActions: true
  },
  {
    type: 'button',
    fixedWidth: 150,
    typeAttributes: {
      label: 'Se melding',
      title: 'Se melding',
      name: 'Thread',
      variant: 'Brand Outline'
    }
  }
];

export default class Aareg_myThreads extends NavigationMixin(LightningElement) {
  @track threads;
  columns = COLUMNS;
  currentUser = Id;
  error;
  breadcrumbs = [
    {
      label: 'Min side',
      href: ''
    },
    {
      label: 'Mine meldinger',
      href: 'mine-meldinger'
    }
  ];

  get isMobile() {
    return window.screen.width < 576;
  }

  renderedCallback() {
    refreshApex(this.threads);
  }

  @wire(getUsersThreads, { userId: '$currentUser' })
  threads(result) {
    if (result.data) {
      if (result.data.length > 0) {
        this.threads = result.data;
      }
      this.error = undefined;
    } else if (result.error) {
      console.error(error);
      this.error = error;
    }
  }

  viewThread(event) {
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
      },
      state: {
        c__fromPage: 'myThreads',
      }
    });
  }
}