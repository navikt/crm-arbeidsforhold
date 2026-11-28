import { expect, test } from '@playwright/test';
import { context, documentScreenshot, openPortalPage } from './support';

const SITE_PATH = '/aaregisteret/s/min-profil';

test.describe('«Min profil» i Experience Cloud', () => {
    test.beforeEach(async ({ page }) => {
        test.skip(!context.networkId || !context.portalUserId, 'Portalbrukaren eller nettstaden manglar i orgen.');
        await openPortalPage(page, SITE_PATH);
        await expect(page.getByRole('heading', { name: 'Min profil', level: 1 })).toBeVisible();
    });

    test('viser ingen adresse før personen har valt kontekst', async ({ page }) => {
        await expect(page.getByRole('combobox', { name: 'Kven gjeld det?' })).toBeVisible();
        await expect(page.getByText(/Ingen opplysningar blir viste før du har valt/)).toBeVisible();
        await expect(page.getByLabel('E-post')).toHaveCount(0);
        await documentScreenshot(page, '06-min-profil-vel-forst');
    });

    test('«Meg selv» viser og lagrar berre privatadressa', async ({ page }) => {
        const selector = page.getByRole('combobox', { name: 'Kven gjeld det?' });
        await selector.click();
        await page.getByRole('option', { name: /Meg selv/ }).click();

        await expect(page.getByRole('heading', { name: 'Adressa di når du handlar på eigne vegner' })).toBeVisible();
        await page.getByLabel('E-post').fill(`cm-e2e.${Date.now()}@example.invalid`);
        await page.getByRole('button', { name: 'Lagre adressa' }).click();
        await expect(page.getByText('Adressa er lagra. Andre adresser er ikkje endra.')).toBeVisible();
        await documentScreenshot(page, '07-min-profil-meg-selv');
    });

    test('organisasjonslista kan søkjast i på namn eller nummer', async ({ page }) => {
        const selector = page.getByRole('combobox', { name: 'Kven gjeld det?' });
        await selector.click();
        const organizationOptions = page.getByRole('option').filter({ hasNotText: 'Meg selv' });
        const warning = page.getByText(/Du kan framleis endre adressa for «Meg selv»/);
        await expect(organizationOptions.first().or(warning)).toBeVisible();
        test.skip(await warning.isVisible(), 'Altinn svarar ikkje i scratch; organisasjonsvalet blir testa manuelt.');

        const name = (await organizationOptions.first().locator('.option-name').innerText()).trim();
        await selector.fill(name.slice(0, 4));
        await expect(page.getByRole('option', { name: new RegExp(name) })).toBeVisible();
    });
});

test.describe('Inngang til «Min profil» frå forsida', () => {
    test('forsida lenkjer til profilen utan at ein organisasjon er vald', async ({ page }) => {
        test.skip(!context.networkId || !context.portalUserId, 'Portalbrukaren eller nettstaden manglar i orgen.');
        await openPortalPage(page, '/aaregisteret/s/');

        const profileLink = page.locator('c-aareg-link-panel').filter({ hasText: 'Min profil' });
        await expect(profileLink).toBeVisible({ timeout: 60_000 });
        await documentScreenshot(page, '11-forside-min-profil');

        await profileLink.click();
        await expect(page).toHaveURL(/\/min-profil/);
        await expect(page.getByRole('heading', { name: 'Min profil', level: 1 })).toBeVisible();
    });
});
