import { LightningElement, api } from 'lwc';

// Stub for c-breadcrumbs from crm-community-base, which is not checked out in CI.
export default class Breadcrumbs extends LightningElement {
    @api urlList = [];
    @api numPops = 1;
    @api desktopStyle;
    @api mobileStyle;
}
