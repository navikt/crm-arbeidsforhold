import { execFile } from 'node:child_process';
import { mkdtemp, readFile, rm, writeFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import path from 'node:path';
import { promisify } from 'node:util';

const execute = promisify(execFile);
const packageDirectory = path.resolve(import.meta.dirname, '..');
const fixtureDirectory = await mkdtemp(path.join(tmpdir(), 'sf-project-pack-'));

try {
    const { stdout: packOutput } = await execute('npm', ['pack', '--json', '--pack-destination', fixtureDirectory], {
        cwd: packageDirectory
    });
    const [{ filename, files }] = JSON.parse(packOutput);
    const tarball = path.join(fixtureDirectory, filename);
    const forbiddenEntries = files
        .map(({ path: filePath }) => filePath)
        .filter((filePath) => /(?:\.map$|node_modules|test-results|screenshots?|\.env|auth)/iu.test(filePath));
    if (forbiddenEntries.length > 0) {
        throw new Error(`Packed CLI contains forbidden files: ${forbiddenEntries.join(', ')}`);
    }
    const fixturePackage = {
        name: 'salesforce-project-cli-pack-smoke',
        private: true,
        version: '1.0.0'
    };
    await writeFile(path.join(fixtureDirectory, 'package.json'), JSON.stringify(fixturePackage));
    await execute('npm', ['install', '--omit=dev', '--ignore-scripts', '--no-audit', '--no-fund', tarball], {
        cwd: fixtureDirectory
    });

    const installedPackage = JSON.parse(
        await readFile(path.join(fixtureDirectory, 'node_modules/@navikt/salesforce-project-cli/package.json'), 'utf8')
    );
    const installedWebApp = await readFile(
        path.join(fixtureDirectory, 'node_modules/@navikt/salesforce-project-cli/web-dist/index.html'),
        'utf8'
    );
    const installedDocumentation = await readFile(
        path.join(fixtureDirectory, 'node_modules/@navikt/salesforce-project-cli/docs/README.md'),
        'utf8'
    );
    const installedArchitecture = await readFile(
        path.join(fixtureDirectory, 'node_modules/@navikt/salesforce-project-cli/docs/architecture.md'),
        'utf8'
    );
    const installedSecurityPolicy = await readFile(
        path.join(fixtureDirectory, 'node_modules/@navikt/salesforce-project-cli/SECURITY.md'),
        'utf8'
    );
    const cliPath = path.join(fixtureDirectory, 'node_modules/@navikt/salesforce-project-cli/dist/cli.js');
    const { stdout: helpOutput } = await execute(process.execPath, [cliPath, '--help'], {
        cwd: fixtureDirectory
    });
    const bundledFrontendPackages = ['@navikt/aksel-icons', '@navikt/ds-css', '@navikt/ds-react', 'react', 'react-dom'];
    const unexpectedRuntimeDependencies = bundledFrontendPackages.filter(
        (packageName) => installedPackage.dependencies?.[packageName] !== undefined
    );

    if (
        installedPackage.version !== '0.1.0' ||
        !helpOutput.includes('doctor') ||
        !installedWebApp.includes('<div id="root"></div>') ||
        !installedDocumentation.includes('Salesforce Project CLI documentation') ||
        !installedArchitecture.includes('# Architecture') ||
        !installedSecurityPolicy.includes('# Security') ||
        unexpectedRuntimeDependencies.length > 0
    ) {
        throw new Error(
            `Packed CLI did not expose the expected production-only runtime: ${unexpectedRuntimeDependencies.join(', ')}`
        );
    }
    process.stdout.write(`Pack smoke passed: ${filename}\n`);
} finally {
    await rm(fixtureDirectory, { force: true, recursive: true });
}
