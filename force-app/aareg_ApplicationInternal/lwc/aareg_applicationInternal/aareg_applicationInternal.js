import { LightningElement,track,api } from 'lwc';
import getApplicationDetails from '@salesforce/apex/AAREG_ApplicationInternalController.getApplicationDetails';
import applicationTitle from '@salesforce/label/c.AAREG_application_title';
import applicantsSection from '@salesforce/label/c.Applicant';
import contactPersonSection from '@salesforce/label/c.Related';
import applicationSection from '@salesforce/label/c.Application';
import dataprocessorSection from '@salesforce/label/c.DataProcessor';
import termsOfUseSection from '@salesforce/label/c.TermsOfUse';
import accessTypesSection from '@salesforce/label/c.AccessType';
import legalbasisSection from '@salesforce/label/c.ApplicationBasisCode';

export default class Aareg_applicationInternal extends LightningElement {
    @api recordId;
    @track application;
    @track basisCodes = [];
    @track relatedContacts = [];
    @track error;

    activeSections = ['applicationSection', 'legalbasisSection', 'dataprocessorSection', 'termsSection', 'contactpersonSection'];

    label ={
        applicationSection,
        dataprocessorSection,
        termsOfUseSection,
        accessTypesSection,
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