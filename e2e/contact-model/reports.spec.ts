import { expect, test } from '@playwright/test';
import { context, documentScreenshot } from './support';

const EXPECTED_REPORTS = [
    'AAREG_CM_Contact_Points_by_Context',
    'AAREG_CM_Items_Manual_Review',
    'AAREG_CM_Items_by_Class',
    'AAREG_CM_Migration_Runs',
    'AAREG_CM_Participations_by_Role'
];

test.describe('Rapportar og dashboard for kontaktmodellen', () => {
    test('alle fem rapportane finst i orgen', () => {
        expect(context.reports.map((report) => report.developerName).sort()).toEqual(EXPECTED_REPORTS);
    });

    for (const developerName of EXPECTED_REPORTS) {
        test(`rapporten ${developerName} opnar utan feil`, async ({ page }) => {
            const report = context.reports.find((candidate) => candidate.developerName === developerName);
            test.skip(!report, `${developerName} manglar i orgen.`);
            await page.goto(`${context.instanceUrl}/lightning/r/Report/${report!.id}/view`);

            const viewer = page.getByRole('main').frameLocator('iframe').first();
            await expect(viewer.getByText(report!.name, { exact: true }).first()).toBeVisible();
            await expect(viewer.getByText('Total Records').first()).toBeVisible();
            await expect(viewer.getByText(/unexpected error|feil oppstod/i)).toHaveCount(0);
        });
    }

    test('dashboardet viser nøkkeltal og køyringar', async ({ page }) => {
        test.skip(!context.dashboardId, 'Dashboardet manglar i orgen.');
        await page.goto(`${context.instanceUrl}/lightning/r/Dashboard/${context.dashboardId}/view`);

        const viewer = page.getByRole('main').frameLocator('iframe').first();
        for (const header of [
            'Migreringskøyringar',
            'Til manuell vurdering (C, D, E)',
            'Deltakingar på søknader',
            'Migreringsrader per klasse',
            'Kontaktpunkt per kontekst',
            'Migreringskøyringar per modus'
        ]) {
            await expect(viewer.getByText(header, { exact: true }).first()).toBeAttached();
        }
        await expect(viewer.getByText(/unexpected error/i)).toHaveCount(0);
        await viewer.getByRole('button', { name: 'Refresh', exact: true }).click();
        await expect(viewer.getByText('Try refreshing the dashboard.')).toHaveCount(0, { timeout: 90_000 });
        await expect(viewer.getByText('Record Count').first()).toBeVisible({ timeout: 90_000 });
        await documentScreenshot(page, '05-dashboard', false);
    });
});
