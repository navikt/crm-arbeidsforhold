import { createElement } from 'lwc';
import AaregRolePage from 'c/aaregRolePage';
import decide from '@salesforce/apex/AAREG_EntryPortalController.decide';
import getOrganizations from '@salesforce/apex/AAREG_EntryPortalController.getOrganizations';
import { CurrentPageReference, getNavigateCalls, resetNavigateCalls } from 'lightning/navigation';
import { readContext, rememberContext } from 'c/aaregPortalContext';

jest.mock('@salesforce/apex/AAREG_EntryPortalController.decide', () => ({ default: jest.fn() }), { virtual: true });
jest.mock('@salesforce/apex/AAREG_EntryPortalController.getOrganizations', () => ({ default: jest.fn() }), {
    virtual: true
});

const ORGANIZATIONS = [{ organizationNumber: '910000001', name: 'Bedrift AS' }];
const granted = (capabilities, organizationNumber = '910000001') => ({
    outcome: 'GRANTED',
    roleKey: 'Employer',
    contextType: 'Organization',
    organizationNumber,
    capabilities
});
const denied = (reason, contextType = 'Organization') => ({ outcome: 'DENIED', reason, contextType });
const flush = () => new Promise((resolve) => setTimeout(resolve, 0));
const byId = (element, id) => element.shadowRoot.querySelector(`[data-id="${id}"]`);
const panelKeys = (element) =>
    [...element.shadowRoot.querySelectorAll('[data-panel]')].map((node) => node.dataset.panel);

async function settle() {
    for (let i = 0; i < 4; i++) {
        await flush();
    }
}

async function mount(roleKey = 'Employer', state = {}) {
    const element = createElement('c-aareg-role-page', { is: AaregRolePage });
    element.roleKey = roleKey;
    document.body.appendChild(element);
    CurrentPageReference.emit({ type: 'comm__namedPage', attributes: { name: 'Arbeidsgiver__c' }, state });
    await settle();
    return element;
}

async function choose(element, organizationNumber) {
    element.shadowRoot
        .querySelector('c-aareg-org-selector')
        .dispatchEvent(new CustomEvent('select', { detail: { organizationNumber, isSelf: false } }));
    await settle();
}

describe('c-aareg-role-page', () => {
    beforeEach(() => {
        window.sessionStorage.clear();
        getOrganizations.mockResolvedValue(ORGANIZATIONS);
        resetNavigateCalls();
    });

    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
        jest.clearAllMocks();
    });

    it('asks for an organization without choosing one automatically', async () => {
        decide.mockResolvedValueOnce(denied('invalid-context'));
        const element = await mount();

        expect(decide).toHaveBeenCalledWith({ roleKey: 'Employer', organizationNumber: undefined });
        const selector = element.shadowRoot.querySelector('c-aareg-org-selector');
        expect(selector.selected).toBeUndefined();
        expect(selector.label).toBe('Velg virksomhet');
        expect(byId(element, 'select-hint')).not.toBeNull();
        expect(byId(element, 'role-bar').textContent).toContain('Rolle: Arbeidsgiver');
        expect(byId(element, 'panels')).toBeNull();
    });

    it('checks access as soon as an organization is chosen and keeps the selector visible', async () => {
        decide.mockResolvedValueOnce(denied('invalid-context')).mockResolvedValueOnce(granted(['SUPPORT', 'MESSAGES']));
        const element = await mount();
        await choose(element, '910000001');

        expect(decide).toHaveBeenLastCalledWith({ roleKey: 'Employer', organizationNumber: '910000001' });
        expect(panelKeys(element)).toEqual(['support', 'messages']);
        const selector = element.shadowRoot.querySelector('c-aareg-org-selector');
        expect(selector).not.toBeNull();
        expect(selector.selected).toBe('910000001');
        await expect(element).toBeAccessible();
    });

    it('shows every panel for full access in a fixed order', async () => {
        decide.mockResolvedValueOnce(granted(['SUPPORT', 'MESSAGES', 'APPLICATION', 'AGREEMENTS']));
        const element = await mount('Employer', { org: '910000001' });

        expect(decide).toHaveBeenCalledWith({ roleKey: 'Employer', organizationNumber: '910000001' });
        expect(panelKeys(element)).toEqual(['new-application', 'my-applications', 'agreements', 'support', 'messages']);
    });

    it('ignores an organization number that is not nine digits', async () => {
        decide.mockResolvedValueOnce(denied('invalid-context'));
        await mount('Employer', { org: '91000000x' });

        expect(decide).toHaveBeenCalledWith({ roleKey: 'Employer', organizationNumber: undefined });
    });

    it('stays on the selector with a message when the chosen organization is denied', async () => {
        decide.mockResolvedValueOnce(denied('invalid-context')).mockResolvedValueOnce(denied('no-access'));
        const element = await mount();
        await choose(element, '910000001');

        expect(byId(element, 'message')).not.toBeNull();
        expect(getNavigateCalls()).toEqual([]);
    });

    it('sends a denied direct link home with a fixed message', async () => {
        decide.mockResolvedValueOnce(denied('no-access'));
        await mount('Employer', { org: '910000002' });

        expect(getNavigateCalls()).toEqual([
            { type: 'comm__namedPage', attributes: { name: 'Home' }, state: { c__message: 'no-access' } }
        ]);
    });

    it('asks a partner which organization they act for', async () => {
        decide.mockResolvedValueOnce(denied('invalid-context'));
        const element = await mount('Partner');

        expect(element.shadowRoot.querySelector('c-aareg-org-selector').label).toBe(
            'Hvilken virksomhet handler du for?'
        );
        expect(byId(element, 'role-bar').textContent).toContain('Rolle: Samarbeidspartner / fullmektig');
    });

    it('sends an inactive role home', async () => {
        decide.mockResolvedValueOnce(denied('role-not-active'));
        await mount('Partner');

        expect(getNavigateCalls()[0].state).toEqual({ c__message: 'role-not-active' });
    });

    it('offers a retry after a technical error', async () => {
        decide.mockRejectedValueOnce(new Error('network')).mockResolvedValueOnce(granted(['SUPPORT']));
        const element = await mount('Employer', { org: '910000001' });
        expect(byId(element, 'technical-error')).not.toBeNull();

        byId(element, 'retry').click();
        await settle();

        expect(decide).toHaveBeenLastCalledWith({ roleKey: 'Employer', organizationNumber: '910000001' });
        expect(panelKeys(element)).toEqual(['support']);
    });

    it('shows the profile and an outlook for a private person without services', async () => {
        decide.mockResolvedValueOnce({ outcome: 'GRANTED', contextType: 'Person', capabilities: [] });
        const element = await mount('Private');

        expect(panelKeys(element)).toEqual(['profile']);
        expect(byId(element, 'private-coming')).not.toBeNull();
        expect(byId(element, 'private-info')).not.toBeNull();
        expect(byId(element, 'organization-selector')).toBeNull();
        expect(getOrganizations).not.toHaveBeenCalled();
    });

    it('remembers the role and the granted organization for the breadcrumb trail', async () => {
        decide.mockResolvedValueOnce(denied('invalid-context')).mockResolvedValueOnce(granted(['SUPPORT']));
        const element = await mount();
        expect(readContext()).toEqual({ roleKey: 'Employer' });

        await choose(element, '910000001');

        expect(readContext()).toEqual({
            roleKey: 'Employer',
            organizationNumber: '910000001',
            organizationName: 'Bedrift AS'
        });
    });

    it('keeps the organization chosen earlier in the session until the user changes it', async () => {
        rememberContext({ roleKey: 'Employer', organizationNumber: '910000001' });
        decide.mockResolvedValue(granted(['APPLICATION']));
        const element = await mount('Employer');

        expect(decide).toHaveBeenCalledWith({ roleKey: 'Employer', organizationNumber: '910000001' });
        expect(element.shadowRoot.querySelector('c-aareg-org-selector').selected).toBe('910000001');
    });

    it('does not reuse an organization remembered for another role', async () => {
        rememberContext({ roleKey: 'Partner', organizationNumber: '910000001' });
        decide.mockResolvedValue(denied('invalid-context'));
        await mount('Employer');

        expect(decide).toHaveBeenCalledWith({ roleKey: 'Employer', organizationNumber: undefined });
    });

    it('forgets the context when the user changes role', async () => {
        rememberContext({ roleKey: 'Employer', organizationNumber: '910000001' });
        decide.mockResolvedValueOnce(granted(['SUPPORT']));
        const element = await mount('Employer', { org: '910000001' });

        byId(element, 'change-role').click();

        expect(readContext()).toEqual({});
        expect(getNavigateCalls()).toEqual([{ type: 'comm__namedPage', attributes: { name: 'Home' }, state: {} }]);
    });
});
