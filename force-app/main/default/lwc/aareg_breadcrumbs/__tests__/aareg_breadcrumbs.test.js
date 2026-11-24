import { createElement } from 'lwc';
import AaregBreadcrumbs from 'c/aareg_breadcrumbs';
import getPortal from '@salesforce/apex/AAREG_EntryPortalController.getPortal';

jest.mock('@salesforce/apex/AAREG_EntryPortalController.getPortal', () => ({ default: jest.fn() }), { virtual: true });

const flush = () => new Promise((resolve) => setTimeout(resolve, 0));

async function render() {
    window.history.pushState({}, '', '/aaregisteret/s/thread/a0X000000000001AAA/melding');
    const element = createElement('c-aareg-breadcrumbs', { is: AaregBreadcrumbs });
    element.firstHref = 'Hjem';
    element.secondHref = 'Mine Meldinger';
    element.thirdHref = 'Henvendelse';
    document.body.appendChild(element);
    await flush();
    return element;
}

describe('c-aareg-breadcrumbs', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
        jest.clearAllMocks();
    });

    it('steps aside when the new portal trail is switched on', async () => {
        getPortal.mockResolvedValue({ enabled: true, roles: [] });
        const element = await render();

        expect(element.shadowRoot.querySelector('nav')).toBeNull();
    });

    it('keeps the legacy trail when the new portal is switched off', async () => {
        getPortal.mockResolvedValue({ enabled: false, roles: [] });
        const element = await render();

        const labels = [...element.shadowRoot.querySelectorAll('nav li')].map((item) => item.textContent.trim());
        expect(labels).toEqual(['Hjem', 'Mine Meldinger', 'Henvendelse']);
    });

    it('keeps the legacy trail when the portal state cannot be read', async () => {
        getPortal.mockRejectedValue(new Error('unavailable'));
        const element = await render();

        expect(element.shadowRoot.querySelector('nav')).not.toBeNull();
    });
});
