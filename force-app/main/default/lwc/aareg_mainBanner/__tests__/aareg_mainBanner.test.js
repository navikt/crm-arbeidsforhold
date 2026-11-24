import { createElement } from 'lwc';
import Aareg_mainBanner from 'c/aareg_mainBanner';
import getPortal from '@salesforce/apex/AAREG_EntryPortalController.getPortal';

jest.mock('@salesforce/apex/AAREG_EntryPortalController.getPortal', () => ({ default: jest.fn() }), { virtual: true });

const flush = () => new Promise((resolve) => setTimeout(resolve, 0));

async function render() {
    const element = createElement('c-aareg-main-banner', { is: Aareg_mainBanner });
    element.title = 'Aa-registeret - Mine Søknader';
    document.body.appendChild(element);
    await flush();
    return element;
}

describe('c-aareg-main-banner', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
        jest.clearAllMocks();
    });

    it('shows the title as a page heading under the portal trail when the new portal is on', async () => {
        getPortal.mockResolvedValue({ enabled: true, roles: [] });
        const element = await render();

        const heading = element.shadowRoot.querySelector('h1');
        expect(heading.textContent).toContain('Mine Søknader');
        expect(heading.classList).toContain('navds-heading');
        expect(element.shadowRoot.querySelector('.mainbanner')).toBeNull();
    });

    it('keeps the blue banner when the new portal is off', async () => {
        getPortal.mockResolvedValue({ enabled: false, roles: [] });
        const element = await render();

        expect(element.shadowRoot.querySelector('.mainbanner h1').textContent).toContain('Mine Søknader');
    });

    it('keeps the blue banner when the portal cannot be read', async () => {
        getPortal.mockRejectedValue(new Error('offline'));
        const element = await render();

        expect(element.shadowRoot.querySelector('.mainbanner')).not.toBeNull();
    });
});
