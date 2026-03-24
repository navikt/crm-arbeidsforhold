const { execSync } = require('child_process');
const sfdxProject = require('../sfdx-project.json');

// Get all dependencies from packageDirectories
const deps = sfdxProject.packageDirectories
    .filter(dir => dir.dependencies)
    .flatMap(dir => dir.dependencies);

const aliases = sfdxProject.packageAliases || {};

console.log(`${'Package Name'.padEnd(40)} ${'Current'.padEnd(15)} ${'Latest Released'}`);
console.log('-'.repeat(70));

for (const dep of deps) {
    const pkgName = dep.package;
    const currentVersion = dep.versionNumber.replace('.LATEST', '').replace('.NEXT', '');
    const packageId = aliases[pkgName];

    if (!packageId) {
        console.log(`${pkgName.padEnd(40)} ${currentVersion.padEnd(15)} NO ALIAS FOUND`);
        continue;
    }

    try {
        const result = execSync(
            `sf package version list --packages ${packageId} --released --order-by CreatedDate --json`,
            { encoding: 'utf-8', stdio: ['pipe', 'pipe', 'pipe'] }
        );
        const json = JSON.parse(result);
        const versions = json.result || [];
        const latest = versions[versions.length - 1];

        if (latest) {
            const latestVersion = `${latest.MajorVersion}.${latest.MinorVersion}.${latest.PatchVersion}`;
            const outdated = currentVersion !== latestVersion ? ' ⚠️  UPDATE AVAILABLE' : ' ✅';
            console.log(`${pkgName.padEnd(40)} ${currentVersion.padEnd(15)} ${latestVersion}${outdated}`);
        } else {
            console.log(`${pkgName.padEnd(40)} ${currentVersion.padEnd(15)} NO RELEASED VERSION`);
        }
    } catch (err) {
        console.log(`${pkgName.padEnd(40)} ${currentVersion.padEnd(15)} ERROR: ${err.message.split('\n')[0]}`);
    }
}