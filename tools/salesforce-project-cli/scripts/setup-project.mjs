import { access, readFile, writeFile } from 'node:fs/promises';
import path from 'node:path';
import readline from 'node:readline/promises';
import { stdin as input, stdout as output } from 'node:process';

const defaultConfig = {
    schemaVersion: 1,
    scratchDefinition: 'config/project-scratch-def.json',
    scratchDurationDays: 14,
    permissionSets: [],
    dummyDataPlan: null,
    communityName: null,
    postSteps: ['deploy'],
    pool: {
        use: false,
        tag: 'dev',
        fallbackToCreate: true
    },
    packageInstallKeyEnvironmentVariable: 'PACKAGE_INSTALL_KEY',
    dependencySourcePolicy: {
        preserveRootFiles: ['README.md']
    }
};

function parseArguments(argumentsList) {
    const options = { projectDirectory: process.cwd(), nonInteractive: false };
    for (let index = 0; index < argumentsList.length; index += 1) {
        const argument = argumentsList[index];
        if (argument === '--non-interactive') {
            options.nonInteractive = true;
        } else if (argument === '--project-dir') {
            const projectDirectory = argumentsList[index + 1];
            if (!projectDirectory) throw new Error('--project-dir requires a path');
            options.projectDirectory = projectDirectory;
            index += 1;
        } else {
            throw new Error(`Unknown setup option: ${argument}`);
        }
    }
    return options;
}

async function fileExists(filePath) {
    try {
        await access(filePath);
        return true;
    } catch {
        return false;
    }
}

function splitList(value) {
    return value
        .split(',')
        .map((item) => item.trim())
        .filter(Boolean);
}

function mergeConfiguration(existingConfig) {
    return {
        ...defaultConfig,
        ...existingConfig,
        pool: { ...defaultConfig.pool, ...(existingConfig?.pool ?? {}) },
        dependencySourcePolicy: {
            ...defaultConfig.dependencySourcePolicy,
            ...(existingConfig?.dependencySourcePolicy ?? {})
        }
    };
}

function displayValue(value) {
    if (value === null || value === undefined || value === '') return 'none';
    if (Array.isArray(value)) return value.length === 0 ? 'none' : value.join(', ');
    return String(value);
}

async function createConfiguration(existingConfig, interactive) {
    const current = mergeConfiguration(existingConfig);
    if (!interactive) return current;

    const prompt = async (question, currentValue, defaultValue) => {
        const effectiveValue = currentValue ?? defaultValue;
        const defaultHint =
            displayValue(currentValue) === displayValue(defaultValue)
                ? ''
                : ` (default: ${displayValue(defaultValue)})`;
        const answer = await interactive.question(`${question} [${displayValue(effectiveValue)}]${defaultHint}: `);
        return answer.trim() || effectiveValue;
    };
    const confirm = async (question, currentValue, defaultValue) => {
        const effectiveValue = currentValue ?? defaultValue;
        const defaultHint = effectiveValue === defaultValue ? '' : ` (default: ${defaultValue ? 'yes' : 'no'})`;
        const answer = await interactive.question(`${question} [${effectiveValue ? 'Y/n' : 'y/N'}]${defaultHint}: `);
        const normalized = answer.trim().toLowerCase();
        if (normalized === '') return currentValue ?? defaultValue;
        return normalized === 'y' || normalized === 'yes';
    };

    const defaultOrgAlias = await prompt('Default org alias (optional)', existingConfig?.defaultOrgAlias, undefined);
    const scratchDefinition = await prompt(
        'Scratch definition',
        existingConfig?.scratchDefinition,
        defaultConfig.scratchDefinition
    );
    const scratchDurationDays = Number(
        await prompt('Scratch duration in days', existingConfig?.scratchDurationDays, defaultConfig.scratchDurationDays)
    );
    const permissionSets = splitList(
        await prompt('Permission sets, comma separated (optional)', existingConfig?.permissionSets?.join(','), '')
    );
    const dummyDataPlan = await prompt('Dummy data plan (optional)', existingConfig?.dummyDataPlan, null);
    const communityName = await prompt('Community name (optional)', existingConfig?.communityName, null);
    const postSteps = splitList(
        await prompt('Post-steps (deploy, permsets, data, community)', existingConfig?.postSteps?.join(','), 'deploy')
    );
    const usePool = await confirm('Use a scratch-org pool?', existingConfig?.pool?.use, defaultConfig.pool.use);
    const pool = {
        use: usePool,
        tag: await prompt('Pool tag', existingConfig?.pool?.tag, defaultConfig.pool.tag),
        fallbackToCreate: await confirm(
            'Fall back to direct org creation?',
            existingConfig?.pool?.fallbackToCreate,
            defaultConfig.pool.fallbackToCreate
        )
    };
    const poolDevHub = await prompt('Pool Dev Hub alias (optional)', existingConfig?.pool?.devHub, null);
    if (poolDevHub) pool.devHub = poolDevHub;
    const packageInstallKeyEnvironmentVariable = await prompt(
        'Environment variable for package install keys',
        existingConfig?.packageInstallKeyEnvironmentVariable,
        defaultConfig.packageInstallKeyEnvironmentVariable
    );
    const preserveRootFiles = splitList(
        await prompt(
            'Root files to preserve during dependency cleanup',
            existingConfig?.dependencySourcePolicy?.preserveRootFiles?.join(','),
            defaultConfig.dependencySourcePolicy.preserveRootFiles.join(',')
        )
    );

    return {
        schemaVersion: 1,
        ...(defaultOrgAlias ? { defaultOrgAlias } : {}),
        scratchDefinition,
        scratchDurationDays,
        permissionSets,
        dummyDataPlan: dummyDataPlan || null,
        communityName: communityName || null,
        postSteps,
        pool,
        packageInstallKeyEnvironmentVariable,
        dependencySourcePolicy: { preserveRootFiles }
    };
}

export async function setupProject(argumentsList = process.argv.slice(2), io = { input, output }) {
    const options = parseArguments(argumentsList);
    const projectDirectory = path.resolve(options.projectDirectory);
    const projectFile = path.join(projectDirectory, 'sfdx-project.json');
    const configFile = path.join(projectDirectory, 'sf-project.config.json');

    if (!(await fileExists(projectFile))) {
        throw new Error(`No sfdx-project.json found in ${projectDirectory}`);
    }

    const configExists = await fileExists(configFile);
    let existingConfig = {};
    if (configExists) existingConfig = JSON.parse(await readFile(configFile, 'utf8'));

    if (configExists && !options.nonInteractive && io.input.isTTY) {
        const prompt = readline.createInterface({ input: io.input, output: io.output });
        const config = await createConfiguration(existingConfig, prompt);
        prompt.close();
        await writeFile(configFile, `${JSON.stringify(config, null, 4)}\n`, 'utf8');
    } else if (!configExists) {
        const prompt =
            options.nonInteractive || !io.input.isTTY
                ? null
                : readline.createInterface({ input: io.input, output: io.output });
        const config = await createConfiguration(existingConfig, prompt);
        prompt?.close();
        await writeFile(configFile, `${JSON.stringify(config, null, 4)}\n`, 'utf8');
        io.output.write(
            `Set ${config.packageInstallKeyEnvironmentVariable} only through an approved secret store or environment variable.\n`
        );
        io.output.write(`Wrote ${configFile}\n`);
        return configFile;
    } else {
        const config = await createConfiguration(existingConfig, null);
        await writeFile(configFile, `${JSON.stringify(config, null, 4)}\n`, 'utf8');
        io.output.write(`Completed missing values in ${configFile} using defaults\n`);
        return configFile;
    }

    io.output.write(`Wrote ${configFile}\n`);
    io.output.write(
        `Set the configured package install key only through an approved secret store or environment variable.\n`
    );
    return configFile;
}

if (import.meta.url === `file://${process.argv[1]}`) {
    try {
        await setupProject();
    } catch (error) {
        process.stderr.write(`${error.message}\n`);
        process.exitCode = 2;
    }
}
