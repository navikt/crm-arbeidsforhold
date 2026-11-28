const crypto = require('node:crypto');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { spawnSync } = require('node:child_process');
const { createInterface } = require('node:readline/promises');
const {
    coverageDiagnostics,
    deploymentDiagnostics,
    diagnosticSecrets,
    packageDiagnostics,
    stageDeployableSource
} = require('./ci-scratch-plan.cjs');

const REPOSITORY = 'navikt/crm-arbeidsforhold';
const ENVIRONMENT = 'ci-scratch-org';
const OWNER_TEAM = 'crm-arbeidsforhold-admin';
const VARIABLE_NAMES = ['CI_SCRATCH_ORG_ID', 'CI_SCRATCH_ORG_EXPIRATION', 'CI_SCRATCH_ORG_CONFIG_SHA256'];
const REGISTRATION_LOCK = 'ci-scratch-org-registration-lock';

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
        const secrets = diagnosticSecrets({ ...process.env, ...options.env });
        const output = `${result.stdout ?? ''}\n${result.stderr ?? ''}`;
        let details = '';
        if (options.diagnostics === 'deployment') details = deploymentDiagnostics(result.stdout, secrets);
        if (options.diagnostics === 'package') details = packageDiagnostics(output, secrets);
        if (options.diagnostics === 'coverage') details = coverageDiagnostics(output, secrets);
        throw new Error(
            `${command} ${args[0] ?? ''} failed with exit code ${result.status}.${details ? `\n${details}` : ''}`
        );
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

function acquireRegistrationLock(run) {
    const root = `repos/${REPOSITORY}/git`;
    const head = run('gh', ['api', `${root}/ref/heads/main`, '--jq', '.object.sha']);
    if (!/^[a-f0-9]{40}$/.test(head)) throw new Error('Could not read the main commit for the registration lock.');
    const tree = run('gh', ['api', `${root}/commits/${head}`, '--jq', '.tree.sha']);
    if (!/^[a-f0-9]{40}$/.test(tree)) throw new Error('Could not read the main tree for the registration lock.');
    const lockCommit = run('gh', [
        'api',
        `${root}/commits`,
        '--method',
        'POST',
        '-f',
        `message=CI scratch-org registration lock ${crypto.randomUUID()}`,
        '-f',
        `tree=${tree}`,
        '-f',
        `parents[]=${head}`,
        '--jq',
        '.sha'
    ]);
    if (!/^[a-f0-9]{40}$/.test(lockCommit)) throw new Error('Could not create the registration lock commit.');
    try {
        run('gh', [
            'api',
            `${root}/refs`,
            '--method',
            'POST',
            '-f',
            `ref=refs/heads/${REGISTRATION_LOCK}`,
            '-f',
            `sha=${lockCommit}`
        ]);
    } catch (error) {
        throw new Error(
            `Could not acquire the shared registration lock ${REGISTRATION_LOCK}; another operator may hold it or GitHub may have accepted the request. Check the lock and follow the recovery guide before retrying.`,
            { cause: error }
        );
    }
    return lockCommit;
}

function releaseRegistrationLock(run, lockCommit) {
    const root = `repos/${REPOSITORY}/git`;
    const current = run('gh', ['api', `${root}/ref/heads/${REGISTRATION_LOCK}`, '--jq', '.object.sha']);
    if (current !== lockCommit) throw new Error('The registration lock no longer belongs to this operation.');
    run('gh', ['api', `${root}/refs/heads/${REGISTRATION_LOCK}`, '--method', 'DELETE']);
}

function setEnvironmentRegistration(registration, run = commandRunner, onEnvironmentWriteStarted = () => {}) {
    validateRegistration(registration);
    const lockCommit = acquireRegistrationLock(run);
    let updateError;
    try {
        writeEnvironmentRegistration(registration, run, onEnvironmentWriteStarted);
    } catch (error) {
        updateError = error;
    }
    try {
        releaseRegistrationLock(run, lockCommit);
    } catch (error) {
        throw new Error(
            `${updateError ? `${updateError.message} ` : ''}Could not release the shared registration lock ${REGISTRATION_LOCK}; follow the recovery guide before another replacement.`,
            { cause: updateError ?? error }
        );
    }
    if (updateError) throw updateError;
}

function writeEnvironmentRegistration(registration, run, onEnvironmentWriteStarted) {
    const previous = readEnvironmentVariables(run);
    const values = [
        ['CI_SCRATCH_ORG_ID', registration.orgId],
        ['CI_SCRATCH_ORG_EXPIRATION', registration.expiration],
        ['CI_SCRATCH_ORG_CONFIG_SHA256', registration.fingerprint]
    ];
    const changed = [];
    try {
        onEnvironmentWriteStarted();
        for (const [name, value] of values) {
            changed.push(name);
            run('gh', ['variable', 'set', name, '--repo', REPOSITORY, '--env', ENVIRONMENT, '--body', value]);
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
            `GitHub Environment update failed. Previous variables were restored; verify the registration because PR validation may fall back. ${error.message}`,
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
            `This will create and register a replacement CI scratch org using Dev Hub ${JSON.stringify(targetDevHub)}. Type "yes" to continue: `
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

function cleanupFailedCreation(run, targetDevHub, candidateName, repositoryPath) {
    const response = parseJson(
        run(
            'sf',
            [
                'data',
                'query',
                '--target-org',
                targetDevHub,
                '--query',
                `SELECT Id, OrgName FROM ScratchOrgInfo WHERE OrgName = '${candidateName}'`,
                '--json'
            ],
            { cwd: repositoryPath }
        ),
        'scratch-org creation request lookup'
    ).result;
    if (
        response?.done !== true ||
        response?.totalSize !== 1 ||
        !Array.isArray(response.records) ||
        response.records.length !== 1 ||
        response.records[0]?.OrgName !== candidateName ||
        !/^2SR[a-zA-Z0-9]{12}([a-zA-Z0-9]{3})?$/.test(response.records[0]?.Id ?? '')
    ) {
        throw new Error('Exactly one matching scratch-org creation request could not be verified.');
    }
    run(
        'sf',
        [
            'data',
            'delete',
            'record',
            '--target-org',
            targetDevHub,
            '--sobject',
            'ScratchOrgInfo',
            '--record-id',
            response.records[0].Id,
            '--json'
        ],
        { cwd: repositoryPath }
    );
}

async function replaceScratchOrg({
    targetDevHub,
    repositoryPath = process.cwd(),
    run = commandRunner,
    confirm = confirmTarget,
    environment = process.env
}) {
    if (
        typeof targetDevHub !== 'string' ||
        targetDevHub.trim() !== targetDevHub ||
        !/^[^\s-][^\p{Cc}]*$/u.test(targetDevHub)
    ) {
        throw new Error('Pass an explicit Salesforce Dev Hub alias with --target-dev-hub.');
    }
    if (!environment.CRM_PACKAGE_KEY) throw new Error('CRM_PACKAGE_KEY must be available in the local environment.');
    verifyLocalSource(run, repositoryPath);
    verifyRepositoryOwner(run);
    await confirm(targetDevHub);

    const temporaryDirectory = fs.mkdtempSync(path.join(os.tmpdir(), 'ci-scratch-org-replace-'));
    const packagePlan = path.join(temporaryDirectory, 'package-plan.json');
    const alias = `ci-scratch-${crypto.randomUUID()}`;
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

        process.stdout.write(
            `Creating the replacement scratch org with request name ${alias} in Dev Hub "${targetDevHub}".\n`
        );
        let creationOutput;
        try {
            creationOutput = run(
                'sf',
                [
                    'org',
                    'create',
                    'scratch',
                    '--definition-file',
                    'config/project-scratch-def.json',
                    '--alias',
                    alias,
                    '--name',
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
        } catch (error) {
            try {
                cleanupFailedCreation(run, targetDevHub, alias, repositoryPath);
            } catch (cleanupError) {
                throw new Error(
                    `${error.message} Automatic cleanup could not be confirmed: ${cleanupError.message} Check the Dev Hub "${targetDevHub}" for scratch-org creation request ${alias}, including delayed creation, before retrying.`,
                    { cause: error }
                );
            }
            throw new Error(
                `${error.message} Cleanup was requested for creation request ${alias}. Check the Dev Hub "${targetDevHub}" for delayed creation before retrying.`,
                { cause: error }
            );
        }
        created = true;
        const createdOrg = parseJson(creationOutput, 'scratch-org creation');
        const createdOrgId = createdOrg.result?.orgId ?? createdOrg.result?.id;
        if (typeof createdOrgId !== 'string' || !/^[a-zA-Z0-9]{15}([a-zA-Z0-9]{3})?$/.test(createdOrgId)) {
            throw new Error('Salesforce did not return a valid scratch-org ID.');
        }

        process.stdout.write('Installing the package versions selected by the current main package plan.\n');
        run(process.execPath, ['scripts/ci-scratch-plan.cjs', 'install', 'sfdx-project.json', packagePlan, alias], {
            cwd: repositoryPath,
            env: commandEnvironment,
            diagnostics: 'package'
        });
        process.stdout.write('Staging deployable metadata and discovering repository Apex tests.\n');
        const stagedSource = path.join(temporaryDirectory, 'force-app');
        fs.copyFileSync(path.join(repositoryPath, '.forceignore'), path.join(temporaryDirectory, '.forceignore'));
        stageDeployableSource(path.join(repositoryPath, 'force-app'), stagedSource);
        const testClasses = parseJson(
            run(process.execPath, ['scripts/ci-scratch-plan.cjs', 'tests', stagedSource], { cwd: repositoryPath }),
            'repository Apex test classes'
        );
        process.stdout.write('Validating staged metadata and tests without persisting metadata in the CI org.\n');
        const deployResult = path.join(temporaryDirectory, 'deploy-result.json');
        fs.writeFileSync(
            deployResult,
            run('sf', validationArguments(stagedSource, testClasses, alias), {
                cwd: repositoryPath,
                diagnostics: 'deployment',
                env: commandEnvironment
            })
        );
        run(process.execPath, ['scripts/ci-scratch-plan.cjs', 'coverage', deployResult, stagedSource], {
            cwd: repositoryPath,
            diagnostics: 'coverage',
            env: commandEnvironment
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
        setEnvironmentRegistration(registration, run, () => {
            registrationStarted = true;
        });
        registered = true;
        process.stdout.write(
            `CI scratch org registered through your GitHub account. The previous org remains until it expires; see the guide for cleanup if needed.\n`
        );
    } catch (error) {
        if (created && !registered) {
            if (registrationStarted) {
                throw new Error(
                    `${error.message} The replacement org was kept as Salesforce alias ${alias} because GitHub may have partially accepted the Environment update. Verify the registration before deleting it.`,
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
    commandRunner,
    replaceScratchOrg,
    setEnvironmentRegistration,
    validationArguments,
    validateRegistration,
    verifyRepositoryOwner
};
