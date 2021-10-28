import { LightningElement, api, wire, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { getRecord, getFieldValue} from 'lightning/uiRecordApi';
import NAME from '@salesforce/schema/Agreement__c.Name';
import DECISION from '@salesforce/schema/Agreement__c.Decision__c';
import API_ACCESS from '@salesforce/schema/Agreement__c.APIAccess__c';
import ACCOUNT_NAME from '@salesforce/schema/Agreement__c.AccountName__c';
import ONLINE_ACCESS from '@salesforce/schema/Agreement__c.OnlineAccess__c';
import EXTRACTION_ACCESS from '@salesforce/schema/Agreement__c.ExtractionAccess__c';
import ORGANIZATION_NUMBER from '@salesforce/schema/Agreement__c.OrganizationNumber__c';
import DATA_PROCESSOR_NAME from '@salesforce/schema/Agreement__c.DataProcessorName__c';
import DATA_PROCESSOR_ORGNUMBER from '@salesforce/schema/Agreement__c.DataProcessorOrganizationNumber__c';
import getAgreementContacts from '@salesforce/apex/AAREG_AgreementController.getAgreementContacts';
import updateAgreement from '@salesforce/apex/AAREG_AgreementController.updateAgreement';
import cancelAgreement from '@salesforce/apex/AAREG_AgreementController.cancelAgreement';

const AGREEMENT_FIELDS = [
  NAME,
  DECISION,
  API_ACCESS,
  ACCOUNT_NAME,
  ONLINE_ACCESS,
  EXTRACTION_ACCESS,
  DATA_PROCESSOR_NAME,
  ORGANIZATION_NUMBER,
  DATA_PROCESSOR_ORGNUMBER
];

export default class Aareg_agreement extends NavigationMixin(LightningElement) {
  @api recordId;
  @track agreementUpdates;
  @track contactRows = [];
  contactsToDelete = [];
  readOnly = true;
  isLoading = false;
  showDecision = false;
  showAgreementCancellationConfirmation = false;
  error;

  connectedCallback() {
    this.agreementUpdates = { Id: this.recordId };
  }

  @wire(getRecord, { recordId: '$recordId', fields: AGREEMENT_FIELDS })
  agreement;

  @wire(getAgreementContacts, { recordId: '$recordId' })
  contacts({ data, error }) {
    if (data) {
      data.forEach((contact) => {
        this.contactRows.push({ uuid: this.createUUID(), ...contact });
      });
    } else if (error) {
      this.error = error;
      console.error(error);
    }
  }

  handleSave() {
    this.isLoading = true;
    this.resetErrors();

    if (this.validateContacts()) {
      updateAgreement({
        agreement: this.agreementUpdates,
        contacts: this.contactRows,
        contactsToDelete: this.contactsToDelete
      })
        .then((result) => {
          this.readOnly = true;
        })
        .catch((error) => {
          console.error(error);
        })
        .finally(() => {
          this.isLoading = false;
        });
    } else {
      this.isLoading = false;
    }
    
  }

  handleAgreementCancellation() {
    this.isLoading = true;
    if (this.agreementUpdates.AA_ConfirmedAgreementCancellation__c) {
      cancelAgreement({
        agreement: this.agreementUpdates
      })
        .then((result) => {
          this.toggleEndAgreement();
          this.showAgreementCancellationConfirmation = true;
          console.log(result);
        })
        .catch((error) => {
          console.error(error);
        })
        .finally(() => {
          this.isLoading = false;
        });
    }
    this.isLoading = false;
  }

  toggleDecision() {
    this.template.querySelector('c-aareg_modal[data-id="Decision-Modal"]').toggle();
  }

  toggleEndAgreement() {
    this.template.querySelector('c-aareg_modal[data-id="End-Agreement"]').toggle();
  }

  toggleReadOnly() {
    if (this.readOnly === false) {
      this.navigateToAgreement();
    } else {
      this.readOnly = false;
    }
  }

  handleCheckboxChange(event) {
    this.agreementUpdates[event.target.dataset.id] = event.target.checked;
  }

  contactChange(event) {
    let changedContact = event.detail;
    let foundIndex = this.contactRows.findIndex((element) => element.uuid === changedContact.uuid);
    if (typeof foundIndex !== 'undefined') {
      this.contactRows[foundIndex] = changedContact;
    }
  }

  addContactRow() {
    this.contactRows.push({ uuid: this.createUUID() });
  }

  removeContactRow(event) {
    let contact = this.contactRows[event.target.value];
    if (contact.Id) {
      this.contactsToDelete.push(contact);
      this.contactRows.splice(event.target.value, 1);
    } else {
      this.contactRows.splice(event.target.value, 1);
    }
  }

  navigateToAgreement() {
    this[NavigationMixin.Navigate]({
      type: 'standard__recordPage',
      attributes: {
        recordId: this.recordId,
        objectApiName: 'Agreement__c',
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

  createUUID() {
    let dt = new Date().getTime();
    let uuid = 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function (c) {
      let r = (dt + Math.random() * 16) % 16 | 0;
      dt = Math.floor(dt / 16);
      return (c === 'x' ? r : (r & 0x3) | 0x8).toString(16);
    });
    return uuid;
  }

  /***************** Validation ****************/

  validateContacts() {
    let isValid = false;
    let agreementNotification = 0;
    let changeNofiication = 0;
    let errorNotification = 0;
    let securityNotification = 0;

    let contacts = this.template.querySelectorAll('c-aareg_application-contact');

    contacts.forEach((con, index) => {
      con.validate();
      if (this.contactRows[index].AgreementNotifications__c) {
        agreementNotification += 1;
      }

      if (this.contactRows[index].ChangeNotifications__c) {
        changeNofiication += 1;
      }

      if (this.contactRows[index].ErrorMessageNotifications__c) {
        errorNotification += 1;
      }

      if (this.contactRows[index].SecurityNotifications__c) {
        securityNotification += 1;
      }
    });

    for (let i = 0; i < contacts.length; i++) {
      let isFocused = contacts[i].focusInput();
      if (isFocused) {
        return isValid;
      }
    }

    if (agreementNotification < 1 || changeNofiication < 1 || errorNotification < 1 || securityNotification < 1) {
      console.log('Missing Contact Notifications.');
      let contacts = this.template.querySelector('[data-id="contacts"]');
      this.setErrorFor(contacts, 'Det må oppgis minimum en kontaktperson per type varsling.');
      return isValid;
    }

    return true;
  }

  setErrorFor(inputField, message) {
    this.hasErrors = true;
    let formControl = inputField.parentElement;
    let small = formControl.querySelector('small');
    small.innerText = message;
    formControl.className = 'form-control error';
  }

  resetErrors() {
    let formControl = this.template.querySelectorAll('.form-control');
    formControl.forEach((element) => {
      element.classList.remove('error');
    });
  }

  get showContactRemove() {
    return this.contactRows.length > 1 && !this.isReadOnly;
  }

  get apiAccess() {
    return getFieldValue(this.agreement, API_ACCESS);
  }

  get onlineAccess() {
    return getFieldValue(this.agreement.data, ONLINE_ACCESS);
  }

  get extractionAccess() {
    return getFieldValue(this.agreement.data, EXTRACTION_ACCESS);
  }

  get name() {
    return getFieldValue(this.agreement.data, NAME);
  }

  get decision() {
    return getFieldValue(this.agreement.data, DECISION);
  }

  get organizationNumber() {
    return getFieldValue(this.agreement.data, ORGANIZATION_NUMBER);
  }

  get accountName() {
    return getFieldValue(this.agreement.data, ACCOUNT_NAME);
  }

  get dataProcessorName() {
    return getFieldValue(this.agreement.data, DATA_PROCESSOR_NAME);
  }

  get dataProcessorOrgNumber() {
    return getFieldValue(this.agreement.data, DATA_PROCESSOR_ORGNUMBER);
  }

  get isReadOnly() {
    return this.readOnly;
  }

  get editAgreementButtonText() {
    return this.isReadOnly ? 'Redigere avtalen' : 'Avbryt';
  }
}
