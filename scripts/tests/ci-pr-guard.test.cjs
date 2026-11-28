const assert = require('node:assert/strict');
const { spawnSync } = require('node:child_process');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { test } = require('node:test');
const {
    isCurrentPullRequest,
    queueRoute,
    validatePrSource,
    verifyRequiredPullRequestInvocation,
    verifyMergeCommit
} = require('../ci-pr-guard.cjs');

const repository = 'example/repository';
const headSha = 'a'.repeat(40);
const baseSha = 'b'.repeat(40);
const mergeSha = 'c'.repeat(40);
const changedSha = 'd'.repeat(40);
const pullRequest = {
    number: 42,
    state: 'open',
    draft: false,
    head: { sha: headSha, ref: 'feature/example', repo: { full_name: repository } },
    base: { sha: baseSha, ref: 'main', repo: { full_name: repository } },
    mergeable: true,
    merge_commit_sha: mergeSha
};

test('does not start a queued validation after the PR or target base changes', () => {
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

test('accepts a required validation only for the captured internal PR to main', () => {
    const event = { number: 42, pull_request: pullRequest };
    const expected = { number: 42, headSha, baseSha, mergeSha };
    const context = {
        repository,
        workflow: '[PR] Validate',
        workflowRef: `${repository}/.github/workflows/pull_request-validation1.yml@refs/pull/42/merge`,
        ref: 'refs/pull/42/merge',
        sha: mergeSha
    };
    assert.doesNotThrow(() => verifyRequiredPullRequestInvocation(event, expected, context));

    for (const [changedEvent, changedExpected, changedContext] of [
        [{ ...event, number: 43 }, expected, context],
        [{ ...event, pull_request: { ...pullRequest, draft: true } }, expected, context],
        [
            {
                ...event,
                pull_request: { ...pullRequest, head: { ...pullRequest.head, repo: { full_name: 'fork/repo' } } }
            },
            expected,
            context
        ],
        [
            { ...event, pull_request: { ...pullRequest, base: { ...pullRequest.base, ref: 'other' } } },
            expected,
            context
        ],
        [event, { ...expected, headSha: changedSha }, context],
        [event, { ...expected, baseSha: changedSha }, context],
        [event, { ...expected, mergeSha: changedSha }, context],
        [event, expected, { ...context, sha: changedSha }],
        [event, expected, { ...context, ref: 'refs/pull/43/merge' }],
        [event, expected, { ...context, workflow: 'Other workflow' }],
        [event, expected, { ...context, workflowRef: `${repository}/.github/workflows/other.yml@refs/pull/42/merge` }],
        [event, expected, { ...context, workflowRef: undefined }]
    ]) {
        assert.throws(
            () => verifyRequiredPullRequestInvocation(changedEvent, changedExpected, changedContext),
            /PR|snapshot/i
        );
    }
});

test('required PR verification CLI rejects a different captured merge commit or calling workflow', (context) => {
    const directory = fs.mkdtempSync(path.join(os.tmpdir(), 'ci-required-pr-'));
    context.after(() => fs.rmSync(directory, { recursive: true, force: true }));
    const eventFile = path.join(directory, 'event.json');
    fs.writeFileSync(eventFile, JSON.stringify({ number: 42, pull_request: pullRequest }));
    const env = {
        ...process.env,
        GITHUB_EVENT_PATH: eventFile,
        GITHUB_REPOSITORY: repository,
        GITHUB_WORKFLOW: '[PR] Validate',
        GITHUB_WORKFLOW_REF: `${repository}/.github/workflows/pull_request-validation1.yml@refs/pull/42/merge`,
        GITHUB_REF: 'refs/pull/42/merge',
        GITHUB_SHA: mergeSha
    };
    const run = (capturedMerge, workflowRef = env.GITHUB_WORKFLOW_REF) =>
        spawnSync(
            process.execPath,
            [path.resolve(__dirname, '../ci-pr-guard.cjs'), 'verify-required', '42', headSha, baseSha, capturedMerge],
            { env: { ...env, GITHUB_WORKFLOW_REF: workflowRef }, encoding: 'utf8' }
        );
    const accepted = run(mergeSha);
    assert.equal(accepted.status, 0, accepted.stderr);
    const rejected = run(changedSha);
    assert.notEqual(rejected.status, 0);
    assert.match(rejected.stderr, /PR|snapshot/i);
    const wrongWorkflow = run(mergeSha, `${repository}/.github/workflows/other.yml@refs/pull/42/merge`);
    assert.notEqual(wrongWorkflow.status, 0);
    assert.match(wrongWorkflow.stderr, /PR|snapshot/i);
});

function mockGh(directory) {
    const mockFile = path.join(directory, 'mock-gh.cjs');
    fs.writeFileSync(
        mockFile,
        `const childProcess = require('node:child_process');
const original = childProcess.execFileSync;
childProcess.execFileSync = (command, args, options) => {
    if (command !== 'gh') return original(command, args, options);
    const endpoint = args[1];
    if (process.env.MOCK_FAIL) throw new Error('HTTP 502');
    let response;
    if (endpoint.endsWith('/pulls/42')) response = JSON.parse(process.env.MOCK_PULL);
    else if (endpoint.includes('/compare/')) response = JSON.parse(process.env.MOCK_COMPARE);
    else if (endpoint.includes('/actions/workflows/pull_request-validation1.yml/runs?status=')) {
        const status = new URL('https://x/' + endpoint).searchParams.get('status');
        response = [{ workflow_runs: JSON.parse(process.env.MOCK_RUNS).filter((run) => run.status === status) }];
    } else if (endpoint.includes('/jobs?')) {
        const id = endpoint.split('/runs/')[1].split('/')[0];
        response = [{ jobs: JSON.parse(process.env.MOCK_JOBS)[id] ?? [] }];
    } else throw new Error('Unexpected GitHub request: ' + endpoint);
    return JSON.stringify(response);
};`
    );
    return mockFile;
}

const reuseJob = 'Validate PR / Validate on reusable org';
const queuedRun = (id, number, status = 'queued') => ({
    id,
    status,
    head_branch: `feature/${number}`,
    pull_requests: number ? [{ number }] : []
});

test('routes to fresh only when two other PRs wait for the CI org', () => {
    const jobs = {
        11: [{ name: reuseJob, status: 'waiting' }],
        12: [{ name: reuseJob, status: 'queued' }],
        13: [{ name: reuseJob, status: 'pending' }],
        14: [{ name: reuseJob, status: 'in_progress' }],
        15: [{ name: 'Validate PR / Prepare validation', status: 'queued' }],
        16: [{ name: reuseJob, status: 'waiting' }]
    };
    const listJobs = (id) => jobs[id] ?? [];
    const current = { runId: 99, pullRequest: 42, headBranch: 'feature/42' };

    const onePr = queueRoute([queuedRun(11, 7), queuedRun(12, 7), queuedRun(16, 42)], listJobs, current);
    assert.equal(onePr.route, 'reuse');
    assert.equal(onePr.waiting, 1);

    const twoPrs = queueRoute(
        [
            queuedRun(11, 7),
            queuedRun(13, 8, 'in_progress'),
            queuedRun(14, 9, 'in_progress'),
            queuedRun(15, 10),
            queuedRun(99, 11)
        ],
        listJobs,
        current
    );
    assert.equal(twoPrs.route, 'fresh');
    assert.equal(twoPrs.waiting, 2);
    assert.match(twoPrs.reason, /2 other PRs/);

    const branchKey = queueRoute(
        [queuedRun(11, 0), { ...queuedRun(12, 0), head_branch: 'feature/42' }],
        listJobs,
        current
    );
    assert.equal(branchKey.waiting, 1);

    const mixed = queueRoute([{ ...queuedRun(11, 0), head_branch: 'feature/7' }, queuedRun(12, 7)], listJobs, current);
    assert.equal(mixed.route, 'reuse');
    assert.equal(mixed.waiting, 1);
});

test('queue CLI reports a fresh route and keeps reuse when GitHub cannot list the queue', (context) => {
    const directory = fs.mkdtempSync(path.join(os.tmpdir(), 'ci-pr-queue-'));
    context.after(() => fs.rmSync(directory, { recursive: true, force: true }));
    const env = {
        ...process.env,
        GITHUB_REPOSITORY: repository,
        GITHUB_RUN_ID: '99',
        MOCK_RUNS: JSON.stringify([queuedRun(11, 7), queuedRun(12, 8, 'in_progress')]),
        MOCK_JOBS: JSON.stringify({
            11: [{ name: reuseJob, status: 'waiting' }],
            12: [{ name: reuseJob, status: 'waiting' }]
        })
    };
    const run = () =>
        spawnSync(
            process.execPath,
            [
                '--require',
                mockGh(directory),
                path.resolve(__dirname, '../ci-pr-guard.cjs'),
                'queue',
                '42',
                'feature/42'
            ],
            { env, encoding: 'utf8' }
        );
    let result = run();
    assert.equal(result.status, 0, result.stderr);
    assert.deepEqual(JSON.parse(result.stdout), {
        route: 'fresh',
        waiting: 2,
        reason: '2 other PRs are waiting for the CI scratch org.'
    });
    env.MOCK_FAIL = 'true';
    result = run();
    assert.equal(result.status, 0, result.stderr);
    assert.equal(JSON.parse(result.stdout).route, 'reuse');
    assert.match(result.stderr, /::warning::.*queue/i);
});

test('guard CLI rechecks the PR snapshot', (context) => {
    const directory = fs.mkdtempSync(path.join(os.tmpdir(), 'ci-pr-guard-'));
    context.after(() => fs.rmSync(directory, { recursive: true, force: true }));
    const env = { ...process.env, GITHUB_REPOSITORY: repository, MOCK_PULL: JSON.stringify(pullRequest) };
    const run = (...args) =>
        spawnSync(
            process.execPath,
            ['--require', mockGh(directory), path.resolve(__dirname, '../ci-pr-guard.cjs'), ...args],
            {
                env,
                encoding: 'utf8'
            }
        );
    let result = run('current', '42', headSha, baseSha);
    assert.equal(result.status, 0, result.stderr);
    assert.equal(JSON.parse(result.stdout).current, true);
    env.MOCK_PULL = JSON.stringify({ ...pullRequest, head: { ...pullRequest.head, sha: 'd'.repeat(40) } });
    result = run('current', '42', headSha, baseSha);
    assert.equal(result.status, 0, result.stderr);
    assert.equal(JSON.parse(result.stdout).current, false);
    result = run('verify-current', '42', headSha, baseSha);
    assert.notEqual(result.status, 0);
    assert.match(result.stderr, /PR changed after the validation was queued/);
});

test('guard CLI keeps a queued PR current when only main has moved forward', (context) => {
    const directory = fs.mkdtempSync(path.join(os.tmpdir(), 'ci-pr-guard-base-'));
    context.after(() => fs.rmSync(directory, { recursive: true, force: true }));
    const env = {
        ...process.env,
        GITHUB_REPOSITORY: repository,
        MOCK_PULL: JSON.stringify({ ...pullRequest, base: { ...pullRequest.base, sha: changedSha } }),
        MOCK_COMPARE: JSON.stringify({ status: 'ahead', behind_by: 0 })
    };
    const run = () =>
        spawnSync(
            process.execPath,
            [
                '--require',
                mockGh(directory),
                path.resolve(__dirname, '../ci-pr-guard.cjs'),
                'verify-current',
                '42',
                headSha,
                baseSha
            ],
            { env, encoding: 'utf8' }
        );
    assert.equal(run().status, 0);
    for (const compare of [
        { status: 'diverged', behind_by: 1 },
        { status: 'behind', behind_by: 2 }
    ]) {
        env.MOCK_COMPARE = JSON.stringify(compare);
        const result = run();
        assert.notEqual(result.status, 0);
        assert.match(result.stderr, /PR changed after the validation was queued/);
    }
    env.MOCK_COMPARE = JSON.stringify({ status: 'ahead', behind_by: 0 });
    env.MOCK_PULL = JSON.stringify({
        ...pullRequest,
        head: { ...pullRequest.head, sha: changedSha },
        base: { ...pullRequest.base, sha: changedSha }
    });
    assert.notEqual(run().status, 0);
});

test('accepts only the captured merge commit with the expected base and PR parents', () => {
    assert.doesNotThrow(() => verifyMergeCommit([mergeSha, baseSha, headSha], mergeSha, baseSha, headSha));
    assert.throws(
        () => verifyMergeCommit([mergeSha, changedSha, headSha], mergeSha, baseSha, headSha, () => false),
        /merge.*commit/i
    );
    for (const commits of [
        ['e'.repeat(40), baseSha, headSha],
        [mergeSha, headSha, baseSha],
        [mergeSha, baseSha],
        [mergeSha, baseSha, 'd'.repeat(40)]
    ]) {
        assert.throws(() => verifyMergeCommit(commits, mergeSha, baseSha, headSha, () => true), /merge.*commit/i);
    }
});

test('accepts a merge commit built on a newer main commit when the PR head is unchanged', () => {
    const checked = [];
    const isNewerMain = (sha) => {
        checked.push(sha);
        return sha === changedSha;
    };
    assert.doesNotThrow(() =>
        verifyMergeCommit([mergeSha, changedSha, headSha], mergeSha, baseSha, headSha, isNewerMain)
    );
    assert.deepEqual(checked, [changedSha]);
    assert.throws(
        () => verifyMergeCommit([mergeSha, changedSha, 'e'.repeat(40)], mergeSha, baseSha, headSha, () => true),
        /merge.*commit/i
    );
});

test('snapshot CLI accepts a newer main parent only when it descends from the captured base on main', (context) => {
    const directory = fs.mkdtempSync(path.join(os.tmpdir(), 'ci-pr-snapshot-'));
    context.after(() => fs.rmSync(directory, { recursive: true, force: true }));
    const git = (...args) =>
        spawnSync('git', ['-c', 'user.name=t', '-c', 'user.email=t@example.com', ...args], {
            cwd: directory,
            encoding: 'utf8'
        }).stdout.trim();
    const commit = (name) => {
        fs.writeFileSync(path.join(directory, name), name);
        git('add', name);
        git('commit', '-q', '-m', name);
        return git('rev-parse', 'HEAD');
    };
    git('init', '-q', '-b', 'main');
    const capturedBase = commit('base');
    const newerMain = commit('newer');
    git('checkout', '-q', '-b', 'feature', capturedBase);
    const prHead = commit('feature');
    git('checkout', '-q', '-b', 'unrelated', capturedBase);
    const unrelated = commit('unrelated');
    git('update-ref', 'refs/remotes/origin/main', newerMain);
    const mergeOn = (parent) => {
        git('checkout', '-q', '--detach', parent);
        git('merge', '-q', '--no-ff', '-m', 'merge', prHead);
        return git('rev-parse', 'HEAD');
    };
    const run = (merge, base) =>
        spawnSync(
            process.execPath,
            [path.resolve(__dirname, '../ci-pr-guard.cjs'), 'verify-snapshot', merge, base, prHead],
            { cwd: directory, encoding: 'utf8' }
        );

    const newerMerge = mergeOn(newerMain);
    assert.equal(run(newerMerge, capturedBase).status, 0);
    const notOnMain = mergeOn(unrelated);
    const rejected = run(notOnMain, capturedBase);
    assert.notEqual(rejected.status, 0);
    assert.match(rejected.stderr, /merge commit/);
    const olderBase = mergeOn(capturedBase);
    assert.notEqual(run(olderBase, newerMain).status, 0);
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
