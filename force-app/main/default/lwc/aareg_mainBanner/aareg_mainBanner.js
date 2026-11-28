import { LightningElement, api } from 'lwc';
import getPortal from '@salesforce/apex/AAREG_EntryPortalController.getPortal';

/**
 * Page title for the legacy Aa-registeret pages. With the new entry portal on, the title is a page heading placed
 * under the portal trail, like the new pages. Otherwise, and when the portal cannot be read, the blue banner is kept.
 */
export default class Aareg_mainBanner extends LightningElement {
    @api title;

    portalEnabled = false;
    resolved = false;

    async connectedCallback() {
        try {
            const portal = await getPortal();
            this.portalEnabled = Boolean(portal?.enabled);
        } catch (error) {
            this.portalEnabled = false;
        }
        this.resolved = true;
    }

    get wrapperClass() {
        if (!this.resolved) {
            return 'pending';
        }
        return this.portalEnabled ? 'page-title' : 'mainbanner';
    }

    get titleClass() {
        return this.portalEnabled ? 'navds-heading navds-heading--xlarge page-title-text' : 'mainbanner-title';
    }
}
