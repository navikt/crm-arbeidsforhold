import { createElement } from 'lwc';
import AaregAdminConfiguration from 'c/aaregAdminConfiguration';
import getConfiguration from '@salesforce/apex/AAREG_AdminConfigurationController.getConfiguration';

jest.mock('@salesforce/apex/AAREG_AdminConfigurationController.getConfiguration', () => ({ default: jest.fn() }), {
    virtual: true
});

const SECTIONS = [
    {
        key: 'p360',
        title: 'P360-arkivering',
        setupUrl: '/lightning/setup/CustomSettings/home',
        items: [
            { label: 'Mock-transport', value: 'På', state: 'success', explanation: 'Ingen data går til P360.' },
            { label: 'Named Credential', value: 'X (finst ikkje i orga)', state: 'warning', explanation: 'Namn.' }
        ]
    }
];

const flush = () => new Promise((resolve) => setTimeout(resolve, 0));

function mount() {
    const element = createElement('c-aareg-admin-configuration', { is: AaregAdminConfiguration });
    document.body.appendChild(element);
    return element;
}

describe('c-aareg-admin-configuration', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
        jest.clearAllMocks();
    });

    it('shows each value with its explanation and a Setup link', async () => {
        getConfiguration.mockResolvedValue(SECTIONS);
        const element = mount();
        await flush();

        const text = element.shadowRoot.textContent;
        expect(text).toContain('Mock-transport');
        expect(text).toContain('Ingen data går til P360.');
        const link = element.shadowRoot.querySelector('a[data-key="p360"]');
        expect(link.getAttribute('href')).toBe('/lightning/setup/CustomSettings/home');
    });

    it('marks warning values so they stand out', async () => {
        getConfiguration.mockResolvedValue(SECTIONS);
        const element = mount();
        await flush();

        const warnings = element.shadowRoot.querySelectorAll('[data-state="warning"]');
        expect(warnings).toHaveLength(1);
        expect(warnings[0].textContent).toContain('finst ikkje');
    });

    it('explains errors instead of failing silently', async () => {
        getConfiguration.mockRejectedValue({ body: { message: 'Ingen tilgang' } });
        const element = mount();
        await flush();

        expect(element.shadowRoot.textContent).toContain('Ingen tilgang');
    });
});
