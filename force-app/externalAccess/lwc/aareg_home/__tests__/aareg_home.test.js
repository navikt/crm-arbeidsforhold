import { createElement } from 'lwc';
import Aareg_home from 'c/aareg_home';
import getOrganizationsWithRoles from '@salesforce/apex/AAREG_HomeController.getOrganizationsWithRoles';
import getLastUsersLastUsedOrganization from '@salesforce/apex/AAREG_HomeController.getLastUsersLastUsedOrganization';
import checkAndShareIfAuthorized from '@salesforce/apex/AAREG_HomeController.checkAndShareIfAuthorized';
import updateLastUsedOrganization from '@salesforce/apex/AAREG_HomeController.updateLastUsedOrganization';
import getUsersThreads from '@salesforce/apex/AAREG_MyThreadsController.getUsersThreads';
import { refreshApex } from '@salesforce/apex';

jest.mock('@salesforce/user/Id', () => ({ default: 'test-user' }), { virtual: true });
jest.mock(
    '@salesforce/apex/AAREG_HomeController.getOrganizationsWithRoles',
    () => {
        const { createApexTestWireAdapter } = jest.requireActual('@salesforce/sfdx-lwc-jest');
        return { default: createApexTestWireAdapter(jest.fn()) };
    },
    { virtual: true }
);
jest.mock('@salesforce/apex/AAREG_HomeController.getLastUsersLastUsedOrganization', () => ({ default: jest.fn() }), {
    virtual: true
});
jest.mock('@salesforce/apex/AAREG_HomeController.updateLastUsedOrganization', () => ({ default: jest.fn() }), {
    virtual: true
});
jest.mock('@salesforce/apex/AAREG_HomeController.checkAndShareIfAuthorized', () => ({ default: jest.fn() }), {
    virtual: true
});
jest.mock(
    '@salesforce/apex/AAREG_MyThreadsController.getUsersThreads',
    () => {
        const { createApexTestWireAdapter } = jest.requireActual('@salesforce/sfdx-lwc-jest');
        return { default: createApexTestWireAdapter(jest.fn()) };
    },
    { virtual: true }
);
const organizationsAdapter = getOrganizationsWithRoles;
const threadsAdapter = getUsersThreads;

const initialOrganizations = {
    success: true,
    altinnVersion: 'v3',
    organizations: [{ type: 'Organization', unitType: 'AS', organizationNumber: '111111111', name: 'Organization A' }]
};

const refreshedOrganizations = {
    ...initialOrganizations,
    organizations: [
        ...initialOrganizations.organizations,
        { type: 'Organization', unitType: 'AS', organizationNumber: '222222222', name: 'Organization B' }
    ]
};

const flushPromises = () => new Promise((resolve) => setTimeout(resolve, 0));

async function createHome() {
    const element = createElement('c-aareg_home', { is: Aareg_home });
    document.body.appendChild(element);
    await flushPromises();
    threadsAdapter.emit([]);
    return element;
}

async function initializeHome() {
    const element = await createHome();
    organizationsAdapter.emit(initialOrganizations);
    await flushPromises();
    await flushPromises();
    return element;
}

describe('c-aareg-home', () => {
    afterEach(() => {
        document.body.innerHTML = '';
        jest.clearAllMocks();
        jest.restoreAllMocks();
    });

    it('refreshes organizations and rechecks the selected organization', async () => {
        getLastUsersLastUsedOrganization.mockResolvedValue('111111111');
        checkAndShareIfAuthorized
            .mockResolvedValueOnce({ hasAccess: true, hasApplicationAccess: true })
            .mockResolvedValueOnce({ hasAccess: false, hasApplicationAccess: false });
        refreshApex.mockImplementation(async () => {
            organizationsAdapter.emit(refreshedOrganizations);
        });
        const element = await initializeHome();

        const refreshButton = element.shadowRoot.querySelector('[data-id="refresh-organizations"]');
        expect(refreshButton).not.toBeNull();
        expect(element.shadowRoot.querySelector('.inner-container')).not.toBeNull();
        expect(element.shadowRoot.querySelector('.organization-select').value).toBe('111111111');

        refreshButton.dispatchEvent(new CustomEvent('click'));
        await flushPromises();
        await flushPromises();
        await flushPromises();

        expect(refreshApex).toHaveBeenCalledTimes(1);
        expect(getLastUsersLastUsedOrganization).toHaveBeenCalledTimes(2);
        expect(checkAndShareIfAuthorized).toHaveBeenCalledTimes(2);
        expect(
            Array.from(element.shadowRoot.querySelectorAll('.organization-select option')).some(
                (option) => option.value === '222222222'
            )
        ).toBe(true);
        expect(element.shadowRoot.querySelector('c-aareg_missing-access')).not.toBeNull();
    });

    it('clears access and does not recheck when the selected organization is no longer available', async () => {
        getLastUsersLastUsedOrganization.mockResolvedValue('111111111');
        checkAndShareIfAuthorized.mockResolvedValue({ hasAccess: true, hasApplicationAccess: true });
        refreshApex.mockImplementation(async () => {
            organizationsAdapter.emit({
                ...initialOrganizations,
                organizations: [{ ...initialOrganizations.organizations[0], unitType: 'BEDR' }]
            });
        });
        const element = await initializeHome();

        element.shadowRoot.querySelector('[data-id="refresh-organizations"]').dispatchEvent(new CustomEvent('click'));
        await flushPromises();
        await flushPromises();

        expect(checkAndShareIfAuthorized).toHaveBeenCalledTimes(1);
        expect(element.shadowRoot.querySelector('c-aareg_missing-access')).toBeNull();
    });

    it('clears access and displays an error when refreshing organizations fails', async () => {
        jest.spyOn(console, 'error').mockImplementation(() => {});
        getLastUsersLastUsedOrganization.mockResolvedValue('111111111');
        checkAndShareIfAuthorized.mockResolvedValue({ hasAccess: true, hasApplicationAccess: true });
        refreshApex.mockImplementation(async () => {
            organizationsAdapter.error({ message: 'refresh failed' }, 500);
        });
        const element = await initializeHome();

        const refreshButton = element.shadowRoot.querySelector('[data-id="refresh-organizations"]');
        expect(refreshButton.variant).toBe('neutral');
        expect(refreshButton.iconName).toBe('utility:refresh');
        refreshButton.dispatchEvent(new CustomEvent('click'));
        await flushPromises();
        await flushPromises();

        expect(checkAndShareIfAuthorized).toHaveBeenCalledTimes(1);
        expect(element.shadowRoot.querySelector('.error-message')).not.toBeNull();
        expect(element.shadowRoot.querySelector('[data-id="refresh-organizations"]')).not.toBeNull();
        expect(element.shadowRoot.querySelector('.organization-select')).toBeNull();
        expect(element.shadowRoot.querySelector('c-aareg_missing-access')).toBeNull();
    });

    it('shows an explicit empty state when refresh succeeds without organizations', async () => {
        getLastUsersLastUsedOrganization.mockResolvedValue('111111111');
        checkAndShareIfAuthorized.mockResolvedValue({ hasAccess: true, hasApplicationAccess: true });
        refreshApex.mockImplementation(async () => {
            organizationsAdapter.emit({ ...initialOrganizations, organizations: [] });
        });
        const element = await initializeHome();

        element.shadowRoot.querySelector('[data-id="refresh-organizations"]').dispatchEvent(new CustomEvent('click'));
        await flushPromises();
        await flushPromises();

        expect(element.shadowRoot.querySelector('[data-id="organization-empty-state"]')).not.toBeNull();
        expect(element.shadowRoot.querySelector('[data-id="refresh-organizations"]')).not.toBeNull();
        expect(element.shadowRoot.querySelector('c-aareg_missing-access')).toBeNull();
    });

    it('requires an explicit selection when the saved organization disappears, then grants support for B', async () => {
        getLastUsersLastUsedOrganization.mockResolvedValue('111111111');
        checkAndShareIfAuthorized
            .mockResolvedValueOnce({ hasAccess: true, hasApplicationAccess: true })
            .mockResolvedValueOnce({ hasAccess: true, hasApplicationAccess: false });
        updateLastUsedOrganization.mockResolvedValue();
        refreshApex.mockImplementation(async () => {
            organizationsAdapter.emit({
                ...initialOrganizations,
                organizations: [refreshedOrganizations.organizations[1]]
            });
        });
        const element = await initializeHome();
        element.shadowRoot.querySelector('[data-id="refresh-organizations"]').click();
        await flushPromises();
        await flushPromises();

        const select = element.shadowRoot.querySelector('.organization-select');
        expect(select.value).toBe('');
        expect(element.shadowRoot.querySelector('.inner-container')).toBeNull();
        expect(checkAndShareIfAuthorized).toHaveBeenCalledTimes(1);
        select.value = '222222222';
        select.dispatchEvent(new CustomEvent('change'));
        await flushPromises();
        await flushPromises();

        expect(element.shadowRoot.querySelector('.organization-select').value).toBe('222222222');
        expect(updateLastUsedOrganization).toHaveBeenCalledWith({
            userId: 'test-user',
            organizationNumber: '222222222'
        });
        expect(checkAndShareIfAuthorized).toHaveBeenLastCalledWith({
            userId: 'test-user',
            orgNumber: '222222222'
        });
        const panels = Array.from(element.shadowRoot.querySelectorAll('c-link-panel'));
        expect(panels.some((panel) => panel.title === 'Brukerstøtte vedrørende Aa-registeret')).toBe(true);
        expect(panels.some((panel) => panel.title === 'Ny søknad')).toBe(false);
    });

    it('keeps a response-level organization error visible on repeated refresh without a new wire emission', async () => {
        jest.spyOn(console, 'error').mockImplementation(() => {});
        getLastUsersLastUsedOrganization.mockResolvedValue('111111111');
        checkAndShareIfAuthorized.mockResolvedValue({ hasAccess: true, hasApplicationAccess: true });
        const element = await initializeHome();
        refreshApex.mockImplementationOnce(async () => {
            organizationsAdapter.emit({ success: false, altinnVersion: 'v3', errorMessage: 'Synthetic failure' });
        });
        element.shadowRoot.querySelector('[data-id="refresh-organizations"]').click();
        await flushPromises();
        await flushPromises();
        refreshApex.mockResolvedValueOnce();
        element.shadowRoot.querySelector('[data-id="refresh-organizations"]').click();
        await flushPromises();
        await flushPromises();

        expect(element.shadowRoot.querySelector('.error-message')).not.toBeNull();
        expect(element.shadowRoot.querySelector('.organization-select')).toBeNull();
        expect(element.shadowRoot.querySelector('c-aareg_missing-access')).toBeNull();
        expect(checkAndShareIfAuthorized).toHaveBeenCalledTimes(1);

        refreshApex.mockImplementationOnce(async () => organizationsAdapter.emit(initialOrganizations));
        element.shadowRoot.querySelector('[data-id="refresh-organizations"]').click();
        await flushPromises();
        await flushPromises();
        expect(element.shadowRoot.querySelector('.error-message')).toBeNull();
        expect(element.shadowRoot.querySelector('.organization-select').value).toBe('111111111');
        expect(element.shadowRoot.querySelector('.inner-container')).not.toBeNull();
    });

    it('shows a selection failure without granting access or calling the rights endpoint', async () => {
        jest.spyOn(console, 'error').mockImplementation(() => {});
        getLastUsersLastUsedOrganization.mockResolvedValue('111111111');
        checkAndShareIfAuthorized.mockResolvedValue({ hasAccess: true, hasApplicationAccess: true });
        updateLastUsedOrganization.mockRejectedValueOnce(new Error('Synthetic selection failure'));
        const element = await initializeHome();
        const select = element.shadowRoot.querySelector('.organization-select');
        select.value = '111111111';
        select.dispatchEvent(new CustomEvent('change'));
        await flushPromises();
        await flushPromises();
        expect(element.shadowRoot.querySelector('.error-message')).not.toBeNull();
        expect(element.shadowRoot.querySelector('.inner-container')).toBeNull();
        expect(element.shadowRoot.querySelector('c-aareg_missing-access')).toBeNull();
        expect(checkAndShareIfAuthorized).toHaveBeenCalledTimes(1);
    });

    it('does not call Apex with the placeholder selection or show a rights denial for a lookup failure', async () => {
        jest.spyOn(console, 'error').mockImplementation(() => {});
        getLastUsersLastUsedOrganization.mockResolvedValue('111111111');
        checkAndShareIfAuthorized.mockResolvedValue({ hasAccess: true, hasApplicationAccess: true });
        updateLastUsedOrganization.mockResolvedValue();
        const element = await initializeHome();
        let select = element.shadowRoot.querySelector('.organization-select');
        select.value = '';
        select.dispatchEvent(new CustomEvent('change'));
        await flushPromises();
        await flushPromises();
        expect(updateLastUsedOrganization).not.toHaveBeenCalled();
        expect(checkAndShareIfAuthorized).toHaveBeenCalledTimes(1);
        expect(element.shadowRoot.querySelector('.error-message')).toBeNull();

        checkAndShareIfAuthorized.mockRejectedValueOnce(new Error('Synthetic rights failure'));
        select = element.shadowRoot.querySelector('.organization-select');
        select.value = '111111111';
        select.dispatchEvent(new CustomEvent('change'));
        await flushPromises();
        await flushPromises();
        expect(element.shadowRoot.querySelector('.error-message')).not.toBeNull();
        expect(element.shadowRoot.querySelector('c-aareg_missing-access')).toBeNull();
    });

    it('does not start a second refresh while the first refresh is pending', async () => {
        getLastUsersLastUsedOrganization.mockResolvedValue('111111111');
        checkAndShareIfAuthorized.mockResolvedValue({ hasAccess: true, hasApplicationAccess: true });
        let completeRefresh;
        refreshApex.mockImplementation(
            () =>
                new Promise((resolve) => {
                    completeRefresh = resolve;
                })
        );
        const element = await initializeHome();
        const refreshButton = element.shadowRoot.querySelector('[data-id="refresh-organizations"]');

        refreshButton.dispatchEvent(new CustomEvent('click'));
        refreshButton.dispatchEvent(new CustomEvent('click'));
        expect(refreshApex).toHaveBeenCalledTimes(1);

        completeRefresh();
        await flushPromises();
        await flushPromises();

        expect(getLastUsersLastUsedOrganization).toHaveBeenCalledTimes(2);
    });

    it('does not check a saved organization when the initial organization fetch fails', async () => {
        jest.spyOn(console, 'error').mockImplementation(() => {});
        getLastUsersLastUsedOrganization.mockResolvedValue('111111111');
        const element = await createHome();

        organizationsAdapter.error({ message: 'organization fetch failed' }, 500);
        await flushPromises();
        await flushPromises();

        expect(getLastUsersLastUsedOrganization).not.toHaveBeenCalled();
        expect(checkAndShareIfAuthorized).not.toHaveBeenCalled();
        expect(element.shadowRoot.querySelector('.error-message')).not.toBeNull();
    });
});
