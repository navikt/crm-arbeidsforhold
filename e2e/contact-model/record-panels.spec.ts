import { expect, test } from '@playwright/test';
import { context, documentScreenshot, openInApp } from './support';

const APP = 'AAREG_Contact_Model';

test.describe('Kontaktmodell-panelet på postsider', () => {
    test('søknaden viser deltakingar med rolle', async ({ page }) => {
        test.skip(!context.applicationId, 'Køyr «npm run contact-model -- apply» først.');
        await openInApp(page, APP, `/lightning/r/Application__c/${context.applicationId}/view`);

        const panel = page.locator('c-aareg-contact-model-panel');
        await expect(panel.getByText('Kontaktmodell').first()).toBeVisible();
        await expect(panel.getByText(/\d+ av \d+ deltakingar er kopla til ein domenekontakt\./)).toBeVisible();
        await documentScreenshot(page, '02-panel-soknad');
    });

    test('organisasjonen viser personar kopla via ACR', async ({ page }) => {
        test.skip(!context.organizationId, 'Køyr «npm run contact-model -- apply» først.');
        await openInApp(page, APP, `/lightning/r/Account/${context.organizationId}/view`);

        const panel = page.locator('c-aareg-contact-model-panel');
        await expect(panel.getByText(/\d+ personar? er kopla til organisasjonen\./)).toBeVisible();
        await documentScreenshot(page, '03-panel-organisasjon');
    });

    test('domenekontakten viser kontaktpunkt per kontekst', async ({ page }) => {
        test.skip(!context.contactId, 'Køyr «npm run contact-model -- apply» først.');
        await openInApp(page, APP, `/lightning/r/Contact/${context.contactId}/view`);

        const panel = page.locator('c-aareg-contact-model-panel');
        await expect(panel.getByText('Kontaktmodell').first()).toBeVisible();
        await expect(panel.getByRole('heading').first()).toBeVisible();
        await documentScreenshot(page, '04-panel-kontakt');
    });
});
