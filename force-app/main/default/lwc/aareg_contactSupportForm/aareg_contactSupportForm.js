import { LightningElement } from 'lwc';

export default class Aareg_contactSupportForm extends LightningElement {
  support;

  get regardingExistingApplication() {
    return false;
  }

  handleInputChange(event) {
    this.support[event.target.dataset.id] = event.target.value;
  }
}
