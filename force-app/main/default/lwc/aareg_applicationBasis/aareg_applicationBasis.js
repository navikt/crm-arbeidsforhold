import { LightningElement, track, wire, api } from 'lwc';
import { getObjectInfo, getPicklistValuesByRecordType } from 'lightning/uiObjectInfoApi';
import APPLICATION_BASIS_CODE_OBJECT from '@salesforce/schema/ApplicationBasisCode__c';

export default class Aareg_applicationBasis extends LightningElement {
  @api record;
  @api readOnly;
  @api organizationType;
  @track purposeOptions;
  @track legalBasisOptions;
  purposeFieldName;
  legalBasisFieldName;
  applicationBasis;
  isOtherOrganizationType = false;
  legalBasisRemovedValuePlaceholder;

  connectedCallback() {
    this.setPicklistFieldNames();
    this.init();
  }

  renderedCallback() {
    this.purpose = this.template.querySelector('[data-id="purpose"]');
    this.legalBasis = this.template.querySelector('[data-id="legal-basis"]');
    this.otherLegalBasis = this.template.querySelector('[data-id="other-legal-basis"]');
    this.otherPurpose = this.template.querySelector('[data-id="other-purpose"]');
    this.processingBasis = this.template.querySelector('[data-id="processing-basis"]');
  }

  get legalBasisValue() {
    return this.applicationBasis[this.legalBasisFieldName];
  }

  get purposeValue() {
    return this.applicationBasis[this.purposeFieldName];
  }

  get showOtherInput() {
    return (
      this.isOtherOrganizationType ||
      this.applicationBasis[this.legalBasisFieldName] === 'Annet - oppgi i tekstfelt under'
    );
  }

  init() {
    this.applicationBasis = {
      uuid: this.record.uuid,
      Id: this.record.Id ? this.record.Id : null,
      OrganizationType__c: this.organizationType,
      LegalBasisMunicipality__c: this.record.LegalBasisMunicipality__c ? this.record.LegalBasisMunicipality__c : null,
      PurposeMunicipality__c: this.record.PurposeMunicipality__c ? this.record.PurposeMunicipality__c : null,
      LegalBasisCounty__c: this.record.LegalBasisCounty__c ? this.record.LegalBasisCounty__c : null,
      PurposeCounty__c: this.record.PurposeCounty__c ? this.record.PurposeCounty__c : null,
      LegalBasisState__c: this.record.LegalBasisState__c ? this.record.LegalBasisState__c : null,
      PurposeState__c: this.record.PurposeState__c ? this.record.PurposeState__c : null,
      LegalBasisPension__c: this.record.LegalBasisPension__c ? this.record.LegalBasisPension__c : null,
      PurposePension__c: this.record.PurposePension__c ? this.record.PurposePension__c : null,
      OtherLegalBasis__c: this.record.OtherLegalBasis__c ? this.record.OtherLegalBasis__c : null,
      OtherPurpose__c: this.record.OtherPurpose__c ? this.record.OtherPurpose__c : null,
      ProcessingBasis__c: this.record.ProcessingBasis__c ? this.record.ProcessingBasis__c : null,
      LegalBasisElectricitySupervision__c: this.record.LegalBasisElectricitySupervision__c
        ? this.record.LegalBasisElectricitySupervision__c
        : null,
      PurposeElectricitySupervision__c: this.record.PurposeElectricitySupervision__c
        ? this.record.PurposeElectricitySupervision__c
        : null
    };
    this.publishChange();
  }

  @wire(getObjectInfo, { objectApiName: APPLICATION_BASIS_CODE_OBJECT })
  basisCodeInfo;

  @wire(getPicklistValuesByRecordType, {
    objectApiName: APPLICATION_BASIS_CODE_OBJECT,
    recordTypeId: '$basisCodeInfo.data.defaultRecordTypeId'
  })
  applicationBasisPicklists({ data, error }) {
    if (data) {
      this.legalBasisOptions = data.picklistFieldValues[this.legalBasisFieldName].values.map((arr) => ({ ...arr }));
      this.legalBasisOptions.forEach((el, index) => {
        if (el.value === this.applicationBasis[this.legalBasisFieldName]) {
          this.legalBasisOptions.splice(index, 1);
          this.legalBasisOptions.unshift(el);
        }
      });
      this.purposeData = data.picklistFieldValues[this.purposeFieldName];
    } else if (error) {
      console.error(error);
    }
  }

  setPicklistFieldNames() {
    switch (this.organizationType) {
      case 'Municipality':
        this.purposeFieldName = 'PurposeMunicipality__c';
        this.legalBasisFieldName = 'LegalBasisMunicipality__c';
        break;
      case 'County':
        this.purposeFieldName = 'PurposeCounty__c';
        this.legalBasisFieldName = 'LegalBasisCounty__c';
        break;
      case 'State':
        this.purposeFieldName = 'PurposeState__c';
        this.legalBasisFieldName = 'LegalBasisState__c';
        break;
      case 'Electricity Supervision':
        this.purposeFieldName = 'PurposeElectricitySupervision__c';
        this.legalBasisFieldName = 'LegalBasisElectricitySupervision__c';
        break;
      case 'Pension':
        this.purposeFieldName = 'PurposePension__c';
        this.legalBasisFieldName = 'LegalBasisPension__c';
        break;
      case 'Other':
        this.isOtherOrganizationType = true;
        break;
      default:
        break;
    }
  }

  /*************** Change handlers ***************/

  handleLegalBasisChange(event) {
    let key = this.purposeData.controllerValues[event.target.value];
    this.purposeOptions = this.purposeData.values.filter((opt) => opt.validFor.includes(key));
    this.applicationBasis[this.legalBasisFieldName] = event.target.value;

    if (event.target.value === 'Annet - oppgi i tekstfelt under') {
      this.applicationBasis[this.purposeFieldName] = 'Annet - oppgi i tekstfelt under';
    } else {
      this.applicationBasis[this.purposeFieldName] = '';
    }

    this.publishChange();
  }

  handlePurposeChange(event) {
    this.applicationBasis[this.purposeFieldName] = event.target.value;
    this.publishChange();
  }

  handleInputChange(event) {
    switch (event.target.dataset.id) {
      case 'other-legal-basis':
        this.applicationBasis.OtherLegalBasis__c = event.target.value;
        break;
      case 'other-purpose':
        this.applicationBasis.OtherPurpose__c = event.target.value;
        break;
      case 'processing-basis':
        this.applicationBasis.ProcessingBasis__c = event.target.value;
        break;
      default:
        return;
    }
    this.publishChange();
  }

  publishChange() {
    const changeEvent = new CustomEvent('applicationbasischange', { detail: this.applicationBasis });
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

    if (!this.isOtherOrganizationType && this.checkNulls(this.applicationBasis[`${this.legalBasisFieldName}`])) {
      this.setErrorFor(this.legalBasis, 'Obligatorisk');
      this.legalBasis.setCustomValidity('Obligatorisk');
    }

    if (!this.isOtherOrganizationType && this.checkNulls(this.applicationBasis[`${this.purposeFieldName}`])) {
      this.setErrorFor(this.purpose, 'Obligatorisk');
      this.purpose.setCustomValidity('Obligatorisk');
    }

    if (this.checkNulls(this.applicationBasis.ProcessingBasis__c)) {
      this.setErrorFor(this.processingBasis, 'Obligatorisk');
      this.processingBasis.setCustomValidity('Obligatorisk');
    }

    if (
      (this.isOtherOrganizationType ||
        this.applicationBasis[`${this.purposeFieldName}`] === 'Annet - oppgi i tekstfelt under') &&
      this.checkNulls(this.applicationBasis.OtherPurpose__c)
    ) {
      this.setErrorFor(this.otherPurpose, 'Obligatorisk');
      this.otherPurpose.setCustomValidity('Obligatorisk');
    }

    if (
      (this.isOtherOrganizationType ||
        this.applicationBasis[`${this.legalBasisFieldName}`] === 'Annet - oppgi i tekstfelt under') &&
      this.checkNulls(this.applicationBasis.OtherLegalBasis__c)
    ) {
      this.setErrorFor(this.otherLegalBasis, 'Obligatorisk');
      this.otherLegalBasis.setCustomValidity('Obligatorisk');
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
