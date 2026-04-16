// Import core LWC modules and Salesforce utilities
import { LightningElement, track, wire } from 'lwc';
import { NavigationMixin, CurrentPageReference } from 'lightning/navigation';

// Import metadata APIs for object and picklist handling
import { getObjectInfo, getPicklistValues } from 'lightning/uiObjectInfoApi';

// Import schema definitions
import INQUIRY_OBJECT from '@salesforce/schema/Inquiry__c';
import TYPE_FIELD from '@salesforce/schema/Inquiry__c.TypeOfInquiry__c';

// Get current logged-in user Id
import Id from '@salesforce/user/Id';

/**
 * Apex methods for server-side operations
 * - Existing endpoints retained for backward compatibility
 * - New endpoints added for draft Inquiry__c + file relink/enrich flow
 */
import getUsersApplications from '@salesforce/apex/AAREG_MyApplicationsController.getUsersApplications';
import createThreadForApplication from '@salesforce/apex/AAREG_contactSupportController.createThreadForApplication';
import createNewInquiry from '@salesforce/apex/AAREG_contactSupportController.createNewInquiry';

// New Apex endpoints for lightning-file-upload flow
import initDraftRecord from '@salesforce/apex/AAREG_contactSupportController.initDraftRecord';
import createFinalInquiry from '@salesforce/apex/AAREG_contactSupportController.createFinalInquiry';
import relinkFilesToParent from '@salesforce/apex/AAREG_contactSupportController.relinkFilesToParent';
import enrichUploadedFiles from '@salesforce/apex/AAREG_contactSupportController.enrichUploadedFiles';
import removeFileLink from '@salesforce/apex/AAREG_contactSupportController.removeFileLink';

import { validateEmail } from 'c/aareg_helperClass';

export default class Aareg_contactSupportForm extends NavigationMixin(LightningElement) {
  // Reactive state for inquiry form
  @track inquiry;
  // Reactive state for picklist options and user interactions
  @track inquiryTypeOptions;

  // Selected application ID for linking inquiries to existing applications, if applicable
  selectedApplicationId;

  // UI state management
  isSubmitted;
  isReadingFiles = false;
  isInitializingDraft = false;
  isRelinking = false;

  // Store existing applications to determine if user has open applications and to link inquiries to them
  existingApplications = [];
  isLoading = false;

  // Current Logged-in User ID for associating inquiries and threads with the correct user/contact
  currentUser = Id;

  // Legacy pending files (kept for backward compatibility with commented-out uploader)
  pendingFiles = [];

  // New state for lightning-file-upload flow
  draftRecordId; // Temporary Inquiry__c to host uploads pre-submit
  finalRecordId;
  uploadedFiles = []; // [{ documentId, name }]
  acceptedFileFormatsArray = ['.pdf', '.docx', '.xlsx', '.png', '.jpg', '.jpeg'];

  // Breadcrumbs for navigation, dynamically updated based on the user's navigation path to provide context and easy navigation back to relevant pages
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

  // Get the current page reference to determine navigation context and adjust breadcrumbs accordingly, enhancing user experience by 
  // providing relevant navigation options based on how they accessed the form
  @wire(CurrentPageReference)
    currentPageReference;

  // Lifecycle hook to initialize component state and set up breadcrumbs based on navigation context
  connectedCallback() {
    this.inquiry = {
      TypeOfInquiry__c: null,
      InquiryDescription__c: null
    };

    // Do NOT initialize draft Inquiry__c here to prevent premature saving
    // Initialize only when needed (when user starts uploading files or submits)

    if (this.currentPageReference?.state?.c__fromPage === 'myThreads') {
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

  // Fetch the user's applications to determine if they have any open applications that can be linked to the inquiry. 
  // This allows users to easily associate their support requests with relevant applications, providing context for support agents 
  // and streamlining the support process. The data is filtered to exclude draft applications, ensuring that only active or 
  // submitted applications are available for linking.
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

  // Fetch object metadata to get the default record type ID, then fetch picklist values for the 
  // TypeOfInquiry__c field to populate the inquiry type options in the form.
  @wire(getObjectInfo, { objectApiName: INQUIRY_OBJECT })
  inquiryObjectInfo;

  // Fetch picklist values for the TypeOfInquiry__c field based on the default record type ID obtained from the object metadata.
  @wire(getPicklistValues, { recordTypeId: '$inquiryObjectInfo.data.defaultRecordTypeId', fieldApiName: TYPE_FIELD })
  typePicklistValues({ data, error }) {
    if (data) {
      this.inquiryTypeOptions = data.values.map((arr) => ({ ...arr }));
    } else if (error) {
      console.error(error);
    }
  }

  // Handle input changes for form fields and update the inquiry state accordingly. This method uses the data-id attribute on 
  // input fields to determine which field is being updated, allowing for a generic handler that can 
  // manage multiple fields without needing separate handlers for each one.
  handleInputChange(event) {
    this.inquiry[event.target.dataset.id] = event.target.value;
  }

  // Handle changes to the related application selection, updating the selectedApplicationId state. This allows the form to 
  // keep track of which application, if any, the user has chosen to link their inquiry to, providing context for support 
  // agents when they review the inquiry.
  handleRelatedApplicationChange(event) {
    this.selectedApplicationId = event.target.value;
  }

  // Initialize a draft Inquiry__c to use as record-id for lightning-file-upload
  async initializeDraftInquiry() {
    try {
      this.isInitializingDraft = true;
      // Server initializes minimal Inquiry__c (e.g., Status = Draft)
      this.draftRecordId = await initDraftRecord();
    } catch (e) {
      // Surface error to user if needed
      // console.error(e);
    } finally {
      this.isInitializingDraft = false;
    }
  }

  // Handle completion of lightning-file-upload; capture file metadata
  async handleFilesUploaded(event) {
    const files = event?.detail?.files || [];

    // Initialize draft record if not already done
    if (!this.draftRecordId) {
      await this.initializeDraftInquiry();
    }
    
    const mapped = files.map(f => ({ documentId: f.documentId, name: f.name }));
    this.uploadedFiles = [...this.uploadedFiles, ...mapped];
  }

  // Allow removing a file uploaded to the draft Inquiry__c by unlinking
  async handleRemoveUploadedFile(event) {
    const documentId = event.currentTarget?.dataset?.docid;
    if (!documentId || !this.draftRecordId) return;

    try {
      await removeFileLink({ documentId, parentId: this.draftRecordId });
      this.uploadedFiles = this.uploadedFiles.filter(f => f.documentId !== documentId);
    } catch (e) {
      // console.error(e);
    }
  }

  // Handle form submission, including validation and final relink/enrich of uploaded files
  handleSubmit(event) {
    if (this.isReadingFiles) {
      console.warn('⏳ Files are still loading, please wait');
      this.isLoading = false;
      return;
    }
    event.preventDefault();
    this.isLoading = true;

    // Reset any previous error states before validating the form to ensure that users receive accurate feedback based on their current input.
    this.resetErrors();

    const form = this.template.querySelector('form');

    if (!form.checkValidity()) {
      let invalidInputs = form.querySelectorAll(':invalid');
      invalidInputs.forEach((element) => {
        this.setErrorFor(element, 'Obligatorisk');
      });
      // If email field is invalid, set specific error message for email format. This provides users with clear guidance on how to correct 
      // their input, improving the user experience and increasing the likelihood of successful form submission.
      const emailInput = this.template.querySelector('input[data-id="Email__c"]');
      if (emailInput && !validateEmail(emailInput.value)) {
        this.setErrorFor(emailInput, 'E-post må være gyldig format.');
      }
      this.isLoading = false;
      return;
    }

    // Scroll to top of the page to ensure that users see any validation errors or success messages that are displayed after form submission, 
    // improving the user experience by providing immediate feedback in a visible area of the page.
    window.scrollTo(0, 0);

    // For lightning-file-upload flow we no longer read base64 in browser.
    // Keep legacy guard only if pendingFiles are used via the commented uploader.
    if (this.pendingFiles?.length && this.pendingFiles.some(f => !f.base64)) {
      // console.error('❌ Some legacy files missing base64:', this.pendingFiles);
      this.isLoading = false;
      return;
    }

    if (this.regardingApplicationInProcess) {
      console.log('Calling createThreadForApplication with:', {
        userId: this.currentUser,
        applicationId: this.selectedApplicationId,
        inquiryType: this.inquiry.TypeOfInquiry__c,
        filesCount: filesToSend.length
      });

      // If the inquiry is regarding an application in process, create a new thread linked to that application. This allows users to 
      // easily associate their support requests with relevant applications, providing context for support agents and streamlining the support process. 
      // The method also handles file attachments by sending the base64 content and filenames to the server, where they can be processed and linked to the appropriate records.
      // Conditional submission:
      //   - If related to application → create thread
      //   - Else → create new inquiry
      // Application-related path remains as-is; no lightning-file-upload integration here
      const filesToSend = (this.pendingFiles || []).map(f => ({ base64: f.base64, fileName: f.name }));
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
      // New flow:
      // 1) Create/complete the final Inquiry__c from draft + form metadata
      // 2) Relink files from draft -> final parent
      // 3) Enrich ContentVersion Title/Description with form metadata
      const metadata = {
        TypeOfInquiry__c: this.inquiry.TypeOfInquiry__c,
        Subject__c: this.inquiry.Subject__c,
        Email__c: this.inquiry.Email__c,
        InquiryDescription__c: this.inquiry.InquiryDescription__c
      };

      const documentIds = (this.uploadedFiles || []).map(f => f.documentId);

      // Fallback: support legacy base64 submission if no lightning-file-upload files present
      const hasUploadedDocs = documentIds.length > 0;

      (async () => {
        try {
          // Create/complete final Inquiry__c (server will update draft Inquiry__c fields and return its Id)
          this.finalRecordId = await createFinalInquiry({
            draftId: this.draftRecordId,
            metadataJson: JSON.stringify(metadata)
          });

          // If files uploaded via lightning-file-upload, relink and enrich
          if (hasUploadedDocs) {
            this.isRelinking = true;

            await relinkFilesToParent({
              documentIds,
              fromParentId: this.draftRecordId,
              toParentId: this.finalRecordId
            });

            
            await enrichUploadedFiles({
              documentIds,
              recordId: this.finalRecordId,
              metadataJson: JSON.stringify({
                subject: this.inquiry.Subject__c,
                description: this.inquiry.InquiryDescription__c
              })
            });
            
          }

          // Mark submitted and show success UI
          this.isSubmitted = true;
        } catch (error) {
          console.error(error);
        } finally {
          this.isRelinking = false;
          this.isLoading = false;
        }
      })();
    }
  } 

  /**
   * Displays error message under input field
   */
  /*
  setErrorFor(inputField, message) {
    this.hasErrors = true;
    let formControl = inputField.parentElement;
    let small = formControl.querySelector('small');
    small.innerText = message;
    formControl.className = 'form-control error';
  }
  */

  /**
   * Clears all error styles from form
   */
  resetErrors() {
    let formControl = this.template.querySelectorAll('.form-control');
    formControl.forEach((element) => {
      element.classList.remove('error');
    });
  }

  // Getter to determine if the inquiry is regarding an application that is currently in process, based on the selected inquiry type. This allows the form to
  // conditionally render certain fields or adjust the submission logic based on whether the inquiry is related to an active application, providing a more 
  // tailored user experience and ensuring that inquiries are properly categorized and linked to relevant records in the system.
  get regardingApplicationInProcess() {
    return this.inquiry.TypeOfInquiry__c === 'Søknad under behandling';
  }

  // Accept standard formats and common document types, but exclude executables for security reasons
  // TODO: Consider adding or deleting  formats based on user feedback, but always balance with security implications
  get acceptedFileFormats() {
    // Kept for legacy uploader; lightning-file-upload uses acceptedFileFormatsArray
    return ['.pdf', '.docx', '.xlsx', '.png', '.jpg', '.jpeg'];
  }

  // Remove a pending file from the list based on its unique ID. This allows users to manage their file attachments before submitting the form, 
  // giving them control over which files are included with their inquiry and ensuring that they can easily correct any mistakes or changes 
  // in their file selection.
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

  /**
  * Navigate to "My Messages" page
  */

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
