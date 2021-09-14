import { LightningElement, track, wire } from 'lwc';
import { getObjectInfo, getPicklistValues } from 'lightning/uiObjectInfoApi';
import INQUIRY_OBJECT from '@salesforce/schema/Inquiry__c';
import TYPE_FIELD from '@salesforce/schema/Inquiry__c.TypeOfInquiry__c';
import Id from '@salesforce/user/Id';
import getUsersApplications from '@salesforce/apex/AAREG_MyApplicationsController.getUsersApplications';
import createThreadForApplication from '@salesforce/apex/AAREG_contactSupportController.createThreadForApplication';
import createNewInquiry from '@salesforce/apex/AAREG_contactSupportController.createNewInquiry';

export default class Aareg_contactSupportForm extends LightningElement {
  @track inquiry;
  @track inquiryTypeOptions;
  selectedApplicationId;
  isSubmitted;
  error;
  existingApplications = [];
  isLoading = false;

  currentUser = Id;

  connectedCallback() {
    this.inquiry = {
      TypeOfInquiry__c: null,
      InquiryDescription__c: null
    };
  }

  @wire(getUsersApplications, { userId: '$currentUser' })
  applications(result) {
    if (result.data) {
      if (result.data.length > 0) {
        this.existingApplications = result.data
          .map((arr) => ({ ...arr }))
          .filter((item) => {
            return item.Status__c !== 'Utkast';
          });
      }
      this.error = undefined;
    } else if (result.error) {
      console.error(error);
      this.error = error;
    }
  }

  @wire(getObjectInfo, { objectApiName: INQUIRY_OBJECT })
  inquiryObjectInfo;

  @wire(getPicklistValues, { recordTypeId: '$inquiryObjectInfo.data.defaultRecordTypeId', fieldApiName: TYPE_FIELD })
  typePicklistValues({ data, error }) {
    if (data) {
      console.log(data.values);
      this.inquiryTypeOptions = data.values.map((arr) => ({ ...arr }));
      console.log(this.inquiryTypeOptions);
    } else if (error) {
      console.error(error);
    }
  }

  handleInputChange(event) {
    this.inquiry[event.target.dataset.id] = event.target.value;
    console.log(this.inquiry);
  }

  handleRelatedApplicationChange(event) {
    this.selectedApplicationId = event.target.value;
  }

  handleSubmit(event) {
    event.preventDefault();
    this.isLoading = true;

    if (this.regardingApplicationInProcess) {
      createThreadForApplication({
        userId: this.currentUser,
        relatedApplicationId: this.selectedApplicationId,
        description: this.inquiry.InquiryDescription__c
      })
        .then((result) => {
          this.isSubmitted = true;
        })
        .catch((error) => {
          console.error(error);
        })
        .finally(() => {
          this.isLoading = false;
        });
    } else {
      createNewInquiry({
        userId: this.currentUser,
        inquiry: this.inquiry
      })
        .then((result) => {
          this.isSubmitted = true;
        })
        .catch((error) => {
          console.error(error);
        })
        .finally(() => {
          this.isLoading = false;
        });
    }
  }

  get regardingApplicationInProcess() {
    return this.inquiry.TypeOfInquiry__c === 'Søknad under behandling';
  }

  get hasOpenApplications() {
    return this.existingApplications.length > 0;
  }

  get inquirySubmitted() {
    return this.isSubmitted;
  }
}
