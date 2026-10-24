const { execFileSync } = require('node:child_process');
const { appendFileSync } = require('node:fs');

function classifyChanges(files, packageDirectories) {
    if (!Array.isArray(packageDirectories) || packageDirectories.length === 0) {
        throw new Error('Expected non-empty packageDirectories in sfdx-project.json.');
    }
    const packagePaths = packageDirectories.map((directory) => {
        if (typeof directory.path !== 'string' || !directory.path.trim()) {
            throw new Error('Invalid package directory path in sfdx-project.json.');
        }
        return `${directory.path.replace(/\/+$/, '')}/`;
    });
    const sharedFiles = new Set([
        'sfdx-project.json',
        'package.json',
        'package-lock.json',
        'scripts/ci-changes.cjs',
        'scripts/tests/ci-changes.test.cjs'
    ]);
    const shared = files.some(
        (file) =>
            sharedFiles.has(file) ||
            file.startsWith('.github/workflows/') ||
            packagePaths.some((directory) => file.startsWith(directory))
    );
    return {
        salesforce:
            shared ||
            files.some(
                (file) =>
                    file === '.forceignore' ||
                    file.startsWith('config/') ||
                    file.startsWith('manifest/') ||
                    file.startsWith('scripts/apex/')
            ),
        lwc: shared || files.some((file) => file === 'jest.config.js' || file === 'jest-sa11y-setup.js')
    };
}

if (require.main === module) {
    const [base, head] = process.argv.slice(2);
    if (!base || !head || !process.env.GITHUB_OUTPUT) {
        throw new Error('Usage: node scripts/ci-changes.cjs <base-sha> <head-sha> with GITHUB_OUTPUT set.');
    }
    const files = execFileSync('git', ['diff', '--name-only', '--no-renames', '-z', `${base}...${head}`, '--'], {
        encoding: 'utf8',
        maxBuffer: 64 * 1024 * 1024
    })
        .split('\0')
        .filter(Boolean);
    const { packageDirectories } = JSON.parse(
        execFileSync('git', ['show', `${base}:sfdx-project.json`], { encoding: 'utf8' })
    );
    const changes = classifyChanges(files, packageDirectories);
    appendFileSync(
        process.env.GITHUB_OUTPUT,
        Object.entries(changes)
            .map(([name, relevant]) => `${name}=${relevant}\n`)
            .join('')
    );
    console.log(`Salesforce validation: ${changes.salesforce}; LWC tests: ${changes.lwc}`);
}

module.exports = { classifyChanges };
