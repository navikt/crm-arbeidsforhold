import { LightningElement, api } from 'lwc';

export default class aareg_applicationContact extends LightningElement {
  @api record;
  contact;

  renderedCallback() {
    this.name = this.template.querySelector('[data-id="name"]');
    this.phone = this.template.querySelector('[data-id="phone"]');
    this.email = this.template.querySelector('[data-id="email"]');
  }

  connectedCallback() {
    this.initContact();
  }

  initContact() {
    this.contact = {
      uuid: this.record.uuid,
      Name: null,
      Phone__c: null,
      Email__c: null,
      AgreementNotifications__c: false,
      ChangeNotifications__c: false,
      ErrorMessageNotifications__c: false,
      SecurityNotifications__c: false
    };
    this.publishChange();
  }

  /*************** Change handlers ***************/

  handleChange(event) {
    switch (event.target.dataset.id) {
      case 'name':
        this.contact.Name = event.target.value;
        break;
      case 'phone':
        this.contact.Phone__c = event.target.value;
        break;
      case 'email':
        this.contact.Email__c = event.target.value;
        break;
      case 'agreement':
        this.contact.AgreementNotifications__c = this.isChecked(this.agreementNotifications);
        break;
      case 'change':
        this.contact.ChangeNotifications__c = this.isChecked(this.changeNotifications);
        break;
      case 'error':
        this.contact.ErrorMessageNotifications__c = this.isChecked(this.errorMessageNotifications);
        break;
      case 'security':
        this.contact.SecurityNotifications__c = this.isChecked(this.securityNotifications);
        break;
      default:
        return;
    }
    this.publishChange();
  }

  publishChange() {
    const changeEvent = new CustomEvent('contactchange', { detail: this.contact });
    this.dispatchEvent(changeEvent);
  }

  publishError() {
    const changeEvent = new CustomEvent('validationerror', { detail: true });
    this.dispatchEvent(changeEvent);
  }

  isChecked(fieldName) {
    if (fieldName) {
      return false;
    } else {
      return true;
    }
  }

  /*************** Validation ***************/
  @api
  validate() {
    if (this.contact.Name === null || '') {
      this.setErrorFor(this.name, 'Navn er obligatorisk');
    }
    if (this.contact.Phone__c === null || '') {
      this.setErrorFor(this.phone, 'Telefonnummer er obligatorisk');
    }
    if (this.contact.Email__c === null || '') {
      this.setErrorFor(this.email, 'E-post er obligatorisk');
    }
  }

  setErrorFor(inputField, message) {
    this.publishError();
    let formControl = inputField.parentElement;
    let small = formControl.querySelector('small');
    small.innerText = message;
    formControl.className = 'form-control error';
  }
}
