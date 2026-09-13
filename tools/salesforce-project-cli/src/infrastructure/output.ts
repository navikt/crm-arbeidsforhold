/**
 * Renders structured operation events as human-readable terminal output or newline-delimited JSON.
 * The stateful writer expects lifecycle order so terminal resource summaries remain accurate.
 */
import type { OperationEvent } from '../domain/events.js';

/** Line-oriented destinations used by CLI output rendering. */
export interface OutputTarget {
    /** Writes one stdout record without assuming terminal capabilities. */
    stdout: (line: string) => void;
    /** Writes one stderr record without assuming terminal capabilities. */
    stderr: (line: string) => void;
}

/** Rendering policy and destinations for structured operation events. */
export interface EventWriterOptions {
    /** Enables ANSI styling for human-readable output. */
    color: boolean;
    /** Includes diagnostic progress events in human-readable output. */
    verbose: boolean;
    /** Emits one JSON object per stdout line instead of human-readable text. */
    json: boolean;
    /** Output destinations supplied by the CLI boundary. */
    output: OutputTarget;
}

interface ResourceSummary {
    created: number;
    installed: number;
    updated: number;
    skipped: number;
    failed: number;
    restored: number;
}

const ANSI = {
    reset: '\u001b[0m',
    boldCyan: '\u001b[1;36m',
    cyan: '\u001b[36m',
    green: '\u001b[32m',
    yellow: '\u001b[33m',
    red: '\u001b[31m'
} as const;

function styled(value: string, color: string, enabled: boolean): string {
    return enabled ? `${color}${value}${ANSI.reset}` : value;
}

function duration(milliseconds: number): string {
    return `${(milliseconds / 1000).toFixed(2)}s`;
}

function marker(symbol: string, plain: string, color: string, options: EventWriterOptions): string {
    return options.color ? styled(symbol, color, true) : plain;
}

function describeEvent(event: OperationEvent, options: EventWriterOptions): string[] {
    switch (event.kind) {
        case 'operation-started':
            return [styled(`${event.operation}${event.dryRun ? ' (dry run)' : ''}`, ANSI.boldCyan, options.color)];
        case 'step-started':
            return [`  ${marker('→', '->', ANSI.cyan, options)} ${event.step} (attempt ${event.attempt})`];
        case 'progress':
            if (event.diagnostic && !options.verbose) {
                return [];
            }
            return [`    ${event.message}`];
        case 'retrying':
            return [
                `  ${marker('↻', 'RETRY', ANSI.yellow, options)} ${event.step}: retry ${event.nextAttempt}/${event.maxAttempts} in ${duration(event.delayMs)} - ${event.message}`
            ];
        case 'warning':
            return [`  ${marker('⚠', 'WARNING', ANSI.yellow, options)} ${event.message}`];
        case 'step-completed':
            return [`  ${marker('✓', 'OK', ANSI.green, options)} ${event.step} (${duration(event.durationMs)})`];
        case 'step-failed':
            return [
                `  ${marker('✗', 'FAILED', ANSI.red, options)} ${event.step} (${duration(event.durationMs)})`,
                `  Cause: ${event.error}`,
                `  Next action: ${event.nextAction ?? 'Review the diagnostic output, correct the failure, and retry.'}`
            ];
        case 'package-result':
            return [`    [${event.ordinal}/${event.total}] ${event.packageName}: ${event.status} - ${event.message}`];
        case 'package-summary':
            return [
                '  Package summary',
                `    Total ${event.total} | Missing ${event.missing} | Installed ${event.installed} | Updated ${event.updated} | Skipped ${event.skipped} | Higher ${event.higher} | Failed ${event.failed}`
            ];
        case 'org-summary':
            return [
                `  Org summary: ${event.acquisition} ${event.alias} - ${event.status}${event.dryRun ? ' (dry run)' : ''}`
            ];
        case 'post-step-result':
            return [`  ${event.postStep}: ${event.status} - ${event.message}`];
        case 'workflow-summary':
            return [
                `  Workflow summary: run ${event.run} | skipped ${event.skipped} | warnings ${event.warnings} | failed ${event.failed}`
            ];
        case 'doctor-check': {
            const checkMarker =
                event.status === 'pass'
                    ? marker('✓', 'PASS', ANSI.green, options)
                    : event.status === 'fail'
                        ? marker('✗', 'FAILED', ANSI.red, options)
                        : marker('-', 'SKIP', ANSI.cyan, options);
            const lines = [`  ${checkMarker} ${event.label} (${duration(event.durationMs)}) - ${event.message}`];
            if (event.status === 'fail') {
                lines.push(
                    `  Next action: ${event.nextAction ?? 'Correct the failed check and rerun sf-project doctor.'}`
                );
            }
            return lines;
        }
        case 'doctor-summary':
            return [`  Doctor summary: passed ${event.passed} | failed ${event.failed} | skipped ${event.skipped}`];
        case 'operation-completed':
            return event.exitCode === 0
                ? [
                    `${marker('✓', 'OK', ANSI.green, options)} ${event.operation} completed in ${duration(event.durationMs)}`
                ]
                : [
                    `${marker('✗', 'FAILED', ANSI.red, options)} ${event.operation} finished with exit code ${event.exitCode} in ${duration(event.durationMs)}`
                ];
    }
}

/**
 * Creates a stateful writer that renders lifecycle events and an operation resource summary.
 *
 * JSON mode preserves one event per stdout line and augments only the terminal operation event
 * with accumulated resources. Human-readable mode filters diagnostic progress unless verbose.
 *
 * @param options - Rendering mode, terminal capabilities, and output destinations.
 * @returns A writer that must receive events in lifecycle order for accurate summaries.
 */
export function createEventWriter(options: EventWriterOptions): (event: OperationEvent) => void {
    const resources: ResourceSummary = {
        created: 0,
        installed: 0,
        updated: 0,
        skipped: 0,
        failed: 0,
        restored: 0
    };
    const restoredPackages = new Set<string>();
    let operation = '';

    return (event) => {
        if (event.kind === 'operation-started') {
            operation = event.operation;
        } else if (event.kind === 'org-summary' && event.acquisition === 'create' && event.status === 'run') {
            resources.created += 1;
        } else if (event.kind === 'package-summary') {
            resources.installed = event.installed;
            resources.updated = event.updated;
            resources.skipped = event.skipped;
            resources.failed = event.failed;
        } else if (event.kind === 'workflow-summary') {
            resources.skipped += event.skipped;
            resources.failed = Math.max(resources.failed, event.failed);
        } else if (event.kind === 'step-failed') {
            resources.failed = Math.max(resources.failed, 1);
        } else if (event.kind === 'progress' && operation === 'dependencies.refresh' && event.packageName) {
            restoredPackages.add(event.packageName);
            resources.restored = restoredPackages.size;
        }

        // Keep JSON mode as stable NDJSON; only the terminal event carries accumulated resources.
        if (options.json) {
            options.output.stdout(
                JSON.stringify(event.kind === 'operation-completed' ? { ...event, resources } : event)
            );
            return;
        }

        if (event.kind === 'operation-completed') {
            options.output.stdout(
                `Summary: created ${resources.created} | installed ${resources.installed} | updated ${resources.updated} | skipped ${resources.skipped} | failed ${resources.failed} | restored ${resources.restored}`
            );
        }
        describeEvent(event, options).forEach(options.output.stdout);
    };
}
