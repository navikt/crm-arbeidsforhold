import { LightningElement,api,wire,track } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { NavigationMixin } from 'lightning/navigation';
import Id from '@salesforce/user/Id';
import getDecision from '@salesforce/apex/AAREG_ApplicationDecisionController.getApplicationDecision';

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
    { label: 'Status', fieldName: 'Status', type: 'text' }
];

export default class Aareg_applicationDecisionInternal extends NavigationMixin(LightningElement) {
    @api recordId;
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

}
