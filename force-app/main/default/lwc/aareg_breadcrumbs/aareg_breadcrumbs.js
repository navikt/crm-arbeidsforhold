import { LightningElement, api } from 'lwc';
import getPortal from '@salesforce/apex/AAREG_EntryPortalController.getPortal';

export default class Aareg_breadcrumbs extends LightningElement {
    @api firstHref;
    @api secondHref;
    @api thirdHref;
    urlListToShow = [];
    replacedByPortalNav = true;
    numPops = 3;

    connectedCallback() {
        this.checkPortalNav();
        const urlList = [];
        urlList.push({ label: this.firstHref, href: '' });
        urlList.push({ label: this.secondHref, href: 'mine-meldinger' });
        urlList.push({ label: this.thirdHref, href: 'henvendelse' });

        let baseURLArray = window.location.pathname.split('/');
        for (let i = 0; i < this.numPops; i++) {
            baseURLArray.pop();
        }
        let baseURL = baseURLArray.join('/');
        this.urlListToShow = urlList.map((x) => ({ ...x, href: baseURL + '/' + x.href }));
        this.removeElementsAfterIndex();
    }

    // c/aaregPortalNav draws the trail while the new entry portal is on; this legacy trail is the rollback view.
    async checkPortalNav() {
        try {
            const portal = await getPortal();
            this.replacedByPortalNav = Boolean(portal?.enabled);
        } catch (error) {
            this.replacedByPortalNav = false;
        }
    }

    removeElementsAfterIndex() {
        let indexToSet = this.urlListToShow.length;
        this.urlListToShow.forEach((element, index) => {
            if (element.href === window.location.pathname) {
                indexToSet = index + 1;
            }
        });
        this.urlListToShow.length = indexToSet;
    }
}
