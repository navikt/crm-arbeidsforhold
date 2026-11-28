const crypto = require('node:crypto');
const { spawn } = require('node:child_process');
const fs = require('node:fs');
const path = require('node:path');

const EXCLUDED_SOURCE_DIRECTORIES = new Set(['unpackagable', 'unpackagable-with-auto-deploy', 'scratch-org']);

function verifyScratchOrg(orgId, expiration, records) {
    if (typeof orgId !== 'string' || typeof expiration !== 'string' || !Array.isArray(records)) {
        throw new Error('Cannot verify scratch org records.');
    }
    if (!/^[a-zA-Z0-9]{15}([a-zA-Z0-9]{3})?$/.test(orgId)) throw new Error('Invalid scratch org ID.');
    const matches = records.filter((record) => record.ScratchOrg === orgId.slice(0, 15) && record.Status === 'Active');
    return matches.length === 1 && matches[0].ExpirationDate === expiration;
}

function compareInstalledVersions(plan, installed) {
    if (!Array.isArray(installed)) throw new Error('Cannot verify installed package versions.');
    if (
        installed.some(
            (entry) => typeof entry?.SubscriberPackageVersionId !== 'string' || !entry.SubscriberPackageVersionId
        )
    ) {
        return { reason: 'Installed package versions cannot be verified.' };
    }
    const installedVersions = new Set(installed.map((entry) => entry.SubscriberPackageVersionId));
    const plannedVersions = new Set(plan.map((entry) => entry.versionId));
    const missing = plan.filter((entry) => !installedVersions.has(entry.versionId));
    const unexpected = [...installedVersions].filter((versionId) => !plannedVersions.has(versionId));
    if (missing.length || unexpected.length) {
        return {
            reason: 'Installed package versions do not exactly match the current plan.',
            missing,
            unexpected
        };
    }
    return null;
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
    if (expectedOrgId !== actualOrgId) {
        return {
            route: 'fresh',
            reason: 'The CI scratch org registration is incomplete: the secret and variables point at different orgs.'
        };
    }
    if (expectedFingerprint !== actualFingerprint) return { route: 'fresh', reason: 'Scratch configuration changed.' };
    const expires = Date.parse(`${expiration}T00:00:00Z`);
    if (
        !Number.isFinite(expires) ||
        new Date(expires).toISOString().slice(0, 10) !== expiration ||
        expires - now.getTime() < 2 * 24 * 60 * 60 * 1000
    ) {
        return { route: 'fresh', reason: 'CI scratch org is expired or close to expiration.' };
    }
    const mismatch = compareInstalledVersions(plan, installed);
    if (mismatch) return { route: 'fresh', reason: mismatch.reason };
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
                    ...(typeof record.Package2Id === 'string' ? { packageId: record.Package2Id } : {}),
                    ...(typeof record.SubscriberPackageId === 'string'
                        ? { subscriberPackageId: record.SubscriberPackageId }
                        : {}),
                    requiresKey: project.packageKeyConfig?.[dependency.package] !== false
                });
            }
        }
    }
    if (plan.length === 0) throw new Error('No package dependencies found.');
    return plan;
}

function addSubscriberPackageIds(selectedVersions, packageRecords) {
    if (!selectedVersions || typeof selectedVersions !== 'object' || Array.isArray(selectedVersions)) {
        throw new Error('Cannot map subscriber package IDs without a selected package plan.');
    }
    if (!Array.isArray(packageRecords)) throw new Error('Cannot read subscriber package IDs from Package2 records.');

    const plannedIds = new Set(
        Object.values(selectedVersions)
            .map((record) => record?.Package2Id)
            .filter((id) => typeof id === 'string')
    );
    const subscriberIds = new Map();
    for (const record of packageRecords) {
        if (!plannedIds.has(record?.Id)) continue;
        if (
            typeof record.SubscriberPackageId !== 'string' ||
            !/^033[a-zA-Z0-9]{12}([a-zA-Z0-9]{3})?$/.test(record.SubscriberPackageId)
        ) {
            throw new Error(`Package2 record ${record.Id} has no valid SubscriberPackageId.`);
        }
        subscriberIds.set(record.Id, record.SubscriberPackageId);
    }

    return Object.fromEntries(
        Object.entries(selectedVersions).map(([name, record]) => {
            if (
                typeof record?.Package2Id !== 'string' ||
                !/^0Ho[a-zA-Z0-9]{12}([a-zA-Z0-9]{3})?$/.test(record.Package2Id)
            ) {
                throw new Error(`Package ${name} has no valid Package2Id.`);
            }
            const subscriberPackageId = subscriberIds.get(record.Package2Id);
            if (!subscriberPackageId) {
                throw new Error(`Missing SubscriberPackageId for planned package ${record.Package2Id}.`);
            }
            return [name, { ...record, SubscriberPackageId: subscriberPackageId }];
        })
    );
}

function stageDeployableSource(sourceDirectory, destinationDirectory) {
    if (!fs.statSync(sourceDirectory).isDirectory()) throw new Error('Salesforce source path must be a directory.');
    fs.mkdirSync(path.dirname(destinationDirectory), { recursive: true });
    fs.cpSync(sourceDirectory, destinationDirectory, {
        recursive: true,
        filter(source) {
            const relative = path.relative(sourceDirectory, source);
            const firstSegment = relative.split(path.sep)[0];
            return !EXCLUDED_SOURCE_DIRECTORIES.has(firstSegment);
        }
    });
    return destinationDirectory;
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

function globToRegExp(pattern) {
    let source = '';
    for (let index = 0; index < pattern.length; index++) {
        const character = pattern[index];
        if (character === '*' && pattern[index + 1] === '*') {
            const slash = pattern[index + 2] === '/';
            source += slash ? '(?:.*/)?' : '.*';
            index += slash ? 2 : 1;
        } else if (character === '*') source += '[^/]*';
        else if (character === '?') source += '[^/]';
        else source += character.replace(/[.+^${}()|[\]\\]/g, '\\$&');
    }
    return new RegExp(`^${pattern.includes('/') ? '' : '(?:.*/)?'}${source.replace(/^\//, '')}$`);
}

function isForceIgnored(file, patterns) {
    const parts = file.split('/');
    const candidates = parts.map((_, index) => parts.slice(0, index + 1).join('/'));
    let ignored = false;
    for (const line of patterns) {
        const pattern = line.trim();
        if (!pattern || pattern.startsWith('#')) continue;
        const negated = pattern.startsWith('!');
        const rule = negated ? pattern.slice(1) : pattern;
        const directoryOnly = rule.endsWith('/');
        const expression = globToRegExp(directoryOnly ? rule.replace(/\/+$/, '') : rule);
        const scope = directoryOnly ? candidates.slice(0, -1) : candidates;
        if (scope.some((candidate) => expression.test(candidate))) ignored = !negated;
    }
    return ignored;
}

function stripApexComments(source) {
    return source.replace(/'(?:\\.|[^'\\\n])*'|\/\*[\s\S]*?\*\/|\/\/[^\n]*/g, (match) =>
        match.startsWith("'") ? match : match.replace(/[^\n]/g, '')
    );
}

function missingCoverageFromList(changedFile, records) {
    if (!changedFile) return [];
    const changed = fs.readFileSync(changedFile, 'utf8').split(/\r?\n/).filter(Boolean);
    const ignore = fs.existsSync('.forceignore') ? fs.readFileSync('.forceignore', 'utf8').split(/\r?\n/) : [];
    return changedSourcesWithoutCoverage(changed, records, '.', ignore);
}

function changedSourcesWithoutCoverage(changedFiles, records, root, ignorePatterns = []) {
    if (!Array.isArray(changedFiles) || !Array.isArray(records))
        throw new Error('Changed files and coverage data are required.');
    const covered = new Set(records.map((record) => record?.name));
    const missing = [];
    for (const file of changedFiles) {
        const extension = path.extname(file).toLowerCase();
        if (!['.cls', '.trigger'].includes(extension)) continue;
        const name = path.basename(file, path.extname(file));
        if (covered.has(name) || isForceIgnored(file, ignorePatterns)) continue;
        const filename = path.join(root, file);
        if (!fs.existsSync(filename)) continue;
        const source = stripApexComments(fs.readFileSync(filename, 'utf8'));
        const declaration = source.replace(/'(?:\\.|[^'\\\n])*'/g, "''").split(/\bclass\b/i)[0];
        if (extension === '.cls' && /@IsTest\b/i.test(declaration)) continue;
        if (/^\s*(?:@\w+(?:\([^)]*\))?\s*)*(?:(?:public|global|private)\s+)?interface\s/i.test(source)) continue;
        const lines = source.split(/\r?\n/).filter((line) => line.includes(';')).length;
        if (lines > 0) missing.push({ name, path: file, lines });
    }
    return missing.sort((first, second) => first.name.localeCompare(second.name));
}

function coverageMarkdown(result, minimum = 85) {
    const passed = result.percentage >= minimum;
    const lines = [
        '### Apex coverage',
        '',
        '| Check | Result |',
        '| --- | --- |',
        `| Repository coverage | ${passed ? '✅' : '❌'} ${result.percentage.toFixed(2)}% (${result.covered}/${result.total} lines, minimum ${minimum}%) |`
    ];
    if (result.missing.length) {
        lines.push(
            '',
            'Changed Apex sources without coverage data are counted as 0%:',
            '',
            '| File | Estimated lines |',
            '| --- | --- |'
        );
        for (const entry of result.missing) lines.push(`| ⚠️ ingen dekningsdata: \`${entry.path}\` | ${entry.lines} |`);
    }
    return `${lines.join('\n')}\n\n`;
}

function calculateCoverage(records, classNames, minimum = 85, missing = []) {
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
    for (const entry of missing) total += entry.lines;
    if (total === 0) throw new Error('No Apex coverage records matched source classes.');
    const percentage = (covered / total) * 100;
    if (percentage < minimum) {
        const note = missing.length
            ? ` This includes ${missing.length} changed Apex source${missing.length === 1 ? '' : 's'} without coverage data counted as 0%: ${missing.map((entry) => entry.name).join(', ')}.`
            : '';
        throw new Error(`Repository Apex coverage ${percentage.toFixed(2)}% is below ${minimum}%.${note}`);
    }
    return { covered, total, percentage, missing };
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

function installArguments(entry, targetOrg, packageKey) {
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
    return args;
}

async function installPackageVersions(plan, targetOrg, packageKey, run) {
    if (!Array.isArray(plan) || plan.length === 0 || !targetOrg || typeof run !== 'function') {
        throw new Error('A package plan, target org and command runner are required.');
    }
    for (const entry of plan) {
        try {
            await run(installArguments(entry, targetOrg, packageKey));
        } catch (error) {
            const message = error instanceof Error ? error.message : String(error);
            throw new Error(
                `Failed to install ${entry.name} ${entry.versionId}: ${packageKey ? message.replaceAll(packageKey, '[REDACTED]') : message}`
            );
        }
    }
}

async function readInstalledPackages(targetOrg, packageKey, run) {
    let output;
    try {
        output = await run(['package', 'installed', 'list', '--target-org', targetOrg, '--json'], { quiet: true });
    } catch (error) {
        const message = error instanceof Error ? error.message : String(error);
        throw new Error(
            `Could not verify installed package versions: ${packageKey ? message.replaceAll(packageKey, '[REDACTED]') : message}`
        );
    }
    let response;
    try {
        response = JSON.parse(output);
    } catch (error) {
        if (!(error instanceof SyntaxError)) throw error;
        throw new Error('Could not parse installed package list returned by Salesforce CLI.');
    }
    if (response?.status !== undefined && response.status !== 0) {
        throw new Error('Salesforce CLI returned a failed installed package list response.');
    }
    return response?.result;
}

function packageMismatchMessage(mismatch) {
    const details = [];
    if (mismatch.missing?.length) {
        details.push(`Missing: ${mismatch.missing.map((entry) => `${entry.name} (${entry.versionId})`).join(', ')}.`);
    }
    if (mismatch.unexpected?.length) {
        details.push(`Unexpected: ${mismatch.unexpected.join(', ')}.`);
    }
    return [mismatch.reason, ...details].join(' ');
}

async function installPlan(plan, targetOrg, packageKey, run) {
    await installPackageVersions(plan, targetOrg, packageKey, run);
    const installed = await readInstalledPackages(targetOrg, packageKey, run);
    const mismatch = compareInstalledVersions(plan, installed);
    if (mismatch) {
        throw new Error(packageMismatchMessage(mismatch));
    }
}

async function reconcileInstalledPackages(plan, installed, targetOrg, packageKey, run) {
    if (!Array.isArray(plan) || plan.length === 0 || !targetOrg || typeof run !== 'function') {
        throw new Error('A package plan, target org and command runner are required.');
    }
    const mismatch = compareInstalledVersions(plan, installed);
    if (!mismatch) return { changed: [] };

    if (plan.some((entry) => !entry.subscriberPackageId)) {
        throw new Error('Package versions cannot be reconciled safely without SubscriberPackageId mappings.');
    }
    const plannedPackageIds = new Set(plan.map((entry) => entry.subscriberPackageId));
    const expectedVersions = new Set(plan.map((entry) => entry.versionId));
    const unexpectedPackages = installed.filter(
        (entry) =>
            !expectedVersions.has(entry.SubscriberPackageVersionId) &&
            (!entry.SubscriberPackageId || !plannedPackageIds.has(entry.SubscriberPackageId))
    );
    if (unexpectedPackages.length) {
        throw new Error('Package versions cannot be reconciled in place; a replacement org is required.');
    }

    const missingVersions = new Set(mismatch.missing.map((entry) => entry.versionId));
    const updates = plan.filter((entry) => missingVersions.has(entry.versionId));
    if (updates.length === 0) {
        throw new Error('Package versions cannot be reconciled in place; a replacement org is required.');
    }

    await installPackageVersions(updates, targetOrg, packageKey, run);
    const updated = await readInstalledPackages(targetOrg, packageKey, run);
    const remaining = compareInstalledVersions(plan, updated);
    if (remaining) {
        throw new Error(`Package versions cannot be reconciled in place. ${packageMismatchMessage(remaining)}`);
    }
    return { changed: updates.map((entry) => entry.name) };
}

function readJson(filename) {
    return JSON.parse(fs.readFileSync(filename, 'utf8'));
}

function diagnosticSecrets(environment = process.env) {
    return Object.entries(environment)
        .filter(
            ([name, value]) =>
                /KEY|TOKEN|PASSWORD|SECRET|AUTH_URL/i.test(name) && typeof value === 'string' && value.length >= 4
        )
        .map(([, value]) => value);
}

function safeDiagnostics(messages, secrets) {
    return [...new Set(messages.filter((message) => typeof message === 'string' && message.trim()))]
        .slice(0, 30)
        .map((message) => {
            let safe = message;
            for (const secret of secrets) {
                if (secret) safe = safe.replaceAll(secret, '[REDACTED]');
            }
            return safe
                .replace(/\b(?:force|https?):\/\/\S+/gi, '[URL REDACTED]')
                .replace(
                    /\b(access[_-]?token|refresh[_-]?token|client[_-]?secret|password|authorization)\s*[:=]\s*(?:bearer\s+)?(?:"[^"]*"|'[^']*'|\S+)/gi,
                    '$1=[REDACTED]'
                )
                .replace(/\b\d{11}\b/g, '[REDACTED]')
                .replace(/[\x00-\x1f\x7f]/g, ' ')
                .replaceAll('::', ': :')
                .slice(0, 1000);
        })
        .join('\n');
}

function deploymentDiagnostics(output, secrets = diagnosticSecrets()) {
    let response;
    try {
        response = JSON.parse(output);
    } catch (error) {
        if (!(error instanceof SyntaxError)) throw error;
        return 'Salesforce CLI failed without valid JSON deployment diagnostics.';
    }
    const asArray = (value) => (Array.isArray(value) ? value : value && typeof value === 'object' ? [value] : []);
    const details = response?.result?.details;
    const result = details?.runTestResult;
    const messages = [
        response?.message,
        response?.result?.message,
        ...asArray(details?.componentFailures).map((entry) => entry?.problem),
        ...asArray(result?.failures).map((entry) => entry?.message),
        ...asArray(result?.codeCoverageWarnings).map((entry) =>
            entry?.name ? `${entry.name}: ${entry.message ?? ''}` : entry?.message
        )
    ];
    return safeDiagnostics(messages, secrets) || 'Salesforce deployment failed without selected diagnostic messages.';
}

function packageDiagnostics(output, secrets = diagnosticSecrets()) {
    const lines = output
        .split(/\r?\n/)
        .filter((line) =>
            /^(Failed to install |Could not verify installed package versions:|Package versions cannot be reconciled|Missing:|Unexpected:)/.test(
                line
            )
        );
    return safeDiagnostics(lines, secrets) || 'Package reconciliation failed without selected diagnostic messages.';
}

function coverageDiagnostics(output, secrets = diagnosticSecrets()) {
    const lines = output
        .split(/\r?\n/)
        .filter((line) =>
            /^(Repository Apex coverage |Apex coverage data |Invalid coverage data |No Apex coverage )/.test(line)
        );
    return safeDiagnostics(lines, secrets) || 'Coverage validation failed without selected diagnostic messages.';
}

function commandRunner(args, packageKey = '', { quiet = false } = {}) {
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
            if (stdout && (!quiet || status !== 0)) process.stdout.write(redact(stdout));
            if (stderr) process.stderr.write(redact(stderr));
            if (status !== 0) reject(new Error(`Salesforce CLI command failed with exit code ${status}.`));
            else resolve(stdout);
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
        await installPlan(plan, targetOrg, process.env.CRM_PACKAGE_KEY ?? '', (installArgs, options) =>
            commandRunner(installArgs, process.env.CRM_PACKAGE_KEY ?? '', options)
        );
        process.stdout.write('Installed package versions match the package plan.\n');
        return;
    }
    if (command === 'reconcile' && values.length === 4) {
        const [projectFile, planFile, installedFile, targetOrg] = values;
        const plan = readPlan(readJson(projectFile), readJson(planFile));
        const installed = readJson(installedFile).result;
        const result = await reconcileInstalledPackages(
            plan,
            installed,
            targetOrg,
            process.env.CRM_PACKAGE_KEY ?? '',
            (installArgs, options) => commandRunner(installArgs, process.env.CRM_PACKAGE_KEY ?? '', options)
        );
        process.stdout.write(
            result.changed.length
                ? `Updated package versions: ${result.changed.join(', ')}.\n`
                : 'Installed package versions already match the package plan.\n'
        );
        return;
    }
    if (command === 'map-package-ids' && values.length === 2) {
        const [planFile, packageRecordsFile] = values;
        const plan = readJson(planFile);
        const records = readJson(packageRecordsFile).result?.records;
        fs.writeFileSync(planFile, JSON.stringify(addSubscriberPackageIds(plan, records)));
        return;
    }
    if (command === 'tests' && values.length === 1) {
        process.stdout.write(`${JSON.stringify(getApexTestClassNames(values[0]))}\n`);
        return;
    }
    if (command === 'coverage' && (values.length === 2 || values.length === 3)) {
        const [coverageFile, sourceDirectory, changedFile] = values;
        const records = coverageRecords(readJson(coverageFile));
        const missing = missingCoverageFromList(changedFile, records);
        for (const entry of missing) {
            process.stderr.write(
                `⚠️ ingen dekningsdata: ${entry.path} (counted as 0% of ${entry.lines} estimated lines)\n`
            );
        }
        const names = getApexCoverageNames(sourceDirectory);
        if (process.env.GITHUB_STEP_SUMMARY) {
            fs.appendFileSync(
                process.env.GITHUB_STEP_SUMMARY,
                coverageMarkdown(calculateCoverage(records, names, 0, missing))
            );
        }
        const result = calculateCoverage(records, names, 85, missing);
        process.stdout.write(`${JSON.stringify(result)}\n`);
        return;
    }
    if (command === 'diagnostics' && values.length === 2) {
        const [kind, file] = values;
        const output = fs.readFileSync(file, 'utf8');
        if (kind === 'deployment') process.stdout.write(`${deploymentDiagnostics(output)}\n`);
        else if (kind === 'package') process.stdout.write(`${packageDiagnostics(output)}\n`);
        else throw new Error('Unsupported diagnostics type.');
        return;
    }
    if (command === 'fingerprint' && values.length === 2) {
        process.stdout.write(`${scratchFingerprint(values[0], values[1])}\n`);
        return;
    }
    throw new Error(
        'Usage: ci-scratch-plan.cjs verify-scratch|route|install|reconcile|map-package-ids|tests|coverage|fingerprint <arguments>'
    );
}

if (require.main === module) {
    main(process.argv.slice(2)).catch((error) => {
        console.error(error.message);
        process.exitCode = 1;
    });
}

module.exports = {
    calculateCoverage,
    coverageDiagnostics,
    deploymentDiagnostics,
    diagnosticSecrets,
    changedSourcesWithoutCoverage,
    coverageMarkdown,
    coverageRecords,
    addSubscriberPackageIds,
    missingCoverageFromList,
    getApexCoverageNames,
    getApexTestClassNames,
    installPlan,
    packageDiagnostics,
    reconcileInstalledPackages,
    isForceIgnored,
    readPlan,
    scratchFingerprint,
    stageDeployableSource,
    selectRoute,
    verifyScratchOrg
};
