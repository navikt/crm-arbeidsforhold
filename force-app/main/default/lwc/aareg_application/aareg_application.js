import { LightningElement, track, api, wire } from 'lwc';
import { NavigationMixin, CurrentPageReference } from 'lightning/navigation';
import Id from '@salesforce/user/Id';
import processApplication from '@salesforce/apex/AAREG_ApplicationController.processApplication';
import getLastUsedOrganizationInformation from '@salesforce/apex/AAREG_ApplicationController.getLastUsedOrganizationInformation';
import getDraftApplication from '@salesforce/apex/AAREG_ApplicationController.getDraftApplication';
import getAccountNameByOrgNumber from '@salesforce/apex/AAREG_ApplicationController.getAccountNameByOrgNumber';
import deleteDraftRecord from '@salesforce/apex/AAREG_ApplicationController.deleteDraftRecord';
import saveAsDraft from '@salesforce/apex/AAREG_ApplicationController.saveAsDraft';
import getUserRights from '@salesforce/apex/AAREG_CommunityUtils.getUserRights';
import { validateEmail } from 'c/aareg_helperClass';

export default class Aareg_application extends NavigationMixin(LightningElement) {
  @api recordId;
  @api hasErrors;
  @api linkToDataElements;
  @api linkToTermsOfUse;
  @track application;
  @track organization;
  @track contactRows = [];
  @track applicationBasisRows = [];
  currentUser = Id;
  hasAccess = false;
  isReadOnly = false;
  applicationSubmitted = false;
  lastUsedOrganization;
  organizationType;
  isLoaded = false;
  fileData = { base64: null, filename: null };
  error;
  @track numPops = 3;
  breadcrumbs = [
    {
      label: 'Min side',
      href: ''
    },
    {
      label: 'Mine søknader',
      href: 'mine-soknader'
    },
    {
      label: 'Se søknad',
      href: 'soknad'
    }
  ];

  @wire(CurrentPageReference)
    currentPageReference;

  connectedCallback() {
    this.init();
    this.setBreadcrumbs();
  }

  get isEditForCheckbox() {
    return this.isEdit && !this.isDraft;
  }
  isEdit = false;
  isDraft = false;
  setBreadcrumbs() {
    if (this.currentPageReference.state.c__applicationType !== 'view' && this.currentPageReference.state.c__applicationType !== 'edit') {
      this.isEdit = false;
      this.breadcrumbs = [
        {
          label: 'Min side',
          href: ''
        },
        {
          label: 'Ny søknad',
          href: 'soknad'
        }
      ];
      this.currentPageReference.state.c__applicationType === 'default' ? this.numPops = 3 : this.numPops = 1;
    }
    if (this.currentPageReference.state.c__applicationType === 'edit') {
      this.isDraft = this.currentPageReference.state.c__isDraft == 'true';
      this.isEdit = true;
      this.breadcrumbs = [
        {
          label: 'Min side',
          href: ''
        },
        {
          label: 'Mine søknader',
          href: 'mine-soknader'
        },
        {
          label: this.isDraft ? 'Utkast' : 'Rediger søknad',
          href: 'soknad'
        }
      ];
      this.numPops = 3;
    }
  }

  async init() {
    try {
      // get the organization info for the current user
      let orgInfo = await getLastUsedOrganizationInformation({ userId: this.currentUser });
      this.organization = orgInfo;
      this.organizationType = orgInfo.AAREG_OrganizationCategory__c;
      this.lastUsedOrganization = orgInfo.INT_OrganizationNumber__c;

      await this.checkAccessToApplication();

      // initialize application based on previously saved draft.
      if (this.recordId) {
        let draftApplication = await getDraftApplication({ recordId: this.recordId });

        this.initApplication();
        this.application = { ...this.application, ...draftApplication.application };

        if (draftApplication.contacts.length >= 1) {
          draftApplication.contacts.forEach((contact) => {
            this.contactRows.push({ uuid: this.createUUID(), ...contact });
          });
        } else {
          this.contactRows.push({ uuid: this.createUUID() });
        }

        if (draftApplication.basisCodes.length >= 1) {
          draftApplication.basisCodes.forEach((code) => {
            this.applicationBasisRows.push({ uuid: this.createUUID(), ...code });
          });
        } else {
          this.applicationBasisRows.push({ uuid: this.createUUID() });
        }
        if (!this.application.AA_isPortalUserEditable__c) {
          this.setAsReadOnly();
        }
        // initialize new application.
      } else {
        this.initApplication();
        this.contactRows.push({ uuid: this.createUUID() });
        this.applicationBasisRows.push({ uuid: this.createUUID() });
      }
    } catch (error) {
      this.hasErrors = true;
      console.error(error);
    } finally {
      this.isLoaded = true;
    }
  }

  initApplication() {
    this.application = {
      AccountId__c: this.organization.Id ? this.organization.Id : null,
      AccountName__c: this.organization.Name ? this.organization.Name : null,
      MailingAddress__c: this.organization.ShippingStreet ? this.organization.ShippingStreet : null,
      MailingCity__c: this.organization.ShippingCity ? this.organization.ShippingCity : null,
      MailingPostalCode__c: this.organization.ShippingPostalCode ? this.organization.ShippingPostalCode : null,
      Email__c: null,
      AA_changesInApplication__c: false,
      DataProcessorName__c: null,
      APIAccess__c: false,
      ExtractionAccess__c: false,
      OnlineAccess__c: false,
      EventAccess__c: false,
      DataProcessorOrganizationNumber__c: null,
      TermsOfUse__c: false,
      organizationName: this.organization.Name ? this.organization.Name : null,
      OrganizationNumber__c: this.organization.INT_OrganizationNumber__c
        ? this.organization.INT_OrganizationNumber__c
        : null,
      OrganizationStructure__c: this.organization.INT_OrganizationalStructure__c
        ? this.organization.INT_OrganizationalStructure__c
        : null
    };
  }

  get acceptedFileFormats() {
    return ['.xlsx', '.pdf', '.docx'];
  }

  get dataElementURL() {
    return 'https://navikt.github.io/aareg/om_tjenestene/soke_om_tilgang.html';
  }

  get termsOfUseURL() {
    return 'https://nav.no/no/nav-og-samfunn/samarbeid/tilgang-til-arbeidsgiver-og-arbeidstakerregisteret-aa-registeret/Bruksvilkår_for_tilgang_til_Aa-registeret.pdf';
  }

  async checkAccessToApplication() {
    getUserRights({ userId: this.currentUser, organizationNumber: this.lastUsedOrganization, serviceCode: '5719' })
      .then((result) => {
        if (result.success) {
          let privileges = JSON.parse(JSON.stringify(result.rights));

          privileges.forEach((privilege) => {
            if (privilege.ServiceCode === '5719') {
              this.hasAccess = true;
              return;
            }
          });
        }
      })
      .catch((error) => {
        console.error(error);
      })
      .finally(() => {
        return this.hasAccess;
      });
  }

  setAsReadOnly() {
    this.isReadOnly = true;
  }

  /*************** Dynamic Element handlers ***************/

  get showContactRemove() {
    return this.contactRows.length > 1 && !this.isReadOnly;
  }

  get showApplicationBasisRemove() {
    return this.applicationBasisRows.length > 1 && !this.isReadOnly;
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

  removeContactRow(event) {
    let contact = this.contactRows[event.target.value];
    if (contact.Id) {
      this.deleteRecord(contact)
        .then(() => {
          this.contactRows.splice(event.target.value, 1);
        })
        .catch((error) => {
          console.error(error);
        });
    } else {
      this.contactRows.splice(event.target.value, 1);
    }
  }

  addContactRow() {
    this.contactRows.push({ uuid: this.createUUID() });
  }

  removeApplicationBasisRow(event) {
    let basisCode = this.applicationBasisRows[event.target.value];
    if (basisCode.Id) {
      this.deleteRecord(basisCode)
        .then(() => {
          this.applicationBasisRows.splice(event.target.value, 1);
        })
        .catch((error) => {
          console.error(error);
        });
    } else {
      this.applicationBasisRows.splice(event.target.value, 1);
    }
  }

  addApplicationBasisRow() {
    this.applicationBasisRows.push({ uuid: this.createUUID() });
  }

  async deleteRecord(recordToDelete) {
    deleteDraftRecord({ record: recordToDelete }).catch((error) => {
      console.error(error);
    });
  }

  /****************************************************************************************/

  handleSaveAsDraft(event) {
    event.preventDefault();
    this.isLoaded = false;
    let draftContacts = this.contactRows.filter((el) => el.Name !== null && el.Name !== '');
    const { base64, filename } = this.fileData;
    saveAsDraft({
      application: this.application,
      basisCode: this.applicationBasisRows,
      relatedContacts: draftContacts,
      base64: base64,
      filename: filename
    })
      .then((result) => {
        sessionStorage.setItem('isSaved', 'true');
        if (this.isEdit) {
          this.navigateToApplication(result, 'edit', ''); // Edit existing Application
        } else {
          this.navigateToApplication(result, 'default', ''); // Edit new Application
        }
      })
      .catch((error) => {
        console.error(error);
      })
      .finally(() => {
        this.isLoaded = true;
      });
  }

  handleSubmit(event) {
    event.preventDefault();
    this.resetErrors();
    this.validateApplicationBasis();
    this.validateContactsBeforeSubmission();
    this.checkApplicationInputs();

    if (this.hasErrors) {
      this.focusInput();
      return;
    }
    window.scrollTo(0, 0);
    this.isLoaded = false;
    const { base64, filename } = this.fileData;
    this.application.AA_changesInApplication__c = this.application.Status__c === 'Additional Information Required' ? true : false;
    processApplication({
      application: this.application,
      basisCode: this.applicationBasisRows,
      relatedContacts: this.contactRows,
      base64: base64,
      fileName: filename
    })
      .then((result) => {
        if (this.application.Status__c === 'Additional Information Required') {
          this.navigateToApplication(result, 'view', 'AIR');
        }
        this.applicationSubmitted = true;
      })
      .catch((error) => {
        console.error(error);
      })
      .finally(() => {
        this.isLoaded = true;
      });
  }

  returnToHome() {
    this[NavigationMixin.Navigate]({
      type: 'standard__namedPage',
      attributes: {
          pageName: 'home'
      },
    });
  }

  /*************** Navigation ***************/

  navigateToApplication(applicationId, type, status) {
    this[NavigationMixin.Navigate]({
      type: 'standard__recordPage',
      attributes: {
        recordId: applicationId,
        objectApiName: 'Application__c',
        actionName: 'view'
      },
      state: {
        c__applicationType: type,
        c__isDraft: this.isDraft,
        c__status: status,
      }
    });
  }

  showModal() {
    this.template.querySelector('c-alertdialog').showModal();
  }

  /*************** Change handlers ***************/

  contactChange(event) {
    let changedContact = event.detail;
    let foundIndex = this.contactRows.findIndex((element) => element.uuid === changedContact.uuid);
    if (typeof foundIndex !== 'undefined') {
      this.contactRows[foundIndex] = changedContact;
    }
  }

  applicationBasisChange(event) {
    let changes = event.detail;
    let foundIndex = this.applicationBasisRows.findIndex((element) => element.uuid === changes.uuid);
    if (typeof foundIndex !== 'undefined') {
      this.applicationBasisRows[foundIndex] = changes;
    }
  }

  handleDataProcessorChange(event) {
    let dataProcessor = event.target.value;
    if (dataProcessor.length === 9) {
      getAccountNameByOrgNumber({ orgNumber: dataProcessor })
        .then((result) => {
          this.application.DataProcessorName__c = result;
          this.application.DataProcessorOrganizationNumber__c = dataProcessor;
        })
        .catch((error) => {
          this.application.DataProcessorName__c = null;
          this.application.DataProcessorOrganizationNumber__c = null;
          this.setErrorFor(this.dataProcess, 'Ugyldig organisasjonsnummer');
        });
    } else if (this.application.DataProcessor__c != null) {
      this.application.DataProcessor__c = null;
      this.application.DataProcessorOrganizationNumber__c = null;
    }
  }

  handleInputChange(event) {
    this.application[event.target.dataset.id] = event.target.value;
  }

  handleCheckboxChange(event) {
    this.application[event.target.dataset.id] = event.target.checked;
  }

  onFileUpload(event) {
    const file = event.target.files[0];
    let reader = new FileReader();
    reader.onload = () => {
      let base64 = reader.result.split(',')[1];
      this.fileData = {
        filename: file.name,
        base64: base64
      };
    };
    reader.readAsDataURL(file);
  }

  /*************** Validation ***************/

  processError(event) {
    if (event.detail) {
      this.hasErrors = true;
    }
  }

  validateApplicationBasis() {
    let purposes = this.template.querySelectorAll('c-aareg_application-basis');

    purposes.forEach((purpose) => {
      purpose.validate();
    });
  }

  validateContactsBeforeSubmission() {
    let agreementNotification = 0;
    let changeNofiication = 0;
    let errorNotification = 0;
    let securityNotification = 0;

    let cons = this.template.querySelectorAll('c-aareg_application-contact');
    let error = false;
    cons.forEach((con) => {
      error += con.validate();
    });

    this.contactRows.forEach((contact) => {
      if (contact.AgreementNotifications__c) {
        agreementNotification += 1;
      }

      if (contact.ChangeNotifications__c) {
        changeNofiication += 1;
      }

      if (contact.ErrorMessageNotifications__c) {
        errorNotification += 1;
      }

      if (contact.SecurityNotifications__c) {
        securityNotification += 1;
      }
    });

    if (agreementNotification < 1 || changeNofiication < 1 || errorNotification < 1 || securityNotification < 1) {
      this.missingContactNotifications = true;
      this.setErrorFor(this.contacts, 'Det må oppgis minimum en kontaktperson per type varsling.');
    } else {
      this.missingContactNotifications = false;
    }
    if (error) {
      this.hasErrors = true;
    }
  }

  content = 'Dine endringer er lagret.';
  header = '';
  renderedCallback() {
    this.email = this.template.querySelector('[data-id="Email__c"]');
    this.contacts = this.template.querySelector('[data-id="contacts"]');
    this.apiAccess = this.template.querySelector('[data-id="APIAccess__c"]');
    this.onlineAccess = this.template.querySelector('[data-id="OnlineAccess__c"]');
    this.extractionAccess = this.template.querySelector('[data-id="ExtractionAccess__c"]');
    this.eventAccess = this.template.querySelector('[data-id="EventAccess__c"]');
    this.accessTypes = this.template.querySelector('[data-id="access-types"]');
    this.dataElements = this.template.querySelector('[data-id="data-element"]');
    this.fileInput = this.template.querySelector('[data-id="file-input"]');
    this.termsOfUse = this.template.querySelector('[data-id="terms"]');
    this.termsOfUseInput = this.template.querySelector('[data-id="TermsOfUse__c"]');
    this.dataProcess = this.template.querySelector('[data-id="data-processor"]');
    if (this.isLoaded === true && this.template.querySelector('c-alertdialog') !== undefined && this.template.querySelector('c-alertdialog') !== null) {
      if (this.currentPageReference.state.c__status === 'AIR') {
        this.header = 'Søknad redigert';
        this.content = 'Søknaden er redigert og sendt inn.';
        this.showModal();
      } else if (sessionStorage.getItem('isSaved') === 'true') {
        this.header = 'Søknad lagret';
        this.content = 'Dine endringer er lagret.';
        this.showModal();
        sessionStorage.setItem('isSaved', 'false');
      } 
    }
  }

  checkApplicationInputs() {
    if (validateEmail(this.application.Email__c)) {
      this.setErrorFor(this.email, 'E-post må være gyldig format.');
      this.email.className = 'invalid';
    }
    if (
      this.application.APIAccess__c === false &&
      this.application.ExtractionAccess__c === false &&
      this.application.OnlineAccess__c === false &&
      this.application.EventAccess__c === false
    ) {
      this.setErrorFor(this.accessTypes, 'Minst én type tilgang er obligatorisk');
      this.apiAccess.className = 'invalid';
    }
    if (
      (this.fileData.base64 === null || this.fileData.filename === null) &&
      this.application.Status__c != 'Additional Information Required'
    ) {
      this.setErrorFor(this.dataElements, 'Obligatorisk');
    }

    if (this.application.TermsOfUse__c === false) {
      this.setErrorFor(this.termsOfUse, 'Obligatorisk');
      this.termsOfUseInput.className = 'invalid';
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
    this.hasErrors = false;

    let inputs = this.template.querySelectorAll('input');
    inputs.forEach((input) => {
      input.classList.remove('invalid');
    });
    let formControl = this.template.querySelectorAll('.form-control');
    formControl.forEach((element) => {
      element.classList.remove('error');
    });
  }

  focusInput() {
    if (this.email.className === 'invalid') {
      this.email.focus();
      return;
    }

    let purposes = this.template.querySelectorAll('c-aareg_application-basis');

    for (let i = 0; i < purposes.length; i++) {
      let isFocused = purposes[i].focusInput();

      if (isFocused) {
        return;
      }
    }

    if (this.apiAccess.className === 'invalid') {
      this.apiAccess.focus();
      return;
    }

    let contacts = this.template.querySelectorAll('c-aareg_application-contact');

    for (let i = 0; i < contacts.length; i++) {
      let isFocused = contacts[i].focusInput();
      if (isFocused) {
        return;
      }
    }

    if (this.missingContactNotifications) {
      contacts[0].focusAgreementNotification();
      return;
    }

    if (this.fileInput.className === 'invalid') {
      this.fileInput.focus();
      return;
    }

    if (this.termsOfUseInput.className === 'invalid') {
      this.termsOfUseInput.focus();
      return;
    }
  }
}
