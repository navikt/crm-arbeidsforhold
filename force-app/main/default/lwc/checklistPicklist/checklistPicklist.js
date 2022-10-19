import { LightningElement, api } from 'lwc';

export default class ChecklistPicklist extends LightningElement {
  @api valueString; // Arrives from the Flow
  @api valueChosen; // Goes to the Flow
  @api label;
  @api defaultValue;
  arrayValues = [];
  picklistOptionValues = []; // Contains the options for the Picklist

  connectedCallback() {
    this.arrayValues = this.valueString.split(';');
    for (var i = 0; i < this.arrayValues.length; i++) {
      this.picklistOptionValues.push(this.arrayValues[i]);
    }
  }

  renderedCallback() {
    this.setDefaultValue();
  }

  setDefaultValue() {
    this.arrayValues.forEach(element => {
      if (this.defaultValue === element) {
        this.valueChosen = this.template.querySelector('select').value = element;
      }
    });
  }

  assignValue(event) {
    this.valueChosen = event.target.value;
  }
}
