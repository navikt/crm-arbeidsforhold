const { execFileSync } = require('node:child_process');
const fs = require('node:fs');
const { setTimeout: delay } = require('node:timers/promises');
const { isDeepStrictEqual } = require('node:util');

const commitPattern = /^[a-f0-9]{40}$/;
const safeNamePattern = /^[A-Za-z0-9_][A-Za-z0-9_. @/-]*$/;
const unsafeNames = new Set(['__proto__', 'constructor', 'prototype']);

function isEligiblePullRequest(pull, run, repository) {
    return (
        pull?.state === 'open' &&
        pull.draft === false &&
        pull.head?.sha === run.head_sha &&
        pull.head?.ref === run.head_branch &&
        pull.head?.repo?.full_name === repository &&
        pull.base?.ref === 'main' &&
        pull.base?.repo?.full_name === repository
    );
}

async function resolvePullRequest(run, repository, github) {
    if (!run || typeof repository !== 'string' || !/^[A-Za-z0-9_.-]+\/[A-Za-z0-9_.-]+$/.test(repository)) {
        throw new Error('A workflow run and repository are required.');
    }
    if (
        run.name !== '[PR] Validate' ||
        run.path !== '.github/workflows/pull_request-validation1.yml' ||
        run.event !== 'pull_request'
    ) {
        return { eligible: false, reason: 'The triggering run is not the PR validation workflow.' };
    }
    if (run.head_repository?.full_name !== repository) {
        return { eligible: false, reason: 'Fork PRs are excluded from the reusable-org pilot.' };
    }
    if (!commitPattern.test(run.head_sha ?? '') || typeof run.head_branch !== 'string' || !run.head_branch) {
        throw new Error('The triggering PR commit or branch is invalid.');
    }
    if (
        !Number.isSafeInteger(run.id) ||
        run.id <= 0 ||
        !Number.isSafeInteger(run.run_attempt) ||
        run.run_attempt <= 0
    ) {
        throw new Error('The triggering workflow run or attempt is invalid.');
    }
    if (!Array.isArray(run.pull_requests)) throw new Error('The workflow run PR references are missing.');

    const pulls = await github.list(run.head_sha);
    if (!Array.isArray(pulls)) throw new Error('The GitHub PR response is invalid.');
    const candidates = pulls.filter((pull) => isEligiblePullRequest(pull, run, repository));
    if (candidates.length === 0) {
        return { eligible: false, reason: 'No open, non-draft internal PR to main matches this run.' };
    }
    if (candidates.length !== 1) throw new Error('Multiple eligible PRs match the triggering workflow run.');
    const number = candidates[0].number;
    if (!Number.isSafeInteger(number) || number <= 0) throw new Error('The PR number is invalid.');

    const runReference = run.pull_requests.find((pull) => pull.number === number);
    if (run.pull_requests.length > 0 && (!runReference || runReference.head?.sha !== run.head_sha)) {
        return { eligible: false, reason: 'The triggering workflow run is associated with a different PR revision.' };
    }
    for (let attempt = 0; attempt < 10; attempt++) {
        const pull = await github.get(number);
        if (!isEligiblePullRequest(pull, run, repository)) {
            return { eligible: false, reason: 'The PR changed or closed before its merge commit was selected.' };
        }
        if (!commitPattern.test(pull.base?.sha ?? '')) throw new Error('The PR base commit is invalid.');
        if (runReference && runReference.base?.sha !== pull.base.sha) {
            return { eligible: false, reason: 'The PR base changed since the triggering workflow run.' };
        }
        if (pull.mergeable === false) {
            return { eligible: false, reason: 'The PR cannot currently be merged.' };
        }
        if (pull.mergeable === true && pull.merge_commit_sha !== null) {
            if (!commitPattern.test(pull.merge_commit_sha ?? '')) throw new Error('The PR merge commit is invalid.');
            return {
                eligible: true,
                number,
                headSha: run.head_sha,
                baseSha: pull.base.sha,
                mergeSha: pull.merge_commit_sha,
                baselineRunId: run.id,
                baselineAttempt: run.run_attempt
            };
        }
        if (pull.mergeable !== null && pull.mergeable !== true) throw new Error('The PR merge status is invalid.');
        if (attempt < 9) await github.wait();
    }
    throw new Error('GitHub did not finish calculating the PR merge commit.');
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
        throw new Error('PR source with symbolic links or submodules is not supported by this pilot.');
    }
    if (
        entries.some((entry) => {
            const filename = entry.slice(entry.indexOf('\t') + 1);
            return /^(?:\.sf|\.sfdx|node_modules)(?:\/|$)/.test(filename);
        })
    ) {
        throw new Error(
            'PR source with local Salesforce configuration or node_modules is not supported by this pilot.'
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
        throw new Error('The PR must not change the Salesforce login URL for this pilot.');
    }
    if (!isDeepStrictEqual(project.plugins, trustedProject.plugins)) {
        throw new Error('The PR must not change Salesforce CLI plugin configuration for this pilot.');
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
    if (!Array.isArray(response) || response.some((page) => !Array.isArray(page))) {
        throw new Error('The paginated GitHub PR response is invalid.');
    }
    return response.flat();
}

async function main(args) {
    if (args.length === 1 && args[0] === 'resolve') {
        const event = JSON.parse(fs.readFileSync(process.env.GITHUB_EVENT_PATH, 'utf8'));
        const repository = process.env.GITHUB_REPOSITORY;
        const github = {
            list: (sha) => githubApi(`repos/${repository}/commits/${sha}/pulls?per_page=100`, true),
            get: (number) => githubApi(`repos/${repository}/pulls/${number}`),
            wait: () => delay(2000)
        };
        process.stdout.write(`${JSON.stringify(await resolvePullRequest(event.workflow_run, repository, github))}\n`);
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
        'Usage: ci-pr-pilot.cjs resolve | verify-source <trusted-project-file> | verify-snapshot <merge> <base> <head>'
    );
}

if (require.main === module) {
    main(process.argv.slice(2)).catch((error) => {
        console.error(error.message);
        process.exitCode = 1;
    });
}

module.exports = { resolvePullRequest, validatePrSource, verifyMergeCommit };
