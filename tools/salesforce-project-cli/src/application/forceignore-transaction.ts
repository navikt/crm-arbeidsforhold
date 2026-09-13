/**
 * Manages durable transactions that temporarily disable and reliably restore `.forceignore`.
 * Marker identity, real paths, and content digests must validate before recovery or cleanup mutates files.
 */
import { createHash } from 'node:crypto';
import { constants } from 'node:fs';
import { copyFile, link, lstat, open, realpath, rm } from 'node:fs/promises';
import path from 'node:path';
import { z } from 'zod';
import { EXIT_CODES, type EventSink, type ExitCode } from '../domain/events.js';

const FORCEIGNORE_FILE = '.forceignore';
const MARKER_FILE = '.forceignore.sf-project.lock';

const transactionMarkerSchema = z.object({
    version: z.literal(1),
    transactionId: z.string().regex(/^[A-Za-z0-9-]{1,128}$/),
    projectRealPath: z.string().min(1),
    forceignoreFile: z.literal(FORCEIGNORE_FILE),
    backupFile: z.string().regex(/^\.forceignore\.sf-project-[A-Za-z0-9-]{1,128}\.backup$/),
    originalContentBase64: z.string(),
    originalSha256: z.string().regex(/^[a-f0-9]{64}$/),
    originalByteLength: z.number().int().nonnegative(),
    originalExisted: z.boolean().default(true),
    createdAt: z.iso.datetime()
});

type TransactionMarker = z.infer<typeof transactionMarkerSchema>;

/** Inputs for inspecting and recovering an interrupted `.forceignore` transaction. */
export interface RecoverForceignoreOptions {
    /** Project root containing the transaction marker and backup. */
    projectDirectory: string;
    /** When `true`, validates and reports recovery without modifying transaction files. */
    dryRun: boolean;
    /** Correlation identifier copied to recovery events. */
    operationId: string;
    /** Event sink receiving the recovery result or actionable failure. */
    emit: EventSink;
}

/** Exclusive lease that keeps `.forceignore` disabled until restoration. */
export interface ForceignoreLease {
    /** Restores the validated original file, removes transaction artifacts, and is safe to call repeatedly. */
    restore: () => Promise<void>;
}

/** Minimal signal-listener contract used to inject process-like cleanup behavior. */
export interface SignalTarget {
    /** Registers a one-shot listener for an interrupt or termination signal. */
    once: (signal: 'SIGINT' | 'SIGTERM', listener: () => void) => unknown;
    /** Removes a previously registered signal listener. */
    removeListener: (signal: 'SIGINT' | 'SIGTERM', listener: () => void) => unknown;
}

function sha256(content: Buffer): string {
    return createHash('sha256').update(content).digest('hex');
}

function isMissing(error: unknown): boolean {
    return error instanceof Error && 'code' in error && error.code === 'ENOENT';
}

async function readRegularFile(filePath: string, label: string): Promise<Buffer> {
    const handle = await open(filePath, constants.O_RDONLY | constants.O_NOFOLLOW);
    try {
        const stats = await handle.stat();
        if (!stats.isFile()) {
            throw new Error(`${label} must be a regular file: ${filePath}`);
        }
        return await handle.readFile();
    } finally {
        await handle.close();
    }
}

function assertOriginal(marker: TransactionMarker, content: Buffer): void {
    if (
        content.byteLength !== marker.originalByteLength ||
        sha256(content) !== marker.originalSha256 ||
        content.toString('base64') !== marker.originalContentBase64
    ) {
        throw new Error('The transaction backup does not match the original .forceignore recorded in the marker.');
    }
}

async function loadValidatedTransaction(projectDirectory: string): Promise<{
    marker: TransactionMarker;
    markerPath: string;
    backupPath: string;
    forceignorePath: string;
    original: Buffer;
}> {
    // Resolve and verify every transaction artifact before trusting marker-controlled paths or content.
    const projectRealPath = await realpath(projectDirectory);
    const markerPath = path.join(projectRealPath, MARKER_FILE);
    const markerContent = await readRegularFile(markerPath, 'The forceignore transaction marker');
    const marker = transactionMarkerSchema.parse(JSON.parse(markerContent.toString('utf8')));

    if (marker.projectRealPath !== projectRealPath) {
        throw new Error('The forceignore transaction marker belongs to a different project path.');
    }

    const expectedBackupFile = `.forceignore.sf-project-${marker.transactionId}.backup`;
    if (marker.backupFile !== expectedBackupFile || path.basename(marker.backupFile) !== marker.backupFile) {
        throw new Error('The forceignore transaction marker has an invalid backup identity.');
    }

    const backupPath = path.join(projectRealPath, marker.backupFile);
    const backupRealPath = await realpath(backupPath);
    if (path.dirname(backupRealPath) !== projectRealPath || backupRealPath !== backupPath) {
        throw new Error('The forceignore transaction backup is not a project-root regular file.');
    }
    const original = await readRegularFile(backupPath, 'The forceignore transaction backup');
    assertOriginal(marker, original);

    return {
        marker,
        markerPath,
        backupPath,
        forceignorePath: path.join(projectRealPath, FORCEIGNORE_FILE),
        original
    };
}

async function restoreValidatedTransaction(
    transaction: Awaited<ReturnType<typeof loadValidatedTransaction>>,
    dryRun: boolean
): Promise<'restored' | 'already-restored' | 'planned'> {
    let activeContent: Buffer | undefined;
    try {
        activeContent = await readRegularFile(transaction.forceignorePath, 'The active .forceignore');
    } catch (error) {
        if (!isMissing(error)) {
            throw error;
        }
    }

    if (activeContent !== undefined) {
        if (!transaction.marker.originalExisted || !activeContent.equals(transaction.original)) {
            throw new Error('An active .forceignore differs from the interrupted transaction original.');
        }
        if (!dryRun) {
            await rm(transaction.backupPath);
            await rm(transaction.markerPath);
        }
        return dryRun ? 'planned' : 'already-restored';
    }

    if (dryRun) {
        return 'planned';
    }

    if (!transaction.marker.originalExisted) {
        await rm(transaction.backupPath);
        await rm(transaction.markerPath);
        return 'already-restored';
    }

    await copyFile(transaction.backupPath, transaction.forceignorePath, constants.COPYFILE_EXCL);
    const restored = await readRegularFile(transaction.forceignorePath, 'The restored .forceignore');
    assertOriginal(transaction.marker, restored);
    await rm(transaction.backupPath);
    await rm(transaction.markerPath);
    return 'restored';
}

/**
 * Recovers or cleans up a durable `.forceignore` transaction left by an interrupted refresh.
 *
 * The marker, backup identity, project realpath, and original content digest must all validate
 * before recovery. No marker is a successful no-op. Expected validation and conflict failures
 * are emitted and returned as `EXIT_CODES.OPERATION_FAILURE`; they do not escape.
 *
 * @param options - Project path, dry-run mode, event sink, and operation identity.
 * @returns Success for no transaction or a validated recovery, otherwise operation failure.
 * @throws `Error` When the initial marker lookup or event sink fails outside the guarded
 * recovery stage.
 */
export async function recoverForceignoreTransaction(options: RecoverForceignoreOptions): Promise<ExitCode> {
    const markerPath = path.join(options.projectDirectory, MARKER_FILE);
    try {
        await lstat(markerPath);
    } catch (error) {
        if (isMissing(error)) {
            options.emit({
                kind: 'progress',
                operationId: options.operationId,
                timestamp: new Date().toISOString(),
                stepId: 'recover-forceignore',
                step: 'Recover .forceignore',
                message: 'No interrupted .forceignore transaction was found',
                dryRun: options.dryRun
            });
            return EXIT_CODES.SUCCESS;
        }
        throw error;
    }

    try {
        const transaction = await loadValidatedTransaction(options.projectDirectory);
        const result = await restoreValidatedTransaction(transaction, options.dryRun);
        options.emit({
            kind: 'progress',
            operationId: options.operationId,
            timestamp: new Date().toISOString(),
            stepId: 'recover-forceignore',
            step: 'Recover .forceignore',
            message:
                result === 'planned'
                    ? 'Would restore .forceignore from the validated interrupted transaction'
                    : result === 'restored'
                        ? 'Restored .forceignore from the validated interrupted transaction'
                        : 'Validated the active .forceignore and cleaned the interrupted transaction',
            dryRun: options.dryRun
        });
        return EXIT_CODES.SUCCESS;
    } catch (error) {
        options.emit({
            kind: 'step-failed',
            operationId: options.operationId,
            timestamp: new Date().toISOString(),
            stepId: 'recover-forceignore',
            step: 'Recover .forceignore',
            exitCode: null,
            durationMs: 0,
            error: error instanceof Error ? error.message : String(error),
            nextAction:
                'Inspect .forceignore.sf-project.lock and its named backup. Resolve the active .forceignore conflict or invalid files, then rerun dependencies recover.'
        });
        return EXIT_CODES.OPERATION_FAILURE;
    }
}

async function writeSyncedExclusive(filePath: string, content: Buffer): Promise<void> {
    const handle = await open(filePath, 'wx', 0o600);
    try {
        await handle.writeFile(content);
        await handle.sync();
    } finally {
        await handle.close();
    }
}

/**
 * Durably removes `.forceignore` and returns a lease that restores its original state.
 *
 * The function exclusively creates and syncs a content-verified backup, publishes a marker,
 * and only then removes the active file. It rejects concurrent/stale transactions and unsafe
 * files. `SIGINT` and `SIGTERM` trigger best-effort asynchronous restoration; calling
 * {@link ForceignoreLease.restore} removes both listeners before awaiting restoration.
 *
 * @param projectDirectory - Project root containing `.forceignore` and transaction artifacts.
 * @param operationId - Safe transaction identifier used in the backup filename and marker.
 * @param signalTarget - Injectable process-like signal target; defaults to the current process.
 * @returns A lease whose idempotent `restore` method validates and restores the original state.
 * @throws `Error` When paths or files are unsafe, a transaction already exists, content
 * changes during setup, the operation identifier is invalid, or filesystem persistence fails.
 */
export async function disableForceignore(
    projectDirectory: string,
    operationId: string,
    signalTarget: SignalTarget = process
): Promise<ForceignoreLease> {
    const projectRealPath = await realpath(projectDirectory);
    const forceignorePath = path.join(projectRealPath, FORCEIGNORE_FILE);
    const markerPath = path.join(projectRealPath, MARKER_FILE);
    const backupFile = `.forceignore.sf-project-${operationId}.backup`;
    const backupPath = path.join(projectRealPath, backupFile);
    const temporaryMarkerPath = `${markerPath}.${operationId}.tmp`;
    let original: Buffer = Buffer.alloc(0);
    let originalExisted = true;
    try {
        original = await readRegularFile(forceignorePath, 'The active .forceignore');
    } catch (error) {
        if (!isMissing(error)) {
            throw error;
        }
        originalExisted = false;
    }
    const marker: TransactionMarker = {
        version: 1,
        transactionId: operationId,
        projectRealPath,
        forceignoreFile: FORCEIGNORE_FILE,
        backupFile,
        originalContentBase64: original.toString('base64'),
        originalSha256: sha256(original),
        originalByteLength: original.byteLength,
        originalExisted,
        createdAt: new Date().toISOString()
    };

    await writeSyncedExclusive(backupPath, original);
    try {
        await writeSyncedExclusive(temporaryMarkerPath, Buffer.from(`${JSON.stringify(marker)}\n`));
        await link(temporaryMarkerPath, markerPath);
        await rm(temporaryMarkerPath);

        if (originalExisted) {
            const current = await readRegularFile(forceignorePath, 'The active .forceignore');
            if (!current.equals(original)) {
                throw new Error('The active .forceignore changed while the refresh transaction was starting.');
            }
            await rm(forceignorePath);
        }
    } catch (error) {
        await rm(temporaryMarkerPath, { force: true });
        try {
            await lstat(markerPath);
        } catch (markerError) {
            if (isMissing(markerError)) {
                await rm(backupPath, { force: true });
            }
        }
        throw error;
    }

    let restored = false;
    const restore = async (): Promise<void> => {
        if (restored) {
            return;
        }
        const transaction = await loadValidatedTransaction(projectRealPath);
        await restoreValidatedTransaction(transaction, false);
        restored = true;
    };

    // Listener removal precedes explicit restore so completed leases cannot react to later process signals.
    const removeSignalListeners = (): void => {
        signalTarget.removeListener('SIGINT', onSignal);
        signalTarget.removeListener('SIGTERM', onSignal);
    };
    const onSignal = (): void => {
        removeSignalListeners();
        void restore();
    };
    signalTarget.once('SIGINT', onSignal);
    signalTarget.once('SIGTERM', onSignal);

    return {
        restore: async () => {
            removeSignalListeners();
            await restore();
        }
    };
}
