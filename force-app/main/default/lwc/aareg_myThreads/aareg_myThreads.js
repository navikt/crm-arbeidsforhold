import { LightningElement, wire, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import Id from '@salesforce/user/Id';
import getCacheValue from '@salesforce/apex/CacheController.getCacheValue';
import getUsersThreadsForOrganization from '@salesforce/apex/AAREG_MyThreadsController.getUsersThreadsForOrganization';
import getUsersThreadsForPerson from '@salesforce/apex/AAREG_MyThreadsController.getUsersThreadsForPerson'; 
import { refreshApex } from '@salesforce/apex';
import unreadCellStyles from '@salesforce/resourceUrl/AAREG_styles';
import { loadStyle } from 'lightning/platformResourceLoader';

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
    label: 'Uleste meldinger',
    fieldName: 'CRM_Number_of_unread_Messages__c',
    type: 'text',
    hideDefaultActions: true,
    cellAttributes: {
      class: { fieldName: 'unreadClass' },
      alignment: 'center'
    }
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
  wiredThreadsResult;
  columns = COLUMNS;
  currentUser = Id;
  error;
  stylesLoaded = false;
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
  if (this.stylesLoaded) return;
  this.stylesLoaded = true;
  loadStyle(this, unreadCellStyles).catch(err =>
    console.error('Failed to load styles', err)
  );
  }

  async connectedCallback() {
    const representingPerson = await getCacheValue({ key: `${this.currentUser}_representingPerson` });
    if (representingPerson === 'true') {
      this.wiredThreads = getUsersThreadsForPerson({ userId: this.currentUser });
    } else {
      this.wiredThreads = getUsersThreadsForOrganization({ userId: this.currentUser });
    }
  }

  //@wire(getUsersThreadsForOrganization, { userId: '$currentUser' })
  wiredThreads(result) {
    this.wiredThreadsResult = result;
    if (result.data) {
      const rows = result.data.map(r => ({
        ...r,
        unreadClass:
          (r.CRM_Number_of_unread_Messages__c || 0) > 0
            ? 'unread-cell'
            : ''
      }));
      this.threads = rows.length > 0 ? rows : undefined;
      this.error = undefined;
    } else if (result.error) {
      console.error(result.error);
      this.error = result.error;
      this.threads = undefined;
    }
  }

 async viewThread(event) {
    const row = event.detail.row;
    this[NavigationMixin.Navigate]({
      type: 'standard__recordPage',
      attributes: {
        recordId: row.Id,
        actionName: 'view'
      }
    });
    await refreshApex(this.wiredThreadsResult);
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