import { LightningElement, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import Id from '@salesforce/user/Id';
import getUsersThreadsForOrganization from '@salesforce/apex/AAREG_MyThreadsController.getUsersThreadsForOrganization';
import getUsersThreadsForPerson from '@salesforce/apex/AAREG_MyThreadsController.getUsersThreadsForPerson'; 
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
    try {
      const representingPerson = sessionStorage.getItem(`${this.currentUser}_userType`) === 'Employee';
      console.log('Cache key:', `${this.currentUser}_userType`, 'Cache value on connectedCallback:', representingPerson);
      await this.loadThreads(representingPerson);
    } catch (error) {
      console.error(error);
      this.error = error;
      this.threads = undefined;
    }
  }

  async loadThreads(isPerson) {
    try {
      const data = isPerson
        ? await getUsersThreadsForPerson({ userId: this.currentUser })
        : await getUsersThreadsForOrganization({ userId: this.currentUser });

      const rows = data.map(r => ({
        ...r,
        unreadClass:
          (r.CRM_Number_of_unread_Messages__c || 0) > 0
            ? 'unread-cell'
            : ''
      }));
      this.threads = rows.length > 0 ? rows : undefined;
      this.error = undefined;
    } catch (resultError) {
      console.error(resultError);
      this.error = resultError;
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

    try {
      const representingPerson = sessionStorage.getItem(`${this.currentUser}_userType`) === 'Employee';
      console.log('Cache key:', `${this.currentUser}_userType`, 'Cache value on viewThread:', representingPerson);
      await this.loadThreads(representingPerson);
    } catch (error) {
      console.error(error);
      this.error = error;
      this.threads = undefined;
    }
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