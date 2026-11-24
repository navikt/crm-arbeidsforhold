import { createElement } from 'lwc';
import AaregEntryPortal from 'c/aaregEntryPortal';
import getPortal from '@salesforce/apex/AAREG_EntryPortalController.getPortal';
import getSettings from '@salesforce/apex/AAREG_ContactModelPortalController.getSettings';
import { CurrentPageReference, getNavigateCalls, resetNavigateCalls } from 'lightning/navigation';
import { readContext, rememberContext } from 'c/aaregPortalContext';

jest.mock('@salesforce/apex/AAREG_EntryPortalController.getPortal', () => ({ default: jest.fn() }), {
    virtual: true
});
jest.mock('@salesforce/apex/AAREG_ContactModelPortalController.getSettings', () => ({ default: jest.fn() }), {
    virtual: true
});

const ROLES = [
    { roleKey: 'Employer', contextType: 'Organization', pageApiName: 'Arbeidsgiver__c' },
    { roleKey: 'Partner', contextType: 'Organization', pageApiName: 'Samarbeidspartner__c' },
    { roleKey: 'Private', contextType: 'Person', pageApiName: 'Privatperson__c' }
];
const flush = () => new Promise((resolve) => setTimeout(resolve, 0));
const byId = (element, id) => element.shadowRoot.querySelector(`[data-id="${id}"]`);

async function mount(state = {}) {
    const element = createElement('c-aareg-entry-portal', { is: AaregEntryPortal });
    document.body.appendChild(element);
    CurrentPageReference.emit({ type: 'comm__namedPage', attributes: { name: 'Home' }, state });
    await flush();
    await flush();
    await flush();
    return element;
}

describe('c-aareg-entry-portal', () => {
    beforeEach(() => {
        getSettings.mockResolvedValue({ profile: true });
        resetNavigateCalls();
    });

    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
        jest.clearAllMocks();
    });

    it('shows the current home page when the portal is off', async () => {
        getPortal.mockResolvedValue({ enabled: false, roles: [] });
        const element = await mount();

        expect(byId(element, 'current-home')).not.toBeNull();
        expect(byId(element, 'roles')).toBeNull();
    });

    it('falls back to the current home page when the portal cannot load', async () => {
        getPortal.mockRejectedValue({ body: { message: 'boom' } });
        const element = await mount();

        expect(byId(element, 'current-home')).not.toBeNull();
    });

    it('lists the roles in server order with nothing preselected', async () => {
        getPortal.mockResolvedValue({ enabled: true, roles: ROLES });
        const element = await mount();

        const roles = [...element.shadowRoot.querySelectorAll('.role-title')].map((node) => node.textContent);
        expect(roles).toEqual(['Arbeidsgiver', 'Samarbeidspartner / fullmektig', 'Privatperson / arbeidstaker']);
        expect(byId(element, 'current-home')).toBeNull();
        expect(byId(element, 'profile')).not.toBeNull();
        expect(getNavigateCalls()).toEqual([]);
        await expect(element).toBeAccessible();
    });

    it('ignores roles it has no text for', async () => {
        getPortal.mockResolvedValue({
            enabled: true,
            roles: [...ROLES, { roleKey: 'Estate', contextType: 'Estate', pageApiName: 'Dodsbo__c' }]
        });
        const element = await mount();

        expect(element.shadowRoot.querySelectorAll('.role-link')).toHaveLength(3);
    });

    it('navigates to the role page when a role is chosen', async () => {
        getPortal.mockResolvedValue({ enabled: true, roles: ROLES });
        const element = await mount();

        element.shadowRoot.querySelector('[data-role="Partner"]').click();

        expect(getNavigateCalls()).toEqual([
            { type: 'comm__namedPage', attributes: { name: 'Samarbeidspartner__c' }, state: {} }
        ]);
    });

    it('shows a fixed message and ignores unknown message codes', async () => {
        getPortal.mockResolvedValue({ enabled: true, roles: ROLES });
        const known = await mount({ c__message: 'no-access' });
        expect(byId(known, 'message').textContent).toBe('Du har ikke tilgang til denne siden. Velg en annen rolle.');
        document.body.removeChild(known);

        const unknown = await mount({ c__message: '<script>' });
        expect(byId(unknown, 'message')).toBeNull();
    });

    it('follows a direct link to an available role with a valid organization number', async () => {
        getPortal.mockResolvedValue({ enabled: true, roles: ROLES });
        await mount({ type: 'employer', org: '910000001' });

        expect(getNavigateCalls()).toEqual([
            { type: 'comm__namedPage', attributes: { name: 'Arbeidsgiver__c' }, state: { org: '910000001' } }
        ]);
    });

    it('drops an invalid organization number and the organization for a person role', async () => {
        getPortal.mockResolvedValue({ enabled: true, roles: ROLES });
        await mount({ type: 'agent', org: '12' });
        await mount({ type: 'private-person', org: '910000001' });

        expect(getNavigateCalls()).toEqual([
            { type: 'comm__namedPage', attributes: { name: 'Samarbeidspartner__c' }, state: {} },
            { type: 'comm__namedPage', attributes: { name: 'Privatperson__c' }, state: {} }
        ]);
    });

    it('stays on the portal when a direct link points to an unavailable role', async () => {
        getPortal.mockResolvedValue({ enabled: true, roles: ROLES.slice(0, 1) });
        const element = await mount({ type: 'agent' });

        expect(getNavigateCalls()).toEqual([]);
        expect(byId(element, 'roles')).not.toBeNull();
    });

    it('forgets the previously chosen role when the home page opens', async () => {
        rememberContext({ roleKey: 'Employer', organizationNumber: '889640782' });
        getPortal.mockResolvedValue({ enabled: true, roles: ROLES });
        await mount();

        expect(readContext()).toEqual({});
    });

    it('links each role card to its page so it can open in a new tab', async () => {
        getPortal.mockResolvedValue({ enabled: true, roles: ROLES });
        const element = await mount();

        expect(element.shadowRoot.querySelector('[data-role="Employer"]').getAttribute('href')).toBe('/s/arbeidsgiver');
    });

    it('hides the profile tile when the profile is off', async () => {
        getPortal.mockResolvedValue({ enabled: true, roles: ROLES });
        getSettings.mockResolvedValue({ profile: false });
        const element = await mount();

        expect(byId(element, 'profile')).toBeNull();
    });
});
