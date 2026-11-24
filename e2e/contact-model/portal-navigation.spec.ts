import { expect, test } from '@playwright/test';
import { context, documentScreenshot, openPortalPage } from './support';

const HOME = '/aaregisteret/s/';
const PRIVATE = 'Privatperson / arbeidstaker';
const breadcrumbs = (page) => page.getByRole('navigation', { name: 'Brødsmulesti' });

test.describe('Navigasjon tilbake med brødsmulesti', () => {
    test.beforeEach(() => {
        test.skip(!context.networkId || !context.portalUserId, 'Portalbrukaren eller nettstaden manglar i orgen.');
    });

    test('forsida har ingen brødsmulesti', async ({ page }) => {
        await openPortalPage(page, HOME);

        await expect(page.locator('c-aareg-entry-portal').getByRole('link', { name: /^Arbeidsgiver/ })).toBeVisible({
            timeout: 60_000
        });
        await expect(breadcrumbs(page)).toHaveCount(0);
    });

    test('stien følgjer rolla ned til «Min profil» og leier tilbake', async ({ page }) => {
        await openPortalPage(page, HOME);
        await page
            .locator('c-aareg-entry-portal')
            .getByRole('link', { name: /^Privatperson/ })
            .click();

        const trail = breadcrumbs(page);
        await expect(trail.getByRole('link', { name: 'Forside' })).toBeVisible({ timeout: 60_000 });
        await expect(trail.locator('[aria-current="page"]')).toHaveText(PRIVATE);
        await documentScreenshot(page, '16-brodsmulesti-rolleside');

        await page.locator('c-aareg-link-panel').filter({ hasText: 'Min profil' }).click();
        await expect(page).toHaveURL(/\/min-profil/);
        await expect(trail.locator('[aria-current="page"]')).toHaveText('Min profil', { timeout: 60_000 });
        await expect(trail.getByRole('link', { name: PRIVATE })).toBeVisible();
        await documentScreenshot(page, '17-brodsmulesti-min-profil');

        await trail.getByRole('link', { name: PRIVATE }).click();
        await expect(page).toHaveURL(/\/privatperson/);
        await expect(page.getByText(`Rolle: ${PRIVATE}`)).toBeVisible({ timeout: 60_000 });

        await breadcrumbs(page).getByRole('link', { name: 'Forside' }).click();
        await expect(page).toHaveURL(/\/s\/$/);
        await expect(breadcrumbs(page)).toHaveCount(0, { timeout: 60_000 });
    });

    test('på smal skjerm blir stien ei «Tilbake til»-lenkje', async ({ page }) => {
        await page.setViewportSize({ width: 375, height: 812 });
        await openPortalPage(page, `${HOME}?type=private-person`);
        await expect(page).toHaveURL(/\/privatperson/, { timeout: 60_000 });

        const back = breadcrumbs(page).getByRole('link', { name: 'Tilbake til Forside' });
        await expect(back).toBeVisible({ timeout: 60_000 });
        await documentScreenshot(page, '18-tilbakelenkje-mobil');

        await back.click();
        await expect(page).toHaveURL(/\/s\/$/);
    });
});
