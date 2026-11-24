import { expect, test } from '@playwright/test';
import { context, documentScreenshot, openPortalPage } from './support';

const SITE_PATH = '/aaregisteret/s/ny-soknad-aa-registret';

test.describe('Ny søknad: rolle først (K5)', () => {
    test.beforeEach(async ({ page }) => {
        test.skip(!context.networkId || !context.portalUserId, 'Portalbrukaren eller nettstaden manglar i orgen.');
        await openPortalPage(page, SITE_PATH);
        await expect(
            page.getByRole('heading', { name: 'Ny søknad om tilgang til Aa-registeret', level: 1 })
        ).toBeVisible({
            timeout: 60_000
        });
    });

    test('ingen rolle er vald på førehand, og søknadsskjemaet er skjult', async ({ page }) => {
        const roles = page.getByRole('group', { name: 'Korleis søkjer du?' });
        await expect(roles.getByRole('radio')).toHaveCount(3);
        for (const radio of await roles.getByRole('radio').all()) {
            await expect(radio).not.toBeChecked();
        }
        await expect(page.getByRole('button', { name: 'Gå vidare til søknaden' })).toHaveCount(0);
        await documentScreenshot(page, '08-ny-soknad-vel-rolle');
    });

    test('privatperson får forklaring og lenkje til «Min profil», ikkje eit skjema', async ({ page }) => {
        await page.getByRole('radio', { name: 'Som privatperson' }).check();
        await expect(page.getByText(/du kan ikkje søkje som privatperson/)).toBeVisible();
        await expect(page.getByRole('link', { name: 'Min profil' })).toHaveAttribute('href', /min-profil/);
        await expect(page.getByRole('combobox', { name: 'Kva organisasjon søkjer du for?' })).toHaveCount(0);
        await documentScreenshot(page, '09-ny-soknad-privatperson');
    });

    test('arbeidsgivar må velje ein organisasjon med stadfesta rolle før han går vidare', async ({ page }) => {
        await page.getByRole('radio', { name: 'Som arbeidsgiver' }).check();
        const selector = page.getByRole('combobox', { name: 'Kva organisasjon søkjer du for?' });
        const altinnWarning = page.getByRole('alert');
        await expect(selector.or(altinnWarning).first()).toBeVisible({ timeout: 60_000 });
        await documentScreenshot(page, '10-ny-soknad-arbeidsgiver');
        test.skip(
            await altinnWarning.isVisible(),
            'Altinn svarar ikkje i scratch; organisasjonsvalet blir testa manuelt.'
        );

        await expect(page.getByRole('button', { name: 'Gå vidare til søknaden' })).toBeDisabled();
        await selector.click();
        await expect(page.getByRole('option', { name: /Meg selv/ })).toHaveCount(0);
    });
});
