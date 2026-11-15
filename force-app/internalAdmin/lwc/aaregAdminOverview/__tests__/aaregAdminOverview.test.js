import { createElement } from 'lwc';
import AaregAdminOverview from 'c/aaregAdminOverview';
import getOverview from '@salesforce/apex/AAREG_AdminOverviewController.getOverview';
import getTileRecords from '@salesforce/apex/AAREG_AdminOverviewController.getTileRecords';

jest.mock('@salesforce/apex/AAREG_AdminOverviewController.getOverview', () => ({ default: jest.fn() }), {
    virtual: true
});
jest.mock('@salesforce/apex/AAREG_AdminOverviewController.getTileRecords', () => ({ default: jest.fn() }), {
    virtual: true
});

const TILES = [
    {
        key: 'applicationsByStatus',
        label: 'Søknader per status',
        description: 'Alle søknader',
        objectApiName: 'Application__c',
        available: true,
        count: 3,
        breakdown: [
            { label: 'New', count: 2 },
            { label: 'Approved', count: 1 }
        ]
    },
    {
        key: 'errorLogs24h',
        label: 'Feil siste 24 timar',
        description: 'Feil',
        objectApiName: 'Application_Log__c',
        available: false,
        message: 'Du har ikkje lesetilgang til Application_Log__c.',
        breakdown: []
    }
];

const flush = () => new Promise((resolve) => setTimeout(resolve, 0));

function mount() {
    const element = createElement('c-aareg-admin-overview', { is: AaregAdminOverview });
    document.body.appendChild(element);
    return element;
}

describe('c-aareg-admin-overview', () => {
    afterEach(() => {
        while (document.body.firstChild) document.body.removeChild(document.body.firstChild);
        jest.clearAllMocks();
    });

    it('shows counts, breakdown and the reason a tile is unavailable', async () => {
        getOverview.mockResolvedValue(TILES);
        const element = mount();
        await flush();

        const tiles = element.shadowRoot.querySelectorAll('[data-tile]');
        expect(tiles).toHaveLength(2);
        expect(tiles[0].textContent).toContain('3');
        expect(tiles[0].textContent).toContain('New: 2');
        expect(tiles[1].textContent).toContain('Du har ikkje lesetilgang til Application_Log__c.');
        expect(tiles[1].querySelector('lightning-button')).toBeNull();
    });

    it('loads the drill-down rows for the chosen tile', async () => {
        getOverview.mockResolvedValue(TILES);
        getTileRecords.mockResolvedValue([
            { id: 'a01000000000001AAA', name: 'APP-1', detail: 'New', lastModified: '2026-11-15T10:00:00.000Z' }
        ]);
        const element = mount();
        await flush();

        element.shadowRoot.querySelector('[data-tile="applicationsByStatus"] lightning-button').click();
        await flush();

        expect(getTileRecords).toHaveBeenCalledWith({ key: 'applicationsByStatus' });
        const table = element.shadowRoot.querySelector('lightning-datatable');
        expect(table.data[0].name).toBe('APP-1');
        expect(table.data[0].recordUrl).toBe('/lightning/r/Application__c/a01000000000001AAA/view');
    });

    it('shows an error when the overview cannot be loaded', async () => {
        getOverview.mockRejectedValue({ body: { message: 'Ingen tilgang' } });
        const element = mount();
        await flush();

        expect(element.shadowRoot.textContent).toContain('Ingen tilgang');
    });
});
