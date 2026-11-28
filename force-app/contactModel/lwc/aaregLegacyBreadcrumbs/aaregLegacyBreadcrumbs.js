import { LightningElement, api } from 'lwc';
import getPortal from '@salesforce/apex/AAREG_EntryPortalController.getPortal';

/**
 * Shows the legacy c-breadcrumbs trail only while the new entry portal is off.
 * When AAREG_ContactModel_EntryPortal is on, c-aareg-portal-nav draws the single trail for the page.
 */
export default class AaregLegacyBreadcrumbs extends LightningElement {
    @api urlList = [];
    @api numPops = 1;

    showLegacy = false;

    async connectedCallback() {
        try {
            const portal = await getPortal();
            this.showLegacy = !portal?.enabled;
        } catch (error) {
            this.showLegacy = true;
        }
    }
}
