/**
 * Clears configured dependency source roots while retaining explicitly preserved files.
 * Realpath containment and symlink checks guard every deletion; dry runs perform no directory mutation.
 */
import { lstat, readdir, realpath, rm } from 'node:fs/promises';
import path from 'node:path';
import type { EventSink } from '../domain/events.js';
import type { ProjectConfiguration } from '../domain/config.js';

/** Inputs for clearing configured dependency source directories. */
export interface ClearDependencySourcesOptions {
    /** Validated project configuration containing dependency roots and preserved filenames. */
    configuration: ProjectConfiguration;
    /** When `true`, emits the planned cleanup without reading or removing directory entries. */
    dryRun: boolean;
    /** Correlation identifier copied to every emitted progress event. */
    operationId: string;
    /** Event sink that receives one progress event per existing dependency directory. */
    emit: EventSink;
}

function assertContained(projectDirectory: string, dependencyDirectory: string): void {
    const relativePath = path.relative(projectDirectory, dependencyDirectory);
    if (relativePath === '' || relativePath.startsWith('..') || path.isAbsolute(relativePath)) {
        throw new Error(`Dependency directory is outside the project root: ${dependencyDirectory}`);
    }
}

async function assertStableDependencyRoot(dependencyDirectory: string, expectedRealPath: string): Promise<void> {
    const currentRootStats = await lstat(dependencyDirectory);
    if (currentRootStats.isSymbolicLink() || (await realpath(dependencyDirectory)) !== expectedRealPath) {
        throw new Error(`Dependency directory changed during cleanup: ${dependencyDirectory}`);
    }
}

/**
 * Removes non-preserved entries from each configured dependency source directory.
 *
 * Missing dependency directories are skipped. Existing roots and children must remain
 * real, contained, non-symbolic-link paths throughout cleanup to prevent deletion outside
 * the project. A dry run emits the same per-directory intent but performs no directory
 * enumeration or mutation.
 *
 * @param options - Validated configuration, dry-run mode, event sink, and operation identity.
 * @returns A promise that resolves after every existing dependency directory is processed.
 * @throws `Error` When a dependency path escapes the project, is a symbolic link,
 * changes during cleanup, contains a symbolic-link child, or cannot be inspected or removed.
 */
export async function clearDependencySources(options: ClearDependencySourcesOptions): Promise<void> {
    const projectRealPath = await realpath(options.configuration.projectDirectory);

    for (const dependency of options.configuration.dependencySources) {
        // Validate declared and resolved paths, then recheck the root around each deletion to resist symlink swaps.
        assertContained(options.configuration.projectDirectory, dependency.directory);

        let dependencyRealPath: string;
        try {
            const stats = await lstat(dependency.directory);
            if (stats.isSymbolicLink()) {
                throw new Error(`Dependency directory must not be a symbolic link: ${dependency.directory}`);
            }
            dependencyRealPath = await realpath(dependency.directory);
        } catch (error) {
            if (error instanceof Error && 'code' in error && error.code === 'ENOENT') {
                continue;
            }
            throw error;
        }

        assertContained(projectRealPath, dependencyRealPath);

        options.emit({
            kind: 'progress',
            operationId: options.operationId,
            timestamp: new Date().toISOString(),
            stepId: `clear-dependency-source:${dependency.packageName}`,
            step: 'Clear dependency source',
            message: options.dryRun ? `Would clear ${dependency.packageName}` : `Clearing ${dependency.packageName}`,
            packageName: dependency.packageName,
            directory: dependency.directory,
            preservedFiles: options.configuration.preserveRootFiles,
            dryRun: options.dryRun
        });

        if (options.dryRun) {
            continue;
        }

        const entries = await readdir(dependencyRealPath, { withFileTypes: true });
        for (const entry of entries.filter(
            (candidate) => !options.configuration.preserveRootFiles.includes(candidate.name)
        )) {
            await assertStableDependencyRoot(dependency.directory, dependencyRealPath);

            const childPath = path.join(dependencyRealPath, entry.name);
            assertContained(dependencyRealPath, childPath);
            const childStats = await lstat(childPath);
            if (childStats.isSymbolicLink()) {
                throw new Error(`Dependency child must not be a symbolic link: ${childPath}`);
            }
            const childRealPath = await realpath(childPath);
            assertContained(dependencyRealPath, childRealPath);
            await assertStableDependencyRoot(dependency.directory, dependencyRealPath);
            await rm(childRealPath, { force: true, recursive: true });
        }
    }
}
