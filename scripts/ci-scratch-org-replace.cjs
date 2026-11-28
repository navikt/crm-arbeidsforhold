const crypto = require('node:crypto');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { spawnSync } = require('node:child_process');
const { createInterface } = require('node:readline/promises');
const { stageDeployableSource } = require('./ci-scratch-plan.cjs');

const REPOSITORY = 'navikt/crm-arbeidsforhold';
const ENVIRONMENT = 'ci-scratch-org';
const OWNER_TEAM = 'crm-arbeidsforhold-admin';
const VARIABLE_NAMES = ['CI_SCRATCH_ORG_ID', 'CI_SCRATCH_ORG_EXPIRATION', 'CI_SCRATCH_ORG_CONFIG_SHA256'];

function commandRunner(command, args, options = {}) {
    const result = spawnSync(command, args, {
        cwd: options.cwd,
        encoding: 'utf8',
        env: options.env ? { ...process.env, ...options.env } : process.env,
        input: options.input,
        maxBuffer: 8 * 1024 * 1024
    });
    if (result.error) throw new Error(`Could not run ${command}: ${result.error.message}`);
    if (result.status !== 0) {
        throw new Error(`${command} ${args[0] ?? ''} failed with exit code ${result.status}.`);
    }
    return result.stdout.trim();
}

function verifyRepositoryOwner(run = commandRunner) {
    const username = run('gh', ['api', 'user', '--jq', '.login']);
    if (!/^[a-zA-Z0-9-]+$/.test(username)) throw new Error('GitHub returned an invalid username.');

    let membership;
    try {
        membership = run('gh', [
            'api',
            `orgs/navikt/teams/${OWNER_TEAM}/memberships/${encodeURIComponent(username)}`,
            '--jq',
            '.state'
        ]);
    } catch (error) {
        throw new Error(
            `Could not verify membership in @navikt/${OWNER_TEAM}. Ensure gh is authenticated with read:org permission.`,
            { cause: error }
        );
    }
    if (membership !== 'active')
        throw new Error(`Only active members of @navikt/${OWNER_TEAM} can replace the CI org.`);

    let permission;
    try {
        permission = run('gh', [
            'api',
            `repos/${REPOSITORY}/collaborators/${encodeURIComponent(username)}/permission`,
            '--jq',
            '.permission'
        ]);
    } catch (error) {
        throw new Error(`Could not verify admin access to ${REPOSITORY}.`, { cause: error });
    }
    if (permission !== 'admin') throw new Error(`Replacing the CI org requires admin permission on ${REPOSITORY}.`);
    return username;
}

function parseJson(output, description) {
    try {
        return JSON.parse(output);
    } catch (error) {
        if (!(error instanceof SyntaxError)) throw error;
        throw new Error(`Could not parse ${description} returned by the CLI.`);
    }
}

function validateRegistration(registration) {
    const expiration = new Date(`${registration?.expiration}T00:00:00Z`);
    if (
        typeof registration?.authUrl !== 'string' ||
        !/^force:\/\/\S+$/.test(registration.authUrl) ||
        /[\r\n]/.test(registration.authUrl) ||
        typeof registration.orgId !== 'string' ||
        !/^[a-zA-Z0-9]{15}([a-zA-Z0-9]{3})?$/.test(registration.orgId) ||
        !Number.isFinite(expiration.getTime()) ||
        expiration.toISOString().slice(0, 10) !== registration.expiration ||
        typeof registration.fingerprint !== 'string' ||
        !/^[a-f0-9]{64}$/.test(registration.fingerprint)
    ) {
        throw new Error('Invalid CI scratch org registration returned by Salesforce.');
    }
}

function readEnvironmentVariables(run = commandRunner) {
    const response = parseJson(
        run('gh', ['variable', 'list', '--repo', REPOSITORY, '--env', ENVIRONMENT, '--json', 'name,value']),
        'GitHub Environment variables'
    );
    if (!Array.isArray(response)) throw new Error('Could not read the CI scratch-org Environment variables.');
    return Object.fromEntries(
        response.filter((entry) => VARIABLE_NAMES.includes(entry.name)).map((entry) => [entry.name, entry.value])
    );
}

function setEnvironmentRegistration(registration, run = commandRunner) {
    validateRegistration(registration);
    const previous = readEnvironmentVariables(run);
    const values = [
        ['CI_SCRATCH_ORG_ID', registration.orgId],
        ['CI_SCRATCH_ORG_EXPIRATION', registration.expiration],
        ['CI_SCRATCH_ORG_CONFIG_SHA256', registration.fingerprint]
    ];
    const changed = [];
    try {
        for (const [name, value] of values) {
            run('gh', ['variable', 'set', name, '--repo', REPOSITORY, '--env', ENVIRONMENT, '--body', value]);
            changed.push(name);
        }
        run('gh', ['secret', 'set', 'CI_SCRATCH_ORG_AUTH_URL', '--repo', REPOSITORY, '--env', ENVIRONMENT], {
            input: registration.authUrl
        });
    } catch (error) {
        const rollbackFailures = [];
        for (const name of changed.reverse()) {
            try {
                if (previous[name] === undefined) {
                    run('gh', ['variable', 'delete', name, '--repo', REPOSITORY, '--env', ENVIRONMENT]);
                } else {
                    run('gh', [
                        'variable',
                        'set',
                        name,
                        '--repo',
                        REPOSITORY,
                        '--env',
                        ENVIRONMENT,
                        '--body',
                        previous[name]
                    ]);
                }
            } catch (rollbackError) {
                rollbackFailures.push(`${name}: ${rollbackError.message}`);
            }
        }
        if (rollbackFailures.length) {
            throw new Error(
                `GitHub Environment update failed and variable rollback was incomplete (${rollbackFailures.join('; ')}). PR validation will fall back until an admin repairs the registration.`,
                { cause: error }
            );
        }
        throw new Error(
            `GitHub Environment update failed. Previous variables were restored; PR validation will fall back until the replacement is registered. ${error.message}`,
            { cause: error }
        );
    }
}

async function confirmTarget(targetDevHub) {
    if (!process.stdin.isTTY || !process.stdout.isTTY) {
        throw new Error('Run this command in an interactive terminal so the Dev Hub target can be confirmed.');
    }
    const terminal = createInterface({ input: process.stdin, output: process.stdout });
    try {
        const answer = await terminal.question(
            `This will create and register a replacement CI scratch org using Dev Hub "${targetDevHub}". Type "yes" to continue: `
        );
        if (answer.trim() !== 'yes') throw new Error('CI scratch-org replacement cancelled.');
    } finally {
        terminal.close();
    }
}

function verifyLocalSource(run, repositoryPath) {
    const remote = run('git', ['remote', 'get-url', 'origin'], { cwd: repositoryPath }).replace(/\.git$/, '');
    if (
        ![
            'https://github.com/navikt/crm-arbeidsforhold',
            'git@github.com:navikt/crm-arbeidsforhold',
            'ssh://git@github.com/navikt/crm-arbeidsforhold'
        ].includes(remote)
    ) {
        throw new Error('Run the replacement command from the navikt/crm-arbeidsforhold repository.');
    }
    run('git', ['fetch', 'origin', 'main'], { cwd: repositoryPath });
    const branch = run('git', ['branch', '--show-current'], { cwd: repositoryPath });
    if (branch !== 'main') throw new Error('Run the replacement command from an up-to-date main checkout.');
    const head = run('git', ['rev-parse', 'HEAD'], { cwd: repositoryPath });
    const main = run('git', ['rev-parse', 'origin/main'], { cwd: repositoryPath });
    if (head !== main) throw new Error('Update the local main branch from origin before replacing the CI org.');
    const changed = run(
        'git',
        [
            'status',
            '--porcelain',
            '--',
            'sfdx-project.json',
            'config/project-scratch-def.json',
            'force-app',
            '.forceignore',
            'bin/package-dependencies.js',
            'bin/package-dependency-report.js',
            'scripts/ci-scratch-plan.cjs',
            'scripts/ci-scratch-org-replace.cjs'
        ],
        { cwd: repositoryPath }
    );
    if (changed)
        throw new Error(
            'The scratch definition, package plan or deployable source has local changes; update main first.'
        );
}

function validationArguments(sourceDirectory, testClasses, targetOrg) {
    if (!Array.isArray(testClasses) || testClasses.length === 0) {
        throw new Error('No repository Apex test classes were found.');
    }
    return [
        'project',
        'deploy',
        'start',
        '--dry-run',
        '--source-dir',
        sourceDirectory,
        '--target-org',
        targetOrg,
        '--test-level',
        'RunSpecifiedTests',
        ...testClasses.flatMap((name) => ['--tests', name]),
        '--coverage-formatters',
        'json',
        '--wait',
        '60',
        '--json'
    ];
}

async function replaceScratchOrg({
    targetDevHub,
    repositoryPath = process.cwd(),
    run = commandRunner,
    confirm = confirmTarget,
    environment = process.env
}) {
    if (typeof targetDevHub !== 'string' || !/^[a-zA-Z0-9._-]+$/.test(targetDevHub)) {
        throw new Error('Pass an explicit Salesforce Dev Hub alias with --target-dev-hub.');
    }
    if (!environment.CRM_PACKAGE_KEY) throw new Error('CRM_PACKAGE_KEY must be available in the local environment.');
    verifyLocalSource(run, repositoryPath);
    verifyRepositoryOwner(run);
    await confirm(targetDevHub);

    const temporaryDirectory = fs.mkdtempSync(path.join(os.tmpdir(), 'ci-scratch-org-replace-'));
    const packagePlan = path.join(temporaryDirectory, 'package-plan.json');
    const alias = `ci-scratch-${crypto.randomUUID().slice(0, 8)}`;
    const commandEnvironment = { CRM_PACKAGE_KEY: environment.CRM_PACKAGE_KEY };
    let created = false;
    let registered = false;
    let registrationStarted = false;
    try {
        run(
            process.execPath,
            [
                'bin/package-dependencies.js',
                '--include-unreleased',
                '--dev-hub',
                targetDevHub,
                '--plan-file',
                packagePlan,
                '--no-color'
            ],
            { cwd: repositoryPath }
        );
        const fingerprint = run(
            process.execPath,
            ['scripts/ci-scratch-plan.cjs', 'fingerprint', 'sfdx-project.json', 'config/project-scratch-def.json'],
            { cwd: repositoryPath }
        );

        process.stdout.write('Creating the replacement scratch org.\n');
        const creationOutput = run(
            'sf',
            [
                'org',
                'create',
                'scratch',
                '--definition-file',
                'config/project-scratch-def.json',
                '--alias',
                alias,
                '--target-dev-hub',
                targetDevHub,
                '--duration-days',
                '30',
                '--no-track-source',
                '--json'
            ],
            { cwd: repositoryPath }
        );
        created = true;
        const createdOrg = parseJson(creationOutput, 'scratch-org creation');
        const createdOrgId = createdOrg.result?.orgId ?? createdOrg.result?.id;
        if (typeof createdOrgId !== 'string' || !/^[a-zA-Z0-9]{15}([a-zA-Z0-9]{3})?$/.test(createdOrgId)) {
            throw new Error('Salesforce did not return a valid scratch-org ID.');
        }

        process.stdout.write('Installing the package versions selected by the current main package plan.\n');
        run(process.execPath, ['scripts/ci-scratch-plan.cjs', 'install', 'sfdx-project.json', packagePlan, alias], {
            cwd: repositoryPath,
            env: commandEnvironment
        });
        process.stdout.write('Staging deployable metadata and discovering repository Apex tests.\n');
        const stagedSource = path.join(temporaryDirectory, 'force-app');
        stageDeployableSource(path.join(repositoryPath, 'force-app'), stagedSource);
        const testClasses = parseJson(
            run(process.execPath, ['scripts/ci-scratch-plan.cjs', 'tests', stagedSource], { cwd: repositoryPath }),
            'repository Apex test classes'
        );
        process.stdout.write('Validating staged metadata and tests without persisting metadata in the CI org.\n');
        const deployResult = path.join(temporaryDirectory, 'deploy-result.json');
        fs.writeFileSync(
            deployResult,
            run('sf', validationArguments(stagedSource, testClasses, alias), { cwd: repositoryPath })
        );
        run(process.execPath, ['scripts/ci-scratch-plan.cjs', 'coverage', deployResult, stagedSource], {
            cwd: repositoryPath
        });

        const org = parseJson(
            run('sf', ['org', 'display', '--target-org', alias, '--json'], { cwd: repositoryPath }),
            'scratch-org details'
        ).result;
        if (org?.id !== createdOrgId || org?.expirationDate?.slice(0, 10) === undefined) {
            throw new Error('Could not verify the created scratch-org identity and expiration.');
        }
        const authResponse = parseJson(
            run('sf', ['org', 'auth', 'show-sfdx-auth-url', '--target-org', alias, '--json'], { cwd: repositoryPath }),
            'scratch-org authentication URL'
        );
        const authUrl =
            typeof authResponse.result === 'string' ? authResponse.result : authResponse.result?.sfdxAuthUrl;
        const registration = {
            authUrl,
            orgId: org.id,
            expiration: org.expirationDate.slice(0, 10),
            fingerprint
        };
        validateRegistration(registration);

        process.stdout.write('Registering the verified org in the ci-scratch-org GitHub Environment.\n');
        registrationStarted = true;
        setEnvironmentRegistration(registration, run);
        registered = true;
        process.stdout.write(
            `CI scratch org registered through your GitHub account. The previous org remains until it expires; see the guide for cleanup if needed.\n`
        );
    } catch (error) {
        if (created && !registered) {
            if (registrationStarted) {
                throw new Error(
                    `${error.message} The replacement org was kept because GitHub may have partially accepted the Environment update. Verify the registration before deleting it.`,
                    { cause: error }
                );
            }
            try {
                run('sf', ['org', 'delete', 'scratch', '--target-org', alias, '--no-prompt'], { cwd: repositoryPath });
            } catch (cleanupError) {
                throw new Error(
                    `${error.message} The unregistered replacement could not be deleted; inspect Salesforce alias ${alias} and remove it manually.`,
                    { cause: cleanupError }
                );
            }
        }
        throw error;
    } finally {
        fs.rmSync(temporaryDirectory, { recursive: true, force: true });
    }
}

async function main(args) {
    if (args.length !== 2 || args[0] !== '--target-dev-hub') {
        throw new Error('Usage: ci-scratch-org-replace.cjs --target-dev-hub <existing-dev-hub-alias>');
    }
    await replaceScratchOrg({ targetDevHub: args[1] });
}

if (require.main === module) {
    main(process.argv.slice(2)).catch((error) => {
        console.error(error.message);
        process.exitCode = 1;
    });
}

module.exports = {
    replaceScratchOrg,
    setEnvironmentRegistration,
    validationArguments,
    validateRegistration,
    verifyRepositoryOwner
};
