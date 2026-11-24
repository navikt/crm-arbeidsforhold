import { createElement } from 'lwc';
import AaregApplicationStart from 'c/aaregApplicationStart';
import getOrganizations from '@salesforce/apex/AAREG_ContactModelPortalController.getOrganizations';
import selectApplicationOrganization from '@salesforce/apex/AAREG_ContactModelPortalController.selectApplicationOrganization';

jest.mock('@salesforce/apex/AAREG_ContactModelPortalController.getOrganizations', () => ({ default: jest.fn() }), {
    virtual: true
});
jest.mock(
    '@salesforce/apex/AAREG_ContactModelPortalController.selectApplicationOrganization',
    () => ({ default: jest.fn() }),
    { virtual: true }
);

const ORGANIZATIONS = [{ organizationNumber: '889640782', name: 'Arbeids- og velferdsetaten' }];
const NAV = { organizationNumber: '889640782', name: 'Arbeids- og velferdsetaten', isSelf: false };
const flush = () => new Promise((resolve) => setTimeout(resolve, 0));

function mount() {
    const element = createElement('c-aareg-application-start', { is: AaregApplicationStart });
    document.body.appendChild(element);
    return element;
}

const byId = (element, id) => element.shadowRoot.querySelector(`[data-id="${id}"]`);
const selector = (element) => element.shadowRoot.querySelector('c-aareg-org-selector');

async function chooseRole(element, role) {
    const input = element.shadowRoot.querySelector(`input[data-role="${role}"]`);
    input.checked = true;
    input.dispatchEvent(new CustomEvent('change'));
    await flush();
    await flush();
}

async function chooseOrganization(element, detail) {
    selector(element).dispatchEvent(new CustomEvent('select', { detail }));
    await flush();
}

describe('c-aareg-application-start', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
        jest.clearAllMocks();
    });

    it('asks for a role before anything else and preselects none', async () => {
        const element = mount();
        await flush();

        const radios = element.shadowRoot.querySelectorAll('input[type="radio"]');
        expect(radios).toHaveLength(3);
        expect([...radios].some((radio) => radio.checked)).toBe(false);
        expect(selector(element)).toBeNull();
        expect(getOrganizations).not.toHaveBeenCalled();
    });

    it('explains that private persons cannot apply and links to the profile', async () => {
        const element = mount();
        await chooseRole(element, 'PRIVATE');

        expect(byId(element, 'private')).not.toBeNull();
        expect(byId(element, 'profile-link').getAttribute('href')).toBe('min-profil');
        expect(selector(element)).toBeNull();
        expect(getOrganizations).not.toHaveBeenCalled();
    });

    it('loads organizations once and shows the searchable selector without «Meg selv»', async () => {
        getOrganizations.mockResolvedValue(ORGANIZATIONS);
        const element = mount();
        await chooseRole(element, 'EMPLOYER');
        await chooseRole(element, 'PARTNER');

        expect(getOrganizations).toHaveBeenCalledTimes(1);
        expect(selector(element).organizations).toEqual(ORGANIZATIONS);
        expect(selector(element).includeSelf).toBeFalsy();
        expect(byId(element, 'continue').disabled).toBe(true);
    });

    it('shows a warning when Altinn cannot be reached', async () => {
        getOrganizations.mockRejectedValue({ body: { message: 'Altinn svarar ikkje.' } });
        const element = mount();
        await chooseRole(element, 'EMPLOYER');

        expect(byId(element, 'organizations-error').textContent).toBe('Altinn svarar ikkje.');
        expect(selector(element)).toBeNull();
    });

    it('verifies the organization on the server before continuing', async () => {
        getOrganizations.mockResolvedValue(ORGANIZATIONS);
        selectApplicationOrganization.mockResolvedValue('889640782');
        const element = mount();
        const handler = jest.fn();
        element.addEventListener('organizationselected', handler);
        await chooseRole(element, 'EMPLOYER');
        await chooseOrganization(element, NAV);

        byId(element, 'organization-form').dispatchEvent(new CustomEvent('submit', { cancelable: true }));
        await flush();
        await flush();

        expect(selectApplicationOrganization).toHaveBeenCalledWith({ organizationNumber: '889640782' });
        expect(handler).toHaveBeenCalledTimes(1);
        expect(handler.mock.calls[0][0].detail).toEqual({
            organizationNumber: '889640782',
            name: 'Arbeids- og velferdsetaten',
            role: 'EMPLOYER'
        });
    });

    it('stays on the step and shows the reason when the role is not confirmed', async () => {
        getOrganizations.mockResolvedValue(ORGANIZATIONS);
        selectApplicationOrganization.mockRejectedValue({ body: { message: 'Du har ikkje rolla i Altinn.' } });
        const element = mount();
        const handler = jest.fn();
        element.addEventListener('organizationselected', handler);
        await chooseRole(element, 'PARTNER');
        await chooseOrganization(element, NAV);

        byId(element, 'organization-form').dispatchEvent(new CustomEvent('submit', { cancelable: true }));
        await flush();
        await flush();

        expect(byId(element, 'error').textContent).toBe('Du har ikkje rolla i Altinn.');
        expect(handler).not.toHaveBeenCalled();
    });
});
