import { createElement } from 'lwc';
import AaregAdminPermissionCenter from 'c/aaregAdminPermissionCenter';
import canViewUsers from '@salesforce/apex/AAREG_AdminPermissionController.canViewUsers';

jest.mock('@salesforce/apex/AAREG_AdminPermissionController.canViewUsers', () => ({ default: jest.fn() }), {
    virtual: true
});
jest.mock(
    '@salesforce/apex/AAREG_AdminPermissionController.getCatalog',
    () => ({ default: jest.fn(() => Promise.resolve([])) }),
    {
        virtual: true
    }
);
jest.mock(
    '@salesforce/apex/AAREG_AdminPermissionController.getUsers',
    () => ({ default: jest.fn(() => Promise.resolve([])) }),
    {
        virtual: true
    }
);
jest.mock('@salesforce/apex/AAREG_AdminPermissionController.getUserAccess', () => ({ default: jest.fn() }), {
    virtual: true
});

const flush = () => new Promise((resolve) => setTimeout(resolve, 0));

async function render() {
    const element = createElement('c-aareg-admin-permission-center', { is: AaregAdminPermissionCenter });
    document.body.appendChild(element);
    await flush();
    return element;
}

describe('c-aareg-admin-permission-center', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
        jest.clearAllMocks();
    });

    it('shows the user tab when the user may view other users', async () => {
        canViewUsers.mockResolvedValue(true);
        const element = await render();

        expect(element.shadowRoot.querySelector('c-aareg-admin-user-access')).not.toBeNull();
        expect(element.shadowRoot.querySelector('[data-id="users-locked"]')).toBeNull();
    });

    it('hides the user tab and names the missing permission set otherwise', async () => {
        canViewUsers.mockRejectedValue(new Error('no access'));
        const element = await render();

        expect(element.shadowRoot.querySelector('c-aareg-admin-user-access')).toBeNull();
        expect(element.shadowRoot.querySelector('[data-id="users-locked"]').textContent).toContain(
            'AAREG Admin Access Overview'
        );
    });
});
