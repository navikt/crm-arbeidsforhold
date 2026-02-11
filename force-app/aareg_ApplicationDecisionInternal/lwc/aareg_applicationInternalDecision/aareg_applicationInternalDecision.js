import { LightningElement,api,track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getDecision from '@salesforce/apex/AAREG_ApplicationDecisionController.getApplicationDecision';
import createDecision from '@salesforce/apex/AAREG_ApplicationDecisionController.createApplicationDecision';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

const COLUMNS = [
    {
        type: 'button',
        initialWidth: 80,
        typeAttributes: {
            name: 'view',
            title: 'Åpne',
            disabled: false,
            value: 'Åpne',
            iconPosition: 'left',
            iconName: 'utility:preview'
        }
    },
    { label: 'Vedtak', fieldName: 'VedtaksNr' },
    { label: 'Status på prosess', fieldName: 'StatusProsess', type: 'text' }
];


export default class Aareg_applicationInternalDecision extends NavigationMixin(LightningElement) {
    @api recordId;
    @track isRowCreated = false; 
    decisionId;
    records;
    error;
    columns = COLUMNS;

    
    connectedCallback() {
        this.fetchDecisionData();
    }

    fetchDecisionData(){
        getDecision({ recordId: this.recordId })
            .then((result) => {
                this.records = result;
                this.error = undefined;
                this.isRowCreated = true; 
                if (!this.records || this.records.length === 0) {
                    this.isRowCreated = false;
                }
            })
            .catch((error) => {
                this.error = error;
                this.records = undefined;
            });
    }

    handleRowAction(event) {
        const row = event.detail.row;
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: row.VedtaksId,
                actionName: 'view'
            }
        });
    }
    handleCreateDecision() {
        createDecision({ recordId: this.recordId })
            .then((result) => {
                this.showToast('Success', 'Vedtak opprettet', 'success');
                this.decisionId = result;
                this[NavigationMixin.Navigate]({
                    type: 'standard__recordPage',
                    attributes: {
                        recordId: this.decisionId,
                        actionName: 'view'
                    }
                });
                this.fetchDecisionData();
                // Refresh the data
            })
            .catch((error) => {
                this.showToast('Error', 'Det skjedde en uventet feil.', 'error');
                console.error(error);
            });
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title,
            message,
            variant
        });
        this.dispatchEvent(event);
    }


}