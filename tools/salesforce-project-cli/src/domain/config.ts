/**
 * Loads Salesforce project settings into the normalized configuration used by application services.
 * Paths are resolved absolutely, optional tool settings receive defaults, and malformed configuration fails validation.
 */
import { readFile } from 'node:fs/promises';
import path from 'node:path';
import { z } from 'zod';
import type { PackageDependency } from './packages.js';

/** Built-in post-steps every project can select; a project may declare additional named steps. */
export const BUILTIN_POST_STEPS = ['deploy', 'permsets', 'data', 'community'] as const;

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

const customPostStepSchema = z.object({
    name: z.string().min(1),
    executable: z.string().min(1),
    arguments: z.array(z.string()).default([]),
    label: z.string().min(1).optional()
});

const toolConfigSchema = z
    .object({
        schemaVersion: z.literal(1).default(1),
        defaultOrgAlias: z.string().min(1).optional(),
        scratchDefinition: z.string().min(1).default('config/project-scratch-def.json'),
        scratchDurationDays: z.number().int().min(1).max(30).default(14),
        permissionSets: z.array(z.string().min(1)).default([]),
        dummyDataPlan: z.string().min(1).nullable().default(null),
        communityName: z.string().min(1).nullable().default(null),
        postSteps: z.array(z.string().min(1)).default(['deploy']),
        customPostSteps: z.array(customPostStepSchema).default([]),
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
                preserveRootFiles: z.array(z.string().min(1)).default(['README.md']),
                requireLocalDirectories: z.boolean().default(true)
            })
            .default({ preserveRootFiles: ['README.md'], requireLocalDirectories: true })
    })
    .superRefine((config, ctx) => {
        const customNames = config.customPostSteps.map((step) => step.name);
        for (const name of customNames) {
            if ((BUILTIN_POST_STEPS as readonly string[]).includes(name)) {
                ctx.addIssue({
                    code: z.ZodIssueCode.custom,
                    path: ['customPostSteps'],
                    message: `customPostSteps name collides with a built-in post-step: ${name}`
                });
            }
        }
        const duplicateCustomNames = customNames.filter((name, index) => customNames.indexOf(name) !== index);
        for (const name of new Set(duplicateCustomNames)) {
            ctx.addIssue({
                code: z.ZodIssueCode.custom,
                path: ['customPostSteps'],
                message: `customPostSteps declares the same name more than once: ${name}`
            });
        }
        const knownStepNames = new Set<string>([...BUILTIN_POST_STEPS, ...customNames]);
        for (const step of config.postSteps) {
            if (!knownStepNames.has(step)) {
                ctx.addIssue({
                    code: z.ZodIssueCode.custom,
                    path: ['postSteps'],
                    message: `postSteps references an unknown step: ${step}`
                });
            }
        }
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
    /**
     * Dependency package names with no matching local package directory, present only when
     * `dependencySourcePolicy.requireLocalDirectories` is `false`. `dependencies clear` and
     * `dependencies refresh` report each as a warning and skip it rather than failing.
     */
    unresolvedDependencyNames: string[];
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
    /** Ordered project configuration steps. Values are built-in step names or declared `customPostSteps[].name` values. */
    postSteps: PostStep[];
    /** Project-declared post-steps beyond the built-in `deploy`, `permsets`, `data`, and `community` steps. */
    customPostSteps: CustomPostStep[];
    /** Scratch-org pool defaults. */
    pool: PoolConfiguration;
    /** Default target org alias used when a command does not provide one. */
    defaultOrgAlias?: string;
}

/** Post-configuration step name: a built-in step or a project-declared custom step name. */
export type PostStep = string;

/** A project-declared post-step run as an external command in canonical order after the built-in steps. */
export interface CustomPostStep {
    /** Step name used in `postSteps` selections; must not collide with a built-in step name. */
    name: string;
    /** Executable invoked for this step, using the same command-runner boundary as built-in steps. */
    executable: string;
    /** Literal argument vector passed to the executable. */
    arguments: string[];
    /** Human-readable label shown in interactive output; defaults to the step name. */
    label?: string;
}

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
 * @throws `Error` When a dependency has no declared package directory and
 * `dependencySourcePolicy.requireLocalDirectories` is `true` (the default).
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

    const requireLocalDirectories = toolConfig.dependencySourcePolicy.requireLocalDirectories;
    const dependencySources: DependencySource[] = [];
    const unresolvedDependencyNames: string[] = [];
    for (const packageName of dependencyNames) {
        const packageDirectory = project.packageDirectories.find((candidate) => {
            return candidate.package === packageName || path.basename(candidate.path) === packageName;
        });

        if (!packageDirectory) {
            if (requireLocalDirectories) {
                throw new Error(`Dependency package directory is not declared: ${packageName}`);
            }
            unresolvedDependencyNames.push(packageName);
            continue;
        }

        dependencySources.push({
            packageName,
            directory: path.resolve(resolvedProjectDirectory, packageDirectory.path)
        });
    }

    return {
        projectDirectory: resolvedProjectDirectory,
        preserveRootFiles: toolConfig.dependencySourcePolicy.preserveRootFiles,
        dependencySources,
        unresolvedDependencyNames,
        packageDependencies,
        packageInstallKeyEnvironmentVariable: toolConfig.packageInstallKeyEnvironmentVariable,
        scratchDefinition: path.resolve(resolvedProjectDirectory, toolConfig.scratchDefinition),
        scratchDurationDays: toolConfig.scratchDurationDays,
        permissionSets: toolConfig.permissionSets,
        dummyDataPlan:
            toolConfig.dummyDataPlan === null ? null : path.resolve(resolvedProjectDirectory, toolConfig.dummyDataPlan),
        communityName: toolConfig.communityName,
        postSteps: toolConfig.postSteps,
        customPostSteps: toolConfig.customPostSteps.map((step) => ({
            name: step.name,
            executable: step.executable,
            arguments: step.arguments,
            ...(step.label === undefined ? {} : { label: step.label })
        })),
        pool: {
            use: toolConfig.pool.use,
            tag: toolConfig.pool.tag,
            fallbackToCreate: toolConfig.pool.fallbackToCreate,
            ...(toolConfig.pool.devHub === undefined ? {} : { devHub: toolConfig.pool.devHub })
        },
        ...(toolConfig.defaultOrgAlias === undefined ? {} : { defaultOrgAlias: toolConfig.defaultOrgAlias })
    };
}
