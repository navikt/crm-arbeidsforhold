import { createElement } from 'lwc';
import Aareg_home from 'c/aareg_home';
import getOrganizationsWithRoles from '@salesforce/apex/AAREG_HomeController.getOrganizationsWithRoles';
import getLastUsersLastUsedOrganization from '@salesforce/apex/AAREG_HomeController.getLastUsersLastUsedOrganization';
import checkAndShareIfAuthorized from '@salesforce/apex/AAREG_HomeController.checkAndShareIfAuthorized';
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
        expect(element.shadowRoot.querySelector('c-aareg_missing-access')).not.toBeNull();
    });

    it('clears access and displays an error when refreshing organizations fails', async () => {
        jest.spyOn(console, 'error').mockImplementation(() => {});
        getLastUsersLastUsedOrganization.mockResolvedValue('111111111');
        checkAndShareIfAuthorized.mockResolvedValue({ hasAccess: true, hasApplicationAccess: true });
        refreshApex.mockRejectedValue(new Error('refresh failed'));
        const element = await initializeHome();

        element.shadowRoot.querySelector('[data-id="refresh-organizations"]').dispatchEvent(new CustomEvent('click'));
        await flushPromises();
        await flushPromises();

        expect(checkAndShareIfAuthorized).toHaveBeenCalledTimes(1);
        expect(element.shadowRoot.querySelector('.error-message')).not.toBeNull();
        expect(element.shadowRoot.querySelector('[data-id="refresh-organizations"]')).not.toBeNull();
        expect(element.shadowRoot.querySelector('c-aareg_missing-access')).not.toBeNull();
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
