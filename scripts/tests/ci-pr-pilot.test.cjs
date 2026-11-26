const assert = require('node:assert/strict');
const { test } = require('node:test');
const { resolvePullRequest, validatePrSource, verifyMergeCommit } = require('../ci-pr-pilot.cjs');

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
