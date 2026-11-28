import { createElement } from 'lwc';
import AaregAdminLaunchpad from 'c/aaregAdminLaunchpad';
import getLaunchpad from '@salesforce/apex/AAREG_AdminNavigationController.getLaunchpad';
import { getNavigateCalls, resetNavigateCalls } from 'lightning/navigation';

jest.mock('@salesforce/apex/AAREG_AdminNavigationController.getLaunchpad', () => ({ default: jest.fn() }), {
    virtual: true
});

const GROUPS = [
    {
        key: 'aareg',
        label: 'Aa-registeret',
        items: [
            {
                key: 'object:Application__c',
                label: 'Søknader',
                description: 'Alle søknader',
                kind: 'object',
                target: 'Application__c',
                available: true
            },
            {
                key: 'navItem:AAREG_Admin_Journey',
                label: 'Søknadsreise',
                description: 'Følg ein søknad',
                kind: 'navItem',
                target: 'AAREG_Admin_Journey',
                available: false,
                reason: 'Fana er ikkje synleg for deg.'
            }
        ]
    },
    {
        key: 'apps',
        label: 'Andre appar',
        items: [
            {
                key: 'app:AAREG_support',
                label: 'Brukarstøtte',
                description: 'Brukarstøtte',
                kind: 'app',
                target: 'AAREG_support',
                available: true
            }
        ]
    }
];

const flush = () => new Promise((resolve) => setTimeout(resolve, 0));

async function render() {
    const element = createElement('c-aareg-admin-launchpad', { is: AaregAdminLaunchpad });
    document.body.appendChild(element);
    await flush();
    return element;
}

describe('c-aareg-admin-launchpad', () => {
    beforeEach(() => {
        getLaunchpad.mockResolvedValue(GROUPS);
        resetNavigateCalls();
    });

    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
        jest.clearAllMocks();
    });

    it('opens the list view when an available object shortcut is chosen', async () => {
        const element = await render();
        element.shadowRoot.querySelector('button[data-key="object:Application__c"]').click();

        expect(getNavigateCalls()).toEqual([
            expect.objectContaining({
                type: 'standard__objectPage',
                attributes: { objectApiName: 'Application__c', actionName: 'list' }
            })
        ]);
    });

    it('opens another app with the c__ app target', async () => {
        const element = await render();
        element.shadowRoot.querySelector('button[data-key="app:AAREG_support"]').click();

        expect(getNavigateCalls()[0]).toEqual(
            expect.objectContaining({ type: 'standard__app', attributes: { appTarget: 'c__AAREG_support' } })
        );
    });

    it('disables unavailable shortcuts and explains why', async () => {
        const element = await render();
        const button = element.shadowRoot.querySelector('button[data-key="navItem:AAREG_Admin_Journey"]');

        expect(button.disabled).toBe(true);
        expect(button.title).toBe('Fana er ikkje synleg for deg.');
    });

    it('filters shortcuts by search term and hides empty groups', async () => {
        const element = await render();
        const search = element.shadowRoot.querySelector('lightning-input');
        search.value = 'brukarst';
        search.dispatchEvent(new CustomEvent('change'));
        await flush();

        const groups = [...element.shadowRoot.querySelectorAll('section')].map((section) => section.dataset.group);
        expect(groups).toEqual(['apps']);
    });

    it('shows the error message when loading fails', async () => {
        getLaunchpad.mockRejectedValue({ body: { message: 'Feil frå server' } });
        const element = await render();

        expect(element.shadowRoot.querySelector('[role="alert"]').textContent).toBe('Feil frå server');
    });
});
