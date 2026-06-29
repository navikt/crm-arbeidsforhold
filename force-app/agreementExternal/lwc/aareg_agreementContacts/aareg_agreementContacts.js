import { LightningElement, track, wire } from 'lwc';
import { CurrentPageReference, NavigationMixin } from 'lightning/navigation';
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

export default class Aareg_agreementContacts extends NavigationMixin(LightningElement) {
  agreementId;
  agreementLabel = '';
  @track contactRows = [];
  wiredResult;
  isSaving = false;
  error;
  hasFocused = false;

  breadcrumbs = [
    { label: 'Min side', href: '' },
    { label: 'Mine avtaler', href: 'mine-avtaler' },
    { label: 'Kontaktpersoner', href: 'kontaktpersoner' }
  ];

  /* ----------------- URL-parameter ----------------- */
  @wire(CurrentPageReference)
  setPageRef(pageRef) {
    if (pageRef?.state?.agreementId) {
      this.agreementId = pageRef.state.agreementId;
    }
    if (pageRef?.state?.agreementNumber) {
      this.agreementLabel = `for avtale ${pageRef.state.agreementNumber}`;
    }
  }

  /* ----------------- Hent kontakter ----------------- */
  @wire(getAgreementContacts, { currentRecordId: '$agreementId' })
  wiredContacts(result) {
    this.wiredResult = result;
    if (result.data) {
      this.contactRows = (result.data.length
        ? result.data.map((c) => ({ ...c, uuid: c.Id }))
        : [newRow()]
      ).map((r, i) => ({
        ...r,
        _indexLabel: i + 1,
        _isFirst: i === 0 ? 'true' : null
      }));
      this.error = undefined;
    } else if (result.error) {
      this.error = result.error;
      console.error(result.error);
    }
  }

  get errorMessage() {
    return this.error?.body?.message ?? 'Kunne ikke hente kontaktpersoner.';
  }

  get showContactRemove() {
    return this.contactRows.length > 1;
  }

  /* ----------------- Felt-endringer ----------------- */
  handleFieldChange(event) {
    const { uuid, field } = event.target.dataset;
    const value =
      event.target.type === 'checkbox' ? event.target.checked : event.target.value;

    this.contactRows = this.contactRows.map((row) =>
      row.uuid === uuid ? { ...row, [field]: value } : row
    );
  }

  /* ----------------- Legg til rad ----------------- */
  addContactRow() {
    this.contactRows = [...this.contactRows, newRow()].map((r, i) => ({
      ...r,
      _indexLabel: i + 1,
      _isFirst: i === 0 ? 'true' : null
    }));
  }

  /* ----------------- Fjern rad ----------------- */
  async removeContactRow(event) {
    const index = parseInt(event.target.value, 10);
    const row = this.contactRows[index];

    if (row?.Id) {
      try {
        await deleteAgreementContact({ contactId: row.Id });
        this.toast('Fjernet', 'Kontaktperson er fjernet.', 'success');
      } catch (err) {
        this.toast('Feil', err?.body?.message ?? 'Kunne ikke fjerne kontaktperson.', 'error');
        return;
      }
    }

    const remaining = this.contactRows.filter((_, i) => i !== index);
    this.contactRows = (remaining.length ? remaining : [newRow()]).map((r, i) => ({
      ...r,
      _indexLabel: i + 1,
      _isFirst: i === 0 ? 'true' : null
    }));
  }

  /* ----------------- Lagre ----------------- */
  async handleSave() {
    // Enkel validering: alle rader må ha Navn
    const invalid = this.contactRows.find((r) => !r.Name || !r.Name.trim());
    if (invalid) {
      this.toast('Mangler navn', 'Alle kontaktpersoner må ha et navn.', 'warning');
      return;
    }

    this.isSaving = true;
    try {
      const toSave = this.contactRows.map(({ uuid, _indexLabel, _isFirst, ...rest }) => {
        const clean = { ...rest };
        if (!clean.Id) delete clean.Id;
        return clean;
      });

      await saveAgreementContacts({
        currentRecordId: this.agreementId,
        contacts: toSave
      });
      await refreshApex(this.wiredResult);
      this.toast('Lagret', 'Kontaktpersoner er oppdatert.', 'success');
    } catch (err) {
      console.error(err);
      this.toast('Feil', err?.body?.message ?? 'Kunne ikke lagre.', 'error');
    } finally {
      this.isSaving = false;
    }
  }

  /* ----------------- Naviger tilbake ----------------- */
  goBack() {
    this[NavigationMixin.Navigate]({
      type: 'comm__namedPage',
      attributes: { name: 'mine-avtaler' }
    });
  }

  toast(title, message, variant) {
    this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
  }
}