import { LightningElement, api } from 'lwc';

export default class aareg_applicationContact extends LightningElement {
  @api record;
  @api readOnly;
  contact;

  renderedCallback() {
    this.name = this.template.querySelector('[data-id="Name"]');
    this.phone = this.template.querySelector('[data-id="Phone__c"]');
    this.email = this.template.querySelector('[data-id="Email__c"]');
    this.agreementNotification = this.template.querySelector('[data-id="AgreementNotifications__c"]');
  }

  connectedCallback() {
    this.initContact();
  }

  initContact() {
    this.contact = {
      uuid: this.record.uuid,
      Id: this.record.Id ? this.record.Id : null,
      Name: this.record.Name ? this.record.Name : null,
      Phone__c: this.record.Phone__c ? this.record.Phone__c : null,
      Email__c: this.record.Email__c ? this.record.Email__c : null,
      AgreementNotifications__c: this.record.AgreementNotifications__c,
      ChangeNotifications__c: this.record.ChangeNotifications__c,
      ErrorMessageNotifications__c: this.record.ErrorMessageNotifications__c,
      SecurityNotifications__c: this.record.SecurityNotifications__c
    };
    this.publishChange();
  }

  /*************** Change handlers ***************/

  handleInputChange(event) {
    this.contact[event.target.dataset.id] = event.target.value;
    this.publishChange();
  }

  handleCheckboxChange(event) {
    this.contact[event.target.dataset.id] = event.target.checked;
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

  /*************** Validation ***************/
  @api
  validate() {
    this.resetErrors();
    if (this.checkNulls(this.contact.Name)) {
      this.setErrorFor(this.name, 'Obligatorisk');
    }
    if (this.checkNulls(this.contact.Phone__c)) {
      this.setErrorFor(this.phone, 'Obligatorisk');
    }
    if (this.checkNulls(this.contact.Email__c)) {
      this.setErrorFor(this.email, 'Obligatorisk');
    }
  }

  @api focusInput() {
    let invalidFields = this.template.querySelector(':invalid');

    if (invalidFields) {
      invalidFields.focus();
      return true;
    }
    return false;
  }

  @api focusAgreementNotification() {
    this.agreementNotification.focus();
  }

  checkNulls(field) {
    if (field === null || field === '') {
      return true;
    } else {
      return false;
    }
  }

  setErrorFor(inputField, message) {
    this.publishError();
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
}
