const assert = require('node:assert/strict');
const { test } = require('node:test');
const { assessMergedPullRequest, auditPush } = require('../post-merge-review-audit.cjs');

const headSha = 'head-sha';
const sha = (digit) => digit.repeat(40);

function pullRequest({ author = 'author', mergedBy = author } = {}) {
    return {
        user: { login: author, type: 'User' },
        merged_by: { login: mergedBy, type: 'User' },
        merged_at: '2026-11-16T12:00:00Z',
        head: { sha: headSha }
    };
}

function review(login, state, { submittedAt = '2026-11-16T11:00:00Z', commitId = headSha, type = 'User' } = {}) {
    return { user: { login, type }, state, submitted_at: submittedAt, commit_id: commitId };
}

const copilotReview = (options) =>
    review('copilot-pull-request-reviewer[bot]', 'COMMENTED', { type: 'Bot', ...options });

test('approval from another person needs no follow-up', () => {
    const result = assessMergedPullRequest(pullRequest({ mergedBy: 'merger' }), [review('colleague', 'APPROVED')]);
    assert.equal(result.followUpRequired, false);
});

test('own bypass merge with Copilot review of the merged commit needs no follow-up', () => {
    const result = assessMergedPullRequest(pullRequest(), [copilotReview()]);
    assert.equal(result.followUpRequired, false);
});

test('own bypass merge without Copilot review needs follow-up', () => {
    const result = assessMergedPullRequest(pullRequest(), [review('author', 'APPROVED')]);
    assert.equal(result.followUpRequired, true);
});

test('own bypass merge where Copilot reviewed only an earlier commit needs follow-up', () => {
    const result = assessMergedPullRequest(pullRequest(), [copilotReview({ commitId: 'older-sha' })]);
    assert.equal(result.followUpRequired, true);
});

test('Copilot review is not enough when someone else bypass-merges the pull request', () => {
    const result = assessMergedPullRequest(pullRequest({ mergedBy: 'merger' }), [copilotReview()]);
    assert.equal(result.followUpRequired, true);
});

test('approval submitted after merge or replaced by requested changes needs follow-up', () => {
    const afterMerge = assessMergedPullRequest(pullRequest({ mergedBy: 'merger' }), [
        review('colleague', 'APPROVED', { submittedAt: '2026-11-16T13:00:00Z' })
    ]);
    const superseded = assessMergedPullRequest(pullRequest({ mergedBy: 'merger' }), [
        review('colleague', 'APPROVED'),
        review('colleague', 'CHANGES_REQUESTED', { submittedAt: '2026-11-16T11:30:00Z' })
    ]);
    assert.equal(afterMerge.followUpRequired, true);
    assert.equal(superseded.followUpRequired, true);
});

test('push range audits each merged PR once and reports direct commits alongside unreviewed PRs', async () => {
    const firstPrCommit = sha('1');
    const firstPrMerge = sha('2');
    const approvedPrMerge = sha('3');
    const directCommit = sha('4');
    const after = sha('5');
    const firstPr = {
        ...pullRequest({ author: 'first-author', mergedBy: 'merger' }),
        number: 10,
        base: { ref: 'main' },
        merge_commit_sha: firstPrMerge,
        html_url: 'https://github.com/navikt/crm-arbeidsforhold/pull/10'
    };
    const approvedPr = {
        ...pullRequest({ author: 'approved-author', mergedBy: 'merger' }),
        number: 11,
        base: { ref: 'main' },
        merge_commit_sha: approvedPrMerge,
        html_url: 'https://github.com/navikt/crm-arbeidsforhold/pull/11'
    };
    const requests = [];
    const createdIssues = [];
    const request = async (path, options = {}) => {
        requests.push({ path, options });
        if (path.startsWith('/repos/navikt/crm-arbeidsforhold/compare/')) {
            return {
                commits: [
                    { sha: firstPrCommit },
                    { sha: firstPrMerge },
                    { sha: approvedPrMerge },
                    { sha: directCommit }
                ]
            };
        }
        if (path.includes(`/commits/${firstPrCommit}/pulls`)) return [firstPr];
        if (path.includes(`/commits/${firstPrMerge}/pulls`)) return [firstPr];
        if (path.includes(`/commits/${approvedPrMerge}/pulls`)) return [approvedPr];
        if (path.includes(`/commits/${directCommit}/pulls`)) {
            return [
                { ...approvedPr, number: 12, merge_commit_sha: sha('b') },
                { ...approvedPr, number: 13, base: { ref: 'feature' } }
            ];
        }
        if (path === '/repos/navikt/crm-arbeidsforhold/pulls/10') return firstPr;
        if (path === '/repos/navikt/crm-arbeidsforhold/pulls/11') return approvedPr;
        if (path.includes('/pulls/10/reviews')) return [];
        if (path.includes('/pulls/11/reviews')) return [review('colleague', 'APPROVED')];
        if (path.startsWith('/search/issues?')) return { items: [] };
        if (path === '/repos/navikt/crm-arbeidsforhold/issues' && options.method === 'POST') {
            createdIssues.push(options.body);
            return { html_url: 'https://github.com/navikt/crm-arbeidsforhold/issues/50' };
        }
        throw new Error(`Unexpected request: ${path}`);
    };

    await auditPush({
        repository: 'navikt/crm-arbeidsforhold',
        before: sha('a'),
        after,
        serverUrl: 'https://github.com',
        request
    });

    assert.equal(requests.filter(({ path }) => path.endsWith('/pulls/10')).length, 1);
    assert.equal(requests.filter(({ path }) => path.endsWith('/pulls/11')).length, 1);
    assert.deepEqual(
        createdIssues.map(({ title }) => title),
        [`Review i etterkant: PR #10`, `Review i etterkant: push til main utan PR (${after.slice(0, 7)})`]
    );
    assert.match(createdIssues[1].body, new RegExp(directCommit));
});

test('single-SHA audit reports a bot-merged PR without sufficient review', async () => {
    const mergedSha = sha('6');
    const requestedPaths = [];
    const createdIssues = [];
    const pr = {
        ...pullRequest({ mergedBy: 'github-actions[bot]' }),
        number: 20,
        base: { ref: 'main' },
        merge_commit_sha: mergedSha,
        html_url: 'https://github.com/navikt/crm-arbeidsforhold/pull/20'
    };
    const request = async (path, options = {}) => {
        requestedPaths.push(path);
        if (path.startsWith(`/repos/navikt/crm-arbeidsforhold/commits/${mergedSha}/pulls`)) return [pr];
        if (path === '/repos/navikt/crm-arbeidsforhold/pulls/20') return pr;
        if (path.startsWith('/repos/navikt/crm-arbeidsforhold/pulls/20/reviews')) return [copilotReview()];
        if (path.startsWith('/search/issues?')) return { items: [] };
        if (path === '/repos/navikt/crm-arbeidsforhold/issues') {
            createdIssues.push(options.body);
            return { html_url: 'https://github.com/navikt/crm-arbeidsforhold/issues/51' };
        }
        throw new Error(`Unexpected request: ${path}`);
    };

    await auditPush({
        repository: 'navikt/crm-arbeidsforhold',
        after: mergedSha,
        serverUrl: 'https://github.com',
        request
    });

    assert.ok(
        requestedPaths.some((path) => path.startsWith(`/repos/navikt/crm-arbeidsforhold/commits/${mergedSha}/pulls`))
    );
    assert.equal(
        requestedPaths.some((path) => path.includes('/compare/')),
        false
    );
    assert.deepEqual(
        createdIssues.map(({ title }) => title),
        ['Review i etterkant: PR #20']
    );
});
