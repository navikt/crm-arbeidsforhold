import { LightningElement,track,api } from 'lwc';
import getApplicationDetails from '@salesforce/apex/AAREG_ApplicationInternalController.getApplicationDetails';
import applicationTitle from '@salesforce/label/c.AAREG_application_title';
import applicantsSection from '@salesforce/label/c.AAREG_applicant_details_section';
import legalbasisSection from '@salesforce/label/c.AAREG_code_basis_section';
import contactPersonSection from '@salesforce/label/c.AAREG_contac_person_section';

export default class Aareg_applicationInternal extends LightningElement {
    @api recordId;
    @track application;
    @track basisCodes = [];
    @track relatedContacts = [];
    @track error;

    label ={
        applicationTitle,
        applicantsSection,
        legalbasisSection,
        contactPersonSection
    }

    connectedCallback() {
        this.fetchApplicationDetails();
    }

    fetchApplicationDetails() {
        getApplicationDetails({ recordId: this.recordId })
            .then((result) => {
                this.application = result.application;
                this.basisCodes = result.basisCodes;
                this.relatedContacts = result.relatedContacts;
                this.error = undefined;
            })
            .catch((error) => {
                this.error = error;
                this.application = undefined;
                this.basisCodes = [];
                this.relatedContacts = [];
            });
    }
}