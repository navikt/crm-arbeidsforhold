import { expect, test } from '@playwright/test';
import { documentScreenshot, openInApp } from './support';

const APP = 'Arbeidsforhold_Admin';

test.describe('Arbeidsforhold Admin: metadata og opprydding', () => {
    test('oversikta viser fjerna metadata og om ho framleis finst i orgen', async ({ page }) => {
        await openInApp(page, APP, '/lightning/n/AAREG_Admin_Metadata_Cleanup');
        const cleanup = page.locator('c-aareg-admin-metadata-cleanup');
        const summary = cleanup.locator('[data-id="summary"]');
        await expect(summary).toContainText('må ryddast', { timeout: 60_000 });
        await expect(summary).toContainText('finst ikkje');
        await expect(cleanup.locator('[data-id="source"]')).toContainText('Repo-grunnlag');

        const guided = cleanup.locator('tr[data-key="ApexClass:AAREG_CheckObjectTypeNamingTest"]');
        await expect(guided).toBeVisible();
        await expect(guided).toContainText('AAREG_checkObjectTypeNamecheTest');
        await expect(guided.getByRole('link', { name: 'Runbook' })).toBeVisible();
        await documentScreenshot(page, '30-admin-metadata-opprydding');

        await cleanup.getByRole('combobox', { name: 'Status i orgen' }).click();
        await page.getByRole('option', { name: 'Finst – må ryddast' }).click();
        const rows = cleanup.locator('[data-id="items"] tbody tr');
        await expect(rows.first()).toBeVisible();
        for (const state of await rows.locator('[data-state]').allTextContents()) {
            expect(state.trim()).toBe('Finst – må ryddast');
        }

        await cleanup.getByRole('combobox', { name: 'Status i orgen' }).click();
        await page.getByRole('option', { name: 'Alle', exact: true }).click();
        await cleanup.getByRole('searchbox', { name: 'Søk etter namn' }).fill('CheckObjectTypeNaming');
        await expect(rows).toHaveCount(1);
        await expect(cleanup.locator('[data-id="orphans"]')).toContainText('Finst berre i orgen');
        await documentScreenshot(page, '31-admin-metadata-filter');
    });

    test('snarvegen «Metadata og opprydding» ligg på startsida', async ({ page }) => {
        await openInApp(page, APP, '/lightning/page/home');
        const launchpad = page.locator('c-aareg-admin-launchpad');
        await launchpad.getByRole('searchbox', { name: /Søk etter område/ }).fill('opprydding', { timeout: 60_000 });
        await launchpad.getByRole('button', { name: /^Metadata og opprydding/ }).click();
        await expect(page).toHaveURL(/\/lightning\/n\/AAREG_Admin_Metadata_Cleanup/, { timeout: 60_000 });
    });
});
