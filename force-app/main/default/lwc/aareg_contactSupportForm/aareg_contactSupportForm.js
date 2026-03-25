import { LightningElement, track, wire } from 'lwc';
import { NavigationMixin, CurrentPageReference } from 'lightning/navigation';
import { getObjectInfo, getPicklistValues } from 'lightning/uiObjectInfoApi';
import INQUIRY_OBJECT from '@salesforce/schema/Inquiry__c';
import TYPE_FIELD from '@salesforce/schema/Inquiry__c.TypeOfInquiry__c';
import Id from '@salesforce/user/Id';
import getUsersApplications from '@salesforce/apex/AAREG_MyApplicationsController.getUsersApplications';
import createThreadForApplication from '@salesforce/apex/AAREG_contactSupportController.createThreadForApplication';
import createNewInquiry from '@salesforce/apex/AAREG_contactSupportController.createNewInquiry';
import { validateEmail } from 'c/aareg_helperClass';

export default class Aareg_contactSupportForm extends NavigationMixin(LightningElement) {
  @track inquiry;
  @track inquiryTypeOptions;
  selectedApplicationId;
  isSubmitted;
  isReadingFiles = false;
  existingApplications = [];
  isLoading = false;
  currentUser = Id;
  // File upload state (mirrors aareg_application)
  pendingFiles = [];
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
    } else if (result.error) {
      console.error(result.error);
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
//    console.log('🚀 SUBMIT pendingFiles:', JSON.stringify(this.pendingFiles));
    if (this.isReadingFiles) {
    console.warn('⏳ Files are still loading, please wait');
    this.isLoading = false;
    return;
  }
    event.preventDefault();
    this.isLoading = true;
    this.resetErrors();

    const form = this.template.querySelector('form');

    if (!form.checkValidity()) {
      let invalidInputs = form.querySelectorAll(':invalid');
      invalidInputs.forEach((element) => {
        this.setErrorFor(element, 'Obligatorisk');
      });
      // Email validation
      const emailInput = this.template.querySelector('input[data-id="Email__c"]');
      if (emailInput && validateEmail(emailInput.value)) {
        this.setErrorFor(emailInput, 'E-post må være gyldig format.');
      }
      this.isLoading = false;
      return;
    }
    window.scrollTo(0, 0);

    if (this.pendingFiles.some(f => !f.base64)) {
      console.error('❌ Some files missing base64:', this.pendingFiles);
      this.isLoading = false;
      return;
    }

    console.log('pendingFiles which will be sent:', JSON.stringify(this.pendingFiles));
    // Prepare files for submission
    const filesToSend = this.pendingFiles.map(f => ({
      base64: f.base64,
      fileName: f.name
    }));

    if (this.regardingApplicationInProcess) {
      console.log('Calling createThreadForApplication with:', {
        userId: this.currentUser,
        applicationId: this.selectedApplicationId,
        inquiryType: this.inquiry.TypeOfInquiry__c,
        filesCount: filesToSend.length
      });

      createThreadForApplication({
        userId: this.currentUser,
        relatedApplicationId: this.selectedApplicationId,
        description: this.inquiry.InquiryDescription__c,
        inquiryType: this.inquiry.TypeOfInquiry__c,
        subject: this.inquiry.Subject__c,
        files: filesToSend
      })
        .then(() => {
          this.isSubmitted = true;
        })
        .catch((error) => {
          console.error(error);
        })
        .finally(() => {
          this.isLoading = false;
        });
    } else {
      console.log('FilesToSend which will be sent:', JSON.stringify(filesToSend));

      // Logging for debugging - can be removed later
      console.log('Making API Call 1', {
        userId: this.currentUser,
        inquiry: this.inquiry,
        files: filesToSend
      });

      createNewInquiry({
        userId: this.currentUser,
        inquiry: this.inquiry,
        files: filesToSend
      })
        .then(() => {
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

  // Accept standard formats and common document types, but exclude executables for security reasons
  get acceptedFileFormats() {
    return ['.pdf', '.docx', '.xlsx', '.pptx', '.png', '.jpg', '.jpeg', '.txt', '.csv', '.zip'];
  }

  onFileUpload(event) {
    const files = Array.from(event.target.files || []);

    if (files.length === 0) {
      return;
    }

    // Validate total size (max 25MB) and count (max 5)
    const totalSize = files.reduce((sum, f) => sum + (f.size || 0), 0);
    if (totalSize > 25 * 1024 * 1024) {
      this.setErrorFor(this.template.querySelector('[data-id="file-upload"]'), 'Total størrelse på filer kan ikke overstige 25 MB.');
      return;
    }
    if (files.length > 5) {
      this.setErrorFor(this.template.querySelector('[data-id="file-upload"]'), 'Du kan maks laste opp 5 filer.');
      return;
    }

    this.isReadingFiles = true;

    const filePromises = files.map(file => {
      return new Promise((resolve, reject) => {
        const reader = new FileReader();

        reader.onload = () => {
          const result = reader.result;

          if (!result || !result.includes(',')) {
            reject('Invalid file data');
            return;
          }

          const base64 = result.split(',')[1];

          resolve({
            id: Date.now() + Math.random(),
            name: file.name,
            base64: base64
          });
        };

        reader.onerror = reject;
        reader.readAsDataURL(file);
      });
    });

    Promise.all(filePromises)
      .then(results => {
        this.pendingFiles = [...this.pendingFiles, ...results];

        console.debug('✅ Files fully loaded:', this.pendingFiles);
      })
      .catch(error => {
        console.error('❌ File read error:', error);
      })
      .finally(() => {
        this.isReadingFiles = false;
      });

    // Clear the input so same file can be selected again
    event.target.value = '';
  }

  removePendingFile(event) {
    const fileId = event.currentTarget.name;
    this.pendingFiles = this.pendingFiles.filter(f => f.id != fileId);
  }

  get hasOpenApplications() {
    return this.existingApplications.length > 0;
  }

  get inquirySubmitted() {
    return this.isSubmitted;
  }

  navigateToMyMessages() {
    this[NavigationMixin.Navigate]({
      type: 'comm__namedPage',
      attributes: {
        name: 'Mine_Meldinger__c'
      }
    });
  }

  setErrorFor(inputField, message) {
    this.hasErrors = true;
    let formControl = inputField.parentElement;
    let small = formControl.querySelector('small');

    small.innerText = message;
    formControl.className = 'form-control error';

    // Auto-clear after 5 seconds
    setTimeout(() => {
      small.innerText = '';
      formControl.classList.remove('error');
    }, 3000);
  }
}
