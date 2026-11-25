import { createElement } from 'lwc';
import AaregAdminMetadataCleanup from 'c/aaregAdminMetadataCleanup';
import getOverview from '@salesforce/apex/AAREG_AdminMetadataCleanupController.getOverview';

jest.mock('@salesforce/apex/AAREG_AdminMetadataCleanupController.getOverview', () => ({ default: jest.fn() }), {
    virtual: true
});

const OVERVIEW = {
    orgName: 'Scratch',
    isSandbox: true,
    sourceCommit: 'abc123def456',
    sourceCommitUrl: 'https://github.com/navikt/crm-arbeidsforhold/commit/abc123def456',
    generatedAt: '2026-11-25T01:00:00+01:00',
    ownedPrefixes: ['AAREG', 'P360'],
    presentCount: 1,
    absentCount: 1,
    manualCount: 1,
    items: [
        { key: 'Flow:AAREG_Old', type: 'Flow', name: 'AAREG_Old', stage: 'Removed', state: 'absent' },
        {
            key: 'Layout:Account-Old',
            type: 'Layout',
            name: 'Account-Old',
            stage: 'Removed',
            state: 'manual',
            guidance: 'Setup > Object Manager.'
        },
        {
            key: 'ApexClass:AAREG_CheckObjectTypeNamingTest',
            type: 'ApexClass',
            name: 'AAREG_CheckObjectTypeNamingTest',
            stage: 'Scheduled_Deletion',
            state: 'present',
            reason: 'Duplicate test class.',
            replacement: 'AAREG_checkObjectTypeNamecheTest',
            runbookUrl: 'https://example.com/runbook',
            commitUrl: 'https://example.com/commit',
            removedOn: '2026-09-14'
        }
    ],
    orphans: [{ key: 'ApexClass:AAREG_Leftover', type: 'ApexClass', name: 'AAREG_Leftover' }]
};

const flush = () => new Promise((resolve) => setTimeout(resolve, 0));

async function mount() {
    const element = createElement('c-aareg-admin-metadata-cleanup', { is: AaregAdminMetadataCleanup });
    document.body.appendChild(element);
    await flush();
    return element;
}

function rowKeys(element) {
    return [...element.shadowRoot.querySelectorAll('table[data-id="items"] tbody tr')].map((row) => row.dataset.key);
}

describe('c-aareg-admin-metadata-cleanup', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
        jest.clearAllMocks();
    });

    it('lists components that still exist in the org first, with stage, reason and runbook', async () => {
        getOverview.mockResolvedValue(OVERVIEW);
        const element = await mount();

        expect(rowKeys(element)).toEqual([
            'ApexClass:AAREG_CheckObjectTypeNamingTest',
            'Layout:Account-Old',
            'Flow:AAREG_Old'
        ]);
        const first = element.shadowRoot.querySelector('tr[data-key="ApexClass:AAREG_CheckObjectTypeNamingTest"]');
        expect(first.textContent).toContain('Finst – må ryddast');
        expect(first.textContent).toContain('Planlagt sletting');
        expect(first.textContent).toContain('Erstatta av AAREG_checkObjectTypeNamecheTest.');
        expect(first.querySelector('a[href="https://example.com/runbook"]')).not.toBeNull();
    });

    it('filters by state in the org and by name', async () => {
        getOverview.mockResolvedValue(OVERVIEW);
        const element = await mount();

        const state = element.shadowRoot.querySelector('lightning-combobox[data-id="state"]');
        state.dispatchEvent(new CustomEvent('change', { detail: { value: 'manual' } }));
        await flush();
        expect(rowKeys(element)).toEqual(['Layout:Account-Old']);

        state.dispatchEvent(new CustomEvent('change', { detail: { value: 'all' } }));
        const search = element.shadowRoot.querySelector('lightning-input');
        search.value = 'aareg_old';
        search.dispatchEvent(new CustomEvent('change'));
        await flush();
        expect(rowKeys(element)).toEqual(['Flow:AAREG_Old']);
    });

    it('shows components that exist only in the org', async () => {
        getOverview.mockResolvedValue(OVERVIEW);
        const element = await mount();

        const orphans = element.shadowRoot.querySelector('section[data-id="orphans"]');
        expect(orphans.textContent).toContain('AAREG_Leftover');
        expect(orphans.textContent).toContain('AAREG og P360');
    });

    it('shows the server error when the overview cannot be read', async () => {
        getOverview.mockRejectedValue({ body: { message: 'Fann ikkje oversikta' } });
        const element = await mount();

        expect(element.shadowRoot.querySelector('[role="alert"]').textContent).toBe('Fann ikkje oversikta');
    });
});
