import { expect, test } from '@playwright/test';
import { documentScreenshot, openInApp } from './support';

const ADMIN_TITLE = 'Kontaktmodell – Aa-registeret';

test.describe('Intern administrasjon av kontaktmodellen', () => {
    test('den eigne appen viser administrasjonssida med alle seksjonar', async ({ page }) => {
        await openInApp(page, 'AAREG_Contact_Model', '/lightning/n/AAREG_Contact_Model');

        await expect(page.getByText(ADMIN_TITLE).first()).toBeVisible();
        for (const heading of ['Nøkkeltal', 'Brytarar (feature flags)', 'Migrering', 'Siste køyringar']) {
            await expect(page.getByRole('heading', { name: heading, exact: true })).toBeVisible();
        }
        for (const action of [
            'Planlegg (PLAN)',
            'Migrer klasse A (APPLY)',
            'Verifiser (VERIFY)',
            'Rull tilbake (ROLLBACK)',
            'Oppdater'
        ]) {
            await expect(page.getByRole('button', { name: action, exact: true })).toBeVisible();
        }
        await expect(page.getByRole('button', { name: 'Set opp primærkonto' })).toBeHidden();
        await expect(page.getByText(/CMR-\d+/).first()).toBeVisible();
        await documentScreenshot(page, '01-admin-kontaktmodell');
    });

    test('APPLY og ROLLBACK krev stadfesting og kan avbrytast utan køyring', async ({ page }) => {
        await openInApp(page, 'AAREG_Contact_Model', '/lightning/n/AAREG_Contact_Model');

        const confirm = page.getByRole('alertdialog');
        const rollback = page.getByRole('button', { name: 'Rull tilbake (ROLLBACK)', exact: true });
        await expect(rollback).toBeDisabled();

        await page.getByRole('button', { name: 'Migrer klasse A (APPLY)', exact: true }).click();
        await expect(confirm.getByRole('button', { name: 'Start køyringa' })).toBeVisible();
        await confirm.getByRole('button', { name: 'Avbryt', exact: true }).click();
        await expect(confirm).toBeHidden();

        await page.getByRole('combobox', { name: 'APPLY-køyring' }).click();
        await page.getByRole('option').first().click();
        await expect(rollback).toBeEnabled();
        await rollback.click();
        await expect(confirm.getByRole('button', { name: 'Start køyringa' })).toBeVisible();
        await documentScreenshot(page, '01b-admin-stadfest-rollback');
        await confirm.getByRole('button', { name: 'Avbryt', exact: true }).click();
        await expect(confirm).toBeHidden();
    });

    for (const app of ['Arbeidsforhold_Admin', 'AAREG_application', 'AAREG_support']) {
        test(`fana «Kontaktmodell» er tilgjengeleg i ${app}`, async ({ page }) => {
            await openInApp(page, app, '/lightning/n/AAREG_Contact_Model');
            await expect(page.getByText(ADMIN_TITLE).first()).toBeVisible();
            await expect(page.getByRole('heading', { name: 'Nøkkeltal', exact: true })).toBeVisible();
        });
    }
});
