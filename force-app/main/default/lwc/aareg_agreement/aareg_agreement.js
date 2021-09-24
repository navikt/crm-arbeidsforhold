import { LightningElement, api, wire, track } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import NAME from '@salesforce/schema/Agreement__c.Name';
import DECISION from '@salesforce/schema/Agreement__c.Decision__c';
import API_ACCESS from '@salesforce/schema/Agreement__c.APIAccess__c';
import ONLINE_ACCESS from '@salesforce/schema/Agreement__c.OnlineAccess__c';
import EXTRACTION_ACCESS from '@salesforce/schema/Agreement__c.ExtractionAccess__c';
import ORGANIZATION_NUMBER from '@salesforce/schema/Agreement__c.OrganizationNumber__c';
import getAgreementContacts from '@salesforce/apex/AAREG_AgreementController.getAgreementContacts';

const AGREEMENT_FIELDS = [NAME, API_ACCESS, EXTRACTION_ACCESS, ONLINE_ACCESS, DECISION, ORGANIZATION_NUMBER];

export default class Aareg_agreement extends LightningElement {
  @api recordId;
  @track contactRows = [];
  readOnly = true;
  showDecision = false;
  error;

  @wire(getRecord, { recordId: '$recordId', fields: AGREEMENT_FIELDS })
  agreement;

  @wire(getAgreementContacts, { recordId: '$recordId' })
  contacts(result) {
    if (result.data) {
      console.log(result.data);
      console.log(result.data.length);
      if (result.data.length) {
        console.log('Has data');
        result.data.forEach((contact) => {
          this.contactRows.push({ uuid: this.createUUID(), ...contact });
        });
      }
      console.log('contact rows', this.contactRows);
    } else if (result.error) {
      this.error = result.error;
      console.error(result.error);
    }
  }

  toggleDecision() {
    this.showDecision === false ? (this.showDecision = true) : (this.showDecision = false);
  }

  toggleReadOnly() {
    this.readOnly === false ? (this.readOnly = true) : (this.readOnly = false);
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

  get apiAccess() {
    return getFieldValue(this.agreement.data, API_ACCESS);
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

  get isReadOnly() {
    return this.readOnly;
  }
}
