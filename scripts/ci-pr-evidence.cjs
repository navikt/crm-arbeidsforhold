const { execFileSync } = require('node:child_process');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { calculateCoverage, coverageRecords, getApexCoverageNames, readPlan } = require('./ci-scratch-plan.cjs');

const commitPattern = /^[a-f0-9]{40}$/;
const identifierPattern = /^[A-Za-z_][A-Za-z0-9_]*$/;
const methodPattern = /^[A-Za-z_][A-Za-z0-9_]*(?:\.[A-Za-z_][A-Za-z0-9_]*){1,2}$/;
const packageNamePattern = /^[A-Za-z0-9_][A-Za-z0-9_. @/-]*$/;

function nonNegativeInteger(value, description) {
    if (!(
        (typeof value === 'string' && /^\d+$/.test(value)) ||
        (typeof value === 'number' && Number.isSafeInteger(value) && value >= 0)
    )) {
        throw new Error(`Invalid ${description}.`);
    }
    const number = Number(value);
    if (!Number.isSafeInteger(number)) throw new Error(`Invalid ${description}.`);
    return number;
}

function checkedMethod(name) {
    if (typeof name !== 'string' || !methodPattern.test(name)) throw new Error('Invalid Apex test method name.');
    return name;
}

function checkedCoverageName(name) {
    if (typeof name !== 'string' || !identifierPattern.test(name)) throw new Error('Invalid Apex coverage name.');
    return name;
}

function coveredComponents(records, sourceNames) {
    const included = new Set(sourceNames);
    return records
        .filter((record) => included.has(record?.name))
        .map((record) => checkedCoverageName(record.name))
        .sort();
}

function extractDeployTests(data) {
    const result = data?.result?.details?.runTestResult;
    if (!result || typeof result !== 'object') throw new Error('Deployment test results are missing.');
    const reportedTestsRun = nonNegativeInteger(result.numTestsRun, 'deployment test count');
    if (nonNegativeInteger(result.numFailures, 'deployment test failure count') !== 0) {
        throw new Error('Deployment test results include failures.');
    }
    const successes =
        result.successes === undefined ? [] : Array.isArray(result.successes) ? result.successes : [result.successes];
    if (reportedTestsRun > 0 && successes.length === 0)
        throw new Error('Deployment test results are missing successful methods.');
    const methods = successes.map((record) => {
        const parts = [record?.namespace, record?.name, record?.methodName].filter(
            (part) => part != null && part !== ''
        );
        if (
            parts.length < 2 ||
            parts.length > 3 ||
            parts.some((part) => typeof part !== 'string' || !identifierPattern.test(part))
        ) {
            throw new Error('Invalid deployment test method name.');
        }
        return checkedMethod(parts.join('.'));
    });
    return { methods: methods.sort(), reportedTestsRun };
}

function extractApexTests(data) {
    const result = Array.isArray(data?.tests) ? data : data?.result;
    if (!result || !Array.isArray(result.tests) || !result.summary) throw new Error('Apex test results are missing.');
    const reportedTestsRun = nonNegativeInteger(result.summary.testsRan, 'Apex test count');
    const outcome = result.summary.outcome;
    if (typeof outcome !== 'string' || !/^[A-Za-z]+$/.test(outcome)) throw new Error('Invalid Apex test outcome.');
    const methods = [];
    const skipped = [];
    for (const record of result.tests) {
        const name = checkedMethod(record?.FullName);
        if (record.Outcome === 'Skip' || record.Outcome === 'Skipped') skipped.push(name);
        else if (record.Outcome === 'Pass' || record.Outcome === 'Fail' || record.Outcome === 'CompileFail')
            methods.push(name);
        else throw new Error('Invalid Apex test outcome.');
    }
    return { methods: methods.sort(), reportedTestsRun, outcome, skipped: skipped.sort() };
}

function summarizeApexFailure(data) {
    const errorType =
        typeof data?.name === 'string' && identifierPattern.test(data.name) ? data.name : 'SalesforceError';
    const tests = data?.result?.tests ?? data?.tests ?? [];
    if (!Array.isArray(tests)) throw new Error('The Salesforce Apex failure response has invalid test results.');
    const failingMethods = tests
        .filter((record) => record.Outcome === 'Fail' || record.Outcome === 'CompileFail')
        .map((record) => checkedMethod(record.FullName))
        .sort();
    return { errorType, failingMethods };
}

function logPayload(line) {
    const match = line.match(/\t\d{4}-\d\d-\d\dT[^\s]*Z (.*)$/);
    return match ? match[1] : line;
}

function extractCheckoutSha(log) {
    if (typeof log !== 'string') throw new Error('The checkout log is missing.');
    const lines = log.split(/\r?\n/);
    const shas = new Set();
    for (let index = 0; index < lines.length; index++) {
        if (!/\[command\].*\/git log -1 --format=%H\s*$/.test(logPayload(lines[index]))) continue;
        const sha = logPayload(lines[index + 1] ?? '').trim();
        if (!commitPattern.test(sha)) throw new Error('The baseline checkout commit could not be verified.');
        shas.add(sha);
    }
    if (shas.size !== 1) throw new Error('The baseline checkout commit could not be verified.');
    return [...shas][0];
}

function extractPackageVersions(log) {
    if (typeof log !== 'string') throw new Error('The package selection log is missing.');
    const packages = new Map();
    let current;
    for (const line of log.split(/\r?\n/)) {
        const payload = logPayload(line);
        if (payload.startsWith('Processing: ')) {
            if (current) throw new Error('The baseline package selection is incomplete.');
            current = payload.slice('Processing: '.length);
            if (!packageNamePattern.test(current) || packages.has(current)) {
                throw new Error('The baseline package selection is invalid.');
            }
        } else if (payload.startsWith('SubscriberPackageVersionId (selected): ')) {
            const versionId = payload.slice('SubscriberPackageVersionId (selected): '.length);
            if (!current || !/^[A-Za-z0-9]+$/.test(versionId)) {
                throw new Error('The baseline package selection is invalid.');
            }
            packages.set(current, versionId);
            current = undefined;
        }
    }
    if (current || packages.size === 0) throw new Error('The baseline package selection is incomplete.');
    return [...packages].map(([name, versionId]) => ({ name, versionId })).sort((a, b) => a.name.localeCompare(b.name));
}

function normalizedPackages(packages) {
    if (!Array.isArray(packages) || packages.length === 0) throw new Error('Package evidence is missing.');
    const seen = new Set();
    return packages
        .map(({ name, versionId }) => {
            if (
                typeof name !== 'string' ||
                !packageNamePattern.test(name) ||
                typeof versionId !== 'string' ||
                !/^[A-Za-z0-9]+$/.test(versionId) ||
                seen.has(name)
            ) {
                throw new Error('Package evidence is invalid.');
            }
            seen.add(name);
            return { name, versionId };
        })
        .sort((a, b) => a.name.localeCompare(b.name));
}

function multisetDifference(first, second, check) {
    const counts = new Map();
    for (const name of second) counts.set(check(name), (counts.get(name) ?? 0) + 1);
    const difference = [];
    for (const name of first) {
        check(name);
        const count = counts.get(name) ?? 0;
        if (count === 0) difference.push(name);
        else counts.set(name, count - 1);
    }
    return difference.sort();
}

function compareEvidence(baseline, pilot) {
    const reasons = [];
    if (
        !commitPattern.test(pilot?.source?.mergeSha ?? '') ||
        !Array.isArray(baseline?.checkoutShas) ||
        !baseline.checkoutShas.length
    ) {
        throw new Error('Source commit evidence is missing.');
    }
    if (baseline.checkoutShas.some((sha) => sha !== pilot.source.mergeSha)) {
        reasons.push('The baseline jobs and pilot did not use the same merge commit.');
    }
    if (JSON.stringify(normalizedPackages(baseline.packages)) !== JSON.stringify(normalizedPackages(pilot.packages))) {
        reasons.push('The selected package versions differ.');
    }
    if (baseline.tests?.outcome !== 'Passed') reasons.push('The baseline Apex tests did not pass.');
    if (!Array.isArray(baseline.tests?.methods) || !Array.isArray(pilot.tests?.methods)) {
        throw new Error('Test method evidence is missing.');
    }
    if (!Array.isArray(baseline.coverageComponents) || !Array.isArray(pilot.coverageComponents)) {
        throw new Error('Covered component evidence is missing.');
    }
    const baselineOnly = multisetDifference(baseline.tests.methods, pilot.tests.methods, checkedMethod);
    const pilotOnly = multisetDifference(pilot.tests.methods, baseline.tests.methods, checkedMethod);
    const baselineCoverageOnly = multisetDifference(
        baseline.coverageComponents,
        pilot.coverageComponents,
        checkedCoverageName
    );
    const pilotCoverageOnly = multisetDifference(
        pilot.coverageComponents,
        baseline.coverageComponents,
        checkedCoverageName
    );
    return {
        comparable: reasons.length === 0,
        reasons,
        baselineOnly,
        pilotOnly,
        sameMethods: baselineOnly.length === 0 && pilotOnly.length === 0,
        baselineCoverageOnly,
        pilotCoverageOnly,
        sameCoverageComponents: baselineCoverageOnly.length === 0 && pilotCoverageOnly.length === 0,
        baselineCoverage: baseline.coverage,
        pilotCoverage: pilot.coverage
    };
}

function readJson(filename) {
    return JSON.parse(fs.readFileSync(filename, 'utf8'));
}

function createEvidence(projectFile, planFile, sourceDirectory, resultFile, coverageFile, outputFile) {
    const route = process.env.CI_VALIDATION_ROUTE;
    if (route !== 'reuse' && route !== 'fresh') throw new Error('The pilot validation route is invalid.');
    const source = {
        headSha: process.env.PR_HEAD_SHA,
        baseSha: process.env.PR_BASE_SHA,
        mergeSha: process.env.PR_MERGE_SHA
    };
    if (Object.values(source).some((sha) => !commitPattern.test(sha ?? '')))
        throw new Error('The pilot source commits are invalid.');
    const repository = process.env.GITHUB_REPOSITORY;
    if (!/^[A-Za-z0-9_.-]+\/[A-Za-z0-9_.-]+$/.test(repository ?? ''))
        throw new Error('The pilot repository is invalid.');
    const number = nonNegativeInteger(process.env.PR_NUMBER, 'PR number');
    if (!number) throw new Error('The PR or baseline run reference is invalid.');
    let baseline;
    if (process.env.GITHUB_EVENT_NAME === 'workflow_run') {
        const runId = nonNegativeInteger(process.env.BASELINE_RUN_ID, 'baseline run ID');
        const attempt = nonNegativeInteger(process.env.BASELINE_ATTEMPT, 'baseline run attempt');
        if (!runId || !attempt) throw new Error('The PR or baseline run reference is invalid.');
        baseline = { runId, attempt };
    } else if (process.env.GITHUB_EVENT_NAME === 'pull_request') {
        if (process.env.BASELINE_RUN_ID || process.env.BASELINE_ATTEMPT) {
            throw new Error('The required PR validation cannot use a pilot baseline.');
        }
    } else {
        throw new Error('The PR validation event is invalid.');
    }

    const project = readJson(projectFile);
    const versions = readJson(planFile);
    const packages = normalizedPackages(readPlan(project, versions));
    const coverageNames = getApexCoverageNames(sourceDirectory).sort();
    coverageNames.forEach(checkedCoverageName);
    const result = resultFile === '-' ? null : readJson(resultFile);
    const tests = result
        ? route === 'reuse'
            ? extractDeployTests(result)
            : extractApexTests(result)
        : { methods: [], reportedTestsRun: 0 };
    const coverageData = coverageFile === '-' ? null : coverageRecords(readJson(coverageFile));
    const coverage = coverageData ? calculateCoverage(coverageData, coverageNames, 0) : null;
    const evidence = {
        schemaVersion: 1,
        repository,
        pullRequest: number,
        ...(baseline ? { baseline } : {}),
        source,
        route,
        packages,
        tests,
        coverage,
        coverageNames,
        coverageComponents: coverageData ? coveredComponents(coverageData, coverageNames) : []
    };
    fs.writeFileSync(outputFile, `${JSON.stringify(evidence, null, 2)}\n`, { flag: 'wx', mode: 0o600 });
    return evidence;
}

function runGh(args, options = {}) {
    return execFileSync('gh', args, { maxBuffer: 64 * 1024 * 1024, ...options });
}

function ghJson(args) {
    return JSON.parse(runGh(args, { encoding: 'utf8' }));
}

function listPages(endpoint) {
    const pages = ghJson(['api', endpoint, '--paginate', '--slurp']);
    if (
        !Array.isArray(pages) ||
        pages.some((page) => !Array.isArray(page) && !Array.isArray(page?.artifacts) && !Array.isArray(page?.jobs))
    ) {
        throw new Error('The paginated GitHub API response is invalid.');
    }
    return pages.flatMap((page) => (Array.isArray(page) ? page : (page.artifacts ?? page.jobs)));
}

function readArtifact(repository, runId, name, directory, entryPatterns, uploadJob) {
    const artifacts = listPages(`repos/${repository}/actions/runs/${runId}/artifacts?per_page=100`);
    const matches = artifacts.filter((artifact) => artifact.name === name && artifact.expired === false);
    if (matches.length !== 1) throw new Error(`Expected exactly one available ${name} artifact.`);
    if (uploadJob) {
        const uploads = (uploadJob.steps ?? []).filter(
            (step) => step.name === 'Upload Apex test results' && step.conclusion === 'success'
        );
        const created = Date.parse(matches[0].created_at);
        const started = Date.parse(uploads[0]?.started_at);
        const completed = Date.parse(uploads[0]?.completed_at);
        if (
            uploads.length !== 1 ||
            !Number.isFinite(created) ||
            !Number.isFinite(started) ||
            !Number.isFinite(completed) ||
            completed < started ||
            created < started ||
            created > completed
        ) {
            throw new Error('The baseline apex-tests artifact does not match the recorded workflow attempt.');
        }
    }
    const artifactId = nonNegativeInteger(matches[0].id, 'artifact ID');
    const archive = path.join(directory, `${artifactId}.zip`);
    fs.writeFileSync(archive, runGh(['api', `repos/${repository}/actions/artifacts/${artifactId}/zip`]), {
        flag: 'wx',
        mode: 0o600
    });
    const entries = execFileSync('unzip', ['-Z1', archive], { encoding: 'utf8', maxBuffer: 8 * 1024 * 1024 }).split(
        /\r?\n/
    );
    return entryPatterns.map((pattern) => {
        const matching = entries.filter((entry) => pattern.test(entry));
        if (matching.length !== 1) throw new Error(`Expected exactly one matching file in ${name}.`);
        return JSON.parse(
            execFileSync('unzip', ['-p', archive, matching[0]], { encoding: 'utf8', maxBuffer: 64 * 1024 * 1024 })
        );
    });
}

function readBaselineLog(repository, runId, attempt, job) {
    return runGh(
        [
            'run',
            'view',
            String(runId),
            '--repo',
            repository,
            '--attempt',
            String(attempt),
            '--job',
            String(job.id),
            '--log'
        ],
        {
            encoding: 'utf8'
        }
    );
}

function findSuccessfulJob(jobs, suffix) {
    const matches = jobs.filter((job) => typeof job.name === 'string' && job.name.endsWith(suffix));
    if (matches.length !== 1 || matches[0].conclusion !== 'success') {
        throw new Error(`The baseline ${suffix} job is missing, ambiguous or unsuccessful.`);
    }
    return matches[0];
}

function compareRuns(baselineRunId, pilotRunId) {
    const baselineId = nonNegativeInteger(baselineRunId, 'baseline run ID');
    const pilotId = nonNegativeInteger(pilotRunId, 'pilot run ID');
    if (!baselineId || !pilotId) throw new Error('Both GitHub Actions run IDs are required.');
    const repository = runGh(['repo', 'view', '--json', 'nameWithOwner', '--jq', '.nameWithOwner'], {
        encoding: 'utf8'
    }).trim();
    if (!/^[A-Za-z0-9_.-]+\/[A-Za-z0-9_.-]+$/.test(repository)) throw new Error('The GitHub repository is invalid.');
    const pilotRun = ghJson(['api', `repos/${repository}/actions/runs/${pilotId}`]);
    if (pilotRun.status !== 'completed' || pilotRun.conclusion !== 'success') {
        throw new Error('The pilot workflow must finish successfully before comparison.');
    }
    const pilotAttempt = nonNegativeInteger(pilotRun.run_attempt, 'pilot run attempt');
    const directory = fs.mkdtempSync(path.join(os.tmpdir(), 'ci-pr-pilot-compare-'));
    try {
        const [pilot] = readArtifact(repository, pilotId, `reusable-pr-pilot-evidence-${pilotAttempt}`, directory, [
            /^evidence\.json$/
        ]);
        if (
            pilot.schemaVersion !== 1 ||
            pilot.repository !== repository ||
            pilot.baseline?.runId !== baselineId ||
            !Number.isSafeInteger(pilot.baseline?.attempt) ||
            pilot.baseline.attempt <= 0
        ) {
            throw new Error('The pilot evidence does not belong to this repository and baseline run.');
        }
        const attempt = pilot.baseline.attempt;
        const baselineRun = ghJson(['api', `repos/${repository}/actions/runs/${baselineId}/attempts/${attempt}`]);
        if (
            baselineRun.name !== '[PR] Validate' ||
            baselineRun.path !== '.github/workflows/pull_request-validation1.yml' ||
            baselineRun.event !== 'pull_request' ||
            baselineRun.head_sha !== pilot.source?.headSha
        ) {
            throw new Error('The baseline workflow does not match the pilot PR revision.');
        }
        if (baselineRun.status !== 'completed' || baselineRun.conclusion !== 'success') {
            throw new Error('The baseline PR workflow must finish successfully before comparison.');
        }
        const jobs = listPages(`repos/${repository}/actions/runs/${baselineId}/attempts/${attempt}/jobs?per_page=100`);
        const setup = findSuccessfulJob(jobs, 'Salesforce validation / Setup');
        const compile = findSuccessfulJob(jobs, 'Salesforce validation / Compile Metadata');
        const test = findSuccessfulJob(jobs, 'Salesforce validation / Run Apex Tests');
        const setupLog = readBaselineLog(repository, baselineId, attempt, setup);
        const checkoutShas = [
            extractCheckoutSha(setupLog),
            extractCheckoutSha(readBaselineLog(repository, baselineId, attempt, compile)),
            extractCheckoutSha(readBaselineLog(repository, baselineId, attempt, test))
        ];
        const [baselineResults, coverageFile] = readArtifact(
            repository,
            baselineId,
            'apex-tests',
            directory,
            [/^test-result-(?!codecoverage\.json$)[A-Za-z0-9]+\.json$/, /^test-result-codecoverage\.json$/],
            test
        );
        if (
            !Array.isArray(pilot.coverageNames) ||
            !pilot.coverageNames.length ||
            pilot.coverageNames.some((name) => typeof name !== 'string' || !identifierPattern.test(name)) ||
            !Array.isArray(pilot.coverageComponents) ||
            !pilot.coverageComponents.length ||
            pilot.coverageComponents.some((name) => !pilot.coverageNames.includes(name)) ||
            !pilot.coverage
        ) {
            throw new Error('The pilot did not record comparable Apex coverage.');
        }
        const baselineCoverageRecords = coverageRecords(coverageFile);
        const baseline = {
            checkoutShas,
            packages: extractPackageVersions(setupLog),
            tests: extractApexTests(baselineResults),
            coverage: calculateCoverage(baselineCoverageRecords, pilot.coverageNames, 0),
            coverageComponents: coveredComponents(baselineCoverageRecords, pilot.coverageNames)
        };
        const summarizeTests = (tests) => ({
            recordedMethods: tests.methods.length,
            reportedTestsRun: tests.reportedTestsRun,
            skipped: Array.isArray(tests.skipped) ? tests.skipped.length : null
        });
        return {
            pullRequest: pilot.pullRequest,
            route: pilot.route,
            baselineTests: summarizeTests(baseline.tests),
            pilotTests: summarizeTests(pilot.tests),
            ...compareEvidence(baseline, pilot)
        };
    } finally {
        fs.rmSync(directory, { recursive: true, force: true });
    }
}

function main(args) {
    if (args.length === 7 && args[0] === 'create') {
        createEvidence(...args.slice(1));
        return;
    }
    if (args.length === 3 && args[0] === 'compare') {
        const result = compareRuns(args[1], args[2]);
        process.stdout.write(`${JSON.stringify(result, null, 2)}\n`);
        if (!result.comparable || !result.sameMethods || !result.sameCoverageComponents) process.exitCode = 1;
        return;
    }
    if (args.length === 2 && args[0] === 'failure') {
        let response;
        try {
            response = readJson(args[1]);
        } catch (error) {
            if (!(error instanceof SyntaxError)) throw error;
            throw new Error('Salesforce returned invalid JSON for the Apex test failure.');
        }
        process.stdout.write(`${JSON.stringify(summarizeApexFailure(response))}\n`);
        return;
    }
    throw new Error(
        'Usage: ci-pr-evidence.cjs create <project> <plan> <source> <tests> <coverage> <output> | compare <baseline-run-id> <pilot-run-id> | failure <response>'
    );
}

if (require.main === module) {
    try {
        main(process.argv.slice(2));
    } catch (error) {
        console.error(error.message);
        process.exitCode = 1;
    }
}

module.exports = {
    compareEvidence,
    extractApexTests,
    extractCheckoutSha,
    extractDeployTests,
    extractPackageVersions,
    summarizeApexFailure
};
