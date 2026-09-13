import AxeBuilder from '@axe-core/playwright';
import { expect, test } from '@playwright/test';

test('dashboard is accessible, responsive, and free of viewport overlap', async ({ page }, testInfo) => {
    await page.goto('/');
    await expect(page.getByRole('heading', { name: 'Salesforce-organisasjonar' })).toBeVisible();
    await expect(page.getByRole('table', { name: 'Tilgjengelege organisasjonar' })).toBeVisible();
    await expect(page.getByRole('table', { name: 'Pakkestatus for scratch-e2e' })).toContainText('crm-platform-base');

    const bodyOverflow = await page.evaluate(
        () => document.documentElement.scrollWidth - document.documentElement.clientWidth
    );
    expect(bodyOverflow).toBeLessThanOrEqual(1);

    const header = await page.locator('.app-header').boundingBox();
    const main = await page.getByRole('main').boundingBox();
    expect(header).not.toBeNull();
    expect(main).not.toBeNull();
    expect(header!.y + header!.height).toBeLessThanOrEqual(main!.y + 1);

    const screenshot = await page.screenshot({ fullPage: true });
    expect(screenshot.byteLength).toBeGreaterThan(10_000);
    await testInfo.attach('dashboard', { body: screenshot, contentType: 'image/png' });

    const accessibility = await new AxeBuilder({ page }).analyze();
    expect(accessibility.violations).toEqual([]);
});

test('destructive target and live operation remain actionable', async ({ page }) => {
    await page.goto('/');
    await page.getByRole('button', { name: 'Slett organisasjon' }).click();
    const dialog = page.getByRole('alertdialog', { name: 'Slett scratch-e2e?' });
    await expect(dialog).toContainText('Mål: scratch-e2e');
    await page.getByRole('button', { name: 'Avbryt' }).click();

    await page.getByRole('button', { name: 'Start kommando' }).click();
    await expect(page.getByRole('heading', { name: 'Pakkeplanlegging køyrer' })).toBeVisible();
    await expect(page.getByText('Deterministisk testoperasjon fullført')).toBeVisible();
    await expect(page.getByRole('heading', { name: 'Pakkeplanlegging er fullført' })).toBeVisible();
});
