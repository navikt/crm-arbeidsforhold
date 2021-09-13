import { LightningElement, track, wire } from 'lwc';
import Id from '@salesforce/user/Id';
import getUsersApplications from '@salesforce/apex/AAREG_MyApplicationsController.getUsersApplications';
import createThreadForApplication from '@salesforce/apex/AAREG_contactSupportController.createThreadForApplication';

export default class Aareg_contactSupportForm extends LightningElement {
  @track supportCase;
  existingApplications;
  selectedApplicationId;
  isSubmitted;
  isLoading = false;
  error;

  currentUser = Id;

  connectedCallback() {
    this.supportCase = {
      Type__c: null,
      Description__c: null
    };
  }

  @wire(getUsersApplications, { userId: '$currentUser' })
  applications(result) {
    if (result.data) {
      if (result.data.length > 0) {
        this.existingApplications = result.data;
        console.log(this.existingApplications);
      }
      this.error = undefined;
    } else if (result.error) {
      console.error(error);
      this.error = error;
    }
  }

  get regardingExistingApplication() {
    return this.supportCase.Type__c === 'Eksisterende Søknad';
  }

  get inquirySubmitted() {
    return this.isSubmitted;
  }

  handleInputChange(event) {
    this.supportCase[event.target.dataset.id] = event.target.value;
    console.log(this.supportCase);
  }

  handleRelatedApplicationChange(event) {
    this.selectedApplicationId = event.target.value;
  }

  handleSubmit(event) {
    event.preventDefault();
    this.isLoading = true;

    if (this.regardingExistingApplication) {
      createThreadForApplication({
        userId: this.currentUser,
        relatedApplicationId: this.selectedApplicationId,
        description: this.supportCase.Description__c
      })
        .then((result) => {
          this.isSubmitted = true;
          console.log(result);
        })
        .catch((error) => {
          console.error(error);
        })
        .finally(() => {
          this.isLoading = false;
          console.log('finished');
        });
    } else {
      // create support case
    }
  }
}
