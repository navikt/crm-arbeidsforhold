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

    test('meldingssida og dei eldre sidene viser berre den nye stien', async ({ page }) => {
        test.skip(!context.threadId, 'Ingen delt Aa-registeret-melding. Køyr «npm run contact-model -- seed».');
        await openPortalPage(page, `${HOME}?type=employer&org=111111111`);
        await expect(page).toHaveURL(/\/arbeidsgiver/, { timeout: 60_000 });

        const siteOrigin = new URL(page.url()).origin;
        await page.goto(`${siteOrigin}${HOME}thread/${context.threadId}/melding`);

        const trail = breadcrumbs(page);
        await expect(trail.locator('[aria-current="page"]')).toHaveText('Melding', { timeout: 60_000 });
        await expect(trail.getByRole('link', { name: 'Arbeidsgiver' })).toBeVisible();
        await expect(trail).toHaveCount(1);
        await expect(page.getByRole('link', { name: 'Hjem', exact: true })).toHaveCount(0);
        const threadTitle = page.getByRole('heading', { level: 1, name: 'Aa-registeret - Henvendelse' });
        await expect(threadTitle).toBeVisible();
        expect((await threadTitle.boundingBox())!.y).toBeGreaterThan((await trail.boundingBox())!.y);
        await documentScreenshot(page, '19-brodsmulesti-melding');

        await trail.getByRole('link', { name: 'Mine meldinger' }).click();
        await expect(page).toHaveURL(/\/mine-meldinger/);
        await expect(breadcrumbs(page).locator('[aria-current="page"]')).toHaveText('Mine meldinger', {
            timeout: 60_000
        });
        await expect(page.getByRole('button', { name: 'Ny melding' })).toBeVisible({ timeout: 60_000 });
        await expect(page.getByRole('link', { name: 'Min side', exact: true })).toHaveCount(0);
        await documentScreenshot(page, '20-brodsmulesti-mine-meldinger');
    });

    test('vald virksomheit blir vist på undersidene til ho blir bytt', async ({ page }) => {
        await openPortalPage(page, `${HOME}?type=employer&org=111111111`);
        await expect(page).toHaveURL(/\/arbeidsgiver/, { timeout: 60_000 });
        const selected = page.locator('c-aareg-org-selector [data-id="current"]');
        await expect(selected).toContainText('111 111 111', { timeout: 60_000 });
        const field = page.locator('c-aareg-org-selector').getByRole('combobox');
        expect((await field.boundingBox())?.width ?? 0).toBeGreaterThan(400);
        const chosenName = (await page.locator('c-aareg-org-selector .current-name').innerText()).trim();
        await documentScreenshot(page, '21-rolleside-vald-virksomheit');

        await page.locator('c-aareg-link-panel').filter({ hasText: 'Mine søknader' }).click();
        await expect(page).toHaveURL(/\/mine-soknader|\/mine-s%C3%B8knader|soknad/i);
        const bar = page.locator('c-aareg-portal-nav [data-id="context"]');
        await expect(bar).toContainText('Arbeidsgiver for', { timeout: 60_000 });
        await expect(bar).toContainText(chosenName);
        await expect(bar).toContainText('Org.nr. 111 111 111');
        const title = page.getByRole('heading', { level: 1, name: /Mine Søknader/ });
        await expect(title).toBeVisible();
        await expect(page.locator('c-aareg_main-banner .mainbanner, c-aareg-main-banner .mainbanner')).toHaveCount(0);
        expect((await title.boundingBox())!.y).toBeGreaterThan((await bar.boundingBox())!.y);
        await documentScreenshot(page, '22-kontekstlinje-underside');

        await bar.getByRole('link', { name: 'Bytt virksomhet' }).click();
        await expect(page).toHaveURL(/\/arbeidsgiver/);
        await expect(page.locator('c-aareg-org-selector [data-id="current"]')).toContainText('111 111 111', {
            timeout: 60_000
        });
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
