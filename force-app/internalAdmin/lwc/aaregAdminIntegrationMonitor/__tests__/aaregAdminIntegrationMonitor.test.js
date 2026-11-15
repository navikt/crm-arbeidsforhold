import { createElement } from 'lwc';
import AaregAdminIntegrationMonitor from 'c/aaregAdminIntegrationMonitor';
import getMonitor from '@salesforce/apex/AAREG_AdminMonitorController.getMonitor';

jest.mock('@salesforce/apex/AAREG_AdminMonitorController.getMonitor', () => ({ default: jest.fn() }), {
    virtual: true
});

const flush = () => new Promise((resolve) => setTimeout(resolve, 0));

function mount() {
    const element = createElement('c-aareg-admin-integration-monitor', { is: AaregAdminIntegrationMonitor });
    document.body.appendChild(element);
    return element;
}

describe('c-aareg-admin-integration-monitor', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
        jest.clearAllMocks();
    });

    it('shows jobs with expired lease highlighted and log sources', async () => {
        getMonitor.mockResolvedValue({
            jobsAvailable: true,
            jobs: [
                {
                    id: 'a01',
                    name: 'JOB-1',
                    status: 'In Progress',
                    attempts: 2,
                    leaseExpired: true,
                    correlationId: 'c1'
                },
                { id: 'a02', name: 'JOB-2', status: 'Failed', attempts: 3, leaseExpired: false, lastErrorCode: 'E1' }
            ],
            logsAvailable: true,
            sources: [{ sourceClass: 'AAREG_AltinnService', total: 2, errors: 1, lastErrorMessage: 'Altinn 500' }],
            scratchCaptureAvailable: false
        });
        const element = mount();
        await flush();

        const datatable = element.shadowRoot.querySelector('lightning-datatable[data-id="jobs"]');
        expect(datatable.data).toHaveLength(2);
        expect(datatable.data[0].leaseText).toBe('Utgått');
        const sources = element.shadowRoot.querySelector('lightning-datatable[data-id="sources"]');
        expect(sources.data[0].sourceClass).toBe('AAREG_AltinnService');
        expect(sources.data[0].errorClass).toBe('slds-text-color_error');
    });

    it('shows lease only for jobs in progress and gives every column a readable width', async () => {
        getMonitor.mockResolvedValue({
            jobsAvailable: true,
            jobs: [
                { id: 'a03', name: 'JOB-3', status: 'Succeeded', leaseExpires: '2026-11-15T12:00:00Z' },
                { id: 'a04', name: 'JOB-4', status: 'In Progress', leaseExpires: '2099-01-01T00:00:00Z' }
            ],
            logsAvailable: true,
            sources: []
        });
        const element = mount();
        await flush();

        const datatable = element.shadowRoot.querySelector('lightning-datatable[data-id="jobs"]');
        expect(datatable.data[0].leaseText).toBe('');
        expect(datatable.data[1].leaseText).toBe('Aktiv');
        expect(datatable.columns.every((column) => column.initialWidth > 0)).toBe(true);
    });

    it('explains unavailable data sources', async () => {
        getMonitor.mockResolvedValue({
            jobsAvailable: false,
            jobsMessage: 'Du har ikkje lesetilgang til P360_Archive_Job__c.',
            jobs: [],
            logsAvailable: false,
            logsMessage: 'Du har ikkje lesetilgang til Application_Log__c.',
            sources: []
        });
        const element = mount();
        await flush();

        expect(element.shadowRoot.textContent).toContain('lesetilgang til P360_Archive_Job__c');
        expect(element.shadowRoot.textContent).toContain('lesetilgang til Application_Log__c');
    });
});
