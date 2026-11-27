const assert = require('node:assert/strict');
const { spawnSync } = require('node:child_process');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { test } = require('node:test');
const {
    calculateCoverage,
    changedSourcesWithoutCoverage,
    coverageMarkdown,
    coverageRecords,
    isForceIgnored,
    getApexCoverageNames,
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
    assert.equal(
        selectRoute({
            ...ready,
            installed: [...ready.installed, { SubscriberPackageVersionId: 'unexpected-version' }]
        }).route,
        'fresh'
    );
    assert.equal(selectRoute({ ...ready, installed: [...ready.installed, {}] }).route, 'fresh');
    assert.equal(selectRoute({ ...ready, actualFingerprint: 'other' }).route, 'fresh');
    assert.equal(selectRoute({ ...ready, expiration: '2030-01-02' }).route, 'fresh');
    assert.equal(selectRoute({ ...ready, enabled: false }).route, 'fresh');
});

test('falls back when the registered secret and variables point at different orgs', () => {
    const route = selectRoute({ ...ready, actualOrgId: 'different' });
    assert.equal(route.route, 'fresh');
    assert.match(route.reason, /registration is incomplete/i);
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

test('calculates repository coverage from source Apex types', () => {
    assert.deepEqual(
        calculateCoverage(
            [
                { name: 'ApexClass', totalCovered: 85, totalLines: 100 },
                { name: 'DependencyClass', totalCovered: 0, totalLines: 100 }
            ],
            ['ApexClass']
        ),
        { covered: 85, total: 100, percentage: 85, missing: [] }
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
    assert.throws(
        () => calculateCoverage([], ['ApexClass'], 85, [{ name: 'ApexClass', path: 'ApexClass.cls', lines: 5 }]),
        /0\.00% is below 85%/
    );
    assert.deepEqual(
        calculateCoverage([], ['ApexClass'], 0, [{ name: 'ApexClass', path: 'ApexClass.cls', lines: 5 }]),
        {
            covered: 0,
            total: 5,
            percentage: 0,
            missing: [{ name: 'ApexClass', path: 'ApexClass.cls', lines: 5 }]
        }
    );
});

test('includes trigger coverage when enforcing the repository coverage threshold', (context) => {
    const directory = fs.mkdtempSync(path.join(os.tmpdir(), 'ci-apex-coverage-'));
    context.after(() => fs.rmSync(directory, { recursive: true, force: true }));
    fs.writeFileSync(path.join(directory, 'Example.cls'), 'public class Example {}');
    fs.writeFileSync(
        path.join(directory, 'ExampleTrigger.trigger'),
        'trigger ExampleTrigger on Account (after insert) {}'
    );
    fs.writeFileSync(path.join(directory, 'Example.page'), '<apex:page />');

    const coverageNames = getApexCoverageNames(directory);
    assert.deepEqual(coverageNames, ['Example', 'ExampleTrigger']);
    assert.throws(
        () =>
            calculateCoverage(
                [
                    { name: 'Example', totalCovered: 90, totalLines: 100 },
                    { name: 'ExampleTrigger', totalCovered: 0, totalLines: 50 }
                ],
                coverageNames
            ),
        /60\.00% is below 85%/
    );
});

test('counts changed Apex sources without coverage data as uncovered', (context) => {
    const directory = fs.mkdtempSync(path.join(os.tmpdir(), 'ci-changed-coverage-'));
    context.after(() => fs.rmSync(directory, { recursive: true, force: true }));
    const classes = path.join(directory, 'force-app', 'main', 'classes');
    fs.mkdirSync(classes, { recursive: true });
    const write = (name, body) => fs.writeFileSync(path.join(classes, name), body);
    write('Covered.cls', 'public class Covered { void a() { x = 1; } }');
    write(
        'Uncovered.cls',
        'public class Uncovered {\n    void a() {\n        x = 1;\n        y = 2;\n    }\n    // z = 3;\n}'
    );
    write('UncoveredTrigger.trigger', 'trigger UncoveredTrigger on Account (after insert) {\n    run();\n}');
    write('NewTest.cls', '@IsTest\nprivate class NewTest { static void t() { x = 1; } }');
    write('Contract.cls', 'public interface Contract {\n    void run();\n}');
    write('Ignored.cls', 'public class Ignored { void a() { x = 1; } }');
    write('Empty.cls', 'public class Empty {}');
    write('Disguised.cls', "// Covered by an @IsTest class\npublic class Disguised {\n    String s = '@IsTest';\n}");
    write(
        'UrlOnly.cls',
        "public class UrlOnly {\n    String u() { return 'https://example.invalid/*x'; } // trailing\n}"
    );
    const changed = [
        'force-app/main/classes/Covered.cls',
        'force-app/main/classes/Uncovered.cls',
        'force-app/main/classes/UncoveredTrigger.trigger',
        'force-app/main/classes/NewTest.cls',
        'force-app/main/classes/Contract.cls',
        'force-app/main/classes/Ignored.cls',
        'force-app/main/classes/Empty.cls',
        'force-app/main/classes/UrlOnly.cls',
        'force-app/main/classes/Disguised.cls',
        'force-app/main/classes/Deleted.cls',
        'force-app/main/lwc/example/example.js'
    ];
    const records = [{ name: 'Covered', totalCovered: 1, totalLines: 1 }];
    const missing = changedSourcesWithoutCoverage(changed, records, directory, ['**/classes/Ignored.cls']);
    assert.deepEqual(missing, [
        { name: 'Disguised', path: 'force-app/main/classes/Disguised.cls', lines: 1 },
        { name: 'Uncovered', path: 'force-app/main/classes/Uncovered.cls', lines: 2 },
        { name: 'UncoveredTrigger', path: 'force-app/main/classes/UncoveredTrigger.trigger', lines: 1 },
        { name: 'UrlOnly', path: 'force-app/main/classes/UrlOnly.cls', lines: 1 }
    ]);

    const result = calculateCoverage(
        [{ name: 'Covered', totalCovered: 97, totalLines: 100 }],
        ['Covered', 'Uncovered', 'UncoveredTrigger'],
        85,
        missing
    );
    assert.equal(result.total, 105);
    assert.deepEqual(result.missing, missing);
    assert.throws(
        () =>
            calculateCoverage([{ name: 'Covered', totalCovered: 10, totalLines: 10 }], ['Covered', 'Uncovered'], 85, [
                { name: 'Uncovered', path: 'Uncovered.cls', lines: 10 }
            ]),
        /50\.00% is below 85%.*1 changed Apex source without coverage data/
    );
});

test('summarizes coverage and lists changed sources without coverage data', () => {
    const missing = [{ name: 'Uncovered', path: 'force-app/main/classes/Uncovered.cls', lines: 20 }];
    const failed = coverageMarkdown({ covered: 80, total: 120, percentage: 66.666, missing });
    assert.match(failed, /❌ 66\.67% \(80\/120 lines, minimum 85%\)/);
    assert.match(failed, /⚠️ ingen dekningsdata: `force-app\/main\/classes\/Uncovered\.cls` \| 20/);
    const passed = coverageMarkdown({ covered: 90, total: 100, percentage: 90, missing: [] });
    assert.match(passed, /✅ 90\.00%/);
    assert.doesNotMatch(passed, /ingen dekningsdata/);
});

test('matches .forceignore patterns with negation and directory rules', () => {
    const patterns = [
        '# comment',
        '**/profiles/*',
        '!unpackagable/profiles/*',
        '**/experiences',
        '**/classes/Site*.cls'
    ];
    assert.equal(isForceIgnored('force-app/main/profiles/Admin.profile-meta.xml', patterns), true);
    assert.equal(isForceIgnored('unpackagable/profiles/Admin.profile-meta.xml', patterns), false);
    assert.equal(isForceIgnored('force-app/x/experiences/site/a.json', patterns), true);
    assert.equal(isForceIgnored('force-app/main/classes/SiteLoginController.cls', patterns), true);
    assert.equal(isForceIgnored('force-app/main/classes/Service.cls', patterns), false);
    assert.equal(isForceIgnored('force-app/ignored/NewService.cls', ['force-app/ignored/']), true);
    assert.equal(isForceIgnored('force-app/ignored', ['force-app/ignored/']), false);
    assert.equal(isForceIgnored('force-app/x/legacy/Old.cls', ['legacy/']), true);
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
    fs.writeFileSync(
        path.join(source, 'ExampleTrigger.trigger'),
        'trigger ExampleTrigger on Account (after insert) {}'
    );
    assert.deepEqual(getApexCoverageNames(source), ['Example', 'ExampleTest', 'ExampleTrigger']);
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
        async (args) => {
            calls.push(args);
            if (args[1] === 'installed') {
                return JSON.stringify({
                    result: [
                        { SubscriberPackageVersionId: 'base-version' },
                        { SubscriberPackageVersionId: 'parent-version' }
                    ]
                });
            }
        }
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
    assert.deepEqual(calls[2], ['package', 'installed', 'list', '--target-org', 'ci-fresh', '--json']);
    assert.equal(calls.length, 3);
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

test('rejects installed packages that do not exactly match the installation plan', async () => {
    const plan = [
        { name: 'base', versionId: 'base-version', requiresKey: false },
        { name: 'parent', versionId: 'parent-version', requiresKey: false }
    ];
    const scenarios = [
        {
            installed: [{ SubscriberPackageVersionId: 'base-version' }],
            expected: /missing.*parent.*parent-version/i
        },
        {
            installed: [{ SubscriberPackageVersionId: 'base-version' }, { SubscriberPackageVersionId: 'old-version' }],
            expected: /missing.*parent.*unexpected.*old-version/i
        },
        {
            installed: [
                { SubscriberPackageVersionId: 'base-version' },
                { SubscriberPackageVersionId: 'parent-version' },
                { SubscriberPackageVersionId: 'extra-version' }
            ],
            expected: /unexpected.*extra-version/i
        },
        {
            installed: [{ SubscriberPackageVersionId: 'base-version' }, {}],
            expected: /installed package versions cannot be verified/i
        },
        { installed: null, expected: /cannot verify installed package versions/i }
    ];
    for (const { installed, expected } of scenarios) {
        await assert.rejects(
            () =>
                installPlan(plan, 'ci-fresh', '', async (args) =>
                    args[1] === 'installed' ? JSON.stringify({ result: installed }) : ''
                ),
            expected
        );
    }
});

test('reports package-list failures and invalid responses without exposing the installation key', async () => {
    const plan = [{ name: 'base', versionId: 'base-version', requiresKey: false }];
    await assert.rejects(
        () =>
            installPlan(plan, 'ci-fresh', 'test-key', async (args) => {
                if (args[1] === 'installed') throw new Error('List unavailable: test-key');
                return '';
            }),
        (error) => {
            assert.match(error.message, /could not verify.*list unavailable/i);
            assert.doesNotMatch(error.message, /test-key/);
            return true;
        }
    );
    await assert.rejects(
        () => installPlan(plan, 'ci-fresh', '', async (args) => (args[1] === 'installed' ? 'not-json' : '')),
        /could not parse.*installed package/i
    );
    await assert.rejects(
        () =>
            installPlan(plan, 'ci-fresh', '', async (args) =>
                args[1] === 'installed'
                    ? JSON.stringify({ status: 1, result: [{ SubscriberPackageVersionId: 'base-version' }] })
                    : ''
            ),
        /failed installed package list response/i
    );
});

test(
    'install command verifies the plan and fails closed on package-list errors',
    { skip: process.platform === 'win32' ? 'The simulated Salesforce CLI uses a Unix executable.' : false },
    (context) => {
        const directory = fs.mkdtempSync(path.join(os.tmpdir(), 'ci-scratch-install-'));
        context.after(() => fs.rmSync(directory, { recursive: true, force: true }));
        const projectFile = path.join(directory, 'project.json');
        const planFile = path.join(directory, 'plan.json');
        const cliFile = path.join(directory, 'sf');
        fs.writeFileSync(
            projectFile,
            JSON.stringify({
                packageDirectories: [{ dependencies: [{ package: 'base' }, { package: 'parent' }] }],
                packageKeyConfig: { base: false, parent: false }
            })
        );
        fs.writeFileSync(
            planFile,
            JSON.stringify({
                base: { SubscriberPackageVersionId: 'base-version' },
                parent: { SubscriberPackageVersionId: 'parent-version' }
            })
        );
        fs.writeFileSync(
            cliFile,
            `#!/usr/bin/env node
const args = process.argv.slice(2);
if (args[0] === 'package' && args[1] === 'install') {
    console.log('Package installation requested');
} else if (args[0] === 'package' && args[1] === 'installed' && args[2] === 'list') {
    if (process.env.TEST_SCENARIO === 'unavailable') {
        console.error('List unavailable: test-key');
        process.exitCode = 1;
    } else {
        const versions = process.env.TEST_SCENARIO === 'missing'
            ? ['base-version']
            : ['base-version', 'parent-version'];
        console.log(JSON.stringify({ result: versions.map((id) => ({ SubscriberPackageVersionId: id })) }));
    }
} else {
    process.exitCode = 1;
}
`,
            { mode: 0o755 }
        );
        const runInstall = (scenario) =>
            spawnSync(
                process.execPath,
                [path.resolve(__dirname, '../ci-scratch-plan.cjs'), 'install', projectFile, planFile, 'ci-fresh'],
                {
                    encoding: 'utf8',
                    env: {
                        ...process.env,
                        PATH: directory + path.delimiter + process.env.PATH,
                        TEST_SCENARIO: scenario,
                        CRM_PACKAGE_KEY: 'test-key'
                    }
                }
            );
        const success = runInstall('matching');
        assert.equal(success.status, 0, success.stderr);
        assert.match(success.stdout, /installed package versions match/i);

        const failure = runInstall('missing');
        assert.notEqual(failure.status, 0);
        assert.match(failure.stderr, /missing.*parent.*parent-version/i);
        assert.doesNotMatch(failure.stdout, /installed package versions match/i);

        const unavailable = runInstall('unavailable');
        assert.notEqual(unavailable.status, 0);
        assert.match(unavailable.stderr, /list unavailable: \[REDACTED\]/i);
        assert.match(unavailable.stderr, /could not verify installed package versions/i);
        assert.doesNotMatch(unavailable.stdout + unavailable.stderr, /test-key/);
    }
);
