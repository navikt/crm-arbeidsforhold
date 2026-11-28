import { LightningElement, api } from 'lwc';

export default class AaregTextField extends LightningElement {
    @api label;
    @api description;
    @api type = 'text';
    @api required = false;
    @api autocomplete;
    @api messageWhenValueMissing = 'Feltet må fylles ut.';
    @api messageWhenTypeMismatch = 'Verdien er ikke gyldig.';
    error;
    currentValue = '';

    @api
    get value() {
        return this.currentValue;
    }
    set value(value) {
        this.currentValue = value ?? '';
    }

    @api
    checkValidity() {
        return !this.validationMessage();
    }

    @api
    reportValidity() {
        this.error = this.validationMessage();
        return !this.error;
    }

    validationMessage() {
        const input = this.template.querySelector('input');
        const validity = input?.validity;
        if (validity?.valueMissing) {
            return this.messageWhenValueMissing;
        }
        if (validity?.typeMismatch) {
            return this.messageWhenTypeMismatch;
        }
        return undefined;
    }

    get fieldClass() {
        return this.error
            ? 'navds-form-field navds-text-field navds-text-field--error'
            : 'navds-form-field navds-text-field';
    }

    get ariaInvalid() {
        return this.error ? 'true' : undefined;
    }

    get describedBy() {
        return (
            [this.description ? 'description' : undefined, this.error ? 'error' : undefined]
                .filter(Boolean)
                .join(' ') || undefined
        );
    }

    handleInput(event) {
        this.currentValue = event.target.value;
        if (this.error) {
            this.error = this.validationMessage();
        }
    }

    handleChange(event) {
        event.stopPropagation();
        this.currentValue = event.target.value;
        this.dispatchEvent(new CustomEvent('change', { detail: { value: this.currentValue } }));
    }
}
