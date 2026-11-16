const COPILOT_REVIEWERS = new Set(['copilot-pull-request-reviewer[bot]', 'Copilot']);
const DECISIVE_STATES = new Set(['APPROVED', 'CHANGES_REQUESTED', 'DISMISSED']);
const ZERO_SHA = '0'.repeat(40);

function assessMergedPullRequest(pullRequest, reviews) {
    const author = pullRequest.user.login;
    const mergedAt = Date.parse(pullRequest.merged_at);
    const reviewsBeforeMerge = reviews
        .filter((review) => review.submitted_at && Date.parse(review.submitted_at) <= mergedAt)
        .sort((first, second) => Date.parse(first.submitted_at) - Date.parse(second.submitted_at));

    const latestHumanStates = new Map();
    for (const review of reviewsBeforeMerge) {
        const login = review.user?.login;
        if (!login || login === author || review.user.type === 'Bot' || !DECISIVE_STATES.has(review.state)) {
            continue;
        }
        latestHumanStates.set(login, review.state);
    }
    const states = [...latestHumanStates.values()];
    if (states.includes('APPROVED')) {
        return { followUpRequired: false, reason: 'Godkjend av ein annan person før merge.' };
    }

    const selfMerged = pullRequest.merged_by?.login === author;
    const copilotReviewedMergedCommit = reviewsBeforeMerge.some(
        (review) => COPILOT_REVIEWERS.has(review.user?.login) && review.commit_id === pullRequest.head.sha
    );
    if (selfMerged && copilotReviewedMergedCommit) {
        return { followUpRequired: false, reason: 'Eigen PR merga med Copilot-review av siste commit.' };
    }
    return {
        followUpRequired: true,
        reason: selfMerged
            ? 'Eigen PR merga utan godkjenning frå ein annan person og utan Copilot-review av siste commit.'
            : 'Merga utan godkjenning frå ein annan person. Copilot-review er ikkje nok når andre merger PR-en.'
    };
}

async function githubRequest(path, { method = 'GET', body } = {}) {
    const response = await fetch(`https://api.github.com${path}`, {
        method,
        headers: {
            Accept: 'application/vnd.github+json',
            Authorization: `Bearer ${process.env.GITHUB_TOKEN}`,
            'X-GitHub-Api-Version': '2022-11-28',
            ...(body ? { 'Content-Type': 'application/json' } : {})
        },
        body: body ? JSON.stringify(body) : undefined
    });
    if (!response.ok) {
        throw new Error(`GitHub API ${method} ${path} failed with status ${response.status}.`);
    }
    return response.json();
}

async function listReviews(repository, number, request = githubRequest) {
    const reviews = [];
    for (let page = 1; ; page += 1) {
        const batch = await request(`/repos/${repository}/pulls/${number}/reviews?per_page=100&page=${page}`);
        reviews.push(...batch);
        if (batch.length < 100) {
            return reviews;
        }
    }
}

async function createIssueOnce(repository, title, body, request = githubRequest) {
    const query = encodeURIComponent(`repo:${repository} is:issue in:title "${title}"`);
    const existing = await request(`/search/issues?q=${query}`);
    if (existing.items.some((issue) => issue.title === title)) {
        console.log(`Issue already exists: ${title}`);
        return;
    }
    const issue = await request(`/repos/${repository}/issues`, { method: 'POST', body: { title, body } });
    console.log(`Created ${issue.html_url}`);
}

async function listPushedCommits(repository, before, after, request) {
    if (!before || before === ZERO_SHA || before === after) {
        return [after];
    }

    const commits = [];
    for (let page = 1; ; page += 1) {
        const comparison = await request(`/repos/${repository}/compare/${before}...${after}?per_page=100&page=${page}`);
        commits.push(...comparison.commits.map(({ sha }) => sha));
        if (comparison.commits.length < 100) {
            return commits;
        }
    }
}

async function listMergedPullRequestsForCommit(repository, sha, commitShas, request) {
    const pulls = [];
    for (let page = 1; ; page += 1) {
        const batch = await request(`/repos/${repository}/commits/${sha}/pulls?per_page=100&page=${page}`);
        pulls.push(
            ...batch.filter(
                (pull) => pull.merged_at && pull.base?.ref === 'main' && commitShas.has(pull.merge_commit_sha)
            )
        );
        if (batch.length < 100) {
            return pulls;
        }
    }
}

async function auditPush({ repository, before, after, serverUrl, request = githubRequest }) {
    const commitShas = new Set(await listPushedCommits(repository, before, after, request));
    const mergedPullRequests = new Map();
    const directCommitShas = [];

    for (const sha of commitShas) {
        const pulls = await listMergedPullRequestsForCommit(repository, sha, commitShas, request);
        if (pulls.length === 0) {
            directCommitShas.push(sha);
        }
        for (const pull of pulls) {
            mergedPullRequests.set(pull.number, pull);
        }
    }

    for (const { number } of mergedPullRequests.values()) {
        const pullRequest = await request(`/repos/${repository}/pulls/${number}`);
        const result = assessMergedPullRequest(pullRequest, await listReviews(repository, number, request));
        console.log(`PR #${number}: ${result.reason}`);
        if (result.followUpRequired) {
            await createIssueOnce(
                repository,
                `Review i etterkant: PR #${number}`,
                [
                    `${pullRequest.html_url} blei merga til \`main\` utan tilstrekkeleg review.`,
                    '',
                    `- Forfattar: @${pullRequest.user.login}`,
                    `- Merga av: @${pullRequest.merged_by?.login ?? 'ukjend'}`,
                    `- Årsak: ${result.reason}`,
                    '',
                    'Ein annan person frå teamet må gå gjennom PR-en, kommentere funn og lukke issuet når reviewen er gjord.'
                ].join('\n'),
                request
            );
        }
    }

    if (directCommitShas.length > 0) {
        const commits = directCommitShas.map((sha) => `- ${serverUrl}/${repository}/commit/${sha}`).join('\n');
        await createIssueOnce(
            repository,
            `Review i etterkant: push til main utan PR (${after.slice(0, 7)})`,
            `Desse commitane kom på \`main\` utan ein merga PR, og har difor ikkje fått review:\n\n${commits}\n\nEin person frå teamet må gå gjennom endringane og lukke issuet.`,
            request
        );
    }
}

async function main() {
    const {
        GITHUB_REPOSITORY: repository,
        GITHUB_SHA: sha,
        GITHUB_EVENT_BEFORE: before,
        AUDIT_SHA: auditSha,
        GITHUB_SERVER_URL: serverUrl
    } = process.env;
    if (!repository || !sha || !process.env.GITHUB_TOKEN) {
        throw new Error('GITHUB_REPOSITORY, GITHUB_SHA and GITHUB_TOKEN are required.');
    }
    const targetSha = auditSha || sha;
    if (!/^[a-f0-9]{40}$/i.test(targetSha)) {
        throw new Error('The audit commit SHA must be a 40-character hexadecimal value.');
    }
    if (before && before !== ZERO_SHA && !/^[a-f0-9]{40}$/i.test(before)) {
        throw new Error('The push-before SHA must be a 40-character hexadecimal value.');
    }
    await auditPush({ repository, before, after: targetSha, serverUrl });
}

if (require.main === module) {
    main().catch((error) => {
        console.error(error.message);
        process.exitCode = 1;
    });
}

module.exports = { assessMergedPullRequest, auditPush };
