import { createElement } from 'lwc';
import AaregContactModelPanel from 'c/aaregContactModelPanel';
import getPanel from '@salesforce/apex/AAREG_ContactModelPanelController.getPanel';

jest.mock(
    '@salesforce/apex/AAREG_ContactModelPanelController.getPanel',
    () => {
        const { createApexTestWireAdapter } = require('@salesforce/sfdx-lwc-jest');
        return { default: createApexTestWireAdapter(jest.fn()) };
    },
    { virtual: true }
);

const flush = () => new Promise((resolve) => setTimeout(resolve, 0));

function mount() {
    const element = createElement('c-aareg-contact-model-panel', { is: AaregContactModelPanel });
    element.recordId = '003000000000001AAA';
    document.body.appendChild(element);
    return element;
}

describe('c-aareg-contact-model-panel', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
    });

    it('shows the summary, a table for sections with rows and an empty text otherwise', async () => {
        const element = mount();
        getPanel.emit({
            summary: 'Domenekontakt i Aa-registeret.',
            sections: [
                {
                    key: 'organizations',
                    title: 'Organisasjonar (ACR)',
                    emptyText: 'Ingen organisasjonstilknytingar.',
                    columns: [{ label: 'Org.nr.', fieldName: 'organizationNumber' }],
                    rows: [{ id: '001', organizationNumber: '999888777' }]
                },
                {
                    key: 'participations',
                    title: 'Roller på søknader',
                    emptyText: 'Ingen roller.',
                    columns: [],
                    rows: []
                }
            ]
        });
        await flush();

        expect(element.shadowRoot.querySelector('[data-id="summary"]').textContent).toBe(
            'Domenekontakt i Aa-registeret.'
        );
        const organizations = element.shadowRoot.querySelector('[data-section="organizations"]');
        expect(organizations.querySelector('lightning-datatable').data).toHaveLength(1);
        const participations = element.shadowRoot.querySelector('[data-section="participations"]');
        expect(participations.querySelector('lightning-datatable')).toBeNull();
        expect(participations.textContent).toContain('Ingen roller.');
    });

    it('shows an error when the panel cannot be read', async () => {
        const element = mount();
        getPanel.error({ message: 'Ingen tilgang' });
        await flush();

        expect(element.shadowRoot.querySelector('[data-id="error"]')).not.toBeNull();
    });
});
