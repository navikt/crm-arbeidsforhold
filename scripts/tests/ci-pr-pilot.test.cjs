const assert = require('node:assert/strict');
const { spawnSync } = require('node:child_process');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { test } = require('node:test');
const {
    hasPriorValidation,
    isCurrentPullRequest,
    resolvePullRequest,
    validatePrSource,
    verifyMergeCommit
} = require('../ci-pr-pilot.cjs');

const repository = 'example/repository';
const headSha = 'a'.repeat(40);
const baseSha = 'b'.repeat(40);
const mergeSha = 'c'.repeat(40);
const workflowRun = {
    name: '[PR] Validate',
    path: '.github/workflows/pull_request-validation1.yml',
    event: 'pull_request',
    id: 123,
    run_attempt: 1,
    run_started_at: '2026-01-02T03:04:05Z',
    head_sha: headSha,
    head_branch: 'feature/example',
    head_repository: { full_name: repository },
    pull_requests: []
};
const pullRequest = {
    number: 42,
    state: 'open',
    draft: false,
    head: { sha: headSha, ref: 'feature/example', repo: { full_name: repository } },
    base: { sha: baseSha, ref: 'main', repo: { full_name: repository } },
    mergeable: true,
    merge_commit_sha: mergeSha
};

function provider(pulls = [pullRequest], detail = pullRequest) {
    const calls = [];
    return {
        calls,
        list: async () => {
            calls.push('list');
            return pulls;
        },
        get: async (number) => {
            calls.push(`get:${number}`);
            return detail;
        },
        wait: async () => calls.push('wait')
    };
}

test('selects one open internal PR and locks its merge, head, base and original CI run', async () => {
    const github = provider();
    assert.deepEqual(await resolvePullRequest(workflowRun, repository, github), {
        eligible: true,
        number: 42,
        headSha,
        baseSha,
        mergeSha,
        baselineRunId: 123,
        baselineAttempt: 1
    });
    assert.deepEqual(github.calls, ['list', 'get:42']);
});

test('does not access PR data or secrets for fork and non-PR workflow runs', async () => {
    for (const run of [
        { ...workflowRun, event: 'push' },
        { ...workflowRun, path: '.github/workflows/other.yml' },
        { ...workflowRun, head_repository: { full_name: 'example/fork' } }
    ]) {
        const github = provider();
        const result = await resolvePullRequest(run, repository, github);
        assert.equal(result.eligible, false);
        assert.ok(result.reason);
        assert.deepEqual(github.calls, []);
    }
});

test('skips drafts, non-main PRs and PRs whose head or branch changed', async () => {
    const cases = [
        { ...pullRequest, draft: true },
        { ...pullRequest, base: { ...pullRequest.base, ref: 'other' } },
        { ...pullRequest, head: { ...pullRequest.head, sha: 'd'.repeat(40) } },
        { ...pullRequest, head: { ...pullRequest.head, ref: 'feature/other' } }
    ];
    for (const candidate of cases) {
        const github = provider([candidate]);
        const result = await resolvePullRequest(workflowRun, repository, github);
        assert.equal(result.eligible, false);
        assert.ok(result.reason);
        assert.deepEqual(github.calls, ['list']);
    }
});

test('skips a PR that changes or becomes unmergeable before its snapshot is selected', async () => {
    for (const detail of [
        { ...pullRequest, head: { ...pullRequest.head, sha: 'd'.repeat(40) } },
        { ...pullRequest, mergeable: false, merge_commit_sha: null },
        { ...pullRequest, state: 'closed' }
    ]) {
        const result = await resolvePullRequest(workflowRun, repository, provider([pullRequest], detail));
        assert.equal(result.eligible, false);
        assert.ok(result.reason);
    }
});

test('waits for GitHub to calculate a merge and rejects ambiguous or invalid references', async () => {
    const github = provider();
    let attempts = 0;
    github.get = async () => {
        attempts++;
        return attempts === 1 ? { ...pullRequest, mergeable: null, merge_commit_sha: null } : pullRequest;
    };
    const result = await resolvePullRequest(workflowRun, repository, github);
    assert.equal(result.mergeSha, mergeSha);
    assert.ok(github.calls.includes('wait'));

    await assert.rejects(
        () => resolvePullRequest(workflowRun, repository, provider([pullRequest, pullRequest])),
        /multiple/i
    );
    await assert.rejects(
        () => resolvePullRequest({ ...workflowRun, head_sha: 'not-a-commit' }, repository, provider()),
        /commit/i
    );
    await assert.rejects(
        () =>
            resolvePullRequest(
                workflowRun,
                repository,
                provider([pullRequest], { ...pullRequest, merge_commit_sha: 'invalid' })
            ),
        /merge.*commit/i
    );
});

test('surfaces GitHub API failures instead of treating them as an ineligible PR', async () => {
    const github = provider();
    github.list = async () => {
        throw new Error('GitHub API unavailable');
    };
    await assert.rejects(() => resolvePullRequest(workflowRun, repository, github), /GitHub API unavailable/);
});

test('skips repeated notifications once the same baseline attempt has a validation', async () => {
    const pilot = {
        id: 501,
        path: '.github/workflows/ci-reusable-pr-pilot.yml',
        event: 'workflow_run',
        status: 'completed',
        conclusion: 'success',
        display_title: 'Reusable PR pilot 123 attempt 1'
    };
    const current = { ...pilot, id: 502, status: 'in_progress' };
    const job = {
        name: 'Run parallel Salesforce pilot / Validate PR #42 on reusable org or fresh fallback',
        status: 'completed',
        conclusion: 'success'
    };
    const github = {
        listPilotRuns: async () => [pilot, current],
        listPilotJobs: async () => [job],
        wait: async () => {}
    };

    assert.equal(await hasPriorValidation(workflowRun, 502, github), true);
    github.listPilotJobs = async () => [{ ...job, conclusion: 'failure' }];
    assert.equal(await hasPriorValidation(workflowRun, 502, github), true);
    github.listPilotJobs = async () => [{ ...job, conclusion: 'skipped' }];
    assert.equal(await hasPriorValidation(workflowRun, 502, github), false);
    github.listPilotJobs = async () => [{ ...job, conclusion: 'cancelled' }];
    assert.equal(await hasPriorValidation(workflowRun, 502, github), false);
    github.listPilotJobs = async () => [{ ...job, conclusion: null }];
    await assert.rejects(() => hasPriorValidation(workflowRun, 502, github), /invalid/i);
    github.listPilotJobs = async () => [];
    await assert.rejects(() => hasPriorValidation(workflowRun, 502, github), /invalid/i);
    github.listPilotRuns = async () => [{ ...pilot, status: 'queued' }, current];
    github.listPilotJobs = async () => {
        throw new Error('Pending pilots must not count as validation.');
    };
    assert.equal(await hasPriorValidation(workflowRun, 502, github), false);
    github.listPilotRuns = async () => [pilot, { ...current, display_title: 'Reusable PR pilot 123 attempt 2' }];
    assert.equal(await hasPriorValidation({ ...workflowRun, run_attempt: 2 }, 502, github), false);
});

test('allows a rerun of the original pilot and surfaces missing or failed GitHub responses', async () => {
    const current = {
        id: 501,
        path: '.github/workflows/ci-reusable-pr-pilot.yml',
        event: 'workflow_run',
        display_title: 'Reusable PR pilot 123 attempt 1'
    };
    const github = {
        listPilotRuns: async () => [current],
        listPilotJobs: async () => {
            throw new Error('The current run must not be inspected.');
        },
        wait: async () => {}
    };
    assert.equal(await hasPriorValidation(workflowRun, 501, github), false);
    github.listPilotRuns = async () => [];
    await assert.rejects(() => hasPriorValidation(workflowRun, 501, github), /current pilot/i);
    github.listPilotRuns = async () => [{ ...current, display_title: 'Unexpected title' }];
    await assert.rejects(() => hasPriorValidation(workflowRun, 501, github), /current pilot/i);
    github.listPilotRuns = async () => {
        throw new Error('GitHub API unavailable');
    };
    await assert.rejects(() => hasPriorValidation(workflowRun, 501, github), /GitHub API unavailable/);
});

test('does not start a queued pilot after the PR or target base changes', () => {
    const expected = { number: 42, headSha, baseSha };
    assert.equal(isCurrentPullRequest(pullRequest, expected, repository), true);
    for (const changed of [
        { ...pullRequest, state: 'closed' },
        { ...pullRequest, draft: true },
        { ...pullRequest, head: { ...pullRequest.head, sha: 'd'.repeat(40) } },
        { ...pullRequest, head: { ...pullRequest.head, repo: null } },
        { ...pullRequest, base: { ...pullRequest.base, sha: 'd'.repeat(40) } },
        { ...pullRequest, base: { ...pullRequest.base, ref: 'other' } }
    ]) {
        assert.equal(isCurrentPullRequest(changed, expected, repository), false);
    }
    assert.throws(() => isCurrentPullRequest({ ...pullRequest, draft: 'false' }, expected, repository), /invalid/i);
});

test('pilot CLI handles paginated GitHub runs and rechecks the PR snapshot', (context) => {
    const directory = fs.mkdtempSync(path.join(os.tmpdir(), 'ci-pr-pilot-'));
    context.after(() => fs.rmSync(directory, { recursive: true, force: true }));
    const eventFile = path.join(directory, 'event.json');
    fs.writeFileSync(eventFile, JSON.stringify({ workflow_run: workflowRun }));
    fs.writeFileSync(
        path.join(directory, 'gh'),
        `#!/usr/bin/env node
const endpoint = process.argv[3];
let response;
if (endpoint.includes('/commits/')) response = [[JSON.parse(process.env.MOCK_PULL)]];
else if (endpoint.endsWith('/pulls/42')) response = JSON.parse(process.env.MOCK_PULL);
else if (endpoint.includes('/actions/workflows/')) response = process.env.MOCK_INVALID ? [{ jobs: [] }] : [{ workflow_runs: JSON.parse(process.env.MOCK_RUNS) }];
else if (endpoint.includes('/actions/runs/501/jobs?filter=all')) response = [{ jobs: JSON.parse(process.env.MOCK_JOBS) }];
else throw new Error('Unexpected GitHub request: ' + endpoint);
process.stdout.write(JSON.stringify(response));
`,
        { mode: 0o755 }
    );
    const previous = {
        id: 501,
        path: '.github/workflows/ci-reusable-pr-pilot.yml',
        event: 'workflow_run',
        status: 'completed',
        conclusion: 'success',
        display_title: 'Reusable PR pilot 123 attempt 1'
    };
    const env = {
        ...process.env,
        PATH: directory + path.delimiter + process.env.PATH,
        GITHUB_EVENT_PATH: eventFile,
        GITHUB_REPOSITORY: repository,
        GITHUB_RUN_ID: '502',
        MOCK_PULL: JSON.stringify(pullRequest),
        MOCK_RUNS: JSON.stringify([previous, { ...previous, id: 502, status: 'in_progress' }]),
        MOCK_JOBS: JSON.stringify([
            {
                name: 'Run parallel Salesforce pilot / Validate PR #42 on reusable org or fresh fallback',
                status: 'completed',
                conclusion: 'success'
            }
        ])
    };
    const run = (...args) =>
        spawnSync(process.execPath, [path.resolve(__dirname, '../ci-pr-pilot.cjs'), ...args], {
            env,
            encoding: 'utf8'
        });

    let result = run('resolve');
    assert.equal(result.status, 0, result.stderr);
    assert.match(JSON.parse(result.stdout).reason, /already validated/);
    env.MOCK_JOBS = JSON.stringify([
        { name: 'Run parallel Salesforce pilot', status: 'completed', conclusion: 'skipped' }
    ]);
    result = run('resolve');
    assert.equal(result.status, 0, result.stderr);
    assert.equal(JSON.parse(result.stdout).eligible, true);
    env.MOCK_INVALID = 'true';
    result = run('resolve');
    assert.notEqual(result.status, 0);
    assert.match(result.stderr, /paginated GitHub response is invalid/);
    delete env.MOCK_INVALID;
    result = run('current', '42', headSha, baseSha);
    assert.equal(result.status, 0, result.stderr);
    assert.equal(JSON.parse(result.stdout).current, true);
    env.MOCK_PULL = JSON.stringify({ ...pullRequest, head: { ...pullRequest.head, sha: 'd'.repeat(40) } });
    result = run('current', '42', headSha, baseSha);
    assert.equal(result.status, 0, result.stderr);
    assert.equal(JSON.parse(result.stdout).current, false);
    result = run('verify-current', '42', headSha, baseSha);
    assert.notEqual(result.status, 0);
    assert.match(result.stderr, /PR changed/);
});

test('accepts only the captured merge commit with the expected base and PR parents', () => {
    assert.doesNotThrow(() => verifyMergeCommit([mergeSha, baseSha, headSha], mergeSha, baseSha, headSha));
    for (const commits of [
        ['e'.repeat(40), baseSha, headSha],
        [mergeSha, headSha, baseSha],
        [mergeSha, baseSha],
        [mergeSha, baseSha, 'd'.repeat(40)]
    ]) {
        assert.throws(() => verifyMergeCommit(commits, mergeSha, baseSha, headSha), /merge.*commit/i);
    }
});

const trustedProject = {
    sfdcLoginUrl: 'trusted-login',
    sourceApiVersion: '68.0',
    packageDirectories: [{ path: 'force-app', dependencies: [{ package: 'base', versionNumber: '1.0.0.LATEST' }] }],
    packageAliases: { base: 'packageReference' }
};

test('accepts regular PR source and its package configuration as data', () => {
    assert.doesNotThrow(() => validatePrSource(trustedProject, trustedProject, '100644 object 0\tsfdx-project.json\0'));
});

test('rejects source symlinks, submodules, escaping paths and untrusted CLI configuration', () => {
    for (const index of ['120000 object 0\tforce-app/link\0', '160000 object 0\tforce-app/submodule\0']) {
        assert.throws(() => validatePrSource(trustedProject, trustedProject, index), /symbolic links|submodules/i);
    }
    for (const badPath of ['../outside', '/absolute', 'force-app/../../outside', '.git/config', 'force-app\\escape']) {
        const project = { ...trustedProject, packageDirectories: [{ path: badPath }] };
        assert.throws(() => validatePrSource(project, trustedProject, ''), /package directory/i);
    }
    assert.throws(
        () => validatePrSource({ ...trustedProject, sfdcLoginUrl: 'other-login' }, trustedProject, ''),
        /login/i
    );
    assert.throws(
        () => validatePrSource({ ...trustedProject, plugins: { plugin: { command: 'changed' } } }, trustedProject, ''),
        /plugin/i
    );
    assert.throws(
        () =>
            validatePrSource(
                {
                    ...trustedProject,
                    packageDirectories: [{ path: 'force-app', dependencies: [{ package: 'bad\n::notice::' }] }]
                },
                trustedProject,
                ''
            ),
        /package.*name/i
    );
    for (const filename of ['.sf/config.json', '.sfdx/sfdx-config.json', 'node_modules/plugin/index.js']) {
        assert.throws(
            () => validatePrSource(trustedProject, trustedProject, `100644 object 0\t${filename}\0`),
            /local.*configuration|node_modules/i
        );
    }
});
