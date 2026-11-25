const assert = require('node:assert/strict');
const { test } = require('node:test');
const { buildInventory, componentForPath, repositoryUrlFromRemote } = require('../metadata-inventory.cjs');

const LOG = [
    '@@aaaaaaaaaaaaaaaa|2026-10-02T10:00:00+02:00|Remove naming test',
    'force-app/main/default/classes/AAREG_CheckObjectTypeNamingTest.cls',
    'force-app/main/default/classes/AAREG_CheckObjectTypeNamingTest.cls-meta.xml',
    'force-app/main/default/objects/Application__c/fields/Old_Field__c.field-meta.xml',
    'force-app/main/default/applications/standard__LightningSales.app-meta.xml',
    '@@bbbbbbbbbbbbbbbb|2026-09-01T10:00:00+02:00|Move controller',
    'force-app/main/default/classes/AAREG_ApplicationController.cls',
    '@@cccccccccccccccc|2026-08-01T10:00:00+02:00|Older removal',
    'force-app/main/default/classes/AAREG_CheckObjectTypeNamingTest.cls',
    'force-app/main/default/objectTranslations/Application__c-no/Application__c-no.objectTranslation-meta.xml'
].join('\n');

const TRACKED = [
    'force-app/externalApplication/classes/AAREG_ApplicationController.cls',
    'force-app/main/default/objects/Application__c/Application__c.object-meta.xml',
    'force-app/main/default/lwc/aaregOrgSelector/aaregOrgSelector.js',
    'crm-platform-base/main/default/classes/LoggerUtility.cls'
];

function inventory() {
    return buildInventory({ logOutput: LOG, trackedFiles: TRACKED, commit: 'dddddddddddddddd', committedAt: 'x' });
}

test('maps source paths to metadata components', () => {
    assert.deepEqual(componentForPath('force-app/a/reports/Folder/AAREG_Report.report-meta.xml'), {
        type: 'Report',
        name: 'AAREG_Report'
    });
    assert.deepEqual(componentForPath('force-app/a/objects/Account/listViews/All.listView-meta.xml'), {
        type: 'ListView',
        name: 'Account.All'
    });
    assert.deepEqual(componentForPath('force-app/integration/p360/classes/adapter/P360_AdapterFactory.cls'), {
        type: 'ApexClass',
        name: 'P360_AdapterFactory'
    });
    assert.equal(componentForPath('force-app/a/objectTranslations/X-no/X-no.objectTranslation-meta.xml'), null);
});

test('lists a removed component once with its most recent deletion', () => {
    const removed = inventory().removed.filter((item) => item.name === 'AAREG_CheckObjectTypeNamingTest');
    assert.equal(removed.length, 1);
    assert.equal(removed[0].commit, 'aaaaaaaaaaaa');
    assert.equal(removed[0].removedOn, '2026-10-02');
});

test('excludes components that were moved and still exist in source', () => {
    const names = inventory().removed.map((item) => `${item.type}:${item.name}`);
    assert.deepEqual(names, ['ApexClass:AAREG_CheckObjectTypeNamingTest', 'CustomField:Application__c.Old_Field__c']);
});

test('repository inventory holds only components with an owned prefix', () => {
    assert.deepEqual(inventory().repository, {
        ApexClass: ['AAREG_ApplicationController'],
        LightningComponentBundle: ['aaregOrgSelector']
    });
});

test('derives a browsable repository URL from SSH and HTTPS remotes', () => {
    const expected = 'https://github.com/navikt/crm-arbeidsforhold';
    assert.equal(repositoryUrlFromRemote('git@github.com:navikt/crm-arbeidsforhold.git\n'), expected);
    assert.equal(repositoryUrlFromRemote('https://github.com/navikt/crm-arbeidsforhold.git'), expected);
});
