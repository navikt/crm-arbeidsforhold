import { describe, expect, it } from 'vitest';
import { EXIT_CODES, type OperationEvent } from '../../src/domain/events.js';
import { createRedactingEventSink, createRedactor } from '../../src/infrastructure/redactor.js';

const common = {
    operationId: 'operation-1',
    timestamp: '2026-09-13T12:00:00.000Z'
};

describe('operation events', () => {
    it('defines the complete event lifecycle while retaining dependency-clear fields', () => {
        const events: OperationEvent[] = [
            { ...common, kind: 'operation-started', operation: 'dependencies.clear', dryRun: true },
            {
                ...common,
                kind: 'step-started',
                stepId: 'clear-source',
                parentStepId: 'dependencies',
                step: 'Clear source',
                attempt: 1
            },
            {
                ...common,
                kind: 'progress',
                stepId: 'clear-source',
                parentStepId: 'dependencies',
                step: 'Clear source',
                message: 'Clearing shared-package',
                packageName: 'shared-package',
                directory: '/project/shared-package',
                preservedFiles: ['README.md'],
                dryRun: true
            },
            {
                ...common,
                kind: 'retrying',
                stepId: 'clear-source',
                parentStepId: 'dependencies',
                step: 'Clear source',
                attempt: 1,
                nextAttempt: 2,
                maxAttempts: 3,
                delayMs: 100,
                message: 'Retrying clear source'
            },
            {
                ...common,
                kind: 'warning',
                stepId: 'clear-source',
                parentStepId: 'dependencies',
                step: 'Clear source',
                message: 'A recoverable condition occurred',
                code: 'RECOVERABLE'
            },
            {
                ...common,
                kind: 'step-completed',
                stepId: 'clear-source',
                parentStepId: 'dependencies',
                step: 'Clear source',
                exitCode: 0,
                durationMs: 12
            },
            {
                ...common,
                kind: 'step-failed',
                stepId: 'clear-source',
                parentStepId: 'dependencies',
                step: 'Clear source',
                exitCode: 1,
                durationMs: 12,
                error: 'Failed'
            },
            {
                ...common,
                kind: 'operation-completed',
                operation: 'dependencies.clear',
                exitCode: 0,
                durationMs: 20,
                dryRun: true
            }
        ];

        expect(events.map((event) => event.kind)).toEqual([
            'operation-started',
            'step-started',
            'progress',
            'retrying',
            'warning',
            'step-completed',
            'step-failed',
            'operation-completed'
        ]);
        expect(events.map((event) => Object.keys(event).sort().join(','))).toEqual([
            'dryRun,kind,operation,operationId,timestamp',
            'attempt,kind,operationId,parentStepId,step,stepId,timestamp',
            'directory,dryRun,kind,message,operationId,packageName,parentStepId,preservedFiles,step,stepId,timestamp',
            'attempt,delayMs,kind,maxAttempts,message,nextAttempt,operationId,parentStepId,step,stepId,timestamp',
            'code,kind,message,operationId,parentStepId,step,stepId,timestamp',
            'durationMs,exitCode,kind,operationId,parentStepId,step,stepId,timestamp',
            'durationMs,error,exitCode,kind,operationId,parentStepId,step,stepId,timestamp',
            'dryRun,durationMs,exitCode,kind,operation,operationId,timestamp'
        ]);
    });

    it('publishes stable process exit codes', () => {
        expect(EXIT_CODES).toEqual({
            SUCCESS: 0,
            OPERATION_FAILURE: 1,
            INVALID_INPUT_OR_CONFIG: 2,
            MISSING_PREREQUISITE: 3,
            AUTH_OR_AUTHORIZATION_FAILURE: 4,
            PARTIAL_COMPLETION: 5
        });
    });

    it('allows progress events outside dependency-source operations', () => {
        const event: OperationEvent = {
            ...common,
            kind: 'progress',
            stepId: 'inspect-org',
            step: 'Inspect org',
            message: 'Reading org details'
        };

        expect(event).toMatchObject({ kind: 'progress', stepId: 'inspect-org' });
    });

    it('redacts configured secrets and Salesforce access tokens before emitting events', () => {
        const emitted: OperationEvent[] = [];
        const secret = 'configured-secret';
        const accessToken = '00D000000000001!AQ0AQJx_access-token-value';
        const emit = createRedactingEventSink(createRedactor([secret]), (event) => emitted.push(event));

        emit({
            ...common,
            kind: 'step-failed',
            stepId: 'authenticate',
            step: `Authenticate with ${secret}`,
            exitCode: 4,
            durationMs: 10,
            error: `Authorization failed for ${accessToken}`
        });

        expect(emitted).toEqual([
            expect.objectContaining({
                step: 'Authenticate with [REDACTED]',
                error: 'Authorization failed for [REDACTED]'
            })
        ]);
    });
});
