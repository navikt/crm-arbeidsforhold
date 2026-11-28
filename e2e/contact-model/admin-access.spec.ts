import { expect, test } from '@playwright/test';
import { documentScreenshot, openInApp } from './support';

const APP = 'Arbeidsforhold_Admin';

test.describe('Arbeidsforhold Admin: snarvegar, løyve og brukarar', () => {
    test('startsida har søkbare snarvegar til alle hovudområda', async ({ page }) => {
        await openInApp(page, APP, '/lightning/page/home');
        const launchpad = page.locator('c-aareg-admin-launchpad');
        await expect(launchpad.getByText('Snarvegar', { exact: true })).toBeVisible({ timeout: 60_000 });
        await expect(launchpad.getByRole('button', { name: /^Løyve og brukarar/ })).toBeEnabled();
        await expect(launchpad.getByRole('button', { name: /^Integrasjonsmonitor/ })).toBeEnabled();
        for (const area of [
            'Aa-registeret',
            'Integrasjonar og drift',
            'Kontaktmodell',
            'Rapportar og dashboard',
            'Tilgang og løyve',
            'Andre appar'
        ]) {
            await expect(launchpad.getByRole('heading', { name: area, exact: true })).toBeVisible();
        }
        await documentScreenshot(page, '26-admin-snarvegar');

        await launchpad.getByRole('searchbox', { name: /Søk etter område/ }).fill('p360');
        await expect(launchpad.getByRole('button', { name: /P360-arkivering/ })).toBeVisible();
        await expect(launchpad.getByRole('heading', { name: 'Andre appar', exact: true })).toBeHidden();
        await launchpad.getByRole('button', { name: /P360-arkivering/ }).click();
        await expect(page).toHaveURL(/\/lightning\/o\/P360_Archive_Job__c\/list/, { timeout: 60_000 });
    });

    test('snarvegen til ein annan app opnar appen', async ({ page }) => {
        await openInApp(page, APP, '/lightning/page/home');
        const launchpad = page.locator('c-aareg-admin-launchpad');
        await launchpad.getByRole('button', { name: /^Brukarstøtte/ }).click();
        await expect(page.locator('.appName, one-app-nav-bar').first()).toContainText(/Brukerstøtte/, {
            timeout: 60_000
        });
    });

    test('løyveoversikta forklarer kvart løyve med tilgang lesen frå orgen', async ({ page }) => {
        await openInApp(page, APP, '/lightning/n/AAREG_Admin_Permissions');
        const catalog = page.locator('c-aareg-admin-permission-catalog');
        const viewer = catalog.getByRole('button', { name: /AAREG_Admin_Viewer/ });
        await expect(viewer).toBeVisible({ timeout: 60_000 });
        await expect(catalog.getByRole('button', { name: /P360_Integration_User/ })).toBeVisible();

        await viewer.click();
        const detail = catalog.getByRole('region', { name: 'Detaljar om løyvet' });
        await expect(detail.getByText('Administrator', { exact: true })).toBeVisible();
        await expect(detail.getByRole('table')).toContainText('Les');
        await documentScreenshot(page, '27-admin-loyveoversikt');

        await catalog.getByRole('combobox', { name: 'Målgruppe' }).click();
        await page.getByRole('option', { name: 'Integrasjonsbrukar' }).click();
        await expect(catalog.getByRole('button', { name: /P360_Integration_User/ })).toBeVisible();
        await expect(viewer).toBeHidden();
    });

    test('brukaroversikta viser interne brukarar, problem og effektiv tilgang', async ({ page }) => {
        await openInApp(page, APP, '/lightning/n/AAREG_Admin_Permissions');
        await page.getByRole('tab', { name: 'Interne brukarar' }).click();
        const users = page.locator('c-aareg-admin-user-access');
        await expect(users.getByText('Aktive brukarar', { exact: true })).toBeVisible({ timeout: 60_000 });
        const table = users.getByRole('table').first();
        await expect(table.getByRole('row').nth(1)).toBeVisible();
        await documentScreenshot(page, '28-admin-interne-brukarar');

        await users.getByRole('searchbox').fill('Saksbehandling');
        const firstUser = table.getByRole('rowheader').first().getByRole('button');
        await firstUser.click();
        const detail = users.getByRole('region', { name: 'Tilgang for brukaren' });
        await expect(detail.getByText('Effektiv tilgang')).toBeVisible();
        await expect(detail.getByText(/^Kjelder:/)).toBeVisible({ timeout: 30_000 });
        await expect(detail.getByRole('button', { name: 'Opne brukaren i Setup' })).toBeVisible();
        await documentScreenshot(page, '29-admin-brukar-tilgang');
    });

    test('fana «Løyve og brukarar» ligg i admin-appen', async ({ page }) => {
        await openInApp(page, APP, '/lightning/page/home');
        const nav = page.getByRole('navigation', { name: 'Global' });
        await nav.getByRole('button', { name: 'Show more navigation items' }).click({ timeout: 60_000 });
        await expect(page.getByRole('menuitem', { name: 'Løyve og brukarar' })).toBeVisible();
    });
});
