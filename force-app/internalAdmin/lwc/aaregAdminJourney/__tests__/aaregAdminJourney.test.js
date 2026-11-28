import { createElement } from 'lwc';
import AaregAdminJourney from 'c/aaregAdminJourney';
import getJourney from '@salesforce/apex/AAREG_AdminJourneyController.getJourney';

jest.mock('@salesforce/apex/AAREG_AdminJourneyController.getJourney', () => ({ default: jest.fn() }), {
    virtual: true
});

const flush = () => new Promise((resolve) => setTimeout(resolve, 0));

const JOURNEY = {
    applicationId: 'a0A1',
    applicationName: 'APP-1',
    entries: [
        { timestamp: '2026-11-01T10:00:00Z', source: 'Application__c', title: 'Søknad oppretta', recordId: 'a0A1' },
        {
            timestamp: '2026-11-02T10:00:00Z',
            source: 'P360_Archive_Job__c',
            title: 'P360-jobb',
            detail: 'corr-1',
            recordId: 'a0J1'
        }
    ],
    missingSteps: ['Arkivert i P360'],
    hiddenCount: 2,
    notes: ['SMS blir knytt til henvendingar.']
};

function mount(recordId) {
    const element = createElement('c-aareg-admin-journey', { is: AaregAdminJourney });
    if (recordId) {
        element.recordId = recordId;
    }
    document.body.appendChild(element);
    return element;
}

describe('c-aareg-admin-journey', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
        jest.clearAllMocks();
    });

    it('loads the journey for the record page application', async () => {
        getJourney.mockResolvedValue(JOURNEY);
        const element = mount('a0A1');
        await flush();

        expect(getJourney).toHaveBeenCalledWith({ applicationId: 'a0A1' });
        const items = element.shadowRoot.querySelectorAll('li[data-source]');
        expect(items).toHaveLength(2);
        expect(element.shadowRoot.textContent).toContain('Ikkje registrert: Arkivert i P360');
        expect(element.shadowRoot.textContent).toContain('2 postar er skjulte');
    });

    it('shows date-only steps without a time of day', async () => {
        getJourney.mockResolvedValue({
            ...JOURNEY,
            entries: [
                {
                    timestamp: '2026-11-01T23:59:59Z',
                    source: 'Application__c',
                    title: 'Sendt inn',
                    recordId: 'a0A1',
                    dateOnly: true
                }
            ]
        });
        const element = mount('a0A1');
        await flush();

        const date = element.shadowRoot.querySelector('li[data-source] lightning-formatted-date-time');
        expect(date.day).toBe('2-digit');
        expect(date.hour).toBeUndefined();
    });

    it('loads the journey when an application is picked', async () => {
        getJourney.mockResolvedValue(JOURNEY);
        const element = mount();
        await flush();
        expect(getJourney).not.toHaveBeenCalled();

        const picker = element.shadowRoot.querySelector('lightning-record-picker');
        picker.dispatchEvent(new CustomEvent('change', { detail: { recordId: 'a0A1' } }));
        await flush();

        expect(getJourney).toHaveBeenCalledWith({ applicationId: 'a0A1' });
    });

    it('explains access errors', async () => {
        getJourney.mockRejectedValue({ body: { message: 'Du har ikkje lesetilgang til søknader.' } });
        const element = mount('a0A1');
        await flush();

        expect(element.shadowRoot.textContent).toContain('Du har ikkje lesetilgang til søknader.');
    });
});
