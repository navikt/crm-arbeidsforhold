/**
 * Executes external programs without a shell and returns redacted, retry-aware results.
 * Stream callbacks receive complete sanitized lines, and cancellation prevents further attempts.
 */
import { StringDecoder } from 'node:string_decoder';
import type { Readable } from 'node:stream';
import { setTimeout as wait } from 'node:timers/promises';
import { execa } from 'execa';
import { createRedactor } from './redactor.js';

/** Controls bounded retries for a command execution. */
export interface RetryOptions {
    /** Total attempts including the initial execution; must be a positive integer. */
    maxAttempts: number;
    /** Delay before each retry in milliseconds. Defaults to zero. */
    delayMs?: number;
    /** Optional classifier that decides whether a failed, non-canceled result is retryable. */
    shouldRetry?: (result: CommandResult) => boolean | Promise<boolean>;
    /** Notification invoked before waiting for the next attempt. */
    onRetry?: (result: CommandResult, nextAttempt: number, delayMs: number) => void;
}

/**
 * Awaitable delay abstraction used to make retry timing abortable and testable.
 *
 * @param milliseconds - Delay duration in milliseconds.
 * @param signal - Optional signal that cancels the delay.
 * @returns A promise settled when the delay completes or is aborted.
 */
export type AsyncDelay = (milliseconds: number, signal?: AbortSignal) => Promise<void>;

/** Describes one shell-free process execution and its observation hooks. */
export interface CommandRequest {
    /** Executable path or name passed directly to the process launcher. */
    executable: string;
    /** Literal argument vector; values are never interpreted by a shell. */
    arguments?: readonly string[];
    /** Working directory for the child process. */
    cwd?: string;
    /** Environment entries merged into the child process environment. */
    env?: Readonly<Record<string, string>>;
    /** Maximum duration of each attempt in milliseconds. */
    timeoutMs?: number;
    /** Signal used to cancel the active process and retry delays. */
    signal?: AbortSignal;
    /** Receives complete, redacted stdout lines as they become available. */
    onStdoutLine?: (line: string) => void;
    /** Receives complete, redacted stderr lines as they become available. */
    onStderrLine?: (line: string) => void;
    /** Retry policy; omission executes exactly once. */
    retry?: RetryOptions;
    /** Injectable retry delay, primarily for deterministic orchestration and tests. */
    delay?: AsyncDelay;
    /** Additional literal values removed from returned and streamed text. */
    secretValues?: readonly string[];
}

/** Sanitized outcome of the final command attempt. */
export interface CommandResult {
    /** Redacted executable value. */
    executable: string;
    /** Redacted argument vector. */
    arguments: string[];
    /** Process exit code, or `null` when no code was produced. */
    exitCode: number | null;
    /** Complete redacted stdout from the final attempt. */
    stdout: string;
    /** Complete redacted stderr from the final attempt. */
    stderr: string;
    /** Wall-clock duration across all attempts and retry delays. */
    durationMs: number;
    /** Whether the final attempt was unsuccessful according to the process launcher. */
    failed: boolean;
    /** Whether the final attempt exceeded its timeout. */
    timedOut: boolean;
    /** Whether the final attempt was canceled. */
    canceled: boolean;
    /** Number of executions performed before this result. */
    attempts: number;
    /** Terminating process signal, when reported by the operating system. */
    signal?: string;
    /** Redacted launcher diagnostic for a failed final attempt. */
    error?: string;
}

function streamLines(
    stream: Readable | null,
    redact: (value: string) => string,
    onLine?: (line: string) => void
): Promise<void> {
    if (!stream || !onLine) {
        return Promise.resolve();
    }

    const decoder = new StringDecoder('utf8');
    let pending = '';

    // Preserve UTF-8 and line boundaries across arbitrary stream chunks before redacting callbacks.
    return new Promise((resolve) => {
        stream.on('data', (chunk) => {
            pending += decoder.write(chunk as Buffer);
            const lines = pending.split(/\r?\n/);
            pending = lines.pop() ?? '';
            lines.forEach((line) => onLine(redact(line)));
        });
        stream.on('end', () => {
            pending += decoder.end();
            if (pending.length > 0) {
                onLine(redact(pending));
            }
            resolve();
        });
    });
}

const defaultDelay: AsyncDelay = async (milliseconds, signal) => {
    await wait(milliseconds, undefined, signal === undefined ? {} : { signal });
};

/**
 * Executes a command without a shell, captures its output, and applies bounded retries.
 *
 * All returned and streamed command text is redacted. Canceled attempts are terminal and are
 * never passed to the retry classifier.
 *
 * @param request - Process, observation, redaction, and retry settings.
 * @returns The sanitized result of the last completed attempt.
 * @throws `RangeError` If `retry.maxAttempts` is not a positive integer.
 * @throws `Error` If process launch or stream handling fails before a result can be produced.
 */
export async function runCommand(request: CommandRequest): Promise<CommandResult> {
    const startedAt = Date.now();
    const commandArguments = [...(request.arguments ?? [])];
    const redactor = createRedactor(request.secretValues);
    const maximumAttempts = request.retry?.maxAttempts ?? 1;
    const delay = request.delay ?? defaultDelay;

    if (!Number.isInteger(maximumAttempts) || maximumAttempts < 1) {
        throw new RangeError('retry.maxAttempts must be a positive integer');
    }

    let attempt = 0;
    while (attempt < maximumAttempts) {
        attempt += 1;
        const subprocess = execa(request.executable, commandArguments, {
            ...(request.cwd === undefined ? {} : { cwd: request.cwd }),
            ...(request.env === undefined ? {} : { env: request.env }),
            ...(request.timeoutMs === undefined ? {} : { timeout: request.timeoutMs }),
            ...(request.signal === undefined ? {} : { cancelSignal: request.signal }),
            shell: false,
            reject: false
        });
        const stdoutStreaming = streamLines(subprocess.stdout, redactor.redact, request.onStdoutLine);
        const stderrStreaming = streamLines(subprocess.stderr, redactor.redact, request.onStderrLine);
        const commandResult = await subprocess;
        await Promise.all([stdoutStreaming, stderrStreaming]);

        const result: CommandResult = {
            executable: redactor.redact(request.executable),
            arguments: commandArguments.map(redactor.redact),
            exitCode: commandResult.exitCode ?? null,
            stdout: redactor.redact(commandResult.stdout),
            stderr: redactor.redact(commandResult.stderr),
            durationMs: Date.now() - startedAt,
            failed: commandResult.failed,
            timedOut: commandResult.timedOut,
            canceled: commandResult.isCanceled,
            attempts: attempt,
            ...(commandResult.signal === undefined ? {} : { signal: commandResult.signal }),
            ...(commandResult.failed ? { error: redactor.redact(commandResult.shortMessage ?? 'Command failed') } : {})
        };
        // Cancellation wins over custom retry policy so an abort cannot start another process.
        const shouldRetry =
            attempt < maximumAttempts &&
            !result.canceled &&
            (request.retry?.shouldRetry === undefined ? result.failed : await request.retry.shouldRetry(result));

        if (!shouldRetry) {
            return result;
        }

        const delayMs = request.retry?.delayMs ?? 0;
        request.retry?.onRetry?.(result, attempt + 1, delayMs);
        await delay(delayMs, request.signal);
    }

    throw new Error('Command runner exhausted attempts without a result');
}
