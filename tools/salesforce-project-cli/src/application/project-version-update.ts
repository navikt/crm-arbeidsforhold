/**
 * Compares package constraints with released versions and optionally updates the project file.
 * Applying changes creates a sibling backup before atomically replacing sfdx-project.json.
 */
import { copyFile, readFile, rename, rm, writeFile } from 'node:fs/promises';
import { randomUUID } from 'node:crypto';
import path from 'node:path';
import { selectLatestPackageVersion, type PackageVersion } from '../domain/packages.js';
import type { CommandResult } from '../infrastructure/command-runner.js';
import type { CommandRunner } from './refresh-dependencies.js';

/** One package constraint that differs from its latest released major/minor/patch version. */
export interface ProjectPackageVersionChange {
    /** Dependency name as declared in sfdx-project.json. */
    packageName: string;
    /** Existing dependency constraint, or an empty string when none is set. */
    currentVersion: string;
    /** Suggested latest base version constraint. */
    latestVersion: string;
}

/** Inputs and result controls for checking or applying package version updates. */
export interface UpdateProjectPackageVersionsOptions {
    /** Absolute project configuration and directory context. */
    configuration: { projectDirectory: string };
    /** Whether changes should be written; false is a read-only preview. */
    apply: boolean;
    /** Injected Salesforce command runner for released package version queries. */
    runCommand: CommandRunner;
}

/** Result of previewing or applying latest released package constraints. */
export interface UpdateProjectPackageVersionsResult {
    /** Per-package constraints that differ from latest released versions. */
    changes: ProjectPackageVersionChange[];
    /** Whether the project file was updated. */
    applied: boolean;
    /** Backup file path when an update was applied. */
    backupPath?: string;
}

interface DependencyEntry {
    package?: unknown;
    versionNumber?: unknown;
}

interface PackageDirectoryEntry {
    dependencies?: DependencyEntry[];
}

interface SfdxProjectDocument {
    packageDirectories: PackageDirectoryEntry[];
    packageAliases?: Record<string, string>;
}

interface VersionListResponse {
    status?: number;
    message?: string;
    result?: Array<{
        MajorVersion?: unknown;
        MinorVersion?: unknown;
        PatchVersion?: unknown;
        BuildNumber?: unknown;
        SubscriberPackageVersionId?: unknown;
    }>;
}

async function latestReleasedVersion(
    packageName: string,
    packageAlias: string,
    projectDirectory: string,
    runCommand: CommandRunner
): Promise<PackageVersion> {
    const result = await runCommand({
        executable: 'sf',
        arguments: [
            'package',
            'version',
            'list',
            '--packages',
            packageAlias,
            '--released',
            '--order-by',
            'CreatedDate',
            '--json'
        ],
        cwd: projectDirectory
    });
    if (result.failed || result.exitCode !== 0) {
        throw new Error(result.error ?? result.stderr ?? `Could not list released versions for ${packageName}`);
    }

    let response: VersionListResponse;
    try {
        response = JSON.parse(result.stdout) as VersionListResponse;
    } catch {
        throw new Error(`Package version list for ${packageName} returned malformed JSON`);
    }
    if (response.status !== undefined && response.status !== 0) {
        throw new Error(response.message ?? `Could not list released versions for ${packageName}`);
    }

    const versions = (response.result ?? []).flatMap((record) => {
        const components = [record.MajorVersion, record.MinorVersion, record.PatchVersion, record.BuildNumber];
        if (!components.every((component) => Number.isInteger(component))) return [];
        if (typeof record.SubscriberPackageVersionId !== 'string') return [];
        return [{ versionNumber: components.join('.'), subscriberPackageVersionId: record.SubscriberPackageVersionId }];
    });
    try {
        return selectLatestPackageVersion(versions);
    } catch {
        throw new Error(`No valid released package version was returned for ${packageName}`);
    }
}

function baseVersion(versionNumber: string): string {
    return versionNumber.split('.').slice(0, 3).join('.');
}

/**
 * Previews package version changes, or applies them with a backup when explicitly requested.
 *
 * All dependency entries for the same package are updated together. Unrelated project JSON is
 * preserved. The write is prepared beside the source file and renamed into place after backup.
 *
 * @param options - Project directory, explicit apply choice, and command runner.
 * @returns Suggested changes and whether they were applied.
 * @throws `Error` When project JSON, package aliases, released versions, or filesystem writes fail.
 */
export async function updateProjectPackageVersions(
    options: UpdateProjectPackageVersionsOptions
): Promise<UpdateProjectPackageVersionsResult> {
    const projectFile = path.join(options.configuration.projectDirectory, 'sfdx-project.json');
    const original = await readFile(projectFile, 'utf8');
    let project: SfdxProjectDocument;
    try {
        project = JSON.parse(original) as SfdxProjectDocument;
    } catch {
        throw new Error('sfdx-project.json is not valid JSON');
    }
    if (!Array.isArray(project.packageDirectories))
        throw new Error('sfdx-project.json packageDirectories must be an array');

    const dependencies = project.packageDirectories.flatMap((directory) => directory.dependencies ?? []);
    const packageNames = [
        ...new Set(
            dependencies.flatMap((dependency) => (typeof dependency.package === 'string' ? [dependency.package] : []))
        )
    ];
    const changes: ProjectPackageVersionChange[] = [];
    const selectedVersions = new Map<string, string>();

    for (const packageName of packageNames) {
        const alias = project.packageAliases?.[packageName];
        if (typeof alias !== 'string' || alias.length === 0)
            throw new Error(`Package alias is not declared: ${packageName}`);
        const latest = await latestReleasedVersion(
            packageName,
            alias,
            options.configuration.projectDirectory,
            options.runCommand
        );
        const latestBase = baseVersion(latest.versionNumber);
        const configured = dependencies.find((dependency) => dependency.package === packageName)?.versionNumber;
        const configuredBase = typeof configured === 'string' ? baseVersion(configured) : '';
        if (configuredBase !== latestBase) {
            const latestVersion = `${latestBase}.LATEST`;
            selectedVersions.set(packageName, latestVersion);
            changes.push({
                packageName,
                currentVersion: typeof configured === 'string' ? configured : '',
                latestVersion
            });
        }
    }

    if (!options.apply || changes.length === 0) return { changes, applied: false };

    for (const directory of project.packageDirectories) {
        for (const dependency of directory.dependencies ?? []) {
            if (typeof dependency.package !== 'string') continue;
            const latestVersion = selectedVersions.get(dependency.package);
            if (latestVersion !== undefined) dependency.versionNumber = latestVersion;
        }
    }

    const backupPath = `${projectFile}.backup`;
    const temporaryPath = `${projectFile}.${process.pid}.${randomUUID()}.tmp`;
    try {
        const formatted = `${JSON.stringify(project, null, 4)}\n`;
        await writeFile(temporaryPath, formatted, 'utf8');
        await copyFile(projectFile, backupPath);
        await rename(temporaryPath, projectFile);
    } finally {
        await rm(temporaryPath, { force: true });
    }
    return { changes, applied: true, backupPath };
}
