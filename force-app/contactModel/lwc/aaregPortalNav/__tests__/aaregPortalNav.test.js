import { createElement } from 'lwc';
import AaregPortalNav from 'c/aaregPortalNav';
import { CurrentPageReference, getNavigateCalls, resetNavigateCalls } from 'lightning/navigation';
import getPortal from '@salesforce/apex/AAREG_EntryPortalController.getPortal';
import { rememberContext } from 'c/aaregPortalContext';

jest.mock('@salesforce/apex/AAREG_EntryPortalController.getPortal', () => ({ default: jest.fn() }), { virtual: true });

const flush = () => new Promise((resolve) => setTimeout(resolve, 0));

async function render(path) {
    window.history.pushState({}, '', path);
    const element = createElement('c-aareg-portal-nav', { is: AaregPortalNav });
    document.body.appendChild(element);
    await flush();
    CurrentPageReference.emit({ type: 'comm__namedPage', attributes: { name: 'x' }, state: {} });
    await flush();
    return element;
}

describe('c-aareg-portal-nav', () => {
    beforeEach(() => {
        window.sessionStorage.clear();
        resetNavigateCalls();
        getPortal.mockResolvedValue({ enabled: true, roles: [] });
    });

    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
        jest.clearAllMocks();
    });

    it('renders the breadcrumb trail with the current page marked', async () => {
        rememberContext({ roleKey: 'Employer', organizationNumber: '889640782' });
        const element = await render('/s/mine-soknader');

        const nav = element.shadowRoot.querySelector('nav');
        expect(nav.getAttribute('aria-label')).toBe('Brødsmulesti');
        const links = [...nav.querySelectorAll('ol a')].map((anchor) => anchor.textContent.trim());
        expect(links).toEqual(['Forside', 'Arbeidsgiver']);
        expect(nav.querySelector('[aria-current="page"]').textContent.trim()).toBe('Mine søknader');
        expect(element.shadowRoot.querySelector('[data-id="back"]').textContent).toContain('Tilbake til Arbeidsgiver');
    });

    it('navigates within the site and keeps the organization on the role page', async () => {
        rememberContext({ roleKey: 'Employer', organizationNumber: '889640782' });
        const element = await render('/s/mine-avtaler');

        element.shadowRoot.querySelector('[data-id="back"]').click();

        expect(getNavigateCalls()).toEqual([
            { type: 'comm__namedPage', attributes: { name: 'Arbeidsgiver__c' }, state: { org: '889640782' } }
        ]);
    });

    it('leads from a message back through Mine meldinger to the role page', async () => {
        rememberContext({ roleKey: 'Partner', organizationNumber: '889640782' });
        const element = await render('/s/thread/a0X000000000001AAA/melding');

        const nav = element.shadowRoot.querySelector('nav');
        const links = [...nav.querySelectorAll('ol a')].map((anchor) => anchor.textContent.trim());
        expect(links).toEqual(['Forside', 'Samarbeidspartner / fullmektig', 'Mine meldinger']);
        expect(nav.querySelector('[aria-current="page"]').textContent.trim()).toBe('Melding');
        expect(element.shadowRoot.querySelector('[data-id="back"]').textContent).toContain(
            'Tilbake til Mine meldinger'
        );
    });

    it('renders nothing when the new portal is switched off', async () => {
        getPortal.mockResolvedValue({ enabled: false, roles: [] });
        const element = await render('/s/mine-soknader');

        expect(element.shadowRoot.querySelector('nav')).toBeNull();
    });

    it('renders nothing on the home page', async () => {
        const element = await render('/s/');

        expect(element.shadowRoot.querySelector('nav')).toBeNull();
    });
});
