const fs = require('node:fs');
const path = require('node:path');
const { spawnSync } = require('node:child_process');

function versionNumber(record) {
    const parts = ['MajorVersion', 'MinorVersion', 'PatchVersion', 'BuildNumber'].map((key) => record[key]);
    if (parts.some((part) => !Number.isInteger(part) || part < 0)) {
        throw new Error('Package report has invalid version components.');
    }
    return parts.join('.');
}

function checkDependencies(project, provider) {
    if (!Array.isArray(project.packageDirectories)) throw new Error('packageDirectories must be an array.');
    const updated = structuredClone(project);
    updated.packageAliases ??= {};
    const errors = [];
    let fixable = true;
    const reports = new Map();
    const knownNames = new Map();
    const versions = {};
    const report = (id) => {
        if (!reports.has(id)) {
            const record = provider.report(id);
            if (record.SubscriberPackageVersionId !== id || !record.Package2Id) {
                throw new Error(`Invalid package report for ${id}.`);
            }
            const subscriber = record.SubscriberPackageVersion;
            if (
                !subscriber ||
                !Object.hasOwn(subscriber, 'Dependencies') ||
                (subscriber.Dependencies !== null && !Array.isArray(subscriber.Dependencies?.ids))
            ) {
                throw new Error(`Missing dependency metadata for ${id}; completeness cannot be verified.`);
            }
            record.VersionNumber = versionNumber(record);
            reports.set(id, record);
        }
        return reports.get(id);
    };
    for (const directory of updated.packageDirectories) {
        if (!directory.dependencies?.length) continue;
        const selected = new Map();
        for (const dependency of directory.dependencies) {
            const id = provider.resolve(dependency);
            const record = report(id);
            if (versions[dependency.package] && versions[dependency.package].SubscriberPackageVersionId !== id) {
                throw new Error(`Conflicting versions for ${dependency.package} across package directories.`);
            }
            knownNames.set(record.Package2Id, dependency.package);
            versions[dependency.package] = record;
            if (selected.has(record.Package2Id))
                throw new Error(`Duplicate package declaration: ${dependency.package}`);
            selected.set(record.Package2Id, { dependency, id });
        }
        const ordered = [];
        const visited = new Set();
        const visiting = new Set();
        const visit = (id, parent) => {
            if (visiting.has(id)) throw new Error(`Dependency cycle: ${[...visiting, id].join(' -> ')}`);
            const record = report(id);
            const name = knownNames.get(record.Package2Id) ?? provider.name(record.Package2Id);
            const existing = selected.get(record.Package2Id);
            if (existing && existing.id !== id) {
                errors.push(
                    `${directory.path}: version mismatch: ${parent} requires ${name} ${versionNumber(record)} (${id}), declared ${existing.id}. Manual version reconciliation required.`
                );
                fixable = false;
                return;
            }
            if (visited.has(id)) return;
            if (!existing) {
                errors.push(`${directory.path}: ${parent} requires missing ${name} ${versionNumber(record)} (${id}).`);
                if (updated.packageAliases[name] && updated.packageAliases[name] !== record.Package2Id) {
                    throw new Error(`Alias collision for ${name}; resolve it manually.`);
                }
                updated.packageAliases[name] = record.Package2Id;
                selected.set(record.Package2Id, {
                    id,
                    dependency: { package: name, versionNumber: versionNumber(record) }
                });
            }
            visiting.add(id);
            for (const entry of record.SubscriberPackageVersion.Dependencies?.ids ?? []) {
                if (typeof entry.subscriberPackageVersionId !== 'string' || !entry.subscriberPackageVersionId) {
                    throw new Error(`Invalid dependency metadata for ${id}.`);
                }
                visit(entry.subscriberPackageVersionId, `${name} ${versionNumber(record)}`);
            }
            visiting.delete(id);
            visited.add(id);
            ordered.push(selected.get(record.Package2Id).dependency);
        };
        for (const { id } of [...selected.values()]) visit(id, directory.path);
        if (fixable && JSON.stringify(ordered) !== JSON.stringify(directory.dependencies)) {
            if (ordered.length === directory.dependencies.length) {
                errors.push(`${directory.path}: incorrect installation order; dependencies must precede dependants.`);
            }
            directory.dependencies = ordered;
        }
    }
    return { valid: errors.length === 0, fixable, errors, project: updated, versions };
}

function createProvider(project, run, latest) {
    const aliases = project.packageAliases ?? {};
    const names = new Map(
        Object.entries(aliases)
            .filter(([, id]) => typeof id === 'string')
            .map(([name, id]) => [id, name])
    );
    let packagesLoaded = false;
    const latestVersions = new Map();
    return {
        resolve(dependency) {
            const reference = aliases[dependency.package] ?? dependency.package;
            if (/^04t[a-zA-Z0-9]{12}(?:[a-zA-Z0-9]{3})?$/.test(reference)) return reference;
            const versions = run([
                'package',
                'version',
                'list',
                '--packages',
                dependency.package,
                '--released',
                '--order-by',
                'CreatedDate'
            ]);
            if (!Array.isArray(versions)) throw new Error(`Invalid version list for ${dependency.package}.`);
            const requested = dependency.versionNumber;
            if (!latest && !/^\d+\.\d+\.\d+\.(?:LATEST|NEXT|\d+)$/.test(requested ?? '')) {
                throw new Error(`Invalid or missing versionNumber for ${dependency.package}.`);
            }
            const parts = requested?.split('.');
            const sorted = [...versions].sort((a, b) => {
                for (const key of ['MajorVersion', 'MinorVersion', 'PatchVersion', 'BuildNumber']) {
                    if (a[key] !== b[key]) return a[key] - b[key];
                }
                return 0;
            });
            const candidates = sorted.filter((record) => {
                const number = versionNumber(record).split('.');
                return (
                    latest ||
                    parts.every(
                        (part, index) => part === 'LATEST' || part === 'NEXT' || Number(part) === Number(number[index])
                    )
                );
            });
            const id = candidates.at(-1)?.SubscriberPackageVersionId;
            if (!id) throw new Error(`Cannot resolve released version for ${dependency.package} ${requested ?? ''}.`);
            const newest = sorted.at(-1);
            latestVersions.set(id, { ...newest, VersionNumber: versionNumber(newest) });
            return id;
        },
        report: (id) => ({
            ...run(['package', 'version', 'report', '--package', id, '--verbose']),
            LatestVersion: latestVersions.get(id)
        }),
        name(id) {
            if (!names.has(id) && !packagesLoaded) {
                const packages = run(['package', 'list']);
                if (!Array.isArray(packages)) throw new Error('Invalid package list response.');
                for (const entry of packages) if (entry.Id && entry.Name) names.set(entry.Id, entry.Name);
                packagesLoaded = true;
            }
            if (!names.has(id)) throw new Error(`Cannot resolve package name for ${id}; check Dev Hub access.`);
            return names.get(id);
        }
    };
}

function runCli(args) {
    const options = {};
    for (let index = 0; index < args.length; index++) {
        const argument = args[index];
        if (['--apply', '--latest', '--dry-run'].includes(argument)) options[argument] = true;
        else if (
            ['--project-file', '--dev-hub', '--plan-file'].includes(argument) &&
            args[index + 1] &&
            !args[index + 1].startsWith('--')
        ) {
            options[argument] = args[++index];
        } else throw new Error(`Unknown or incomplete option: ${argument}`);
    }
    if (options['--apply'] && options['--dry-run']) throw new Error('--apply cannot be combined with --dry-run.');
    const file = path.resolve(options['--project-file'] ?? 'sfdx-project.json');
    const original = fs.readFileSync(file, 'utf8');
    const project = JSON.parse(original);
    const hub = options['--dev-hub'] ?? process.env.SF_TARGET_DEV_HUB;
    const key = process.env[process.env.PACKAGE_INSTALL_KEY_ENV_VAR ?? 'PACKAGE_INSTALL_KEY'];
    const redact = (text) => (key ? text.replaceAll(key, '***') : text);
    const run = (command) => {
        const arguments_ = [...command, ...(hub ? ['--target-dev-hub', hub] : []), '--json'];
        const result =
            process.platform === 'win32'
                ? spawnSync(
                      'pwsh.exe',
                      [
                          '-NoLogo',
                          '-NoProfile',
                          '-Command',
                          "$PSNativeCommandArgumentPassing='Standard'; $a=ConvertFrom-Json $env:PACKAGE_CHECK_ARGV; & sf @a; exit $LASTEXITCODE"
                      ],
                      {
                          cwd: path.dirname(file),
                          encoding: 'utf8',
                          env: { ...process.env, PACKAGE_CHECK_ARGV: JSON.stringify(arguments_) }
                      }
                  )
                : spawnSync('sf', arguments_, { cwd: path.dirname(file), encoding: 'utf8' });
        if (result.error) throw new Error(`Cannot start Salesforce CLI: ${result.error.message}`);
        const output = result.stdout;
        const start = output.indexOf('{');
        if (start < 0)
            throw new Error(
                redact(`Salesforce returned no JSON dependency metadata (exit ${result.status}): ${result.stderr}`)
            );
        const response = JSON.parse(output.slice(start));
        if (result.status !== 0 || response.status !== 0 || response.result === undefined) {
            throw new Error(redact(`Salesforce dependency read failed: ${response.message ?? 'invalid response'}`));
        }
        return response.result;
    };
    console.log('Dependency preflight: reading exact version dependency metadata (no org mutations).');
    const result = checkDependencies(project, createProvider(project, run, options['--latest']));
    for (const message of result.errors) console.error(message);
    if (result.valid) {
        if (options['--plan-file'])
            fs.writeFileSync(options['--plan-file'], JSON.stringify(result.versions), { flag: 'wx' });
        console.log('Dependency preflight PASSED: complete, exact-version, dependency-first manifest.');
        return 0;
    }
    if (!options['--apply'] || !result.fixable) {
        console.error(
            result.fixable
                ? 'No files changed. Review the reported additions/order, then explicitly run --apply-dependencies to update the manifest.'
                : 'No files changed. Reconcile conflicting versions manually; higher versions are not assumed compatible.'
        );
        return 1;
    }
    const backup = `${file}.dependencies.backup`;
    if (fs.existsSync(backup))
        throw new Error(`Backup already exists: ${backup}. Preserve or move it before applying.`);
    if (fs.readFileSync(file, 'utf8') !== original)
        throw new Error('Project file changed during dependency check; retry after reviewing it.');
    fs.writeFileSync(backup, original, { flag: 'wx' });
    const temporary = `${file}.dependencies-${process.pid}.tmp`;
    try {
        fs.writeFileSync(temporary, JSON.stringify(result.project, null, 4) + '\n', { flag: 'wx' });
        fs.renameSync(temporary, file);
    } finally {
        if (fs.existsSync(temporary)) fs.unlinkSync(temporary);
    }
    console.log(
        `Applied missing exact-version dependencies and dependency-first ordering. Backup: ${backup}. Review the diff and rerun setup.`
    );
    return 0;
}

if (require.main === module) {
    try {
        process.exitCode = runCli(process.argv.slice(2));
    } catch (error) {
        console.error(`Dependency preflight FAILED: ${error.message}`);
        process.exitCode = 1;
    }
}

module.exports = { checkDependencies, createProvider, runCli };
