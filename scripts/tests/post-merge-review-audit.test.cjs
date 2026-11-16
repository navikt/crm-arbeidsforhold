const assert = require('node:assert/strict');
const { test } = require('node:test');
const { assessMergedPullRequest } = require('../post-merge-review-audit.cjs');

const headSha = 'head-sha';

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
