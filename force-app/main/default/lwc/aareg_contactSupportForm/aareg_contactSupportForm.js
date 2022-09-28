import { LightningElement, track, wire } from 'lwc';
import { NavigationMixin, CurrentPageReference } from 'lightning/navigation';
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
  breadcrumbs = [
    {
      label: 'Min side',
      href: ''
    },
    {
      label: 'Ny melding',
      href: 'ny-melding'
    }
  ];

  @wire(CurrentPageReference)
    currentPageReference;

  connectedCallback() {
    this.inquiry = {
      TypeOfInquiry__c: null,
      InquiryDescription__c: null
    };
    if (this.currentPageReference.state.c__fromPage === 'myThreads') {
      this.breadcrumbs = [
        {
          label: 'Min side',
          href: ''
        },
        {
          label: 'Mine meldinger',
          href: 'mine-meldinger'
        },
        {
          label: 'Ny melding',
          href: 'ny-melding'
        }
      ];
    }
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
      this.inquiryTypeOptions = data.values.map((arr) => ({ ...arr }));
    } else if (error) {
      console.error(error);
    }
  }

  handleInputChange(event) {
    this.inquiry[event.target.dataset.id] = event.target.value;
  }

  handleRelatedApplicationChange(event) {
    this.selectedApplicationId = event.target.value;
  }

  handleSubmit(event) {
    event.preventDefault();
    this.isLoading = true;
    this.resetErrors();

    const form = this.template.querySelector('form');

    if (!form.checkValidity()) {
      let invalidInputs = form.querySelectorAll(':invalid');
      invalidInputs.forEach((element) => {
        this.setErrorFor(element, 'Obligatorisk');
      });
      this.isLoading = false;
      return;
    }

    if (this.regardingApplicationInProcess) {
      createThreadForApplication({
        userId: this.currentUser,
        relatedApplicationId: this.selectedApplicationId,
        description: this.inquiry.InquiryDescription__c,
        inquiryType: this.inquiry.TypeOfInquiry__c,
        subject: this.inquiry.subject__c
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

  get regardingApplicationInProcess() {
    return this.inquiry.TypeOfInquiry__c === 'Søknad under behandling';
  }

  get hasOpenApplications() {
    return this.existingApplications.length > 0;
  }

  get inquirySubmitted() {
    return this.isSubmitted;
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
}
