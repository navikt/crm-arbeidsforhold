import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import communityBase from '@salesforce/community/basePath';

export default class LinkPanel extends NavigationMixin(LightningElement) {
  @api title;
  @api subTitle;
  @api relativePath;
  basePath = communityBase;

  get panelTitle() {
    return this.title;
  }

  get panelSubTitle() {
    return this.subTitle;
  }

  navigateToPage(event) {
    this[NavigationMixin.Navigate]({
      type: 'comm__namedPage',
      attributes: {
        name: this.relativePath
      }
    });
  }
}
