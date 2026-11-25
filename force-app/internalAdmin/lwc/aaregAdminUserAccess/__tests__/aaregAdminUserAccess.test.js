import { createElement } from 'lwc';
import AaregAdminUserAccess from 'c/aaregAdminUserAccess';
import getUsers from '@salesforce/apex/AAREG_AdminPermissionController.getUsers';
import getUserAccess from '@salesforce/apex/AAREG_AdminPermissionController.getUserAccess';
import { getNavigateCalls, resetNavigateCalls } from 'lightning/navigation';

jest.mock('@salesforce/apex/AAREG_AdminPermissionController.getUsers', () => ({ default: jest.fn() }), {
    virtual: true
});
jest.mock('@salesforce/apex/AAREG_AdminPermissionController.getUserAccess', () => ({ default: jest.fn() }), {
    virtual: true
});

const USERS = [
    {
        userId: '005000000000001AAA',
        name: 'Ola Saksbehandlar',
        username: 'ola@example.com',
        profileName: 'Standard User',
        isActive: true,
        status: 'ok',
        lastLogin: '2026-11-20T10:00:00.000Z',
        assignments: [{ apiName: 'AAREG_Arbeidsforhold_Saksbehandling', label: 'Saksbehandling' }],
        issues: []
    },
    {
        userId: '005000000000002AAA',
        name: 'Kari Frosen',
        username: 'kari@example.com',
        profileName: 'Standard User',
        isActive: true,
        status: 'error',
        assignments: [{ apiName: 'AAREG_Arbeidsforhold_Support', label: 'Support' }],
        issues: [{ level: 'error', message: 'Brukaren er frosen og kan ikkje logge inn.' }]
    },
    {
        userId: '005000000000003AAA',
        name: 'Per Slutta',
        username: 'per@example.com',
        isActive: false,
        status: 'warning',
        assignments: [{ apiName: 'AAREG_Admin_Viewer', label: 'Admin Viewer' }],
        issues: [{ level: 'warning', message: 'Inaktiv brukar har framleis Arbeidsforhold-løyve.' }]
    }
];

const flush = () => new Promise((resolve) => setTimeout(resolve, 0));

async function render() {
    const element = createElement('c-aareg-admin-user-access', { is: AaregAdminUserAccess });
    document.body.appendChild(element);
    await flush();
    return element;
}

const rows = (element) => [...element.shadowRoot.querySelectorAll('tr[data-user]')].map((row) => row.dataset.user);

describe('c-aareg-admin-user-access', () => {
    beforeEach(() => {
        getUsers.mockResolvedValue(USERS);
        resetNavigateCalls();
    });

    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
        jest.clearAllMocks();
    });

    it('lists active users with the worst problems first and counts inactive users separately', async () => {
        const element = await render();

        expect(rows(element)).toEqual(['005000000000002AAA', '005000000000001AAA']);
        expect(element.shadowRoot.querySelector('[data-summary="inactive"]').textContent).toContain('1');
    });

    it('includes inactive users when asked', async () => {
        const element = await render();
        const checkbox = element.shadowRoot.querySelector('[data-id="inactive"]');
        checkbox.checked = true;
        checkbox.dispatchEvent(new CustomEvent('change'));
        await flush();

        expect(rows(element)).toContain('005000000000003AAA');
    });

    it('finds users by permission API name', async () => {
        const element = await render();
        const search = element.shadowRoot.querySelector('[data-id="search"]');
        search.value = 'support';
        search.dispatchEvent(new CustomEvent('change'));
        await flush();

        expect(rows(element)).toEqual(['005000000000002AAA']);
    });

    it('shows problems and effective access with sources for the selected user', async () => {
        getUserAccess.mockResolvedValue({
            sources: ['Support'],
            objects: [
                { apiName: 'Inquiry__c', label: 'Henvending', canRead: true, accessText: 'Les', sources: ['Support'] }
            ],
            customPermissions: [],
            apps: [{ apiName: 'AAREG_support', label: 'Brukerstøtte', granted: true, sources: ['Support'] }]
        });
        const element = await render();
        element.shadowRoot.querySelector('button[data-id="005000000000002AAA"]').click();
        await flush();

        expect(getUserAccess).toHaveBeenCalledWith({ userId: '005000000000002AAA' });
        const detail = element.shadowRoot.querySelector('[data-id="user-detail"]');
        expect(detail.textContent).toContain('Brukaren er frosen');
        expect(detail.textContent).toContain('Henvending');
        expect(detail.textContent).toContain('Brukerstøtte');
    });

    it('opens the selected user in Setup', async () => {
        getUserAccess.mockResolvedValue({ sources: [], objects: [], customPermissions: [], apps: [] });
        const element = await render();
        element.shadowRoot.querySelector('button[data-id="005000000000001AAA"]').click();
        await flush();
        element.shadowRoot.querySelector('lightning-button').click();

        expect(getNavigateCalls()[0].attributes.url).toContain('005000000000001AAA');
    });

    it('shows the server message when the user list is denied', async () => {
        getUsers.mockRejectedValue({ body: { message: 'Du manglar løyvesettet' } });
        const element = await render();

        expect(element.shadowRoot.querySelector('[role="alert"]').textContent).toBe('Du manglar løyvesettet');
    });
});
