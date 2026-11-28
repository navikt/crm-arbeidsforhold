import { createElement } from 'lwc';
import AaregLegacyBreadcrumbs from 'c/aaregLegacyBreadcrumbs';
import getPortal from '@salesforce/apex/AAREG_EntryPortalController.getPortal';

jest.mock('@salesforce/apex/AAREG_EntryPortalController.getPortal', () => ({ default: jest.fn() }), { virtual: true });

const flush = () => new Promise((resolve) => setTimeout(resolve, 0));
const URL_LIST = [
    { label: 'Min side', href: '' },
    { label: 'Mine meldinger', href: 'mine-meldinger' }
];

async function render() {
    const element = createElement('c-aareg-legacy-breadcrumbs', { is: AaregLegacyBreadcrumbs });
    element.urlList = URL_LIST;
    element.numPops = 2;
    document.body.appendChild(element);
    await flush();
    return element;
}

describe('c-aareg-legacy-breadcrumbs', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
        jest.clearAllMocks();
    });

    it('leaves navigation to the portal trail when the new portal is on', async () => {
        getPortal.mockResolvedValue({ enabled: true, roles: [] });
        const element = await render();

        expect(element.shadowRoot.querySelector('c-breadcrumbs')).toBeNull();
    });

    it('passes the legacy trail through when the new portal is off', async () => {
        getPortal.mockResolvedValue({ enabled: false, roles: [] });
        const element = await render();

        const legacy = element.shadowRoot.querySelector('c-breadcrumbs');
        expect(legacy.urlList).toEqual(URL_LIST);
        expect(legacy.numPops).toBe(2);
    });

    it('keeps the legacy trail when the portal state cannot be read', async () => {
        getPortal.mockRejectedValue(new Error('unavailable'));
        const element = await render();

        expect(element.shadowRoot.querySelector('c-breadcrumbs')).not.toBeNull();
    });
});
