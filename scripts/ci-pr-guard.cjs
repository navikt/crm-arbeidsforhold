const { execFileSync } = require('node:child_process');
const fs = require('node:fs');
const { isDeepStrictEqual } = require('node:util');

const commitPattern = /^[a-f0-9]{40}$/;
const repositoryPattern = /^[A-Za-z0-9_.-]+\/[A-Za-z0-9_.-]+$/;
const safeNamePattern = /^[A-Za-z0-9_][A-Za-z0-9_. @/-]*$/;
const unsafeNames = new Set(['__proto__', 'constructor', 'prototype']);

function isCurrentPullRequest(pull, expected, repository) {
    if (
        !repositoryPattern.test(repository ?? '') ||
        !Number.isSafeInteger(expected?.number) ||
        expected.number <= 0 ||
        !commitPattern.test(expected.headSha ?? '') ||
        !commitPattern.test(expected.baseSha ?? '')
    ) {
        throw new Error('The expected PR snapshot is invalid.');
    }
    if (
        !pull ||
        pull.number !== expected.number ||
        typeof pull.state !== 'string' ||
        typeof pull.draft !== 'boolean' ||
        !commitPattern.test(pull.head?.sha ?? '') ||
        !commitPattern.test(pull.base?.sha ?? '') ||
        (pull.head?.repo !== null && typeof pull.head?.repo?.full_name !== 'string') ||
        typeof pull.base?.repo?.full_name !== 'string' ||
        typeof pull.base?.ref !== 'string'
    ) {
        throw new Error('The GitHub PR response is invalid.');
    }
    return (
        pull.state === 'open' &&
        pull.draft === false &&
        pull.head.sha === expected.headSha &&
        pull.base.sha === expected.baseSha &&
        pull.head.repo?.full_name === repository &&
        pull.base.repo?.full_name === repository &&
        pull.base.ref === 'main'
    );
}

function verifyRequiredPullRequestInvocation(event, expected, context) {
    const workflowPath = `${context?.repository}/.github/workflows/pull_request-validation1.yml@`;
    if (
        event?.number !== expected?.number ||
        context?.workflow !== '[PR] Validate' ||
        typeof context.workflowRef !== 'string' ||
        !context.workflowRef.startsWith(workflowPath) ||
        context.workflowRef.length === workflowPath.length ||
        context.ref !== `refs/pull/${expected?.number}/merge` ||
        !commitPattern.test(expected?.mergeSha ?? '') ||
        context.sha !== expected.mergeSha ||
        !isCurrentPullRequest(event.pull_request, expected, context.repository)
    ) {
        throw new Error('The required PR validation does not match the captured PR snapshot.');
    }
}

const waitingJobStatuses = new Set(['queued', 'waiting', 'pending', 'requested']);
const reuseJobSuffix = 'Validate on reusable org';

function queueRoute(runs, listJobs, current, limit = 2) {
    if (!Array.isArray(runs)) throw new Error('The workflow run list is invalid.');
    const ownKey = String(current.pullRequest);
    const waiting = new Set();
    for (const run of runs) {
        if (run?.id === current.runId) continue;
        const number = run?.pull_requests?.[0]?.number;
        const key = number
            ? String(number)
            : run?.head_branch === current.headBranch
              ? ownKey
              : `branch:${run?.head_branch}`;
        if (key === ownKey || waiting.has(key)) continue;
        const jobs = listJobs(run.id);
        if (!Array.isArray(jobs)) throw new Error('The workflow job list is invalid.');
        if (jobs.some((job) => job?.name?.endsWith(reuseJobSuffix) && waitingJobStatuses.has(job.status))) {
            waiting.add(key);
        }
    }
    const count = waiting.size;
    if (count >= limit) {
        return { route: 'fresh', waiting: count, reason: `${count} other PRs are waiting for the CI scratch org.` };
    }
    return { route: 'reuse', waiting: count, reason: '' };
}

function verifyMergeCommit(commits, mergeSha, baseSha, headSha) {
    if (
        !Array.isArray(commits) ||
        commits.length !== 3 ||
        [mergeSha, baseSha, headSha].some((sha) => !commitPattern.test(sha ?? '')) ||
        commits[0] !== mergeSha ||
        commits[1] !== baseSha ||
        commits[2] !== headSha
    ) {
        throw new Error('The checked-out PR merge commit does not match the captured base and head.');
    }
}

function assertSafeIndex(index) {
    if (typeof index !== 'string') throw new Error('The PR source index is invalid.');
    const entries = index.split('\0').filter(Boolean);
    if (entries.some((entry) => entry.startsWith('120000 ') || entry.startsWith('160000 '))) {
        throw new Error('PR source with symbolic links or submodules is not supported by the reusable validation.');
    }
    if (
        entries.some((entry) => {
            const filename = entry.slice(entry.indexOf('\t') + 1);
            return /^(?:\.sf|\.sfdx|node_modules)(?:\/|$)/.test(filename);
        })
    ) {
        throw new Error(
            'PR source with local Salesforce configuration or node_modules is not supported by the reusable validation.'
        );
    }
}

function assertSafeName(name, description) {
    if (typeof name !== 'string' || !safeNamePattern.test(name) || unsafeNames.has(name)) {
        throw new Error(`Invalid ${description}.`);
    }
}

function validatePrSource(project, trustedProject, index) {
    assertSafeIndex(index);
    if (
        !project ||
        !trustedProject ||
        !Array.isArray(project.packageDirectories) ||
        !project.packageDirectories.length
    ) {
        throw new Error('The PR Salesforce project configuration is invalid.');
    }
    if (project.sfdcLoginUrl !== trustedProject.sfdcLoginUrl) {
        throw new Error('The PR must not change the Salesforce login URL for the reusable validation.');
    }
    if (!isDeepStrictEqual(project.plugins, trustedProject.plugins)) {
        throw new Error('The PR must not change Salesforce CLI plugin configuration for the reusable validation.');
    }
    if (typeof project.sourceApiVersion !== 'string' || !/^\d+\.\d+$/.test(project.sourceApiVersion)) {
        throw new Error('The PR source API version is invalid.');
    }
    for (const directory of project.packageDirectories) {
        if (
            typeof directory?.path !== 'string' ||
            !directory.path.split('/').every((part) => /^[A-Za-z0-9_][A-Za-z0-9_. -]*$/.test(part))
        ) {
            throw new Error('The PR contains an unsafe package directory path.');
        }
        if (directory.dependencies !== undefined && !Array.isArray(directory.dependencies)) {
            throw new Error('The PR package dependencies are invalid.');
        }
        for (const dependency of directory.dependencies ?? []) {
            assertSafeName(dependency?.package, 'package name');
            if (
                dependency.versionNumber !== undefined &&
                (typeof dependency.versionNumber !== 'string' ||
                    !/^\d+\.\d+\.\d+\.(?:LATEST|NEXT|\d+)$/.test(dependency.versionNumber))
            ) {
                throw new Error('The PR package version is invalid.');
            }
        }
    }
    for (const [name, value] of Object.entries(project.packageAliases ?? {})) {
        assertSafeName(name, 'package alias');
        if (typeof value !== 'string' || !/^[A-Za-z0-9]+$/.test(value)) {
            throw new Error('The PR package alias value is invalid.');
        }
    }
    for (const [name, value] of Object.entries(project.packageKeyConfig ?? {})) {
        assertSafeName(name, 'package key configuration name');
        if (typeof value !== 'boolean') throw new Error('The PR package key configuration is invalid.');
    }
}

function githubApi(path, paginate = false) {
    const output = execFileSync('gh', ['api', path, ...(paginate ? ['--paginate', '--slurp'] : [])], {
        encoding: 'utf8',
        maxBuffer: 32 * 1024 * 1024
    });
    const response = JSON.parse(output);
    if (!paginate) return response;
    if (!Array.isArray(response)) throw new Error('The paginated GitHub response is invalid.');
    return response.flatMap((page) => {
        const items = paginate === true ? page : page?.[paginate];
        if (!Array.isArray(items)) throw new Error('The paginated GitHub response is invalid.');
        return items;
    });
}

function getCurrentPullRequest(args, repository) {
    if (!repositoryPattern.test(repository ?? '') || !/^[1-9]\d*$/.test(args[1] ?? '')) {
        throw new Error('The expected PR snapshot is invalid.');
    }
    const expected = { number: Number(args[1]), headSha: args[2], baseSha: args[3] };
    const pull = githubApi(`repos/${repository}/pulls/${expected.number}`);
    return isCurrentPullRequest(pull, expected, repository);
}

async function main(args) {
    if (args.length === 3 && args[0] === 'queue') {
        const repository = process.env.GITHUB_REPOSITORY;
        if (!repositoryPattern.test(repository ?? '') || !/^[1-9]\d*$/.test(args[1])) {
            throw new Error('The queue request is invalid.');
        }
        const current = { runId: Number(process.env.GITHUB_RUN_ID), pullRequest: Number(args[1]), headBranch: args[2] };
        let decision;
        try {
            const runs = ['in_progress', 'queued'].flatMap((status) =>
                githubApi(
                    `repos/${repository}/actions/workflows/pull_request-validation1.yml/runs?status=${status}&per_page=100`,
                    'workflow_runs'
                )
            );
            const listJobs = (runId) =>
                githubApi(`repos/${repository}/actions/runs/${runId}/jobs?filter=latest&per_page=100`, 'jobs');
            decision = queueRoute(runs, listJobs, current);
        } catch (error) {
            process.stderr.write(
                `::warning::Could not read the CI scratch org queue; keeping the reusable route. ${error.message}\n`
            );
            decision = { route: 'reuse', waiting: 0, reason: '' };
        }
        process.stdout.write(`${JSON.stringify(decision)}\n`);
        return;
    }
    if (args.length === 4 && (args[0] === 'current' || args[0] === 'verify-current')) {
        const current = getCurrentPullRequest(args, process.env.GITHUB_REPOSITORY);
        if (args[0] === 'verify-current' && !current) {
            throw new Error('The PR changed after the validation was queued.');
        }
        if (args[0] === 'current') process.stdout.write(`${JSON.stringify({ current })}\n`);
        return;
    }
    if (args.length === 5 && args[0] === 'verify-required') {
        if (!/^[1-9]\d*$/.test(args[1])) throw new Error('The expected PR snapshot is invalid.');
        const event = JSON.parse(fs.readFileSync(process.env.GITHUB_EVENT_PATH, 'utf8'));
        const expected = { number: Number(args[1]), headSha: args[2], baseSha: args[3], mergeSha: args[4] };
        const context = {
            repository: process.env.GITHUB_REPOSITORY,
            workflow: process.env.GITHUB_WORKFLOW,
            workflowRef: process.env.GITHUB_WORKFLOW_REF,
            ref: process.env.GITHUB_REF,
            sha: process.env.GITHUB_SHA
        };
        verifyRequiredPullRequestInvocation(event, expected, context);
        return;
    }
    if (args.length === 2 && args[0] === 'verify-source') {
        const index = execFileSync('git', ['ls-files', '--stage', '-z'], {
            encoding: 'utf8',
            maxBuffer: 64 * 1024 * 1024
        });
        assertSafeIndex(index);
        const project = JSON.parse(fs.readFileSync('sfdx-project.json', 'utf8'));
        const trustedProject = JSON.parse(fs.readFileSync(args[1], 'utf8'));
        validatePrSource(project, trustedProject, index);
        return;
    }
    if (args.length === 4 && args[0] === 'verify-snapshot') {
        const commits = execFileSync('git', ['rev-list', '--parents', '-n', '1', 'HEAD'], { encoding: 'utf8' })
            .trim()
            .split(/\s+/);
        verifyMergeCommit(commits, args[1], args[2], args[3]);
        return;
    }
    throw new Error(
        'Usage: ci-pr-guard.cjs queue <number> <head-branch> | current|verify-current <number> <head> <base> | verify-source <trusted-project-file> | verify-snapshot <merge> <base> <head>' +
            ' | verify-required <number> <head> <base> <merge>'
    );
}

if (require.main === module) {
    main(process.argv.slice(2)).catch((error) => {
        console.error(error.message);
        process.exitCode = 1;
    });
}

module.exports = {
    isCurrentPullRequest,
    queueRoute,
    validatePrSource,
    verifyRequiredPullRequestInvocation,
    verifyMergeCommit
};
