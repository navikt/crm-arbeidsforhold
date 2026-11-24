import { expect, test } from '@playwright/test';
import { context, documentScreenshot, openPortalPage } from './support';

const HOME = '/aaregisteret/s/';
const MIN_SIDE = 'Min side – Brukerstøtte og søknad om tilgang til Aa-registeret';
const roleLink = (page, name: string) =>
    page.locator('c-aareg-entry-portal').getByRole('link', { name: new RegExp(`^${name}`) });

test.describe('Inngangsportal med rolleval', () => {
    test.beforeEach(() => {
        test.skip(!context.networkId || !context.portalUserId, 'Portalbrukaren eller nettstaden manglar i orgen.');
    });

    test('forsida viser rollene utan at noko er valt', async ({ page }) => {
        await openPortalPage(page, HOME);

        await expect(
            page.getByRole('heading', { name: 'Brukerstøtte og søknad om tilgang til Aa-registeret', level: 1 })
        ).toBeVisible({ timeout: 60_000 });
        await expect(roleLink(page, 'Arbeidsgiver')).toBeVisible();
        await expect(roleLink(page, 'Samarbeidspartner')).toBeVisible();
        await expect(roleLink(page, 'Privatperson')).toBeVisible();
        await expect(page.locator('c-link-panel').filter({ hasText: 'Min profil' })).toBeVisible();
        await expect(page).toHaveURL(/\/s\/$/);
        await documentScreenshot(page, '12-inngangsportal-rolleval');
    });

    test('arbeidsgivar må velje virksomheit før tenestene blir viste', async ({ page }) => {
        await openPortalPage(page, HOME);
        await roleLink(page, 'Arbeidsgiver').click();

        await expect(page).toHaveURL(/\/arbeidsgiver/);
        await expect(page.getByRole('heading', { name: MIN_SIDE, level: 1 })).toBeVisible({ timeout: 60_000 });
        await expect(page.getByText('Rolle: Arbeidsgiver')).toBeVisible();
        const selector = page.getByRole('combobox');
        const altinnWarning = page.getByText(/Altinn/).first();
        await expect(selector.or(altinnWarning)).toBeVisible({ timeout: 60_000 });
        await expect(page.locator('c-link-panel')).toHaveCount(0);
        await expect(page.getByRole('button', { name: 'Oppdater liste' })).toBeVisible();
        await documentScreenshot(page, '13-rolleside-arbeidsgiver-vel-virksomheit');
    });

    test('direktelenkje for privatperson går til rollesida med «Min profil»', async ({ page }) => {
        await openPortalPage(page, `${HOME}?type=private-person`);

        await expect(page).toHaveURL(/\/privatperson/, { timeout: 60_000 });
        await expect(page.getByText('Rolle: Privatperson / arbeidstaker')).toBeVisible();
        await expect(page.getByText('Du trenger ikke velge virksomhet.')).toBeVisible();
        await expect(page.locator('c-link-panel').filter({ hasText: 'Min profil' })).toBeVisible();
        await expect(page.getByText('Flere tjenester for privatpersoner kommer.')).toBeVisible();
        await documentScreenshot(page, '14-rolleside-privatperson');
    });

    test('ugyldig organisasjonsnummer i lenkja blir ignorert', async ({ page }) => {
        await openPortalPage(page, '/aaregisteret/s/arbeidsgiver?org=abc');

        await expect(page.getByText('Rolle: Arbeidsgiver')).toBeVisible({ timeout: 60_000 });
        await expect(page.getByRole('button', { name: 'Oppdater liste' })).toBeVisible({ timeout: 60_000 });
        await expect(page.locator('c-link-panel')).toHaveCount(0);
    });

    test('forsida viser berre faste meldingar', async ({ page }) => {
        await openPortalPage(page, `${HOME}?c__message=no-access`);
        await expect(page.getByText('Du har ikke tilgang til denne siden. Velg en annen rolle.')).toBeVisible({
            timeout: 60_000
        });
        await documentScreenshot(page, '15-inngangsportal-ingen-tilgang');

        await page.goto(page.url().replace('no-access', 'ukjent'));
        await expect(roleLink(page, 'Arbeidsgiver')).toBeVisible({ timeout: 60_000 });
        await expect(page.getByText('Du har ikke tilgang til denne siden.')).toHaveCount(0);
    });

    test('«Bytt rolle» går tilbake til rollevalet', async ({ page }) => {
        await openPortalPage(page, '/aaregisteret/s/privatperson');
        await page.getByRole('link', { name: 'Bytt rolle' }).click();

        await expect(roleLink(page, 'Samarbeidspartner')).toBeVisible({ timeout: 60_000 });
    });
});
