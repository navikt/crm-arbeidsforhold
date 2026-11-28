import { LightningElement, api, wire } from 'lwc';
import getPanel from '@salesforce/apex/AAREG_ContactModelPanelController.getPanel';

export default class AaregContactModelPanel extends LightningElement {
    @api recordId;
    panel;
    error;

    @wire(getPanel, { recordId: '$recordId' })
    wiredPanel({ data, error }) {
        if (data) {
            this.panel = data;
            this.error = undefined;
        } else if (error) {
            this.panel = undefined;
            this.error = error?.body?.message ?? 'Kunne ikkje hente kontaktmodellen.';
        }
    }

    get sections() {
        return (this.panel?.sections ?? []).map((section) => ({
            ...section,
            hasRows: section.rows.length > 0,
            headingId: `cm-panel-${section.key}`
        }));
    }
}
