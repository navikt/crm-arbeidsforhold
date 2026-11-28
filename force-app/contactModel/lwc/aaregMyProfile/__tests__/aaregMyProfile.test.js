import { createElement } from 'lwc';
import AaregMyProfile from 'c/aaregMyProfile';
import getSettings from '@salesforce/apex/AAREG_ContactModelPortalController.getSettings';
import getOrganizations from '@salesforce/apex/AAREG_ContactModelPortalController.getOrganizations';
import getProfile from '@salesforce/apex/AAREG_ContactModelPortalController.getProfile';
import saveAddress from '@salesforce/apex/AAREG_ContactModelPortalController.saveAddress';
import { rememberContext } from 'c/aaregPortalContext';

jest.mock('@salesforce/apex/AAREG_ContactModelPortalController.getSettings', () => ({ default: jest.fn() }), {
    virtual: true
});
jest.mock('@salesforce/apex/AAREG_ContactModelPortalController.getOrganizations', () => ({ default: jest.fn() }), {
    virtual: true
});
jest.mock('@salesforce/apex/AAREG_ContactModelPortalController.getProfile', () => ({ default: jest.fn() }), {
    virtual: true
});
jest.mock('@salesforce/apex/AAREG_ContactModelPortalController.saveAddress', () => ({ default: jest.fn() }), {
    virtual: true
});

const ORGANIZATIONS = [{ organizationNumber: '889640782', name: 'Arbeids- og velferdsetaten' }];
const flush = () => new Promise((resolve) => setTimeout(resolve, 0));

async function mount(settings = { profile: true, orgSelector: true }) {
    getSettings.mockResolvedValue(settings);
    getOrganizations.mockResolvedValue(ORGANIZATIONS);
    const element = createElement('c-aareg-my-profile', { is: AaregMyProfile });
    document.body.appendChild(element);
    await flush();
    await flush();
    return element;
}

const byId = (element, id) => element.shadowRoot.querySelector(`[data-id="${id}"]`);
const selector = (element) => element.shadowRoot.querySelector('c-aareg-org-selector');

async function choose(element, detail) {
    selector(element).dispatchEvent(new CustomEvent('select', { detail }));
    await flush();
    await flush();
}

const SELF = { organizationNumber: null, name: 'Meg selv', isSelf: true };
const NAV = { organizationNumber: '889640782', name: 'Arbeids- og velferdsetaten', isSelf: false };

describe('c-aareg-my-profile', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
        jest.clearAllMocks();
    });

    it('shows no address until a context is chosen', async () => {
        const element = await mount();

        expect(selector(element).organizations).toEqual(ORGANIZATIONS);
        expect(byId(element, 'choose-first')).not.toBeNull();
        expect(byId(element, 'form')).toBeNull();
        expect(getProfile).not.toHaveBeenCalled();
    });

    it('starts with the organization chosen on the role page and still checks it in Altinn', async () => {
        window.sessionStorage.clear();
        rememberContext({ roleKey: 'Employer', organizationNumber: '889640782' });
        getProfile.mockResolvedValue({
            organization: { organizationNumber: '889640782', name: 'Arbeids- og velferdsetaten', verified: true }
        });
        const element = await mount();
        await flush();

        expect(getProfile).toHaveBeenCalledWith({ organizationNumber: '889640782' });
        expect(selector(element).selected).toBe('889640782');
        expect(byId(element, 'choose-first')).toBeNull();
        window.sessionStorage.clear();
    });

    it('starts with «Meg selv» for a private person', async () => {
        window.sessionStorage.clear();
        rememberContext({ roleKey: 'Private' });
        getProfile.mockResolvedValue({ privateEmail: 'meg@example.invalid' });
        const element = await mount();
        await flush();

        expect(getProfile).toHaveBeenCalledWith({ organizationNumber: null });
        expect(selector(element).selected).toBe('SELF');
        window.sessionStorage.clear();
    });

    it('shows only the private address for «Meg selv»', async () => {
        getProfile.mockResolvedValue({ privateEmail: 'meg@example.com', organization: null });
        const element = await mount();
        await choose(element, SELF);

        expect(getProfile).toHaveBeenCalledWith({ organizationNumber: null });
        expect(byId(element, 'email').value).toBe('meg@example.com');
        expect(byId(element, 'form').textContent).toContain('eigne vegner');
    });

    it('shows the organization address only after Altinn confirms the role', async () => {
        getProfile.mockResolvedValue({
            privateEmail: 'meg@example.com',
            organization: { organizationNumber: '889640782', name: 'Nav', verified: true, email: 'jobb@nav.no' }
        });
        const element = await mount();
        await choose(element, NAV);

        expect(byId(element, 'email').value).toBe('jobb@nav.no');
        expect(element.shadowRoot.textContent).not.toContain('meg@example.com');
    });

    it('explains a denied role and shows no form', async () => {
        getProfile.mockResolvedValue({
            privateEmail: 'meg@example.com',
            organization: {
                organizationNumber: '889640782',
                verified: false,
                message: 'Altinn stadfestar ikkje rolla di.'
            }
        });
        const element = await mount();
        await choose(element, NAV);

        expect(byId(element, 'denied').textContent).toContain('Altinn stadfestar ikkje');
        expect(byId(element, 'form')).toBeNull();
    });

    it('saves the address for the chosen context', async () => {
        getProfile.mockResolvedValue({
            organization: { organizationNumber: '889640782', name: 'Nav', verified: true, email: 'gammal@nav.no' }
        });
        saveAddress.mockResolvedValue({
            organization: { organizationNumber: '889640782', name: 'Nav', verified: true, email: 'ny@nav.no' }
        });
        const element = await mount();
        await choose(element, NAV);

        const email = byId(element, 'email');
        email.reportValidity = jest.fn(() => true);
        email.value = 'ny@nav.no';
        email.dispatchEvent(new CustomEvent('change'));
        byId(element, 'form').dispatchEvent(new CustomEvent('submit', { cancelable: true }));
        await flush();
        await flush();

        expect(saveAddress).toHaveBeenCalledWith({ organizationNumber: '889640782', email: 'ny@nav.no', phone: '' });
        expect(byId(element, 'saved').textContent).toContain('Andre adresser er ikkje endra');
    });

    it('keeps «Meg selv» usable when Altinn fails', async () => {
        getSettings.mockResolvedValue({ profile: true, orgSelector: true });
        getOrganizations.mockRejectedValue({ body: { message: 'Altinn svarar ikkje.' } });
        const element = createElement('c-aareg-my-profile', { is: AaregMyProfile });
        document.body.appendChild(element);
        await flush();
        await flush();

        expect(byId(element, 'organizations-error').textContent).toContain('Meg selv');
        expect(selector(element)).not.toBeNull();
    });

    it('tells the user when the profile is switched off', async () => {
        const element = await mount({ profile: false, orgSelector: false });

        expect(byId(element, 'disabled')).not.toBeNull();
        expect(getOrganizations).not.toHaveBeenCalled();
    });
});
