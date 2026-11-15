import { LightningElement, api } from 'lwc';
import getJourney from '@salesforce/apex/AAREG_AdminJourneyController.getJourney';

const SOURCE_LABEL = {
    Application__c: 'Søknad',
    Application__History: 'Feltendring',
    Application_Decision__c: 'Vedtak',
    Agreement__c: 'Avtale',
    ContentDocument: 'Fil',
    P360_Archive_Job__c: 'P360-jobb',
    Application_Log__c: 'Logg',
    EmailMessage: 'E-post',
    Thread__c: 'Dialog'
};

export default class AaregAdminJourney extends LightningElement {
    _recordId;
    journey;
    entries = [];
    error;
    loading = false;

    @api
    get recordId() {
        return this._recordId;
    }

    set recordId(value) {
        this._recordId = value;
        if (value) {
            this.load(value);
        }
    }

    get isAppPage() {
        return !this._recordId;
    }

    handlePick(event) {
        const applicationId = event.detail?.recordId;
        if (applicationId) {
            this.load(applicationId);
        } else {
            this.journey = undefined;
            this.entries = [];
        }
    }

    async load(applicationId) {
        this.loading = true;
        this.error = undefined;
        try {
            const journey = await getJourney({ applicationId });
            this.journey = journey;
            this.entries = (journey.entries ?? []).map((entry, index) => ({
                ...entry,
                key: `${index}-${entry.recordId}`,
                sourceLabel: SOURCE_LABEL[entry.source] ?? entry.source,
                url:
                    entry.source === 'ContentDocument'
                        ? `/lightning/r/ContentDocument/${entry.recordId}/view`
                        : `/lightning/r/${entry.recordId}/view`
            }));
        } catch (error) {
            this.journey = undefined;
            this.entries = [];
            this.error = error?.body?.message ?? error?.message ?? 'Ukjend feil';
        } finally {
            this.loading = false;
        }
    }

    get hiddenText() {
        const count = this.journey?.hiddenCount ?? 0;
        return count > 0 ? `${count} postar er skjulte fordi du manglar tilgang.` : undefined;
    }

    get missingSteps() {
        return (this.journey?.missingSteps ?? []).map((step) => ({ step, text: `Ikkje registrert: ${step}` }));
    }
}
