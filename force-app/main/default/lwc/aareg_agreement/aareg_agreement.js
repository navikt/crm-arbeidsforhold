import { LightningElement, api, wire, track } from 'lwc';
import navLogo from '@salesforce/resourceUrl/logo';
import { NavigationMixin } from 'lightning/navigation';
import { getRecord, getFieldValue} from 'lightning/uiRecordApi';
import NAME from '@salesforce/schema/Agreement__c.Name';
import DECISIONDATE from '@salesforce/schema/Agreement__c.Application__r.DecisionDate__c';
import DECISION from '@salesforce/schema/Agreement__c.Decision__c';
import API_ACCESS from '@salesforce/schema/Agreement__c.APIAccess__c';
import ACCOUNT_NAME from '@salesforce/schema/Agreement__c.AccountName__c';
import ONLINE_ACCESS from '@salesforce/schema/Agreement__c.OnlineAccess__c';
import EVENT_ACCESS from '@salesforce/schema/Agreement__c.EventAccess__c';
import EXTRACTION_ACCESS from '@salesforce/schema/Agreement__c.ExtractionAccess__c';
import ORGANIZATION_NUMBER from '@salesforce/schema/Agreement__c.OrganizationNumber__c';
import DATA_PROCESSOR_NAME from '@salesforce/schema/Agreement__c.DataProcessorName__c';
import DATA_PROCESSOR_ORGNUMBER from '@salesforce/schema/Agreement__c.DataProcessorOrganizationNumber__c';
import getAgreementContacts from '@salesforce/apex/AAREG_AgreementController.getAgreementContacts';
import updateAgreement from '@salesforce/apex/AAREG_AgreementController.updateAgreement';
import cancelAgreement from '@salesforce/apex/AAREG_AgreementController.cancelAgreement';

  
const AGREEMENT_FIELDS = [
  NAME,
  DECISIONDATE,
  DECISION,
  API_ACCESS,
  ACCOUNT_NAME,
  ONLINE_ACCESS,
  EVENT_ACCESS,
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
  navLogoUrl = navLogo;
  @track agreement;
  initialAgreement;
  breadcrumbs = [
    {
      label: 'Min side',
      href: ''
    },
    {
      label: 'Mine avtaler',
      href: 'mine-avtaler'
    },
    {
      label: 'Se avtale',
      href: 'avtale'
    }
  ];

  connectedCallback() {
    this.agreementUpdates = { Id: this.recordId };
  }

  @wire(getRecord, { recordId: '$recordId', fields: AGREEMENT_FIELDS })
  agreementWire({ data, error }) {
    if (data) {
      this.initialAgreement = data;
      this.agreement = JSON.parse(JSON.stringify(this.initialAgreement));
      // Remove image from decision (can't be loaded - violates the Content Security Policy)
      let decisionString = JSON.stringify(this.agreement.fields.Decision__c);
      let subStr1 = decisionString.substring(0, decisionString.indexOf('<img'));
      let subStr2 = decisionString.substring(decisionString.indexOf('</img>')+6, decisionString.length);
      this.agreement.fields.Decision__c = JSON.parse(subStr1 + subStr2);
    } else if (error) {
      console.error(error);
    }
  }

  @wire(getAgreementContacts, { recordId: '$recordId' })
  contacts({ data, error }) {
    if (data) {
      data.forEach((contact) => {
        this.contactRows.push({ uuid: this.createUUID(), ...contact });
      });
    } else if (error) {
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

  hideCancellationPopup = false;
  handleAgreementCancellation() {
    this.hideCancellationPopup = true;
    this.isLoading = true;
    if (this.agreementUpdates.AA_ConfirmedAgreementCancellation__c) {
      cancelAgreement({
        agreement: this.agreementUpdates
      })
        .then((result) => {
          this.showAgreementCancellationConfirmation = true;
        })
        .catch((error) => {
          console.error(error);
        })
        .finally(() => {
          this.isLoading = false;
        });
    }
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

  disableDeactivateAgreementButton = true;
  handleCheckboxChange(event) {
    this.agreementUpdates[event.target.dataset.id] = event.target.checked;
    this.disableDeactivateAgreementButton = !this.agreementUpdates.AA_ConfirmedAgreementCancellation__c;
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

  navigateToMyAgreements() {
    this[NavigationMixin.Navigate]({
      type: 'comm__namedPage',
      attributes: {
        name: 'Mine_Avtaler__c'
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
    let agreementNotification = 0;
    let changeNofiication = 0;
    let errorNotification = 0;
    let securityNotification = 0;

    let contacts = this.template.querySelectorAll('c-aareg_application-contact');

    let error = false;
    contacts.forEach((con, index) => {
      error += con.validate();
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
        return false;
      }
    }

    if (agreementNotification < 1 || changeNofiication < 1 || errorNotification < 1 || securityNotification < 1) {
      let contacts = this.template.querySelector('[data-id="contacts"]');
      this.setErrorFor(contacts, 'Det må oppgis minimum en kontaktperson per type varsling.');
      return false;
    }
    if (error) {
      return false;
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
    return getFieldValue(this.agreement, ONLINE_ACCESS);
  }

  get eventAccess() {
    return getFieldValue(this.agreement, EVENT_ACCESS);
  }

  get extractionAccess() {
    return getFieldValue(this.agreement, EXTRACTION_ACCESS);
  }

  get name() {
    return getFieldValue(this.agreement, NAME);
  }

  get decisionDate() {
    return getFieldValue(this.agreement, DECISIONDATE);
  }

  get decision() {
    return getFieldValue(this.agreement, DECISION);
  }

  get organizationNumber() {
    return getFieldValue(this.agreement, ORGANIZATION_NUMBER);
  }

  get accountName() {
    return getFieldValue(this.agreement, ACCOUNT_NAME);
  }

  get dataProcessorName() {
    return getFieldValue(this.agreement, DATA_PROCESSOR_NAME);
  }

  get dataProcessorOrgNumber() {
    return getFieldValue(this.agreement, DATA_PROCESSOR_ORGNUMBER);
  }

  get isReadOnly() {
    return this.readOnly;
  }

  get editAgreementButtonText() {
    return this.isReadOnly ? 'Redigere avtalen' : 'Avbryt';
  }
}
