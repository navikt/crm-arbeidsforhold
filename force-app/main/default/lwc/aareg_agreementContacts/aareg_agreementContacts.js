import { LightningElement, api, track, wire } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getAgreementContacts from '@salesforce/apex/AAREG_MyAgreementsController.getAgreementContacts';
import saveAgreementContacts from '@salesforce/apex/AAREG_MyAgreementsController.saveAgreementContacts';
import deleteAgreementContact from '@salesforce/apex/AAREG_MyAgreementsController.deleteAgreementContact';

const newRow = () => ({
  uuid: crypto.randomUUID ? crypto.randomUUID() : `tmp-${Date.now()}-${Math.random()}`,
  Id: null,
  Name: '',
  Phone__c: '',
  Email__c: '',
  AgreementNotifications__c: false,
  ChangeNotifications__c: false,
  ErrorMessageNotifications__c: false,
  SecurityNotifications__c: false
});

export default class Aareg_agreementContacts extends LightningElement {
  @api agreementId;
  @api readOnly = false;
  hasFocused = false;
  @track contactRows = [];
  wiredResult;
  isSaving = false;
  error;

  renderedCallback() {
    console.log('renderedCallback, hasFocused=', this.hasFocused, 'rows=', this.contactRows.length);
    if (this.hasFocused || this.contactRows.length === 0) return;
    const firstInput = this.template.querySelector('lightning-input[data-first="true"]');
    if (firstInput) {
      this.hasFocused = true;
      Promise.resolve().then(() => firstInput.focus());
    }
  }

  connectedCallback() {
    this.template.addEventListener('click', (e) => {
      console.log('CLICK target:', e.target.tagName, e.target.className);
      setTimeout(() => {
        console.log('activeElement:', document.activeElement?.tagName, document.activeElement);
      }, 0);
    }, true);
  }

  @wire(getAgreementContacts, { currentRecordId: '$agreementId' })
  wiredContacts(result) {
    this.wiredResult = result;
    if (result.data) {
      this.contactRows = result.data.length
        ? result.data.map((c) => ({ ...c, uuid: c.Id }))
        : [newRow()];
      this.error = undefined;
    } else if (result.error) {
      this.error = result.error;
      console.error(result.error);
    }
  }

  get showContactRemove() {
    return !this.readOnly && this.contactRows.length > 1;
  }

  // Reset når modalen lukkes (kall fra parent via @api hvis ønskelig)
    @api
    resetFocus() {
    this.hasFocused = false;
    }

  /* ----------------- Row helpers ----------------- */
  contactChange(event) {
    const updated = event.detail; // { uuid, field, value } – avhenger av c-aareg_application-contact
    this.contactRows = this.contactRows.map((row) =>
      row.uuid === updated.uuid ? { ...row, ...updated.record ?? updated } : row
    );
  }

  addContactRow() {
    this.contactRows = [...this.contactRows, newRow()];
    Promise.resolve().then(() => {
    const firsts = this.template.querySelectorAll('lightning-input[data-first="true"]');
    firsts[firsts.length - 1]?.focus();
  });
  }

  async removeContactRow(event) {
    const index = parseInt(event.target.value, 10);
    const row = this.contactRows[index];

    if (row?.Id) {
      try {
        await deleteAgreementContact({ contactId: row.Id });
      } catch (err) {
        this.toast('Feil', 'Kunne ikke slette kontaktperson.', 'error');
        return;
      }
    }
    this.contactRows = this.contactRows.filter((_, i) => i !== index);
    if (this.contactRows.length === 0) this.contactRows = [newRow()];
  }

  processError(event) {
    console.warn('Validation error from contact row:', event.detail);
  }

  /* ----------------- Save ----------------- */
  async handleSave() {
    this.isSaving = true;
    try {
      const toSave = this.contactRows.map(({ uuid, ...rest }) => {
        const clean = { ...rest };
        if (!clean.Id) delete clean.Id;
        return clean;
      });

      await saveAgreementContacts({currentRecordId: this.agreementId, contacts: toSave });
      await refreshApex(this.wiredResult);
      this.toast('Lagret', 'Kontaktpersoner er oppdatert.', 'success');
      this.dispatchEvent(new CustomEvent('saved'));
    } catch (err) {
      console.error(err);
      this.toast('Feil', err?.body?.message ?? 'Kunne ikke lagre.', 'error');
    } finally {
      this.isSaving = false;
    }
  }

  /* ----------------- Field change ----------------- */
  handleFieldChange(event) {
    const { uuid, field } = event.target.dataset;
    const value =
      event.target.type === 'checkbox' ? event.target.checked : event.target.value;

    this.contactRows = this.contactRows.map((row) =>
      row.uuid === uuid ? { ...row, [field]: value } : row
    );
  }

  toast(title, message, variant) {
    this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
  }
}