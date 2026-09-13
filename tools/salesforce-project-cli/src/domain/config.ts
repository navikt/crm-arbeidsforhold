/**
 * Loads Salesforce project settings into the normalized configuration used by application services.
 * Paths are resolved absolutely, optional tool settings receive defaults, and malformed configuration fails validation.
 */
import { readFile } from 'node:fs/promises';
import path from 'node:path';
import { z } from 'zod';
import type { PackageDependency } from './packages.js';

const dependencySchema = z.object({
    package: z.string().min(1),
    versionNumber: z.string().optional()
});

const packageDirectorySchema = z.object({
    path: z.string().min(1),
    package: z.string().min(1).optional(),
    dependencies: z.array(dependencySchema).optional()
});

const sfdxProjectSchema = z.object({
    packageDirectories: z.array(packageDirectorySchema).min(1),
    packageAliases: z.record(z.string(), z.string().min(1)).default({}),
    packageKeyConfig: z.record(z.string(), z.boolean()).default({})
});

const toolConfigSchema = z.object({
    schemaVersion: z.literal(1).default(1),
    defaultOrgAlias: z.string().min(1).optional(),
    scratchDefinition: z.string().min(1).default('config/project-scratch-def.json'),
    scratchDurationDays: z.number().int().min(1).max(30).default(14),
    permissionSets: z.array(z.string().min(1)).default([]),
    dummyDataPlan: z.string().min(1).nullable().default(null),
    communityName: z.string().min(1).nullable().default(null),
    postSteps: z.array(z.enum(['deploy', 'permsets', 'data', 'community'])).default(['deploy']),
    pool: z
        .object({
            use: z.boolean().default(false),
            tag: z.string().min(1).default('dev'),
            devHub: z.string().min(1).optional(),
            fallbackToCreate: z.boolean().default(true)
        })
        .default({ use: false, tag: 'dev', fallbackToCreate: true }),
    packageInstallKeyEnvironmentVariable: z.string().min(1).default('PACKAGE_INSTALL_KEY'),
    dependencySourcePolicy: z
        .object({
            preserveRootFiles: z.array(z.string().min(1)).default(['README.md'])
        })
        .default({ preserveRootFiles: ['README.md'] })
});

/** A package dependency whose retrieved metadata is stored inside the project. */
export interface DependencySource {
    /** Package name as declared in `sfdx-project.json`. */
    packageName: string;
    /** Absolute path to the declared package directory. */
    directory: string;
}

/**
 * Validated, normalized configuration consumed by application services.
 *
 * All filesystem paths are absolute. Optional project configuration has already
 * been merged with portable defaults.
 */
export interface ProjectConfiguration {
    /** Absolute Salesforce project root. */
    projectDirectory: string;
    /** Root-level files retained when dependency source directories are cleared. */
    preserveRootFiles: string[];
    /** Declared package dependencies that have local source directories. */
    dependencySources: DependencySource[];
    /** Package dependencies in installation order. */
    packageDependencies: PackageDependency[];
    /** Environment variable from which package installation keys are read. */
    packageInstallKeyEnvironmentVariable: string;
    /** Absolute path to the scratch-org definition. */
    scratchDefinition: string;
    /** Default scratch-org lifetime, constrained to Salesforce limits. */
    scratchDurationDays: number;
    /** Permission sets assigned by the `permsets` post-step. */
    permissionSets: string[];
    /** Absolute dummy-data plan path, or `null` when data import is disabled. */
    dummyDataPlan: string | null;
    /** Experience Cloud community name, or `null` when publishing is disabled. */
    communityName: string | null;
    /** Ordered project configuration steps. */
    postSteps: PostStep[];
    /** Scratch-org pool defaults. */
    pool: PoolConfiguration;
    /** Default target org alias used when a command does not provide one. */
    defaultOrgAlias?: string;
}

/** Supported project post-configuration steps. */
export type PostStep = 'deploy' | 'permsets' | 'data' | 'community';

/** Defaults for optional scratch-org pool acquisition. */
export interface PoolConfiguration {
    /** Whether org creation should try the configured pool first. */
    use: boolean;
    /** Pool tag passed to the `sfp` command. */
    tag: string;
    /** Whether an empty or unavailable pool may fall back to org creation. */
    fallbackToCreate: boolean;
    /** Explicit Dev Hub alias or username for pool commands. */
    devHub?: string;
}

async function readJson(filePath: string): Promise<unknown> {
    return JSON.parse(await readFile(filePath, 'utf8'));
}

/**
 * Loads and normalizes Salesforce and tool configuration for one project.
 *
 * `sfdx-project.json` is required. `sf-project.config.json` is optional and is
 * merged with schema defaults before relative paths are resolved.
 *
 * @param projectDirectory - Salesforce project root, absolute or relative to the current process.
 * @returns A validated configuration with absolute filesystem paths.
 * @throws `SyntaxError` When a configuration file is not valid JSON.
 * @throws `z.ZodError` When either configuration violates its schema.
 * @throws `Error` When a dependency has no declared package directory.
 */
export async function loadProjectConfiguration(projectDirectory: string): Promise<ProjectConfiguration> {
    const resolvedProjectDirectory = path.resolve(projectDirectory);
    const project = sfdxProjectSchema.parse(await readJson(path.join(resolvedProjectDirectory, 'sfdx-project.json')));

    let toolConfig = toolConfigSchema.parse({});
    try {
        toolConfig = toolConfigSchema.parse(
            await readJson(path.join(resolvedProjectDirectory, 'sf-project.config.json'))
        );
    } catch (error) {
        if (!(error instanceof Error && 'code' in error && error.code === 'ENOENT')) {
            throw error;
        }
    }

    const dependencyNames = [
        ...new Set(
            project.packageDirectories.flatMap((packageDirectory) =>
                (packageDirectory.dependencies ?? []).map((dependency) => dependency.package)
            )
        )
    ];

    const packageDependencies = project.packageDirectories.flatMap((packageDirectory) =>
        (packageDirectory.dependencies ?? []).map((dependency) => {
            const packageAlias = project.packageAliases[dependency.package];
            return {
                packageName: dependency.package,
                ...(packageAlias === undefined ? {} : { packageAlias }),
                ...(dependency.versionNumber === undefined ? {} : { configuredVersion: dependency.versionNumber }),
                requiresInstallationKey: project.packageKeyConfig[dependency.package] ?? true
            };
        })
    );

    const dependencySources = dependencyNames.map((packageName) => {
        const packageDirectory = project.packageDirectories.find((candidate) => {
            return candidate.package === packageName || path.basename(candidate.path) === packageName;
        });

        if (!packageDirectory) {
            throw new Error(`Dependency package directory is not declared: ${packageName}`);
        }

        return {
            packageName,
            directory: path.resolve(resolvedProjectDirectory, packageDirectory.path)
        };
    });

    return {
        projectDirectory: resolvedProjectDirectory,
        preserveRootFiles: toolConfig.dependencySourcePolicy.preserveRootFiles,
        dependencySources,
        packageDependencies,
        packageInstallKeyEnvironmentVariable: toolConfig.packageInstallKeyEnvironmentVariable,
        scratchDefinition: path.resolve(resolvedProjectDirectory, toolConfig.scratchDefinition),
        scratchDurationDays: toolConfig.scratchDurationDays,
        permissionSets: toolConfig.permissionSets,
        dummyDataPlan:
            toolConfig.dummyDataPlan === null ? null : path.resolve(resolvedProjectDirectory, toolConfig.dummyDataPlan),
        communityName: toolConfig.communityName,
        postSteps: toolConfig.postSteps,
        pool: {
            use: toolConfig.pool.use,
            tag: toolConfig.pool.tag,
            fallbackToCreate: toolConfig.pool.fallbackToCreate,
            ...(toolConfig.pool.devHub === undefined ? {} : { devHub: toolConfig.pool.devHub })
        },
        ...(toolConfig.defaultOrgAlias === undefined ? {} : { defaultOrgAlias: toolConfig.defaultOrgAlias })
    };
}
