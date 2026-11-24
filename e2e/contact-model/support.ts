import { expect, type Page } from '@playwright/test';
import fs from 'node:fs';
import path from 'node:path';

export type ScratchContext = {
    instanceUrl: string;
    orgId: string;
    applicationId?: string;
    organizationId?: string;
    contactId?: string;
    contactPointId?: string;
    migrationRunId?: string;
    listViews: string[];
    dashboardId?: string;
    reports: { id: string; developerName: string; name: string }[];
    networkId?: string;
    portalUserId?: string;
    threadId?: string;
};

export const context: ScratchContext = JSON.parse(
    fs.readFileSync(path.join(__dirname, '.auth', 'context.json'), 'utf8')
);

const DOC_SCREENSHOTS = path.join(__dirname, '../../docs/architecture/kontaktmodell/testing/skjermbilete');

/** Opens a Lightning path in the given app so record-page overrides for that app apply. */
export async function openInApp(page: Page, appDeveloperName: string, lightningPath: string): Promise<void> {
    await page.goto(`${context.instanceUrl}/lightning/app/c__${appDeveloperName}`);
    await expect(page.locator('one-appnav, .appName').first()).toBeVisible();
    await page.goto(`${context.instanceUrl}${lightningPath}`);
}

/** Stores a named screenshot for the documentation when CM_DOC_SCREENSHOTS=1. */
export async function documentScreenshot(page: Page, name: string, fullPage = true): Promise<void> {
    if (process.env.CM_DOC_SCREENSHOTS !== '1') {
        return;
    }
    fs.mkdirSync(DOC_SCREENSHOTS, { recursive: true });
    // Charts finish their render animation after the assertions pass; the pause only affects documentation images.
    await page.waitForTimeout(3_000);
    await page.screenshot({ path: path.join(DOC_SCREENSHOTS, `${name}.png`), fullPage });
}

/** Logs in as the seeded portal user and opens a path on the Experience Cloud site. */
export async function openPortalPage(page: Page, sitePath: string): Promise<void> {
    const parameters = new URLSearchParams({
        oid: context.orgId,
        retURL: `/${context.portalUserId}`,
        sunetworkid: context.networkId!,
        sunetworkuserid: context.portalUserId!
    });
    await page.goto(`${context.instanceUrl}/servlet/servlet.su?${parameters}`);
    await page.waitForURL(/\.site\.com\//, { timeout: 90_000 });
    const siteOrigin = new URL(page.url()).origin;
    await page.goto(`${siteOrigin}${sitePath}`);
}
