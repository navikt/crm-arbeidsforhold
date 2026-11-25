const crypto = require('node:crypto');
const { spawn } = require('node:child_process');
const fs = require('node:fs');
const path = require('node:path');

function verifyScratchOrg(orgId, expiration, records) {
    if (typeof orgId !== 'string' || typeof expiration !== 'string' || !Array.isArray(records)) {
        throw new Error('Cannot verify scratch org records.');
    }
    if (!/^[a-zA-Z0-9]{15}([a-zA-Z0-9]{3})?$/.test(orgId)) throw new Error('Invalid scratch org ID.');
    const matches = records.filter((record) => record.ScratchOrg === orgId.slice(0, 15) && record.Status === 'Active');
    return matches.length === 1 && matches[0].ExpirationDate === expiration;
}

function selectRoute({
    enabled,
    expectedOrgId,
    actualOrgId,
    expiration,
    expectedFingerprint,
    actualFingerprint,
    installed,
    plan,
    now = new Date()
}) {
    if (!Array.isArray(plan) || plan.length === 0 || plan.some((entry) => !entry?.versionId)) {
        throw new Error('Invalid package plan.');
    }
    if (!enabled || !expectedOrgId || !actualOrgId || !expectedFingerprint || !expiration) {
        return { route: 'fresh', reason: 'CI scratch org is not fully configured.' };
    }
    if (expectedOrgId !== actualOrgId) throw new Error('CI scratch org identity does not match the registered org.');
    if (expectedFingerprint !== actualFingerprint) return { route: 'fresh', reason: 'Scratch configuration changed.' };
    const expires = Date.parse(`${expiration}T00:00:00Z`);
    if (
        !Number.isFinite(expires) ||
        new Date(expires).toISOString().slice(0, 10) !== expiration ||
        expires - now.getTime() < 2 * 24 * 60 * 60 * 1000
    ) {
        return { route: 'fresh', reason: 'CI scratch org is expired or close to expiration.' };
    }
    if (!Array.isArray(installed)) throw new Error('Cannot verify installed package versions.');
    if (
        installed.some(
            (entry) => typeof entry?.SubscriberPackageVersionId !== 'string' || !entry.SubscriberPackageVersionId
        )
    ) {
        return { route: 'fresh', reason: 'Installed package versions cannot be verified.' };
    }
    const installedVersions = new Set(installed.map((entry) => entry.SubscriberPackageVersionId));
    const plannedVersions = new Set(plan.map((entry) => entry.versionId));
    if (
        installedVersions.size !== plannedVersions.size ||
        [...plannedVersions].some((versionId) => !installedVersions.has(versionId))
    ) {
        return { route: 'fresh', reason: 'Installed package versions do not exactly match the current plan.' };
    }
    return { route: 'reuse', reason: 'CI scratch org matches the package plan.' };
}

function readPlan(project, selectedVersions) {
    const plan = [];
    for (const directory of project.packageDirectories) {
        for (const dependency of directory.dependencies ?? []) {
            const record = selectedVersions[dependency.package];
            if (!record?.SubscriberPackageVersionId) {
                throw new Error(`Missing selected version for ${dependency.package}.`);
            }
            if (!plan.some((entry) => entry.name === dependency.package)) {
                plan.push({
                    name: dependency.package,
                    versionId: record.SubscriberPackageVersionId,
                    requiresKey: project.packageKeyConfig?.[dependency.package] !== false
                });
            }
        }
    }
    if (plan.length === 0) throw new Error('No package dependencies found.');
    return plan;
}

function scratchFingerprint(projectFile, definitionFile) {
    const project = JSON.parse(fs.readFileSync(projectFile, 'utf8'));
    return crypto
        .createHash('sha256')
        .update(fs.readFileSync(definitionFile))
        .update(project.sourceApiVersion ?? '')
        .digest('hex');
}

function getApexCoverageNames(sourceDirectory) {
    const names = new Set();
    const visit = (directory) => {
        for (const entry of fs.readdirSync(directory, { withFileTypes: true })) {
            const filename = path.join(directory, entry.name);
            if (entry.isDirectory()) visit(filename);
            else if (entry.isFile() && ['.cls', '.trigger'].includes(path.extname(entry.name).toLowerCase())) {
                names.add(path.basename(entry.name, path.extname(entry.name)));
            }
        }
    };
    visit(sourceDirectory);
    return [...names];
}

function getApexTestClassNames(sourceDirectory) {
    const names = new Set();
    const visit = (directory) => {
        for (const entry of fs.readdirSync(directory, { withFileTypes: true })) {
            const filename = path.join(directory, entry.name);
            if (entry.isDirectory()) visit(filename);
            else if (
                entry.isFile() &&
                entry.name.endsWith('.cls') &&
                /@IsTest\b/i.test(fs.readFileSync(filename, 'utf8'))
            ) {
                names.add(entry.name.slice(0, -4));
            }
        }
    };
    visit(sourceDirectory);
    return [...names];
}

function calculateCoverage(records, classNames, minimum = 85) {
    if (!Array.isArray(records) || !Array.isArray(classNames) || classNames.length === 0) {
        throw new Error('Apex coverage data and source classes are required.');
    }
    const included = new Set(classNames);
    let covered = 0;
    let total = 0;
    for (const record of records) {
        if (!included.has(record.name)) continue;
        const recordCovered = Number(record.totalCovered ?? record.numLocations - record.numLocationsNotCovered);
        const recordTotal = Number(record.totalLines ?? record.numLocations);
        if (
            !Number.isFinite(recordCovered) ||
            !Number.isFinite(recordTotal) ||
            recordTotal < 0 ||
            recordCovered < 0 ||
            recordCovered > recordTotal
        ) {
            throw new Error(`Invalid coverage data for ${record.name}.`);
        }
        covered += recordCovered;
        total += recordTotal;
    }
    if (total === 0) throw new Error('No Apex coverage records matched source classes.');
    const percentage = (covered / total) * 100;
    if (percentage < minimum) {
        throw new Error(`Repository Apex coverage ${percentage.toFixed(2)}% is below ${minimum}%.`);
    }
    return { covered, total, percentage };
}

function coverageRecords(data) {
    const records = Array.isArray(data)
        ? data
        : (data.result?.details?.runTestResult?.codeCoverage ??
          data.result?.codecoverage ??
          data.result?.codeCoverage ??
          data.codecoverage ??
          data.codeCoverage);
    if (!Array.isArray(records)) throw new Error('Apex coverage data is missing from the test result.');
    return records;
}

async function installPlan(plan, targetOrg, packageKey, run) {
    if (!Array.isArray(plan) || plan.length === 0 || !targetOrg || typeof run !== 'function') {
        throw new Error('A package plan, target org and command runner are required.');
    }
    for (const entry of plan) {
        if (!entry.name || !entry.versionId || typeof entry.requiresKey !== 'boolean') {
            throw new Error('Invalid package installation plan.');
        }
        if (entry.requiresKey && !packageKey) {
            throw new Error(`Package installation key is required for ${entry.name}.`);
        }
        const args = [
            'package',
            'install',
            '--target-org',
            targetOrg,
            '--package',
            entry.versionId,
            '--no-prompt',
            '--wait',
            '15',
            '--publish-wait',
            '10'
        ];
        if (entry.requiresKey) args.push('--installation-key', packageKey);
        try {
            await run(args);
        } catch (error) {
            const message = error instanceof Error ? error.message : String(error);
            throw new Error(
                `Failed to install ${entry.name} ${entry.versionId}: ${packageKey ? message.replaceAll(packageKey, '[REDACTED]') : message}`
            );
        }
    }
}

function readJson(filename) {
    return JSON.parse(fs.readFileSync(filename, 'utf8'));
}

function commandRunner(args, packageKey = '') {
    return new Promise((resolve, reject) => {
        const child = spawn('sf', args, { stdio: ['ignore', 'pipe', 'pipe'] });
        let stdout = '';
        let stderr = '';
        child.stdout.setEncoding('utf8');
        child.stderr.setEncoding('utf8');
        child.stdout.on('data', (chunk) => {
            stdout += chunk;
        });
        child.stderr.on('data', (chunk) => {
            stderr += chunk;
        });
        child.on('error', reject);
        child.on('close', (status) => {
            const redact = (value) => (packageKey ? value.replaceAll(packageKey, '[REDACTED]') : value);
            if (stdout) process.stdout.write(redact(stdout));
            if (stderr) process.stderr.write(redact(stderr));
            if (status !== 0) reject(new Error(`Salesforce CLI command failed with exit code ${status}.`));
            else resolve();
        });
    });
}

async function main(args) {
    const [command, ...values] = args;
    if (command === 'verify-scratch' && values.length === 1) {
        const records = readJson(values[0]).result?.records;
        if (!verifyScratchOrg(process.env.CI_SCRATCH_ORG_ID, process.env.CI_SCRATCH_ORG_EXPIRATION, records)) {
            throw new Error('No active scratch org matches its registered ID and expiration.');
        }
        return;
    }
    if (command === 'route' && values.length === 5) {
        const [projectFile, planFile, orgFile, installedFile, definitionFile] = values;
        const project = readJson(projectFile);
        const plan = readPlan(project, readJson(planFile));
        const org = readJson(orgFile).result;
        const installed = readJson(installedFile).result;
        const route = selectRoute({
            enabled: process.env.CI_FORCE_FRESH !== 'true',
            expectedOrgId: process.env.CI_SCRATCH_ORG_ID,
            actualOrgId: org?.id,
            expiration: process.env.CI_SCRATCH_ORG_EXPIRATION,
            expectedFingerprint: process.env.CI_SCRATCH_ORG_CONFIG_SHA256,
            actualFingerprint: scratchFingerprint(projectFile, definitionFile),
            installed,
            plan
        });
        process.stdout.write(`${JSON.stringify(route)}\n`);
        return;
    }
    if (command === 'install' && values.length === 3) {
        const [projectFile, planFile, targetOrg] = values;
        const plan = readPlan(readJson(projectFile), readJson(planFile));
        await installPlan(plan, targetOrg, process.env.CRM_PACKAGE_KEY ?? '', (installArgs) =>
            commandRunner(installArgs, process.env.CRM_PACKAGE_KEY ?? '')
        );
        return;
    }
    if (command === 'tests' && values.length === 1) {
        process.stdout.write(`${JSON.stringify(getApexTestClassNames(values[0]))}\n`);
        return;
    }
    if (command === 'coverage' && values.length === 2) {
        const [coverageFile, sourceDirectory] = values;
        const data = readJson(coverageFile);
        const result = calculateCoverage(coverageRecords(data), getApexCoverageNames(sourceDirectory));
        process.stdout.write(`${JSON.stringify(result)}\n`);
        return;
    }
    if (command === 'fingerprint' && values.length === 2) {
        process.stdout.write(`${scratchFingerprint(values[0], values[1])}\n`);
        return;
    }
    throw new Error('Usage: ci-scratch-plan.cjs verify-scratch|route|install|tests|coverage|fingerprint <arguments>');
}

if (require.main === module) {
    main(process.argv.slice(2)).catch((error) => {
        console.error(error.message);
        process.exitCode = 1;
    });
}

module.exports = {
    calculateCoverage,
    coverageRecords,
    getApexCoverageNames,
    getApexTestClassNames,
    installPlan,
    readPlan,
    scratchFingerprint,
    selectRoute,
    verifyScratchOrg
};
