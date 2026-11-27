const assert = require('node:assert/strict');
const { spawnSync } = require('node:child_process');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { test } = require('node:test');
const { scratchFingerprint } = require('../ci-scratch-plan.cjs');

const directory = path.resolve(__dirname, '../../.github/workflows');
const readWorkflow = (name) => fs.readFileSync(path.join(directory, name), 'utf8').replace(/\r\n/g, '\n');

test('package creation runs on main for metadata and package configuration changes', () => {
    const source = readWorkflow('push_create-package1.yml');
    assert.match(source, /workflow_dispatch:/);
    assert.match(source, /branches:\s*\n\s*- main\b/);
    assert.doesNotMatch(source, /- master\b/);
    for (const file of ['force-app/**', 'sfdx-project.json', '.forceignore']) {
        assert.ok(source.includes(`'${file}'`) || source.includes(`"${file}"`), `Missing package trigger: ${file}`);
    }
});

test('direct dev deployment is manual and reuses the tested dependency installer', () => {
    const source = readWorkflow('push_deploy-to-dev1.yml');
    assert.match(source, /workflow_dispatch:/);
    assert.doesNotMatch(source, /^\s+push:/m);
    assert.match(
        source,
        /bash bin\/create-scratch-org\.sh --no-config --alias dev --update-packages --skip-version-check/
    );
    assert.match(source, /PACKAGE_INSTALL_KEY: \$\{\{ secrets\.CRM_PACKAGE_KEY \}\}/);
    assert.match(
        source,
        /sf project deploy start --source-dir force-app --target-org dev --test-level RunLocalTests --wait 60/
    );
    assert.doesNotMatch(source, /\bsfdx\b|sfpowerkit|install-keys|GITHUB_OUTPUT/);
    assert.match(source, /persist-credentials: false/);
    assert.match(source, /node-version: '22'/);
});

for (const lineEnding of ['\n', '\r\n']) {
    test(`credential-bearing dev deployment only runs for main with ${JSON.stringify(lineEnding)} line endings`, () => {
        const source = readWorkflow('push_deploy-to-dev1.yml').replace(/\r?\n/g, lineEnding);
        assert.match(source, /deploy-metadata:\r?\n\s+if: github\.ref == 'refs\/heads\/main'\r?\n/);
    });
}

for (const name of ['pull_request-validation1.yml', 'pull_request-lwc-validation.yml']) {
    test(`${name} validates PRs targeting nested branch names too`, () => {
        assert.match(readWorkflow(name), /branches:\s*\n\s*- '\*\*'/);
    });
}

test('PR validation serializes each PR without cancelling an active run and grants only read permissions', () => {
    const source = readWorkflow('pull_request-validation1.yml');
    assert.match(source, /^permissions:\n {4}contents: read\n {4}pull-requests: read\n {4}actions: read$/m);
    assert.match(
        source,
        /^concurrency:\n {4}group: pr-validation-\$\{\{ github\.event\.pull_request\.number \}\}\n {4}cancel-in-progress: false$/m
    );
    assert.match(source, /uses: \.\/\.github\/workflows\/salesforce-validation\.yml/);
    assert.match(source, /CRM_PROD_SFDX_URL: \$\{\{ secrets\.CRM_PROD_SFDX_URL \}\}/);
    assert.match(source, /CRM_PACKAGE_KEY: \$\{\{ secrets\.CRM_PACKAGE_KEY \}\}/);
    assert.doesNotMatch(source, /secrets: inherit/);
});

test('Salesforce validation calls the local workflow only for same-repository Salesforce PRs to main', () => {
    const source = readWorkflow('salesforce-validation.yml');
    assert.match(source, /^permissions:\n {4}contents: read\n {4}pull-requests: read\n {4}actions: read$/m);
    assert.match(source, /workflow_call:\n {8}secrets:\n {12}CRM_PROD_SFDX_URL:\n {16}required: true/);
    assert.match(source, /CRM_PACKAGE_KEY:\n {16}required: false/);
    assert.match(source, /name: Compile Metadata/);
    assert.match(source, /name: Run Apex Tests/);
    assert.match(source, /name: Validate 85% Code Coverage/);
    assert.doesNotMatch(source, /crm-workflows-base|secrets: inherit/);

    const validation = jobSection(source, 'salesforce');
    assert.match(validation, /needs\.changes\.outputs\.salesforce == 'true'/);
    assert.match(validation, /github\.event\.pull_request\.base\.ref == 'main'/);
    assert.match(validation, /github\.event\.pull_request\.head\.repo\.full_name == github\.repository/);
    assert.match(validation, /uses: \.\/\.github\/workflows\/ci-reusable-scratch-org\.yml/);
    assert.match(validation, /pull_number: \$\{\{ github\.event\.pull_request\.number \}\}/);
    assert.match(validation, /head_sha: \$\{\{ github\.event\.pull_request\.head\.sha \}\}/);
    assert.match(validation, /base_sha: \$\{\{ github\.event\.pull_request\.base\.sha \}\}/);
    assert.match(validation, /merge_sha: \$\{\{ github\.event\.pull_request\.merge_commit_sha \}\}/);
    assert.match(validation, /CRM_PROD_SFDX_URL: \$\{\{ secrets\.CRM_PROD_SFDX_URL \}\}/);
    assert.match(validation, /CRM_PACKAGE_KEY: \$\{\{ secrets\.CRM_PACKAGE_KEY \}\}/);
    assert.doesNotMatch(validation, /CI_SCRATCH_ORG_AUTH_URL|secrets: inherit/);

    const compile = stepScript(
        jobSection(source, 'compile'),
        'Require successful or unnecessary Salesforce validation'
    );
    assert.match(compile, /BASE_REF/);
    assert.match(compile, /HEAD_REPOSITORY/);
    assert.match(compile, /BASE_REF.*main/);
    assert.match(compile, /HEAD_REPOSITORY.*REPOSITORY/);
    const runGate = (values) =>
        spawnSync('/bin/bash', ['-c', compile], {
            encoding: 'utf8',
            env: {
                ...process.env,
                CHANGES_RESULT: 'success',
                RELEVANT: 'true',
                VALIDATION_RESULT: 'success',
                BASE_REF: 'main',
                HEAD_REPOSITORY: 'example/repository',
                REPOSITORY: 'example/repository',
                ...values
            }
        });
    if (process.platform !== 'win32') {
        assert.equal(runGate({ RELEVANT: 'false', VALIDATION_RESULT: 'skipped' }).status, 0);
        assert.notEqual(runGate({ BASE_REF: 'release', VALIDATION_RESULT: 'skipped' }).status, 0);
        assert.notEqual(runGate({ HEAD_REPOSITORY: 'contributor/repository', VALIDATION_RESULT: 'skipped' }).status, 0);
    }
    assert.notEqual(runGate({ VALIDATION_RESULT: 'skipped' }).status, 0);
});

test('offline CI covers the workflow contracts and Node tooling on PRs and main', () => {
    const source = readWorkflow('scratch-org-offline.yml');
    for (const pattern of ['scripts/*.cjs', 'scripts/tests/**', '.github/workflows/**']) {
        assert.equal(source.split(`'${pattern}'`).length - 1, 2, pattern);
    }
});

const reusableWorkflow = () => readWorkflow('ci-reusable-scratch-org.yml');
const jobSection = (workflow, job) => {
    const start = workflow.indexOf(`\n    ${job}:\n`);
    assert.ok(start >= 0, `Missing job ${job}`);
    const next = workflow.slice(start + 1).search(/\n {4}[a-z-]+:\n/);
    return next < 0 ? workflow.slice(start) : workflow.slice(start, start + 1 + next + 1);
};
const stepScript = (section, name) => {
    const start = section.indexOf(`- name: ${name}`);
    assert.ok(start >= 0, `Missing step ${name}`);
    const rest = section.slice(start + 1);
    const end = rest.search(/\n {12}- (name|uses):/);
    const step = end < 0 ? rest : rest.slice(0, end + 1);
    const script = step.match(/\n {14}run: \|\n((?: {18}.*\n)+)/)?.[1].replace(/^ {18}/gm, '');
    assert.ok(script, `Missing script for ${name}`);
    return script;
};

test('the PR pilot is removed and required CI does not call it', () => {
    assert.equal(fs.existsSync(path.join(directory, 'ci-reusable-pr-pilot.yml')), false);
    assert.equal(fs.existsSync(path.resolve(__dirname, '../ci-pr-pilot.cjs')), false);
    for (const name of fs.readdirSync(directory).filter((name) => name.endsWith('.yml'))) {
        assert.doesNotMatch(readWorkflow(name), /ci-reusable-pr-pilot|ci-pr-pilot\.cjs|baseline_run_id/, name);
    }
});

test('only the reusable org job is locked and protected; the new-org job runs without the lock', () => {
    const source = reusableWorkflow();
    const prepare = jobSection(source, 'prepare');
    const reuse = jobSection(source, 'reuse');
    const fresh = jobSection(source, 'fresh');
    assert.doesNotMatch(source.slice(0, source.indexOf('\njobs:')), /concurrency:/);
    assert.match(source, /^permissions:\n {4}contents: read\n {4}pull-requests: read\n {4}actions: read$/m);
    assert.doesNotMatch(source, /pull-requests: write|contents: write|actions: write|secrets: inherit/);
    assert.doesNotMatch(source, /pull_request:|pull_request_target:|repo_only/);
    assert.doesNotMatch(prepare, /environment:|concurrency:|secrets\./);
    assert.match(reuse, /needs: prepare\n {8}if: needs\.prepare\.outputs\.route == 'reuse'/);
    assert.match(reuse, /\n {8}environment: ci-scratch-org\n/);
    assert.match(
        reuse,
        /\n {8}concurrency:\n {12}group: crm-arbeidsforhold-reusable-scratch-org\n {12}cancel-in-progress: false\n {12}queue: max\n/
    );
    assert.match(reuse, /fallback: \$\{\{ steps\.route\.outputs\.fallback \}\}/);
    assert.doesNotMatch(fresh, /environment:|concurrency:|CI_SCRATCH_ORG_AUTH_URL/);
    assert.match(fresh, /needs: \[prepare, reuse\]/);
    assert.match(fresh, /if: >-\n\s+!cancelled\(\) &&\n\s+needs\.prepare\.result == 'success' &&/);
    for (const job of ['reuse', 'fresh']) {
        assert.match(
            stepScript(
                jobSection(source, job),
                job === 'reuse' ? 'List changed Apex sources' : 'Enforce repository Apex coverage in fresh org'
            ),
            /--diff-filter=AMR /
        );
        assert.match(
            stepScript(jobSection(source, job), 'Save minimal PR test and package evidence'),
            /evidence\.json" \$\{changed\[@\]\+"\$\{changed\[@\]\}"\}/
        );
    }
    assert.match(fresh, /needs\.prepare\.outputs\.route == 'fresh' \|\|/);
    assert.match(fresh, /needs\.reuse\.result == 'success' && needs\.reuse\.outputs\.fallback == 'true'/);
    assert.match(
        fresh,
        /- name: Delete one-time scratch org\n {14}if: always\(\) && steps\.create-fresh\.outputs\.created == 'true'/
    );
});

test('PR checks run from trusted base scripts before any Salesforce credential is used', () => {
    const source = reusableWorkflow();
    const prepare = jobSection(source, 'prepare');
    const caller = readWorkflow('pull_request-validation1.yml');
    const verify = jobSection(caller, 'verify-pr');
    const validationCall = jobSection(caller, 'run-pr-validation');
    assert.match(verify, /github\.event\.pull_request\.draft == false/);
    assert.match(verify, /github\.event\.pull_request\.base\.ref == 'main'/);
    assert.match(verify, /github\.event\.pull_request\.head\.repo\.full_name == github\.repository/);
    assert.match(verify, /ref: \$\{\{ github\.event\.pull_request\.base\.sha \}\}/);
    assert.match(verify, /MERGE_SHA: \$\{\{ github\.sha \}\}/);
    assert.match(verify, /ci-pr-guard\.cjs" verify-required/);
    assert.match(validationCall, /needs: verify-pr/);
    assert.match(validationCall, /needs\.verify-pr\.result == 'success'/);
    assert.match(validationCall, /needs\.verify-pr\.result == 'skipped'/);

    const order = [
        '- name: Reject unsupported PR source',
        '- name: Checkout trusted workflow scripts',
        'ci-pr-guard.cjs" verify-current',
        'ci-pr-guard.cjs" queue'
    ].map((marker) => prepare.indexOf(marker));
    assert.ok(
        order.every((index, position) => index >= 0 && (position === 0 || index > order[position - 1])),
        order.join()
    );
    assert.doesNotMatch(prepare, /verify-required/);
    assert.match(prepare, /github\.event\.pull_request\.base\.ref != 'main'/);
    assert.match(prepare, /github\.event\.pull_request\.head\.repo\.full_name != github\.repository/);
    for (const job of ['prepare', 'reuse', 'fresh']) {
        assert.match(
            jobSection(source, job),
            /ref: \$\{\{ github\.event_name == 'pull_request' && github\.event\.pull_request\.base\.sha \|\| github\.sha \}\}[\s\S]*?path: trusted/,
            job
        );
    }
    for (const job of ['reuse', 'fresh']) {
        const section = jobSection(source, job);
        const current = section.indexOf('ci-pr-guard.cjs" verify-current');
        const candidate = section.indexOf('path: candidate');
        const snapshot = section.indexOf('ci-pr-guard.cjs" verify-snapshot');
        const devHub = section.indexOf('- name: Authenticate scratch-org Dev Hub');
        assert.ok(current >= 0 && current < candidate && candidate < snapshot && snapshot < devHub, job);
        assert.match(section, /ref: \$\{\{ inputs\.merge_sha \|\| github\.sha \}\}[\s\S]*?path: candidate/);
        assert.match(section, /\$TRUSTED_ROOT\/bin\/package-dependencies\.js" --include-unreleased --plan-file/);
    }
});

test(
    'the prepare job chooses a route from force_fresh and the CI org queue',
    { skip: process.platform === 'win32' ? 'The workflow runs on Ubuntu with Bash.' : false },
    (context) => {
        const directory = fs.mkdtempSync(path.join(os.tmpdir(), 'ci-prepare-route-'));
        context.after(() => fs.rmSync(directory, { recursive: true, force: true }));
        const trusted = path.join(directory, 'trusted', 'scripts');
        fs.mkdirSync(trusted, { recursive: true });
        fs.copyFileSync(path.resolve(__dirname, '../ci-pr-guard.cjs'), path.join(trusted, 'ci-pr-guard.cjs'));
        const mock = path.join(directory, 'mock-gh.cjs');
        fs.writeFileSync(
            mock,
            `const child = require('node:child_process');
const original = child.execFileSync;
child.execFileSync = (command, args, options) => {
    if (command !== 'gh') return original(command, args, options);
    if (args[1].includes('/jobs?')) return JSON.stringify([{ jobs: [{ name: 'Validate PR / Validate on reusable org', status: 'waiting' }] }]);
    const status = args[1].includes('status=queued') ? 'queued' : 'in_progress';
    return JSON.stringify([{ workflow_runs: JSON.parse(process.env.MOCK_RUNS).filter((run) => run.status === status) }]);
};`
        );
        const script = stepScript(
            jobSection(reusableWorkflow(), 'prepare'),
            'Choose reusable org or fresh scratch org'
        );
        const output = path.join(directory, 'output');
        const summary = path.join(directory, 'summary');
        const run = (overrides) => {
            fs.writeFileSync(output, '');
            fs.writeFileSync(summary, '');
            const result = spawnSync('/bin/bash', ['-c', script], {
                encoding: 'utf8',
                env: {
                    ...process.env,
                    GITHUB_WORKSPACE: directory,
                    GITHUB_REPOSITORY: 'example/repository',
                    GITHUB_RUN_ID: '99',
                    GITHUB_OUTPUT: output,
                    GITHUB_STEP_SUMMARY: summary,
                    NODE_OPTIONS: `--require=${mock}`,
                    EVENT_NAME: 'pull_request',
                    FORCE_FRESH: 'false',
                    PR_NUMBER: '42',
                    HEAD_REF: 'feature/42',
                    MOCK_RUNS: '[]',
                    ...overrides
                }
            });
            assert.equal(result.status, 0, result.stderr);
            return { result, output: fs.readFileSync(output, 'utf8'), summary: fs.readFileSync(summary, 'utf8') };
        };
        assert.match(run({}).output, /route=reuse\n/);
        const queued = run({
            MOCK_RUNS: JSON.stringify([
                { id: 1, status: 'queued', pull_requests: [{ number: 7 }] },
                { id: 2, status: 'in_progress', pull_requests: [{ number: 8 }] }
            ])
        });
        assert.match(
            queued.output,
            /route=fresh\nreason=2 other PRs are waiting for the CI scratch org\.\nwaiting=2\n/
        );
        assert.match(queued.summary, /🆕 New scratch org/);
        assert.match(run({ FORCE_FRESH: 'true' }).output, /route=fresh\nreason=Fresh-org validation was requested\./);
        const dispatch = run({ EVENT_NAME: 'workflow_dispatch', PR_NUMBER: '', HEAD_REF: '' });
        assert.match(dispatch.output, /route=reuse\n/);
        assert.match(dispatch.summary, /♻️ Reusable CI org/);
    }
);

test('PR-controlled Salesforce output cannot issue GitHub workflow commands', () => {
    const source = reusableWorkflow();
    for (const [job, name] of [
        ['reuse', 'Resolve and validate exact package versions'],
        ['reuse', 'Validate reusable org with tests and coverage'],
        ['fresh', 'Resolve and validate exact package versions for the new org'],
        ['fresh', 'Create one-time scratch org'],
        ['fresh', 'Install the exact validated package plan'],
        ['fresh', 'Deploy source to fresh org'],
        ['fresh', 'Delete one-time scratch org']
    ]) {
        const script = stepScript(jobSection(source, job), name);
        assert.ok(script.indexOf('::stop-commands::$command_token') >= 0, name);
        assert.ok(script.indexOf('::stop-commands::$command_token') < script.indexOf('::$command_token::'), name);
    }
});

test('both routes exclude the non-package sources before validation', () => {
    const source = reusableWorkflow();
    for (const [job, exclude, validate] of [
        ['reuse', 'Exclude non-package sources from validation', 'Validate reusable org with tests and coverage'],
        ['fresh', 'Exclude non-package sources from the new org', 'Deploy source to fresh org']
    ]) {
        const section = jobSection(source, job);
        const script = stepScript(section, exclude);
        for (const directory of ['unpackagable', 'unpackagable-with-auto-deploy', 'scratch-org']) {
            assert.ok(script.includes(`rm -rf ./force-app/${directory}\n`), `${job}: ${directory}`);
        }
        assert.ok(section.indexOf(`- name: ${exclude}`) < section.indexOf(`- name: ${validate}`), job);
    }
});

test(
    'both routes run exactly the repository test classes and enforce 85% coverage',
    { skip: process.platform === 'win32' ? 'The workflow runs on Ubuntu with Bash.' : false },
    async (context) => {
        const directory = fs.mkdtempSync(path.join(os.tmpdir(), 'ci-repo-tests-'));
        context.after(() => fs.rmSync(directory, { recursive: true, force: true }));
        const classes = path.join(directory, 'force-app', 'classes');
        fs.mkdirSync(classes, { recursive: true });
        fs.writeFileSync(path.join(classes, 'Service.cls'), 'public class Service {}');
        fs.writeFileSync(
            path.join(classes, 'ServiceTrigger.trigger'),
            'trigger ServiceTrigger on Account (after insert) {}'
        );
        fs.writeFileSync(path.join(classes, 'RepoAlphaTest.cls'), '@IsTest class RepoAlphaTest {}');
        fs.writeFileSync(path.join(classes, 'RepoBetaTest.cls'), '@IsTest class RepoBetaTest {}');
        const trace = path.join(directory, 'sf-args.txt');
        fs.writeFileSync(
            path.join(directory, 'sf'),
            '#!/bin/sh\nprintf "%s\\n" "$@" > "$TEST_TRACE"\nprintf "%s" "$TEST_RESPONSE"\n',
            {
                mode: 0o755
            }
        );
        const source = reusableWorkflow();
        const script = stepScript(jobSection(source, 'reuse'), 'Validate reusable org with tests and coverage');
        const freshScript = stepScript(jobSection(source, 'fresh'), 'Run repository Apex tests in fresh org');
        const freshBashAvailable = spawnSync('bash', ['-c', 'type mapfile >/dev/null 2>&1']).status === 0;
        const env = {
            ...process.env,
            PATH: directory + path.delimiter + process.env.PATH,
            RUNNER_TEMP: directory,
            TRUSTED_ROOT: path.resolve(__dirname, '../..'),
            TEST_TRACE: trace
        };
        const run = (coverage = [{ name: 'Service', numLocations: 100, numLocationsNotCovered: 10 }], changed) => {
            fs.writeFileSync(trace, '');
            fs.rmSync(path.join(directory, 'changed-apex.txt'), { force: true });
            if (changed) fs.writeFileSync(path.join(directory, 'changed-apex.txt'), changed);
            const result = spawnSync('/bin/bash', ['-c', script], {
                cwd: directory,
                encoding: 'utf8',
                env: {
                    ...env,
                    TEST_RESPONSE: JSON.stringify({
                        result: { details: { runTestResult: { codeCoverage: coverage } } }
                    })
                }
            });
            return { result, args: fs.readFileSync(trace, 'utf8').trim().split('\n') };
        };
        const runFresh = () => {
            fs.writeFileSync(trace, '');
            const result = spawnSync('bash', ['-c', freshScript], {
                cwd: directory,
                encoding: 'utf8',
                env: { ...env, TEST_RESPONSE: '{}' }
            });
            return { result, args: fs.readFileSync(trace, 'utf8').trim().split('\n') };
        };
        const namesFromArgs = (args) =>
            args.flatMap((argument, index) => (argument === '--tests' ? [args[index + 1]] : []));

        const selected = run();
        assert.equal(selected.result.status, 0, selected.result.stderr);
        assert.equal(selected.args[selected.args.indexOf('--test-level') + 1], 'RunSpecifiedTests');
        assert.deepEqual(namesFromArgs(selected.args), ['RepoAlphaTest', 'RepoBetaTest']);
        assert.ok(selected.args.includes('--dry-run'));
        await context.test(
            'the new-org route receives the same repository classes',
            { skip: freshBashAvailable ? false : 'The Ubuntu workflow requires Bash 4 or newer.' },
            () => {
                const fresh = runFresh();
                assert.equal(fresh.result.status, 0, fresh.result.stderr);
                assert.deepEqual(namesFromArgs(fresh.args), namesFromArgs(selected.args));
            }
        );

        assert.equal(run([{ name: 'Service', numLocations: 100, numLocationsNotCovered: 15 }]).result.status, 0);
        const lowCoverage = run([{ name: 'Service', numLocations: 100, numLocationsNotCovered: 16 }]);
        assert.notEqual(lowCoverage.result.status, 0);
        assert.match(lowCoverage.result.stderr, /84\.00% is below 85%/);
        const lowTrigger = run([
            { name: 'Service', numLocations: 100, numLocationsNotCovered: 10 },
            { name: 'ServiceTrigger', numLocations: 100, numLocationsNotCovered: 100 }
        ]);
        assert.notEqual(lowTrigger.result.status, 0);
        assert.match(lowTrigger.result.stderr, /45\.00% is below 85%/);

        fs.writeFileSync(
            path.join(classes, 'NewService.cls'),
            'public class NewService {\n' + '    x = 1;\n'.repeat(20) + '}'
        );
        const uncovered = run(
            [{ name: 'Service', numLocations: 100, numLocationsNotCovered: 10 }],
            'force-app/classes/NewService.cls\n'
        );
        assert.notEqual(uncovered.result.status, 0);
        assert.match(uncovered.result.stderr, /ingen dekningsdata: force-app\/classes\/NewService\.cls/);
        assert.match(uncovered.result.stderr, /75\.00% is below 85%/);
        fs.unlinkSync(path.join(classes, 'NewService.cls'));

        fs.unlinkSync(path.join(classes, 'RepoAlphaTest.cls'));
        fs.unlinkSync(path.join(classes, 'RepoBetaTest.cls'));
        const empty = run();
        assert.notEqual(empty.result.status, 0);
        assert.match(empty.result.stderr, /no repository apex test classes/i);
        assert.equal(fs.readFileSync(trace, 'utf8'), '');
        await context.test(
            'the new-org route also fails when no repository tests are found',
            { skip: freshBashAvailable ? false : 'The Ubuntu workflow requires Bash 4 or newer.' },
            () => {
                const emptyFresh = runFresh();
                assert.notEqual(emptyFresh.result.status, 0);
                assert.match(emptyFresh.result.stderr, /no repository apex test classes/i);
                assert.equal(fs.readFileSync(trace, 'utf8'), '');
            }
        );
    }
);

test(
    'reuse validation failures remain failures and cannot trigger the new-org route',
    { skip: process.platform === 'win32' ? 'The workflow runs on Ubuntu with Bash.' : false },
    (context) => {
        const directory = fs.mkdtempSync(path.join(os.tmpdir(), 'ci-reuse-failure-'));
        context.after(() => fs.rmSync(directory, { recursive: true, force: true }));
        const classes = path.join(directory, 'force-app', 'classes');
        fs.mkdirSync(classes, { recursive: true });
        fs.writeFileSync(path.join(classes, 'RepoTest.cls'), '@IsTest class RepoTest {}');
        fs.writeFileSync(path.join(directory, 'sf'), '#!/bin/sh\nprintf "%s" "$TEST_RESPONSE"\nexit 19\n', {
            mode: 0o755
        });
        const reuse = jobSection(reusableWorkflow(), 'reuse');
        const script = stepScript(reuse, 'Validate reusable org with tests and coverage');
        assert.doesNotMatch(reuse, /continue-on-error/);
        assert.doesNotMatch(script, /fallback|CI_VALIDATION_ROUTE=fresh/);

        for (const { diagnostic, expected } of [
            {
                diagnostic: { componentFailures: [{ problem: 'Metadata compilation failed' }] },
                expected: 'Metadata compilation failed'
            },
            {
                diagnostic: { runTestResult: { failures: [{ message: '::error::Apex test failed' }] } },
                expected: '::error::Apex test failed'
            },
            {
                diagnostic: {
                    runTestResult: { codeCoverageWarnings: { name: 'Service', message: 'Coverage is 74%' } }
                },
                expected: 'Service: Coverage is 74%'
            },
            {
                diagnostic: {
                    runTestResult: { codeCoverageWarnings: [{ name: 'ServiceTrigger', message: 'Coverage is 50%' }] }
                },
                expected: 'ServiceTrigger: Coverage is 50%'
            }
        ]) {
            const result = spawnSync('/bin/bash', ['-c', script], {
                cwd: directory,
                encoding: 'utf8',
                env: {
                    ...process.env,
                    PATH: directory + path.delimiter + process.env.PATH,
                    RUNNER_TEMP: directory,
                    TRUSTED_ROOT: path.resolve(__dirname, '../..'),
                    TEST_RESPONSE: JSON.stringify({ result: { details: diagnostic } })
                }
            });
            assert.equal(result.status, 19, result.stderr);
            const token = result.stdout.match(/::stop-commands::([a-f0-9-]+)/)?.[1];
            assert.ok(token);
            assert.ok(result.stdout.indexOf(expected) > result.stdout.indexOf(`::stop-commands::${token}`));
            assert.ok(result.stdout.indexOf(`::${token}::`) > result.stdout.indexOf(expected));
        }
    }
);

test('checks active scratch status and matching org identity before querying installed packages', () => {
    const source = stepScript(jobSection(reusableWorkflow(), 'reuse'), 'Check the registered CI org');
    const markers = [
        'sf data query',
        'ci-scratch-plan.cjs" verify-scratch',
        'sf org login sfdx-url --sfdx-url-file "$auth_file" --alias ci-reuse',
        'jq -e --arg expected "$CI_SCRATCH_ORG_ID"',
        'sf package installed list --target-org ci-reuse'
    ].map((marker) => source.indexOf(marker));
    assert.ok(
        markers.every((index, position) => index >= 0 && (position === 0 || index > markers[position - 1])),
        markers.join()
    );
    assert.match(source, /ScratchOrgInfo/);
    assert.match(source, /CI_SCRATCH_ORG_ID.*=~ \^\[a-zA-Z0-9\]/);
});

test(
    'routes the actual reusable-org check safely with a simulated Salesforce CLI',
    { skip: process.platform === 'win32' ? 'The workflow runs on Ubuntu with Bash.' : false },
    (context) => {
        const directory = fs.mkdtempSync(path.join(os.tmpdir(), 'ci-scratch-route-'));
        context.after(() => fs.rmSync(directory, { recursive: true, force: true }));
        for (const subdirectory of ['bin', 'config', 'scripts']) fs.mkdirSync(path.join(directory, subdirectory));

        const projectFile = path.join(directory, 'sfdx-project.json');
        const definitionFile = path.join(directory, 'config/project-scratch-def.json');
        const traceFile = path.join(directory, 'sf-calls.txt');
        const githubEnv = path.join(directory, 'github-env.txt');
        fs.writeFileSync(
            projectFile,
            JSON.stringify({
                sourceApiVersion: '67.0',
                packageDirectories: [{ dependencies: [{ package: 'base' }] }]
            })
        );
        fs.writeFileSync(definitionFile, '{}');
        fs.writeFileSync(
            path.join(directory, 'package-plan.json'),
            JSON.stringify({ base: { SubscriberPackageVersionId: 'planned-version' } })
        );
        fs.copyFileSync(
            path.resolve(__dirname, '../ci-scratch-plan.cjs'),
            path.join(directory, 'scripts/ci-scratch-plan.cjs')
        );
        const cliFile = path.join(directory, 'fake-cli.cjs');
        fs.writeFileSync(
            cliFile,
            `
            const fs = require('node:fs');
            const args = process.argv.slice(2);
            fs.appendFileSync(process.env.TEST_TRACE, args.slice(0, 3).join(' ') + '\\n');
            const scenario = process.env.TEST_SCENARIO;
            if (args[0] === 'data' && args[1] === 'query') {
                if (scenario === 'query-failed') process.exit(1);
                const records = scenario === 'inactive' ? [] : [{
                    ScratchOrg: process.env.CI_SCRATCH_ORG_ID.slice(0, 15),
                    Status: 'Active',
                    ExpirationDate: process.env.CI_SCRATCH_ORG_EXPIRATION
                }];
                console.log(JSON.stringify({ result: { records } }));
            } else if (args[0] === 'org' && args[1] === 'login') {
                process.exit(0);
            } else if (args[0] === 'org' && args[1] === 'display') {
                const id = scenario === 'wrong-org' ? 'B'.repeat(15) + 'XYZ' : process.env.CI_SCRATCH_ORG_ID;
                console.log(JSON.stringify({ result: { id } }));
            } else if (args[0] === 'package' && args[1] === 'installed') {
                const id = scenario === 'old-package' ? 'old-version' : 'planned-version';
                console.log(JSON.stringify({ result: [{ SubscriberPackageVersionId: id }] }));
            } else {
                process.exit(2);
            }
        `
        );
        const quote = (value) => `'${value.replaceAll("'", "'\\''")}'`;
        fs.writeFileSync(
            path.join(directory, 'bin/sf'),
            `#!/bin/sh\nexec ${quote(process.execPath)} ${quote(cliFile)} "$@"\n`,
            { mode: 0o755 }
        );

        const script = stepScript(jobSection(reusableWorkflow(), 'reuse'), 'Check the registered CI org');
        const githubOutput = path.join(directory, 'github-output.txt');
        const all = ['data query', 'org login', 'org display', 'package installed'];
        const scenarios = [
            { name: 'ready', route: 'reuse', calls: all },
            { name: 'inactive', route: 'fresh', calls: ['data query'] },
            { name: 'query-failed', route: 'fresh', calls: ['data query'] },
            { name: 'old-package', route: 'fresh', calls: all },
            {
                name: 'wrong-org',
                route: 'fresh',
                reason: /registration is incomplete/,
                calls: ['data query', 'org login', 'org display']
            },
            { name: 'invalid-id', route: 'fresh', reason: /registration is incomplete/, calls: [] },
            { name: 'unregistered', route: 'fresh', reason: /No CI scratch org is registered/, calls: [] }
        ];
        for (const scenario of scenarios) {
            fs.writeFileSync(traceFile, '');
            fs.writeFileSync(githubEnv, '');
            fs.writeFileSync(githubOutput, '');
            const result = spawnSync('/bin/bash', ['-c', script], {
                cwd: directory,
                encoding: 'utf8',
                env: {
                    ...process.env,
                    PATH: path.join(directory, 'bin') + path.delimiter + process.env.PATH,
                    TRUSTED_ROOT: directory,
                    RUNNER_TEMP: directory,
                    GITHUB_ENV: githubEnv,
                    GITHUB_OUTPUT: githubOutput,
                    GITHUB_STEP_SUMMARY: path.join(directory, 'summary.md'),
                    TEST_TRACE: traceFile,
                    TEST_SCENARIO: scenario.name,
                    CI_SCRATCH_ORG_AUTH_URL: scenario.name === 'unregistered' ? '' : 'placeholder',
                    CI_SCRATCH_ORG_ID:
                        scenario.name === 'invalid-id' ? "invalid' OR Status='Active" : 'A'.repeat(15) + 'XYZ',
                    CI_SCRATCH_ORG_EXPIRATION: '2099-12-01',
                    CI_SCRATCH_ORG_CONFIG_SHA256: scratchFingerprint(projectFile, definitionFile)
                }
            });
            assert.equal(result.status, 0, `${scenario.name}: ${result.stderr}`);
            assert.match(
                fs.readFileSync(githubEnv, 'utf8'),
                new RegExp(`CI_VALIDATION_ROUTE=${scenario.route}`),
                scenario.name
            );
            const output = fs.readFileSync(githubOutput, 'utf8');
            assert.match(output, new RegExp(`fallback=${scenario.route === 'fresh'}`), scenario.name);
            if (scenario.reason) assert.match(output, scenario.reason, scenario.name);
            const calls = fs.readFileSync(traceFile, 'utf8').trim();
            assert.deepEqual(
                calls ? calls.split('\n').map((line) => line.split(' ').slice(0, 2).join(' ')) : [],
                scenario.calls,
                scenario.name
            );
            assert.equal(fs.existsSync(path.join(directory, 'reuse-auth.txt')), false, scenario.name);
        }
    }
);

test('promotion helper uses the local reusable workflow', () => {
    const caller = readWorkflow('helper_promotion1.yml');
    assert.match(caller, /uses: \.\/\.github\/workflows\/package-promotion\.yml/);
    assert.match(caller, /packageId: \$\{\{ inputs\.packageId \}\}/);
    assert.match(caller, /comment: \$\{\{ inputs\.comment \}\}/);
    assert.match(caller, /if: github\.ref == 'refs\/heads\/main'/);
    assert.match(
        caller,
        /run-package-promotion:[\s\S]*?permissions:\s*\n\s+contents: write\s*\n\s+pull-requests: write\s*\n\s+actions: write/
    );
    assert.match(caller, /CRM_PROD_SFDX_URL: \$\{\{ secrets\.CRM_PROD_SFDX_URL \}\}/);
    assert.match(caller, /CRM_PREPROD_SFDX_URL: \$\{\{ secrets\.CRM_PREPROD_SFDX_URL \}\}/);
    assert.match(caller, /CRM_UAT_SFDX_URL: \$\{\{ secrets\.CRM_UAT_SFDX_URL \}\}/);
    assert.match(caller, /CRM_PACKAGE_KEY: \$\{\{ secrets\.CRM_PACKAGE_KEY \}\}/);
    assert.doesNotMatch(caller, /secrets: inherit|CRM_DEPLOYMENT_PAT/);
    assert.doesNotMatch(caller, /crm-workflows-base\/\.github\/workflows\/packagePromotion\.yml/);

    const promotion = readWorkflow('package-promotion.yml');
    assert.match(promotion, /workflow_call:/);
    assert.match(promotion, /validate-inputs:[\s\S]*?PACKAGE_ID: \$\{\{ inputs\.packageId \}\}/);
    assert.match(promotion, /\[\[ ! "\$PACKAGE_ID" =~ \^\(\[A-Za-z0-9\]\{15\}\|\[A-Za-z0-9\]\{18\}\)\$ \]\]/);
    assert.match(
        promotion,
        /install-package-preprod:[\s\S]*?needs: \[validate-inputs\][\s\S]*?uses: \.\/\.github\/workflows\/package-install\.yml/
    );
    assert.match(
        promotion,
        /install-package-uat:[\s\S]*?needs: \[validate-inputs\][\s\S]*?uses: \.\/\.github\/workflows\/package-install\.yml/
    );
    assert.match(promotion, /promote-package:[\s\S]*?needs: \[validate-inputs, install-package-preprod\]/);
    assert.match(promotion, /promote-package:\n\s+name: [^\n]+\n\s+environment: production\n/);
    assert.match(promotion, /create-release:\n\s+name: [^\n]+\n\s+environment: production\n/);
    assert.match(promotion, /sf package version promote/);
    assert.match(promotion, /packageMinorVersionUpdater@/);
    assert.match(promotion, /create-pull-request@/);
    assert.match(promotion, /gh pr merge .*--auto .*--match-head-commit/);
    assert.match(
        promotion,
        /Wait for version-update PR to merge[\s\S]*?gh pr view[\s\S]*?gh workflow run push_create-package1\.yml --ref "\$dispatch_ref"/
    );
    assert.match(
        promotion,
        /gh pr view .*--json state,mergedAt,headRefOid,mergedBy,mergeCommit[\s\S]*?merged_by=\$\(jq -r '\.mergedBy\.login \/\/ empty'[\s\S]*?if \[\[ "\$merged_by" != "app\/github-actions" && "\$merged_by" != "github-actions\[bot\]" \]\]; then[\s\S]*?gh api "repos\/\$GITHUB_REPOSITORY\/actions\/workflows\/push_create-package1\.yml\/runs\?head_sha=\$merge_sha[\s\S]*?gh workflow run/
    );
    assert.match(promotion, /dispatch_ref="package-create-\$\{GITHUB_RUN_ID\}-\$\{GITHUB_RUN_ATTEMPT\}"/);
    assert.match(
        promotion,
        /gh api -X POST "repos\/\$GITHUB_REPOSITORY\/git\/refs" -f ref="refs\/tags\/\$dispatch_ref" -f sha="\$merge_sha"[\s\S]*?trap cleanup_dispatch_tag EXIT[\s\S]*?gh workflow run push_create-package1\.yml --ref "\$dispatch_ref"/
    );
    assert.match(
        promotion,
        /cleanup_dispatch_tag\(\) \{[\s\S]*?gh api -X DELETE "repos\/\$GITHUB_REPOSITORY\/git\/refs\/tags\/\$dispatch_ref"[\s\S]*?exit "\$dispatch_status"/
    );
    assert.match(
        promotion,
        /push-new-version-number:[\s\S]*?permissions:\s*\n\s+contents: write\s*\n\s+pull-requests: write\s*\n\s+actions: write/
    );
    assert.match(promotion, /create-release:[\s\S]*?softprops\/action-gh-release@/);
    assert.match(promotion, /target_commitish: \$\{\{ github\.sha \}\}/);
    assert.doesNotMatch(promotion, /CRM_DEPLOYMENT_PAT|merge-pull-request-action|--admin/);
    assert.doesNotMatch(
        promotion,
        /navikt\/crm-workflows-base\/.*(?:@master|@main)|(?:actions|peter-evans|metcalfc|softprops)\/.*@(?![a-f0-9]{40}\b)[^\s]+/
    );
    assert.equal(fs.existsSync(path.join(directory, 'promotion-auto-merge.yml')), false);
});

test('bot-merged promotion PRs dispatch the review audit for the exact merge commit', () => {
    const audit = readWorkflow('post-merge-review-audit.yml');
    assert.match(audit, /workflow_dispatch:\s*\n\s+inputs:\s*\n\s+sha:/);
    assert.match(audit, /AUDIT_SHA: \$\{\{ inputs\.sha \|\| github\.sha \}\}/);

    const promotion = readWorkflow('package-promotion.yml');
    assert.match(
        promotion,
        /echo "bot-merge-sha=\$merge_sha" >> "\$GITHUB_OUTPUT"[\s\S]*?gh workflow run push_create-package1\.yml[\s\S]*?if: always\(\) && steps\.wait-for-merge\.outputs\.bot-merge-sha != ''[\s\S]*?gh workflow run post-merge-review-audit\.yml --ref main --repo "\$GITHUB_REPOSITORY" -f sha="\$MERGE_SHA"/
    );
});

test('audit concurrency is keyed by the SHA being audited', () => {
    const audit = readWorkflow('post-merge-review-audit.yml');
    assert.match(audit, /group: post-merge-review-audit-\$\{\{ inputs\.sha \|\| github\.sha \}\}/);
});

test('sandbox installation inherits only its explicitly passed secrets', () => {
    const promotion = readWorkflow('package-promotion.yml');
    for (const [job, allowedSecret, forbiddenSecret] of [
        ['install-package-preprod', 'CRM_PREPROD_SFDX_URL', 'CRM_UAT_SFDX_URL'],
        ['install-package-uat', 'CRM_UAT_SFDX_URL', 'CRM_PREPROD_SFDX_URL']
    ]) {
        const section = promotion.match(new RegExp(`^    ${job}:\\n([\\s\\S]*?)(?=^    [\\w-]+:|$(?![\\s\\S]))`, 'm'));
        assert.ok(section, `Missing ${job}`);
        assert.match(section[1], new RegExp(`${allowedSecret}: \\$\\{\\{ secrets\\.${allowedSecret} \\}\\}`));
        assert.match(section[1], /CRM_PACKAGE_KEY: \$\{\{ secrets\.CRM_PACKAGE_KEY \}\}/);
        assert.doesNotMatch(section[1], new RegExp(`${forbiddenSecret}|CRM_PROD_SFDX_URL|secrets: inherit`));
    }

    const installer = readWorkflow('package-install.yml');
    assert.match(installer, /workflow_call:/);
    assert.match(installer, /CRM_PREPROD_SFDX_URL:\s*\n\s+required: false/);
    assert.match(installer, /CRM_UAT_SFDX_URL:\s*\n\s+required: false/);
    assert.match(installer, /CRM_PACKAGE_KEY:\s*\n\s+required: true/);
    assert.doesNotMatch(installer, /CRM_PROD_SFDX_URL|CRM_DEPLOYMENT_PAT/);
    assert.match(installer, /uses: navikt\/crm-workflows-base\/\.github\/workflows\/deployPackage\.yml@[a-f0-9]{40}/);
    assert.match(installer, /secrets: inherit/);
});

for (const name of fs.readdirSync(directory).filter((name) => name.endsWith('.yml'))) {
    test(`${name} declares token permissions and pins external actions`, () => {
        const source = readWorkflow(name);
        assert.match(source, /^permissions:\s*\n\s+contents: read\b/m);
        for (const [, reference] of source.matchAll(/\buses: ([^\s]+)/g)) {
            if (!reference.startsWith('./')) {
                assert.match(reference, /@[a-f0-9]{40}$/, reference);
            }
        }
    });

    test(`${name} does not interpolate inputs or actors directly into shell scripts`, () => {
        const source = readWorkflow(name);
        assert.doesNotMatch(source, /(?:echo|run:).*\$\{\{\s*(?:inputs\.|github\.event\.inputs\.|github\.actor)/);
    });
}
