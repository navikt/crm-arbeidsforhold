import { chromium } from '@playwright/test';
import fs from 'node:fs';
import path from 'node:path';

// eslint-disable-next-line @typescript-eslint/no-require-imports
const { sfInvocation } = require('../../scripts/p360-scratch-contract.cjs');
// eslint-disable-next-line @typescript-eslint/no-require-imports
const { verifyScratchTarget } = require('../../scripts/scratch-target.cjs');
// eslint-disable-next-line @typescript-eslint/no-require-imports
const { spawnSync } = require('node:child_process');

const AUTH_DIRECTORY = path.join(__dirname, '.auth');

type SfResult = { status: number; result?: any; message?: string };

function runSf(args: string[], options: { target?: string } = {}): SfResult {
    const invocation = sfInvocation(process.platform, args, options.target);
    const result = spawnSync(invocation.command, invocation.args, {
        encoding: 'utf8',
        shell: invocation.shell,
        env: invocation.env,
        maxBuffer: 64 * 1024 * 1024
    });
    const start = (result.stdout ?? '').indexOf('{');
    if (start < 0) {
        throw new Error(`The Salesforce CLI returned no JSON for "sf ${args.slice(0, 2).join(' ')}".`);
    }
    return JSON.parse(result.stdout.slice(start));
}

/**
 * Verifies the scratch target, signs the admin in through frontdoor and stores the record Ids the specs use.
 * The frontdoor URL contains a session and is never logged or written to disk.
 */
export default async function globalSetup(): Promise<void> {
    const { target, runSf: runOnTarget } = verifyScratchTarget(runSf, () => undefined);

    const query = (soql: string): any[] => {
        const response = runOnTarget(['data', 'query', '--target-org', target, '--query', soql, '--json']);
        if (response.status !== 0) {
            throw new Error(`Query failed: ${response.message}`);
        }
        return response.result.records ?? [];
    };
    const first = (soql: string): any => query(soql)[0] ?? {};

    const opened = runOnTarget(['org', 'open', '--target-org', target, '--url-only', '--json']);
    const frontdoor: string | undefined = opened.result?.url;
    if (opened.status !== 0 || !frontdoor) {
        throw new Error('Could not create a frontdoor URL for the scratch org.');
    }
    const instanceUrl = new URL(frontdoor).origin;

    const contactPoint = first(
        "SELECT Contact__c, Organization__c FROM AAREG_Contact_Point__c WHERE Context__c = 'Organization' ORDER BY CreatedDate DESC LIMIT 1"
    );
    const participation = first(
        'SELECT Application__c FROM RelatedContact__c WHERE Contact_Point__c != null ORDER BY CreatedDate DESC LIMIT 1'
    );
    const context = {
        instanceUrl,
        orgId: first('SELECT Id FROM Organization').Id,
        applicationId: participation.Application__c,
        organizationId: contactPoint.Organization__c,
        contactId: contactPoint.Contact__c,
        dashboardId: first("SELECT Id FROM Dashboard WHERE DeveloperName = 'AAREG_Contact_Model_Overview'").Id,
        reports: query("SELECT Id, DeveloperName, Name FROM Report WHERE DeveloperName LIKE 'AAREG_CM_%'").map(
            ({ Id, DeveloperName, Name }) => ({ id: Id, developerName: DeveloperName, name: Name })
        ),
        networkId: first("SELECT Id FROM Network WHERE UrlPathPrefix = 'aaregisteret'").Id,
        portalUserId: first(
            "SELECT Id FROM User WHERE Username LIKE 'aareg.community.test.%@example.invalid' AND IsActive = true LIMIT 1"
        ).Id
    };

    fs.mkdirSync(AUTH_DIRECTORY, { recursive: true });
    fs.writeFileSync(path.join(AUTH_DIRECTORY, 'context.json'), JSON.stringify(context, null, 2));

    const browser = await chromium.launch();
    try {
        const page = await browser.newPage();
        await page.goto(frontdoor, { waitUntil: 'domcontentloaded', timeout: 90_000 });
        await page.waitForURL(/\/lightning\//, { timeout: 90_000 });
        await page.context().storageState({ path: path.join(AUTH_DIRECTORY, 'admin.json') });
    } finally {
        await browser.close();
    }
}
