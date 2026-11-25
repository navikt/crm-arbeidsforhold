const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { test } = require('node:test');
const {
    calculateCoverage,
    coverageRecords,
    getApexClassNames,
    getApexTestClassNames,
    installPlan,
    readPlan,
    scratchFingerprint,
    selectRoute,
    verifyScratchOrg
} = require('../ci-scratch-plan.cjs');

const project = {
    packageDirectories: [
        {
            dependencies: [
                { package: 'base', versionNumber: '1.0.0.LATEST' },
                { package: 'parent', versionNumber: '2.0.0.LATEST' }
            ]
        }
    ]
};

test('preserves selected package IDs and key policy in manifest order', () => {
    const plan = readPlan(
        {
            ...project,
            packageKeyConfig: { base: false, parent: true }
        },
        {
            base: { SubscriberPackageVersionId: 'base-version' },
            parent: { SubscriberPackageVersionId: 'parent-version' }
        }
    );
    assert.deepEqual(plan, [
        { name: 'base', versionId: 'base-version', requiresKey: false },
        { name: 'parent', versionId: 'parent-version', requiresKey: true }
    ]);
});

const ready = {
    enabled: true,
    expectedOrgId: 'expected',
    actualOrgId: 'expected',
    expiration: '2030-01-15',
    expectedFingerprint: 'same',
    actualFingerprint: 'same',
    installed: [{ SubscriberPackageVersionId: 'baseNew' }, { SubscriberPackageVersionId: 'parent' }],
    plan: [{ versionId: 'baseNew' }, { versionId: 'parent' }],
    now: new Date('2030-01-01T12:00:00Z')
};

test('reuses only a registered org with the exact installed versions', () => {
    assert.equal(selectRoute(ready).route, 'reuse');
    assert.equal(selectRoute({ ...ready, installed: [{ SubscriberPackageVersionId: 'baseOld' }] }).route, 'fresh');
    assert.equal(selectRoute({ ...ready, actualFingerprint: 'other' }).route, 'fresh');
    assert.equal(selectRoute({ ...ready, expiration: '2030-01-02' }).route, 'fresh');
    assert.equal(selectRoute({ ...ready, enabled: false }).route, 'fresh');
});

test('fails closed when the registered org identity does not match', () => {
    assert.throws(() => selectRoute({ ...ready, actualOrgId: 'different' }), /identity/i);
});

test('rejects an invalid package plan instead of routing to fallback', () => {
    assert.throws(() => selectRoute({ ...ready, plan: [{ name: 'base' }] }), /plan/i);
    assert.throws(() => selectRoute({ ...ready, enabled: false, plan: [] }), /plan/i);
});

test('does not reuse an org with an invalid expiration date', () => {
    assert.equal(selectRoute({ ...ready, expiration: '2030-02-31' }).route, 'fresh');
});

test('requires a case-sensitive active Dev Hub scratch record with the registered expiration', () => {
    const orgId = 'A'.repeat(15);
    const record = { ScratchOrg: orgId, Status: 'Active', ExpirationDate: '2030-01-15' };
    assert.equal(verifyScratchOrg(`${orgId}XYZ`, '2030-01-15', [record]), true);
    assert.equal(verifyScratchOrg(orgId.toLowerCase(), '2030-01-15', [record]), false);
    assert.equal(verifyScratchOrg(orgId, '2030-01-16', [record]), false);
    assert.equal(verifyScratchOrg(orgId, '2030-01-15', [{ ...record, Status: 'Deleted' }]), false);
    assert.equal(verifyScratchOrg(orgId, '2030-01-15', []), false);
    assert.throws(() => verifyScratchOrg(orgId, '2030-01-15', null), /scratch.*record/i);
    assert.throws(() => verifyScratchOrg("invalid' OR Status='Active", '2030-01-15', []), /invalid.*org.*id/i);
});

test('calculates the repository coverage threshold using only source classes', () => {
    assert.deepEqual(
        calculateCoverage(
            [
                { name: 'ApexClass', totalCovered: 85, totalLines: 100 },
                { name: 'DependencyClass', totalCovered: 0, totalLines: 100 }
            ],
            ['ApexClass']
        ),
        { covered: 85, total: 100, percentage: 85 }
    );
    assert.throws(
        () => calculateCoverage([{ name: 'ApexClass', totalCovered: 84, totalLines: 100 }], ['ApexClass']),
        /below 85%/
    );
    assert.throws(
        () => calculateCoverage([{ name: 'ApexClass', totalCovered: 110, totalLines: 100 }], ['ApexClass']),
        /invalid coverage/i
    );
    assert.throws(() => calculateCoverage([], ['ApexClass']), /No Apex coverage records/);
});

test('reads coverage from Salesforce deploy and Apex test result shapes', () => {
    const records = [{ name: 'ApexClass', numLocations: 100, numLocationsNotCovered: 15 }];
    assert.deepEqual(coverageRecords({ result: { details: { runTestResult: { codeCoverage: records } } } }), records);
    assert.deepEqual(coverageRecords({ result: { codecoverage: records } }), records);
    assert.deepEqual(coverageRecords({ codeCoverage: records }), records);
    assert.throws(() => coverageRecords({ result: {} }), /coverage data is missing/);
});

test('finds Apex test classes and fingerprints the checked scratch definition', (context) => {
    const directory = fs.mkdtempSync(path.join(os.tmpdir(), 'ci-scratch-plan-'));
    context.after(() => fs.rmSync(directory, { recursive: true, force: true }));
    const source = path.join(directory, 'classes');
    fs.mkdirSync(source);
    fs.writeFileSync(path.join(source, 'Example.cls'), 'public class Example {}');
    fs.writeFileSync(path.join(source, 'ExampleTest.cls'), '@IsTest public class ExampleTest {}');
    const projectFile = path.join(directory, 'sfdx-project.json');
    const definitionFile = path.join(directory, 'scratch.json');
    fs.writeFileSync(projectFile, JSON.stringify({ sourceApiVersion: '68.0' }));
    fs.writeFileSync(definitionFile, '{"edition":"Enterprise"}');
    const first = scratchFingerprint(projectFile, definitionFile);
    fs.writeFileSync(definitionFile, '{"edition":"Developer"}');
    assert.deepEqual(getApexClassNames(source), ['Example', 'ExampleTest']);
    assert.deepEqual(getApexTestClassNames(source), ['ExampleTest']);
    assert.notEqual(scratchFingerprint(projectFile, definitionFile), first);
});

test('installs the validated exact versions in order without exposing keys in output', async () => {
    const calls = [];
    await installPlan(
        [
            { name: 'base', versionId: 'base-version', requiresKey: false },
            { name: 'parent', versionId: 'parent-version', requiresKey: true }
        ],
        'ci-fresh',
        'test-key',
        async (args) => calls.push(args)
    );
    assert.deepEqual(calls[0], [
        'package',
        'install',
        '--target-org',
        'ci-fresh',
        '--package',
        'base-version',
        '--no-prompt',
        '--wait',
        '15',
        '--publish-wait',
        '10'
    ]);
    assert.ok(calls[1].includes('parent-version'));
    assert.deepEqual(calls[1].slice(-2), ['--installation-key', 'test-key']);
    await assert.rejects(
        () => installPlan([{ name: 'parent', versionId: 'id', requiresKey: true }], 'org', '', async () => {}),
        /key is required/
    );
    await assert.rejects(
        () =>
            installPlan([{ name: 'parent', versionId: 'id', requiresKey: true }], 'org', 'test-key', async () => {
                throw new Error('Failure containing test-key');
            }),
        (error) => {
            assert.match(error.message, /Failed to install parent id/);
            assert.doesNotMatch(error.message, /test-key/);
            return true;
        }
    );
});
