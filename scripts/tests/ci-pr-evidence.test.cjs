const assert = require('node:assert/strict');
const { spawnSync } = require('node:child_process');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { test } = require('node:test');
const {
    compareEvidence,
    extractApexTests,
    extractCheckoutSha,
    extractDeployTests,
    extractPackageVersions,
    summarizeApexFailure
} = require('../ci-pr-evidence.cjs');

const mergeSha = 'a'.repeat(40);
const otherSha = 'b'.repeat(40);

test('records actual deployment test methods without exposing other Salesforce response fields', () => {
    const data = {
        result: {
            details: {
                runTestResult: {
                    numTestsRun: '2',
                    numFailures: '0',
                    successes: [
                        { name: 'OtherTest', methodName: 'second' },
                        { namespace: null, name: 'ExampleTest', methodName: 'first' }
                    ]
                }
            },
            username: 'do-not-copy'
        }
    };
    assert.deepEqual(extractDeployTests(data), {
        methods: ['ExampleTest.first', 'OtherTest.second'],
        reportedTestsRun: 2
    });
    assert.deepEqual(
        extractDeployTests({
            result: {
                details: {
                    runTestResult: {
                        numTestsRun: '1',
                        numFailures: '0',
                        successes: { name: 'OnlyTest', methodName: 'works' }
                    }
                }
            }
        }),
        { methods: ['OnlyTest.works'], reportedTestsRun: 1 }
    );
    assert.throws(
        () => extractDeployTests({ result: { details: { runTestResult: { numTestsRun: '2', numFailures: '0' } } } }),
        /test.*results/i
    );
});

test('compares recorded Apex methods instead of trusting Salesforce summary counts', () => {
    const data = {
        summary: { testsRan: 3, outcome: 'Passed', username: 'do-not-copy' },
        tests: [
            { FullName: 'OtherTest.second', Outcome: 'Pass', Message: 'do-not-copy' },
            { FullName: 'ExampleTest.first', Outcome: 'Pass' }
        ]
    };
    assert.deepEqual(extractApexTests(data), {
        methods: ['ExampleTest.first', 'OtherTest.second'],
        reportedTestsRun: 3,
        outcome: 'Passed',
        skipped: []
    });
    assert.throws(
        () => extractApexTests({ summary: {}, tests: [{ FullName: 'bad\n::notice::', Outcome: 'Pass' }] }),
        /test/i
    );
});

test('reports failing test names and CLI error type without logging raw messages or identities', () => {
    const response = {
        name: 'ApexTestFailure',
        message: 'do-not-copy',
        result: {
            tests: [
                { FullName: 'ExampleTest.fails', Outcome: 'Fail', Message: 'do-not-copy' },
                { FullName: 'ExampleTest.works', Outcome: 'Pass' }
            ]
        }
    };
    assert.deepEqual(summarizeApexFailure(response), {
        errorType: 'ApexTestFailure',
        failingMethods: ['ExampleTest.fails']
    });
});

test('reads the actual checkout commit and selected package versions from baseline CI logs', () => {
    const log = [
        'job\tstep\t2026-01-01T00:00:00Z [command]/usr/bin/git log -1 --format=%H',
        `job\tstep\t2026-01-01T00:00:01Z ${mergeSha}`,
        'job\tstep\t2026-01-01T00:00:02Z   echo "Processing: $alias"',
        'job\tstep\t2026-01-01T00:00:03Z Processing: base',
        'job\tstep\t2026-01-01T00:00:04Z SubscriberPackageVersionId (selected): versionA',
        'job\tstep\t2026-01-01T00:00:05Z Processing: another',
        'job\tstep\t2026-01-01T00:00:06Z SubscriberPackageVersionId (selected): versionB'
    ].join('\n');
    assert.equal(extractCheckoutSha(log), mergeSha);
    assert.deepEqual(extractPackageVersions(log), [
        { name: 'another', versionId: 'versionB' },
        { name: 'base', versionId: 'versionA' }
    ]);
    assert.throws(() => extractCheckoutSha(log.replace(mergeSha, 'not-a-commit')), /checkout.*commit/i);
    assert.throws(
        () => extractPackageVersions(log.replace('SubscriberPackageVersionId (selected): versionA', 'skipped')),
        /package/i
    );
});

test('marks different commits or selected package versions as not comparable', () => {
    const baseline = {
        checkoutShas: [mergeSha, mergeSha, mergeSha],
        packages: [{ name: 'base', versionId: 'versionA' }],
        tests: { methods: ['ExampleTest.first'], reportedTestsRun: 1, outcome: 'Passed', skipped: [] },
        coverage: { covered: 85, total: 100, percentage: 85 },
        coverageComponents: ['Example']
    };
    const pilot = {
        source: { mergeSha },
        packages: [{ name: 'base', versionId: 'versionA' }],
        tests: { methods: ['ExampleTest.first'], reportedTestsRun: 1 },
        coverage: { covered: 86, total: 100, percentage: 86 },
        coverageComponents: ['Example']
    };
    assert.deepEqual(compareEvidence(baseline, pilot), {
        comparable: true,
        reasons: [],
        baselineOnly: [],
        pilotOnly: [],
        sameMethods: true,
        baselineCoverageOnly: [],
        pilotCoverageOnly: [],
        sameCoverageComponents: true,
        baselineCoverage: baseline.coverage,
        pilotCoverage: pilot.coverage
    });
    const changedCommit = compareEvidence({ ...baseline, checkoutShas: [mergeSha, otherSha, mergeSha] }, pilot);
    assert.equal(changedCommit.comparable, false);
    assert.match(changedCommit.reasons.join(' '), /commit/i);
    const changedPackages = compareEvidence(
        { ...baseline, packages: [{ name: 'base', versionId: 'versionB' }] },
        pilot
    );
    assert.equal(changedPackages.comparable, false);
    assert.match(changedPackages.reasons.join(' '), /package/i);
});

test('reports individual method differences even when test counts are equal', () => {
    const baseline = {
        checkoutShas: [mergeSha],
        packages: [{ name: 'base', versionId: 'versionA' }],
        tests: { methods: ['ExampleTest.old'], reportedTestsRun: 1, outcome: 'Passed', skipped: [] },
        coverage: { covered: 85, total: 100, percentage: 85 },
        coverageComponents: ['Example']
    };
    const pilot = {
        source: { mergeSha },
        packages: baseline.packages,
        tests: { methods: ['ExampleTest.new'], reportedTestsRun: 1 },
        coverage: baseline.coverage,
        coverageComponents: baseline.coverageComponents
    };
    const result = compareEvidence(baseline, pilot);
    assert.equal(result.comparable, true);
    assert.equal(result.sameMethods, false);
    assert.deepEqual(result.baselineOnly, ['ExampleTest.old']);
    assert.deepEqual(result.pilotOnly, ['ExampleTest.new']);
});

test('reports different covered components even when totals and test methods match', () => {
    const baseline = {
        checkoutShas: [mergeSha],
        packages: [{ name: 'base', versionId: 'versionA' }],
        tests: { methods: ['ExampleTest.works'], outcome: 'Passed' },
        coverage: { covered: 85, total: 100, percentage: 85 },
        coverageComponents: ['Example', 'Shared', 'Shared']
    };
    const pilot = {
        source: { mergeSha },
        packages: baseline.packages,
        tests: { methods: ['ExampleTest.works'] },
        coverage: baseline.coverage,
        coverageComponents: ['Example', 'Other', 'Shared']
    };
    const result = compareEvidence(baseline, pilot);
    assert.equal(result.comparable, true);
    assert.equal(result.sameMethods, true);
    assert.equal(result.sameCoverageComponents, false);
    assert.deepEqual(result.baselineCoverageOnly, ['Shared']);
    assert.deepEqual(result.pilotCoverageOnly, ['Other']);
});

test('writes a minimal evidence artifact from the actual deployment result', (context) => {
    const directory = fs.mkdtempSync(path.join(os.tmpdir(), 'ci-pr-evidence-'));
    context.after(() => fs.rmSync(directory, { recursive: true, force: true }));
    const source = path.join(directory, 'source');
    fs.mkdirSync(source);
    fs.writeFileSync(path.join(source, 'Example.cls'), 'public class Example {}');
    const project = path.join(directory, 'project.json');
    const plan = path.join(directory, 'plan.json');
    const result = path.join(directory, 'result.json');
    const output = path.join(directory, 'evidence.json');
    fs.writeFileSync(project, JSON.stringify({ packageDirectories: [{ dependencies: [{ package: 'base' }] }] }));
    fs.writeFileSync(plan, JSON.stringify({ base: { SubscriberPackageVersionId: 'versionA' } }));
    fs.writeFileSync(
        result,
        JSON.stringify({
            result: {
                username: 'do-not-copy',
                details: {
                    runTestResult: {
                        numTestsRun: '1',
                        numFailures: '0',
                        successes: [{ name: 'ExampleTest', methodName: 'works' }],
                        codeCoverage: [{ name: 'Example', numLocations: 100, numLocationsNotCovered: 15 }]
                    }
                }
            }
        })
    );
    const options = {
        encoding: 'utf8',
        env: {
            ...process.env,
            CI_VALIDATION_ROUTE: 'reuse',
            GITHUB_EVENT_NAME: 'workflow_run',
            GITHUB_REPOSITORY: 'example/repository',
            PR_NUMBER: '42',
            PR_HEAD_SHA: 'b'.repeat(40),
            PR_BASE_SHA: 'c'.repeat(40),
            PR_MERGE_SHA: mergeSha,
            BASELINE_RUN_ID: '123',
            BASELINE_ATTEMPT: '1'
        }
    };
    const script = path.resolve(__dirname, '../ci-pr-evidence.cjs');
    const execution = spawnSync(
        process.execPath,
        [script, 'create', project, plan, source, result, result, output],
        options
    );
    assert.equal(execution.status, 0, execution.stderr);
    const raw = fs.readFileSync(output, 'utf8');
    const evidence = JSON.parse(raw);
    assert.deepEqual(evidence.tests.methods, ['ExampleTest.works']);
    assert.deepEqual(evidence.coverage, { covered: 85, total: 100, percentage: 85 });
    assert.deepEqual(evidence.coverageComponents, ['Example']);
    assert.deepEqual(evidence.packages, [{ name: 'base', versionId: 'versionA' }]);
    assert.deepEqual(evidence.baseline, { runId: 123, attempt: 1 });
    assert.doesNotMatch(raw, /do-not-copy/);

    const requiredOptions = {
        ...options,
        env: { ...options.env, GITHUB_EVENT_NAME: 'pull_request', BASELINE_RUN_ID: '', BASELINE_ATTEMPT: '' }
    };
    const requiredOutput = path.join(directory, 'required-evidence.json');
    const required = spawnSync(
        process.execPath,
        [script, 'create', project, plan, source, result, result, requiredOutput],
        requiredOptions
    );
    assert.equal(required.status, 0, required.stderr);
    const requiredEvidence = JSON.parse(fs.readFileSync(requiredOutput, 'utf8'));
    assert.equal(Object.hasOwn(requiredEvidence, 'baseline'), false);
    assert.deepEqual(requiredEvidence.tests.methods, ['ExampleTest.works']);
    assert.deepEqual(requiredEvidence.coverage, { covered: 85, total: 100, percentage: 85 });

    for (const invalidEnv of [
        { GITHUB_EVENT_NAME: 'workflow_run', BASELINE_RUN_ID: '', BASELINE_ATTEMPT: '' },
        { GITHUB_EVENT_NAME: 'pull_request', BASELINE_RUN_ID: '123', BASELINE_ATTEMPT: '' },
        { GITHUB_EVENT_NAME: 'push', BASELINE_RUN_ID: '', BASELINE_ATTEMPT: '' }
    ]) {
        const invalid = spawnSync(
            process.execPath,
            [script, 'create', project, plan, source, result, result, path.join(directory, 'invalid.json')],
            { ...options, env: { ...options.env, ...invalidEnv } }
        );
        assert.notEqual(invalid.status, 0);
    }

    fs.writeFileSync(path.join(source, 'not a valid class.cls'), '');
    const unsafe = spawnSync(
        process.execPath,
        [script, 'create', project, plan, source, result, result, path.join(directory, 'unsafe.json')],
        options
    );
    assert.notEqual(unsafe.status, 0);
    assert.match(unsafe.stderr, /invalid.*coverage.*name/i);
});

test(
    'compares the two recorded CI runs using only their intended artifacts and logs',
    { skip: process.platform === 'win32' ? 'The comparison uses macOS/Linux archive tools.' : false },
    (context) => {
        const directory = fs.mkdtempSync(path.join(os.tmpdir(), 'ci-pr-compare-'));
        context.after(() => fs.rmSync(directory, { recursive: true, force: true }));
        const files = path.join(directory, 'files');
        const bin = path.join(directory, 'bin');
        fs.mkdirSync(files);
        fs.mkdirSync(bin);
        const evidence = {
            schemaVersion: 1,
            repository: 'example/repository',
            pullRequest: 42,
            baseline: { runId: 123, attempt: 1 },
            source: { headSha: 'b'.repeat(40), baseSha: 'c'.repeat(40), mergeSha },
            route: 'reuse',
            packages: [{ name: 'base', versionId: 'versionA' }],
            tests: { methods: ['ExampleTest.works'], reportedTestsRun: 1 },
            coverage: { covered: 85, total: 100, percentage: 85 },
            coverageNames: ['Example'],
            coverageComponents: ['Example']
        };
        fs.writeFileSync(path.join(files, 'evidence.json'), JSON.stringify(evidence));
        fs.writeFileSync(
            path.join(files, 'test-result-testRun.json'),
            JSON.stringify({
                summary: { testsRan: 1, outcome: 'Passed', username: 'do-not-copy' },
                tests: [{ FullName: 'ExampleTest.works', Outcome: 'Pass' }]
            })
        );
        fs.writeFileSync(
            path.join(files, 'test-result-codecoverage.json'),
            JSON.stringify([{ name: 'Example', totalCovered: 85, totalLines: 100 }])
        );
        const baselineZip = path.join(directory, 'baseline.zip');
        const pilotZip = path.join(directory, 'pilot.zip');
        for (const [archive, names] of [
            [baselineZip, ['test-result-testRun.json', 'test-result-codecoverage.json']],
            [pilotZip, ['evidence.json']]
        ]) {
            const result = spawnSync('zip', ['-q', '-j', archive, ...names.map((name) => path.join(files, name))], {
                encoding: 'utf8'
            });
            assert.equal(result.status, 0, result.stderr);
        }
        const fakeGh = path.join(directory, 'fake-gh.cjs');
        fs.writeFileSync(
            fakeGh,
            `
            const fs = require('node:fs');
            const args = process.argv.slice(2);
            const endpoint = args[1];
            const checkout = ${JSON.stringify(`job\tstep\t2026-01-01T00:00:00Z [command]/usr/bin/git log -1 --format=%H\njob\tstep\t2026-01-01T00:00:01Z ${mergeSha}`)};
            const packages = '\\njob\\tstep\\t2026-01-01T00:00:02Z Processing: base\\njob\\tstep\\t2026-01-01T00:00:03Z SubscriberPackageVersionId (selected): versionA';
            const json = (value) => console.log(JSON.stringify(value));
            if (args[0] === 'repo') console.log('example/repository');
            else if (args[0] === 'run') console.log(checkout + (args.includes('11') ? packages : ''));
            else if (endpoint.endsWith('/actions/runs/456')) json({ status: 'completed', conclusion: 'success', run_attempt: 1 });
            else if (endpoint.endsWith('/actions/runs/123/attempts/1')) json({ name: '[PR] Validate', path: process.env.TEST_WRONG_WORKFLOW ? '.github/workflows/other.yml' : '.github/workflows/pull_request-validation1.yml', event: 'pull_request', head_sha: ${JSON.stringify('b'.repeat(40))}, status: 'completed', conclusion: 'success' });
            else if (endpoint.includes('/attempts/1/jobs?')) json([{ jobs: [
                { id: 11, name: 'Validate PR / Salesforce validation / Setup', conclusion: 'success' },
                { id: 12, name: 'Validate PR / Salesforce validation / Compile Metadata', conclusion: 'success' },
                { id: 13, name: 'Validate PR / Salesforce validation / Run Apex Tests', conclusion: 'success', steps: [
                    { name: 'Upload Apex test results', conclusion: 'success', started_at: '2026-01-01T00:00:00Z', completed_at: '2026-01-01T00:00:10Z' }
                ] }
            ] }]);
            else if (endpoint.includes('/actions/runs/456/artifacts?')) json([{ artifacts: [{ id: 21, name: 'reusable-pr-pilot-evidence-1', expired: false }] }]);
            else if (endpoint.includes('/actions/runs/123/artifacts?')) json([{ artifacts: [{ id: 22, name: 'apex-tests', expired: false, created_at: process.env.TEST_WRONG_ATTEMPT ? '2026-01-02T00:00:00Z' : '2026-01-01T00:00:05Z' }] }]);
            else if (endpoint.endsWith('/actions/artifacts/21/zip')) process.stdout.write(fs.readFileSync(${JSON.stringify(pilotZip)}));
            else if (endpoint.endsWith('/actions/artifacts/22/zip')) process.stdout.write(fs.readFileSync(${JSON.stringify(baselineZip)}));
            else process.exit(2);
        `
        );
        const quote = (value) => `'${value.replaceAll("'", "'\\''")}'`;
        fs.writeFileSync(path.join(bin, 'gh'), `#!/bin/sh\nexec ${quote(process.execPath)} ${quote(fakeGh)} "$@"\n`, {
            mode: 0o755
        });
        const execution = spawnSync(
            process.execPath,
            [path.resolve(__dirname, '../ci-pr-evidence.cjs'), 'compare', '123', '456'],
            {
                encoding: 'utf8',
                env: { ...process.env, PATH: bin + path.delimiter + process.env.PATH }
            }
        );
        assert.equal(execution.status, 0, execution.stderr);
        assert.doesNotMatch(execution.stdout, /do-not-copy/);
        const result = JSON.parse(execution.stdout);
        assert.equal(result.comparable, true);
        assert.equal(result.sameMethods, true);
        assert.equal(result.sameCoverageComponents, true);
        assert.deepEqual(result.baselineTests, { recordedMethods: 1, reportedTestsRun: 1, skipped: 0 });
        assert.deepEqual(result.pilotTests, { recordedMethods: 1, reportedTestsRun: 1, skipped: null });
        assert.deepEqual(result.baselineCoverage, { covered: 85, total: 100, percentage: 85 });

        const wrongAttempt = spawnSync(
            process.execPath,
            [path.resolve(__dirname, '../ci-pr-evidence.cjs'), 'compare', '123', '456'],
            {
                encoding: 'utf8',
                env: { ...process.env, PATH: bin + path.delimiter + process.env.PATH, TEST_WRONG_ATTEMPT: 'true' }
            }
        );
        assert.notEqual(wrongAttempt.status, 0);
        assert.match(wrongAttempt.stderr, /artifact.*attempt/i);

        const wrongWorkflow = spawnSync(
            process.execPath,
            [path.resolve(__dirname, '../ci-pr-evidence.cjs'), 'compare', '123', '456'],
            {
                encoding: 'utf8',
                env: { ...process.env, PATH: bin + path.delimiter + process.env.PATH, TEST_WRONG_WORKFLOW: 'true' }
            }
        );
        assert.notEqual(wrongWorkflow.status, 0);
        assert.match(wrongWorkflow.stderr, /baseline workflow.*match/i);
    }
);
