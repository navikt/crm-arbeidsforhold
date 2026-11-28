import { createElement } from 'lwc';
import AaregAdminPermissionCatalog from 'c/aaregAdminPermissionCatalog';
import getCatalog from '@salesforce/apex/AAREG_AdminPermissionController.getCatalog';

jest.mock('@salesforce/apex/AAREG_AdminPermissionController.getCatalog', () => ({ default: jest.fn() }), {
    virtual: true
});

const ENTRIES = [
    {
        apiName: 'AAREG_Arbeidsforhold_Saksbehandling',
        label: 'Saksbehandling',
        kind: 'Løyvesett',
        audienceLabel: 'Saksbehandlar',
        explanation: 'Saksbehandling i Aa-registeret.',
        documented: true,
        recommendedWith: ['AAREG_Arbeidsforhold_run_flow'],
        directAssignees: 3,
        objects: [{ apiName: 'Application__c', label: 'Søknad', accessText: 'Les, Endre' }],
        customPermissions: [],
        apps: ['Aa-registeret – Søknad'],
        apexClassCount: 4,
        members: [],
        memberOf: []
    },
    {
        apiName: 'P360_Integration_User',
        label: 'P360 Integration User',
        kind: 'Løyvesettgruppe',
        audienceLabel: 'Integrasjonsbrukar',
        explanation: 'Gruppe for P360-integrasjonsbrukaren.',
        documented: true,
        recommendedWith: [],
        directAssignees: 1,
        objects: [],
        customPermissions: [],
        apps: [],
        apexClassCount: 0,
        members: ['P360_Archive_Job_Processing'],
        memberOf: []
    }
];

const flush = () => new Promise((resolve) => setTimeout(resolve, 0));

async function render() {
    const element = createElement('c-aareg-admin-permission-catalog', { is: AaregAdminPermissionCatalog });
    document.body.appendChild(element);
    await flush();
    return element;
}

const listedNames = (element) =>
    [...element.shadowRoot.querySelectorAll('button[data-name]')].map((button) => button.dataset.name);

describe('c-aareg-admin-permission-catalog', () => {
    beforeEach(() => getCatalog.mockResolvedValue(ENTRIES));

    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
        jest.clearAllMocks();
    });

    it('filters permissions by audience', async () => {
        const element = await render();
        element.shadowRoot
            .querySelector('lightning-combobox')
            .dispatchEvent(new CustomEvent('change', { detail: { value: 'Integrasjonsbrukar' } }));
        await flush();

        expect(listedNames(element)).toEqual(['P360_Integration_User']);
    });

    it('searches in the explanation text', async () => {
        const element = await render();
        const search = element.shadowRoot.querySelector('lightning-input');
        search.value = 'saksbehandling i';
        search.dispatchEvent(new CustomEvent('change'));
        await flush();

        expect(listedNames(element)).toEqual(['AAREG_Arbeidsforhold_Saksbehandling']);
    });

    it('shows recommended companions and object access for the selected permission', async () => {
        const element = await render();
        element.shadowRoot.querySelector('button[data-name="AAREG_Arbeidsforhold_Saksbehandling"]').click();
        await flush();

        const detail = element.shadowRoot.querySelector('[data-id="detail"]');
        expect(detail.textContent).toContain('AAREG_Arbeidsforhold_run_flow');
        expect(detail.textContent).toContain('Les, Endre');
        expect(detail.textContent).toContain('Aa-registeret – Søknad');
    });
});
