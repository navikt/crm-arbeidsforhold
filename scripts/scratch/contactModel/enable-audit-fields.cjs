'use strict';

// Scratch only. Turns on the org preference that allows the scratch seed to set CreatedById on synthetic applications.
// The preference has no metadata representation, so the Setup page is used. AAREG_FRONTDOOR_URL is passed by
// scripts/contact-model.cjs after the scratch target is verified; it contains a session and is never logged.
const { chromium } = require('@playwright/test');

(async () => {
    const url = process.env.AAREG_FRONTDOOR_URL;
    if (!url) {
        throw new Error('AAREG_FRONTDOOR_URL is required.');
    }
    const browser = await chromium.launch();
    try {
        const page = await browser.newPage();
        await page.goto(url, { waitUntil: 'networkidle', timeout: 120000 });
        const checkbox = page.locator('#auditFieldInactiveOwner');
        if (await checkbox.isChecked()) {
            console.log('Audit field preference already enabled.');
            return;
        }
        await checkbox.check();
        await Promise.all([page.waitForLoadState('networkidle'), page.locator('input[name="save"]').first().click()]);
        console.log('Audit field preference enabled.');
    } finally {
        await browser.close();
    }
})().catch((error) => {
    console.error(error.message);
    process.exitCode = 1;
});
