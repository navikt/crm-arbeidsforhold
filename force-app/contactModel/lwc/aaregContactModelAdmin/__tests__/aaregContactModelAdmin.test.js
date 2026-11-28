import { createElement } from 'lwc';
import AaregContactModelAdmin from 'c/aaregContactModelAdmin';
import getOverview from '@salesforce/apex/AAREG_ContactModelAdminController.getOverview';
import startRun from '@salesforce/apex/AAREG_ContactModelAdminController.startRun';
import setUpPrimaryAccount from '@salesforce/apex/AAREG_ContactModelAdminController.setUpPrimaryAccount';

jest.mock('@salesforce/apex/AAREG_ContactModelAdminController.getOverview', () => ({ default: jest.fn() }), {
    virtual: true
});
jest.mock('@salesforce/apex/AAREG_ContactModelAdminController.startRun', () => ({ default: jest.fn() }), {
    virtual: true
});
jest.mock('@salesforce/apex/AAREG_ContactModelAdminController.setUpPrimaryAccount', () => ({ default: jest.fn() }), {
    virtual: true
});

const overview = (overrides = {}) => ({
    canMigrate: true,
    primaryAccountReady: true,
    flags: [
        {
            name: 'AAREG_ContactModel_ShadowWrite',
            exists: true,
            enabledInOrg: true,
            activeForCurrentUser: true,
            description: 'Skuggeskriving'
        },
        {
            name: 'AAREG_ContactModel_Profile',
            exists: true,
            enabledInOrg: true,
            activeForCurrentUser: false,
            requiredPermission: 'AAREG_ContactModelPilot'
        }
    ],
    metrics: [{ key: 'domainContacts', label: 'Domenekontaktar', value: 4, help: 'Éin per portalbrukar.' }],
    runs: [
        { Id: 'a01', Name: 'CMR-0002', Mode__c: 'APPLY', Status__c: 'Completed', Linked__c: 3 },
        { Id: 'a00', Name: 'CMR-0001', Mode__c: 'PLAN', Status__c: 'Completed' }
    ],
    ...overrides
});

const flush = () => new Promise((resolve) => setTimeout(resolve, 0));

async function mount(data) {
    getOverview.mockResolvedValue(data);
    const element = createElement('c-aareg-contact-model-admin', { is: AaregContactModelAdmin });
    document.body.appendChild(element);
    await flush();
    return element;
}

const button = (element, label) =>
    [...element.shadowRoot.querySelectorAll('lightning-button')].find((candidate) => candidate.label === label);

describe('c-aareg-contact-model-admin', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
        jest.clearAllMocks();
    });

    it('shows key figures and whether each flag applies to the current user', async () => {
        const element = await mount(overview());

        expect(element.shadowRoot.querySelector('[data-metric="domainContacts"]').textContent).toContain('4');
        const rows = element.shadowRoot.querySelectorAll('tr[data-flag]');
        expect(rows[0].textContent).toContain('På for deg');
        expect(rows[1].textContent).toContain('På (krev løyve)');
        expect(rows[1].textContent).toContain('AAREG_ContactModelPilot');
    });

    it('asks for confirmation before APPLY and starts the run only after confirming', async () => {
        startRun.mockResolvedValue('a02');
        const element = await mount(overview());

        button(element, 'Migrer klasse A (APPLY)').click();
        await flush();
        expect(startRun).not.toHaveBeenCalled();
        expect(element.shadowRoot.querySelector('[data-id="confirm"]').textContent).toContain('berre klasse A');

        button(element, 'Start køyringa').click();
        await flush();
        expect(startRun).toHaveBeenCalledWith({ mode: 'APPLY', sourceRunId: null });
        expect(element.shadowRoot.querySelector('[data-id="notice"]').textContent).toContain('er starta');
    });

    it('requires a completed APPLY run before rollback and passes it as source', async () => {
        startRun.mockResolvedValue('a03');
        const element = await mount(overview());
        expect(button(element, 'Rull tilbake (ROLLBACK)').disabled).toBe(true);

        const combobox = element.shadowRoot.querySelector('lightning-combobox');
        expect(combobox.options).toEqual([{ label: 'CMR-0002 (kopla 3)', value: 'a01' }]);
        combobox.dispatchEvent(new CustomEvent('change', { detail: { value: 'a01' } }));
        await flush();

        button(element, 'Rull tilbake (ROLLBACK)').click();
        await flush();
        button(element, 'Start køyringa').click();
        await flush();
        expect(startRun).toHaveBeenCalledWith({ mode: 'ROLLBACK', sourceRunId: 'a01' });
    });

    it('hides actions for users without the migrate permission', async () => {
        const element = await mount(overview({ canMigrate: false }));

        expect(button(element, 'Planlegg (PLAN)')).toBeUndefined();
        expect(element.shadowRoot.querySelector('[data-id="no-permission"]')).not.toBeNull();
    });

    it('offers primary account setup when it is missing and blocks APPLY', async () => {
        setUpPrimaryAccount.mockResolvedValue('001');
        const element = await mount(overview({ primaryAccountReady: false }));

        expect(button(element, 'Migrer klasse A (APPLY)').disabled).toBe(true);
        button(element, 'Set opp primærkonto').click();
        await flush();
        expect(setUpPrimaryAccount).toHaveBeenCalled();
    });

    it('disables new runs while a run is active', async () => {
        const element = await mount(
            overview({ runs: [{ Id: 'a04', Name: 'CMR-0004', Mode__c: 'PLAN', Status__c: 'Running' }] })
        );

        expect(button(element, 'Planlegg (PLAN)').disabled).toBe(true);
    });

    it('shows server errors', async () => {
        getOverview.mockRejectedValue({ body: { message: 'Du manglar tilgang' } });
        const element = createElement('c-aareg-contact-model-admin', { is: AaregContactModelAdmin });
        document.body.appendChild(element);
        await flush();

        expect(element.shadowRoot.querySelector('[data-id="error"]').textContent).toContain('Du manglar tilgang');
    });
});
