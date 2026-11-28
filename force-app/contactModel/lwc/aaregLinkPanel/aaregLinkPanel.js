import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import basePath from '@salesforce/community/basePath';
import { hrefFor } from 'c/aaregPortalContext';

export default class AaregLinkPanel extends NavigationMixin(LightningElement) {
    @api title;
    @api description;
    @api page;
    @api icon;
    @api count;
    @api countLabel = 'nye';

    get href() {
        return hrefFor(basePath, this.page);
    }

    get hasCount() {
        return Number(this.count) > 0;
    }

    handleClick(event) {
        if (event.ctrlKey || event.metaKey || event.shiftKey) {
            return;
        }
        event.preventDefault();
        this[NavigationMixin.Navigate]({ type: 'comm__namedPage', attributes: { name: this.page } });
    }
}
