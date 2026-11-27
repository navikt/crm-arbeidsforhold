const assert = require('node:assert/strict');
const { spawnSync } = require('node:child_process');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { test } = require('node:test');
const { extractApexTests, extractDeployTests, summarizeApexFailure } = require('../ci-pr-evidence.cjs');

const mergeSha = 'a'.repeat(40);

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
            GITHUB_EVENT_NAME: 'pull_request',
            GITHUB_REPOSITORY: 'example/repository',
            PR_NUMBER: '42',
            PR_HEAD_SHA: 'b'.repeat(40),
            PR_BASE_SHA: 'c'.repeat(40),
            PR_MERGE_SHA: mergeSha
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
    assert.deepEqual(evidence.coverage, { covered: 85, total: 100, percentage: 85, missing: [] });
    assert.deepEqual(evidence.coverageComponents, ['Example']);
    assert.deepEqual(evidence.packages, [{ name: 'base', versionId: 'versionA' }]);
    assert.equal(Object.hasOwn(evidence, 'baseline'), false);
    assert.doesNotMatch(raw, /do-not-copy/);

    fs.writeFileSync(
        path.join(source, 'NewService.cls'),
        'public class NewService {\n' + '    x = 1;\n'.repeat(20) + '}'
    );
    const changed = path.join(directory, 'changed.txt');
    fs.writeFileSync(changed, 'source/NewService.cls\n');
    const adjustedOutput = path.join(directory, 'adjusted.json');
    const adjusted = spawnSync(
        process.execPath,
        [script, 'create', project, plan, source, result, result, adjustedOutput, changed],
        { ...options, cwd: directory }
    );
    assert.equal(adjusted.status, 0, adjusted.stderr);
    assert.deepEqual(JSON.parse(fs.readFileSync(adjustedOutput, 'utf8')).coverage, {
        covered: 85,
        total: 120,
        percentage: (85 / 120) * 100,
        missing: [{ name: 'NewService', path: 'source/NewService.cls', lines: 20 }]
    });
    fs.unlinkSync(path.join(source, 'NewService.cls'));

    const invalid = spawnSync(
        process.execPath,
        [script, 'create', project, plan, source, result, result, path.join(directory, 'invalid.json')],
        { ...options, env: { ...options.env, GITHUB_EVENT_NAME: 'workflow_run' } }
    );
    assert.notEqual(invalid.status, 0);

    fs.writeFileSync(path.join(source, 'not a valid class.cls'), '');
    const unsafe = spawnSync(
        process.execPath,
        [script, 'create', project, plan, source, result, result, path.join(directory, 'unsafe.json')],
        options
    );
    assert.notEqual(unsafe.status, 0);
    assert.match(unsafe.stderr, /invalid.*coverage.*name/i);
});
