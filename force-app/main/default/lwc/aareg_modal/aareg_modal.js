import { LightningElement, api } from 'lwc';

export default class Aareg_modal extends LightningElement {
  showModal = false;

  @api
  toggle() {
    this.showModal === false ? (this.showModal = true) : (this.showModal = false);
  }
}
