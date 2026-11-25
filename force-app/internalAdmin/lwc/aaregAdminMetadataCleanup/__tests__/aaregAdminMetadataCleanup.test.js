import { createElement } from 'lwc';
import AaregAdminMetadataCleanup from 'c/aaregAdminMetadataCleanup';
import getOverview from '@salesforce/apex/AAREG_AdminMetadataCleanupController.getOverview';

jest.mock('@salesforce/apex/AAREG_AdminMetadataCleanupController.getOverview', () => ({ default: jest.fn() }), {
    virtual: true
});

const OVERVIEW = {
    orgName: 'Scratch',
    isSandbox: true,
    orgKind: 'Scratch',
    environments: [
        { name: 'SIT2', label: 'SIT2', requiredForArchive: true, isCurrent: false },
        { name: 'Production', label: 'Produksjon', requiredForArchive: true, isCurrent: false }
    ],
    archivedCount: 1,
    sourceCommit: 'abc123def456',
    sourceCommitUrl: 'https://github.com/navikt/crm-arbeidsforhold/commit/abc123def456',
    generatedAt: '2026-11-25T01:00:00+01:00',
    ownedPrefixes: ['AAREG', 'P360'],
    presentCount: 1,
    absentCount: 1,
    manualCount: 1,
    items: [
        {
            key: 'Flow:AAREG_Old',
            type: 'Flow',
            name: 'AAREG_Old',
            stage: 'Removed',
            state: 'absent',
            verifications: [{ environment: 'SIT2', environmentLabel: 'SIT2', verifiedOn: '2026-11-20' }]
        },
        {
            key: 'ApexClass:AAREG_Archived',
            type: 'ApexClass',
            name: 'AAREG_Archived',
            stage: 'Removed',
            state: 'absent',
            archived: true,
            verifications: [
                { environment: 'SIT2', environmentLabel: 'SIT2', verifiedOn: '2026-11-20' },
                { environment: 'Production', environmentLabel: 'Produksjon', verifiedOn: '2026-11-22' }
            ]
        },
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

    it('hides archived components until the user asks to see them', async () => {
        getOverview.mockResolvedValue(OVERVIEW);
        const element = await mount();

        expect(rowKeys(element)).not.toContain('ApexClass:AAREG_Archived');
        expect(element.shadowRoot.querySelector('[data-id="summary"]').textContent).toContain('1 arkivert');
        const flow = element.shadowRoot.querySelector('tr[data-key="Flow:AAREG_Old"]');
        expect(flow.textContent).toContain('SIT2: 2026-11-20');
        expect(flow.textContent).toContain('Produksjon: –');

        const toggle = element.shadowRoot.querySelector('lightning-input[data-id="archived"]');
        toggle.checked = true;
        toggle.dispatchEvent(new CustomEvent('change'));
        await flush();
        const archived = element.shadowRoot.querySelector('tr[data-key="ApexClass:AAREG_Archived"]');
        expect(archived.textContent).toContain('Arkivert');
    });

    it('warns when a verified deletion no longer holds', async () => {
        getOverview.mockResolvedValue({
            ...OVERVIEW,
            items: [{ ...OVERVIEW.items[3], reappeared: true, verifications: OVERVIEW.items[1].verifications }]
        });
        const element = await mount();

        expect(element.shadowRoot.querySelector('tbody tr').textContent).toContain('Finst igjen – må ryddast');
    });

    it('exports components that are absent in the current environment as verification evidence', async () => {
        getOverview.mockResolvedValue({
            ...OVERVIEW,
            orgKind: 'Sandbox',
            sandboxName: 'sit2',
            currentEnvironment: 'SIT2',
            items: [
                { ...OVERVIEW.items[0], readyToVerify: true, verifications: [] },
                { ...OVERVIEW.items[3], readyToVerify: false }
            ]
        });
        const element = await mount();

        expect(element.shadowRoot.querySelector('[data-id="source"]').textContent).toContain('SIT2');
        const button = element.shadowRoot.querySelector('lightning-button[data-id="export"]');
        expect(button.label).toBe('Lag verifikasjon for SIT2 (1)');
        button.dispatchEvent(new CustomEvent('click'));
        await flush();
        const exported = JSON.parse(element.shadowRoot.querySelector('lightning-textarea[data-id="export"]').value);
        expect(exported.environment).toBe('SIT2');
        expect(exported.components).toEqual([{ type: 'Flow', name: 'AAREG_Old' }]);
        expect(exported.checkedOn).toMatch(/^\d{4}-\d{2}-\d{2}$/);
    });

    it('tells the user how to map an unknown sandbox', async () => {
        getOverview.mockResolvedValue({ ...OVERVIEW, orgKind: 'Sandbox', sandboxName: 'dev1' });
        const element = await mount();

        const source = element.shadowRoot.querySelector('[data-id="source"]').textContent;
        expect(source).toContain('dev1');
        expect(source).toContain('AAREG_Cleanup_Environment__mdt');
        expect(element.shadowRoot.querySelector('lightning-button[data-id="export"]')).toBeNull();
    });

    it('shows the server error when the overview cannot be read', async () => {
        getOverview.mockRejectedValue({ body: { message: 'Fann ikkje oversikta' } });
        const element = await mount();

        expect(element.shadowRoot.querySelector('[role="alert"]').textContent).toBe('Fann ikkje oversikta');
    });
});
