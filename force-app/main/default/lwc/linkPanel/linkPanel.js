import { LightningElement, api } from 'lwc';
import communityBase from '@salesforce/community/basePath';

export default class LinkPanel extends LightningElement {
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

  get url() {
    return this.basePath + this.relativePath;
  }
}
