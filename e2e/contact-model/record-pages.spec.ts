import { expect, test } from '@playwright/test';
import { context, documentScreenshot, openInApp } from './support';

const APP = 'Arbeidsforhold_Admin';

const EXPECTED_LIST_VIEWS = [
    'AAREG_Contact_Migration_Run__c.Active_Runs',
    'AAREG_Contact_Migration_Run__c.All_Runs',
    'AAREG_Contact_Migration_Run__c.Apply_And_Rollback_Runs',
    'AAREG_Contact_Migration_Run__c.Failed_Runs',
    'AAREG_Contact_Migration_Run__c.Last_30_Days',
    'AAREG_Contact_Migration_Run__c.Runs_With_Deviations',
    'AAREG_Contact_Point__c.All_Contact_Points',
    'AAREG_Contact_Point__c.Missing_Email',
    'AAREG_Contact_Point__c.Org_Context_Missing_Organization',
    'AAREG_Contact_Point__c.Organization_Contact_Points',
    'AAREG_Contact_Point__c.Private_Contact_Points',
    'AAREG_Contact_Point__c.Recently_Changed'
];

test.describe('Listevisningar og postsider for kontaktpunkt og migreringskøyringar', () => {
    test('alle listevisningane finst i orgen', () => {
        expect([...context.listViews].sort()).toEqual(EXPECTED_LIST_VIEWS);
    });

    test('listevisninga for kontaktpunkt viser rader med kontakt og kontekst', async ({ page }) => {
        await openInApp(page, APP, '/lightning/o/AAREG_Contact_Point__c/list?filterName=All_Contact_Points');
        await expect(page.getByRole('heading', { name: /All Contact Points/ }).first()).toBeVisible({
            timeout: 60_000
        });
        await expect(page.getByText('Context', { exact: true }).filter({ visible: true }).first()).toBeVisible();
        await expect(page.getByRole('link', { name: /^ACP-/ }).filter({ visible: true }).first()).toBeVisible();
        await documentScreenshot(page, '23-listevisning-kontaktpunkt');
    });

    test('postsida for kontaktpunkt viser kontekst, adresse og deltakingar', async ({ page }) => {
        test.skip(!context.contactPointId, 'Køyr «npm run contact-model -- apply» først.');
        await openInApp(page, APP, `/lightning/r/AAREG_Contact_Point__c/${context.contactPointId}/view`);
        const detail = page.locator('records-record-layout-section, force-record-layout-section');
        await expect(detail.getByText('Address', { exact: true }).first()).toBeVisible({ timeout: 60_000 });
        await expect(page.getByText('Organization', { exact: true }).first()).toBeVisible();
        await expect(page.getByRole('link', { name: /^Participations/ }).first()).toBeVisible();
        await documentScreenshot(page, '24-postside-kontaktpunkt');
    });

    test('postsida for migreringskøyring viser resultat, klassar og rader', async ({ page }) => {
        test.skip(!context.migrationRunId, 'Køyr «npm run contact-model -- apply» først.');
        await openInApp(page, APP, `/lightning/r/AAREG_Contact_Migration_Run__c/${context.migrationRunId}/view`);
        for (const section of ['Timeline', 'Results', 'Classification', 'Summary']) {
            await expect(page.getByText(section, { exact: true }).first()).toBeVisible({ timeout: 60_000 });
        }
        await expect(
            page
                .locator('article')
                .filter({ hasText: /^Items/ })
                .first()
        ).toBeVisible();
        await expect(page.getByRole('link', { name: /^Items/ }).first()).toBeVisible();
        await documentScreenshot(page, '25-postside-migreringskoyring');
    });
});
