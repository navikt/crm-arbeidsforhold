const { execSync } = require('node:child_process');
const fs = require('node:fs');
const readline = require('node:readline');
const path = require('node:path');

const ROOT_PROJECT_PATH = path.join(__dirname, '..', 'sfdx-project.json');

const TIMEOUT_MS = 120000;
const MAX_RETRIES = 2;
const RETRY_DELAY_MS = 5000;

function isValidPackageId(id) {
    return /^0Ho[a-zA-Z0-9]{12,15}$/.test(id);
}

function normalizeVersion(version) {
    return version.replace(/\.(?:LATEST|NEXT)$/, '');
}

function isValidVersionString(version) {
    return /^\d+\.\d+\.\d+$/.test(version);
}

function compareVersions(left, right) {
    const leftParts = normalizeVersion(left).split('.').map(Number);
    const rightParts = normalizeVersion(right).split('.').map(Number);

    for (let index = 0; index < 3; index++) {
        if (leftParts[index] !== rightParts[index]) {
            return leftParts[index] > rightParts[index] ? 1 : -1;
        }
    }
    return 0;
}

function sleep(milliseconds) {
    const waitTime = Math.max(0, Math.ceil(milliseconds));
    Atomics.wait(new Int32Array(new SharedArrayBuffer(4)), 0, 0, waitTime);
}

function runWithRetry(command, retries = MAX_RETRIES, { exec = execSync, sleepFn = sleep, logger = console } = {}) {
    for (let attempt = 0; attempt <= retries; attempt++) {
        try {
            return exec(command, {
                encoding: 'utf-8',
                stdio: ['pipe', 'pipe', 'pipe'],
                timeout: TIMEOUT_MS
            });
        } catch (error) {
            const isTimeout = error.message.includes('ETIMEDOUT') || error.message.includes('TIMEOUT');
            if (!isTimeout || attempt === retries) {
                throw error;
            }

            logger.log(`    ⏳ Timeout, retrying (${attempt + 1}/${retries})...`);
            sleepFn(RETRY_DELAY_MS);
        }
    }
}

function promptForUpdate(question) {
    const rl = readline.createInterface({ input: process.stdin, output: process.stdout });
    return new Promise((resolve) => {
        rl.question(question, (answer) => {
            rl.close();
            resolve(answer);
        });
    });
}

function updateSfdxProject(projectPath, backupPath, updates) {
    const projectData = JSON.parse(fs.readFileSync(projectPath, 'utf-8'));
    fs.copyFileSync(projectPath, backupPath);

    for (const update of updates) {
        if (!isValidVersionString(update.latestVersion)) {
            throw new Error(`Invalid version format for ${update.packageName}: ${update.latestVersion}`);
        }

        for (const directory of projectData.packageDirectories) {
            if (!directory.dependencies) continue;

            for (const dependency of directory.dependencies) {
                if (dependency.package === update.packageName) {
                    dependency.versionNumber = `${update.latestVersion}.LATEST`;
                }
            }
        }
    }

    fs.writeFileSync(projectPath, `${JSON.stringify(projectData, null, 4)}\n`, 'utf-8');
}

async function main({
    projectPath = ROOT_PROJECT_PATH,
    exec = execSync,
    prompt = promptForUpdate,
    sleepFn = sleep,
    retries = MAX_RETRIES,
    logger = console
} = {}) {
    const backupPath = `${projectPath}.backup`;
    let sfdxProject;
    try {
        sfdxProject = JSON.parse(fs.readFileSync(projectPath, 'utf-8'));
    } catch (error) {
        logger.error(`\n❌ Unable to read sfdx-project.json: ${error.message}\n`);
        return 1;
    }

    try {
        exec('sf org list --json', {
            encoding: 'utf-8',
            stdio: ['pipe', 'pipe', 'pipe'],
            timeout: TIMEOUT_MS
        });
    } catch (error) {
        logger.error('\n❌ SF CLI not authenticated or not installed. Run: sf org login devhub\n');
        return 1;
    }

    const dependencies = sfdxProject.packageDirectories
        .filter((directory) => directory.dependencies)
        .flatMap((directory) => directory.dependencies);
    const aliases = sfdxProject.packageAliases || {};
    const updatesAvailable = [];

    logger.log(`\n${'Package Name'.padEnd(40)} ${'Current'.padEnd(15)} ${'Latest Released'}`);
    logger.log('-'.repeat(80));

    for (const dependency of dependencies) {
        const packageName = dependency.package;
        const currentVersion = normalizeVersion(dependency.versionNumber);
        const packageId = aliases[packageName];

        if (!packageId) {
            logger.log(`${packageName.padEnd(40)} ${currentVersion.padEnd(15)} NO ALIAS FOUND`);
            continue;
        }

        if (!isValidPackageId(packageId)) {
            logger.log(`${packageName.padEnd(40)} ${currentVersion.padEnd(15)} INVALID PACKAGE ID`);
            continue;
        }

        try {
            const result = runWithRetry(
                `sf package version list --packages ${packageId} --released --order-by CreatedDate --json`,
                retries,
                { exec, sleepFn, logger }
            );
            const json = JSON.parse(result);
            const versions = json.result || [];
            const latest = versions[versions.length - 1];

            if (!latest) {
                logger.log(`${packageName.padEnd(40)} ${currentVersion.padEnd(15)} NO RELEASED VERSION`);
                continue;
            }

            const latestVersion = `${latest.MajorVersion}.${latest.MinorVersion}.${latest.PatchVersion}`;
            if (!isValidVersionString(latestVersion)) {
                logger.log(`${packageName.padEnd(40)} ${currentVersion.padEnd(15)} INVALID VERSION FORMAT`);
                continue;
            }

            const outdated = compareVersions(currentVersion, latestVersion) < 0;
            const status = outdated ? ' ⚠️  UPDATE AVAILABLE' : ' ✅';
            logger.log(`${packageName.padEnd(40)} ${currentVersion.padEnd(15)} ${latestVersion}${status}`);

            if (outdated) {
                updatesAvailable.push({ packageName, currentVersion, latestVersion });
            }
        } catch (error) {
            const errorMessage = error.message.includes('ETIMEDOUT')
                ? 'TIMEOUT (try again later)'
                : error.message.split('\n')[0];
            logger.log(`${packageName.padEnd(40)} ${currentVersion.padEnd(15)} ERROR: ${errorMessage}`);
        }
    }

    if (updatesAvailable.length === 0) {
        logger.log('\n✅ All packages are up to date!\n');
        return 0;
    }

    logger.log(`\n⚠️  ${updatesAvailable.length} package(s) have updates available:\n`);
    updatesAvailable.forEach((update, index) => {
        logger.log(`  ${index + 1}. ${update.packageName}: ${update.currentVersion} → ${update.latestVersion}`);
    });

    const answer = await prompt('\nDo you want to update sfdx-project.json? (YES/NO): ');
    if (answer.trim().toUpperCase() !== 'YES') {
        logger.log('\n❌ No changes made to sfdx-project.json\n');
        return 0;
    }

    try {
        updateSfdxProject(projectPath, backupPath, updatesAvailable);
        logger.log('\n✅ sfdx-project.json has been updated!\n');
        logger.log('Updated packages:');
        updatesAvailable.forEach((update) => {
            logger.log(`  ✅ ${update.packageName}: ${update.currentVersion} → ${update.latestVersion}`);
        });
        logger.log(`\n💾 Backup saved to: ${backupPath}`);
    } catch (error) {
        logger.error(`\n❌ Error updating file: ${error.message}`);
        if (fs.existsSync(backupPath)) {
            fs.copyFileSync(backupPath, projectPath);
            logger.log('🔄 Restored from backup.');
        }
        return 1;
    }
    return 0;
}

if (require.main === module) {
    main()
        .then((exitCode) => {
            process.exitCode = exitCode;
        })
        .catch((error) => {
            console.error(error);
            process.exitCode = 1;
        });
}

module.exports = {
    compareVersions,
    isValidPackageId,
    isValidVersionString,
    main,
    normalizeVersion,
    runWithRetry,
    sleep,
    updateSfdxProject
};
