/**
 * Defines stable exit codes and lifecycle events shared by CLI, web, and automation consumers.
 * Numeric codes and event discriminants are compatibility contracts.
 */
/**
 * Stable process exit codes shared by commands, events, and external automation.
 *
 * Numeric values are part of the CLI contract and must remain backward compatible.
 */
export const EXIT_CODES = Object.freeze({
  SUCCESS: 0,
  OPERATION_FAILURE: 1,
  INVALID_INPUT_OR_CONFIG: 2,
  MISSING_PREREQUISITE: 3,
  AUTH_OR_AUTHORIZATION_FAILURE: 4,
  PARTIAL_COMPLETION: 5
} as const);

/** A process exit code defined by {@link EXIT_CODES}. */
export type ExitCode = (typeof EXIT_CODES)[keyof typeof EXIT_CODES];

export interface EventBase {
  /** Correlation identifier shared by every event from one operation. */
  operationId: string;
  /** ISO-8601 timestamp for deterministic transport and display. */
  timestamp: string;
}

/**
 * A discriminated event emitted during an operation lifecycle.
 *
 * Every event carries an operation correlation identifier and an ISO timestamp. Step events
 * additionally use stable step identifiers so human and machine consumers can reconstruct
 * nesting, retries, outcomes, and summaries without parsing rendered text.
 */
export type OperationEvent =
  | (EventBase & {
    kind: 'operation-started';
    operation: string;
    dryRun: boolean;
  })
  | (EventBase & {
    kind: 'step-started';
    stepId: string;
    parentStepId?: string;
    step: string;
    attempt: number;
  })
  | (EventBase & {
    kind: 'progress';
    stepId: string;
    parentStepId?: string;
    step: string;
    message: string;
    diagnostic?: boolean;
    packageName?: string;
    directory?: string;
    preservedFiles?: string[];
    dryRun?: boolean;
  })
  | (EventBase & {
    kind: 'retrying';
    stepId: string;
    parentStepId?: string;
    step: string;
    attempt: number;
    nextAttempt: number;
    maxAttempts: number;
    delayMs: number;
    message: string;
    error?: string;
  })
  | (EventBase & {
    kind: 'warning';
    stepId?: string;
    parentStepId?: string;
    step?: string;
    message: string;
    code?: string;
  })
  | (EventBase & {
    kind: 'step-completed';
    stepId: string;
    parentStepId?: string;
    step: string;
    exitCode: number;
    durationMs: number;
  })
  | (EventBase & {
    kind: 'step-failed';
    stepId: string;
    parentStepId?: string;
    step: string;
    exitCode: number | null;
    durationMs: number;
    error: string;
    nextAction?: string;
  })
  | (EventBase & {
    kind: 'package-result';
    packageName: string;
    ordinal: number;
    total: number;
    attempt: number;
    status: 'missing' | 'installed' | 'update' | 'updated' | 'skip' | 'higher' | 'failed';
    selectedVersion: string;
    selectedVersionId: string;
    installedVersion?: string;
    message: string;
  })
  | (EventBase & {
    kind: 'package-summary';
    total: number;
    missing: number;
    installed: number;
    updated: number;
    skipped: number;
    higher: number;
    failed: number;
  })
  | (EventBase & {
    kind: 'org-summary';
    alias: string;
    acquisition: 'create' | 'pool' | 'delete' | 'configure';
    status: 'run' | 'failed';
    dryRun: boolean;
  })
  | (EventBase & {
    kind: 'post-step-result';
    postStep: 'deploy' | 'permsets' | 'data' | 'community';
    status: 'run' | 'skipped' | 'warning' | 'failure';
    message: string;
    dryRun: boolean;
  })
  | (EventBase & {
    kind: 'workflow-summary';
    run: number;
    skipped: number;
    warnings: number;
    failed: number;
    dryRun: boolean;
  })
  | (EventBase & {
    kind: 'operation-completed';
    operation: string;
    exitCode: ExitCode;
    durationMs: number;
    dryRun: boolean;
  })
  | (EventBase & {
    kind: 'doctor-check';
    check: 'node' | 'sf' | 'project' | 'auth' | 'sfp';
    label: string;
    status: 'pass' | 'fail' | 'skip';
    durationMs: number;
    message: string;
    nextAction?: string;
  })
  | (EventBase & {
    kind: 'doctor-summary';
    passed: number;
    failed: number;
    skipped: number;
    exitCode: ExitCode;
  });

/**
 * Receives operation events in emission order.
 *
 * @param event - The next structured lifecycle event.
 */
export type EventSink = (event: OperationEvent) => void;
