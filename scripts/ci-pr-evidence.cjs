const fs = require('node:fs');
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

function readJson(filename) {
    return JSON.parse(fs.readFileSync(filename, 'utf8'));
}

function createEvidence(projectFile, planFile, sourceDirectory, resultFile, coverageFile, outputFile) {
    const route = process.env.CI_VALIDATION_ROUTE;
    if (route !== 'reuse' && route !== 'fresh') throw new Error('The validation route is invalid.');
    const source = {
        headSha: process.env.PR_HEAD_SHA,
        baseSha: process.env.PR_BASE_SHA,
        mergeSha: process.env.PR_MERGE_SHA
    };
    if (Object.values(source).some((sha) => !commitPattern.test(sha ?? '')))
        throw new Error('The PR source commits are invalid.');
    const repository = process.env.GITHUB_REPOSITORY;
    if (!/^[A-Za-z0-9_.-]+\/[A-Za-z0-9_.-]+$/.test(repository ?? '')) throw new Error('The repository is invalid.');
    const number = nonNegativeInteger(process.env.PR_NUMBER, 'PR number');
    if (!number) throw new Error('The PR reference is invalid.');
    if (process.env.GITHUB_EVENT_NAME !== 'pull_request') throw new Error('The PR validation event is invalid.');

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

function main(args) {
    if (args.length === 7 && args[0] === 'create') {
        createEvidence(...args.slice(1));
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
        'Usage: ci-pr-evidence.cjs create <project> <plan> <source> <tests> <coverage> <output> | failure <response>'
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
    extractApexTests,
    extractDeployTests,
    summarizeApexFailure
};
