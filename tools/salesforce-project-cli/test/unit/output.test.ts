import { describe, expect, it } from 'vitest';
import type { OperationEvent } from '../../src/domain/events.js';
import { createEventWriter } from '../../src/infrastructure/output.js';

const common = {
    operationId: 'operation-1',
    timestamp: '2026-09-13T12:00:00.000Z'
};

const events: OperationEvent[] = [
    { ...common, kind: 'operation-started', operation: 'org.create', dryRun: false },
    { ...common, kind: 'step-started', stepId: 'acquire', step: 'Acquire scratch org', attempt: 1 },
    {
        ...common,
        kind: 'progress',
        stepId: 'acquire',
        step: 'Acquire scratch org',
        message: 'Creating crm-arbeidsforhold'
    },
    {
        ...common,
        kind: 'progress',
        stepId: 'acquire',
        step: 'Acquire scratch org',
        message: 'sf org create scratch --alias crm-arbeidsforhold',
        diagnostic: true
    },
    {
        ...common,
        kind: 'retrying',
        stepId: 'acquire',
        step: 'Acquire scratch org',
        attempt: 1,
        nextAttempt: 2,
        maxAttempts: 3,
        delayMs: 1500,
        message: 'Salesforce CLI connection reset'
    },
    {
        ...common,
        kind: 'warning',
        stepId: 'acquire',
        step: 'Acquire scratch org',
        message: 'Using fallback scratch creation'
    },
    {
        ...common,
        kind: 'step-completed',
        stepId: 'acquire',
        step: 'Acquire scratch org',
        exitCode: 0,
        durationMs: 1250
    },
    {
        ...common,
        kind: 'operation-completed',
        operation: 'org.create',
        exitCode: 0,
        durationMs: 2500,
        dryRun: false
    }
];

function render(options: { color: boolean; verbose: boolean; json?: boolean }): { stdout: string[]; stderr: string[] } {
    const stdout: string[] = [];
    const stderr: string[] = [];
    const write = createEventWriter({
        ...options,
        json: options.json ?? false,
        output: { stdout: (line) => stdout.push(line), stderr: (line) => stderr.push(line) }
    });
    events.forEach(write);
    return { stdout, stderr };
}

describe('CLI event output', () => {
    it('renders a colored operation and step hierarchy for an interactive terminal', () => {
        expect(render({ color: true, verbose: false }).stdout.join('\n')).toMatchInlineSnapshot(`
          "[1;36morg.create[0m
            [36m→[0m Acquire scratch org (attempt 1)
              Creating crm-arbeidsforhold
            [33m↻[0m Acquire scratch org: retry 2/3 in 1.50s - Salesforce CLI connection reset
            [33m⚠[0m Using fallback scratch creation
            [32m✓[0m Acquire scratch org (1.25s)
          Summary: created 0 | installed 0 | updated 0 | skipped 0 | failed 0 | restored 0
          [32m✓[0m org.create completed in 2.50s"
        `);
    });

    it('renders plain text with no ANSI escapes when color is disabled', () => {
        const rendered = render({ color: false, verbose: false }).stdout.join('\n');

        expect(rendered.split('\n').slice(0, 3).join('\n')).toMatchInlineSnapshot(`
                  "org.create
                    -> Acquire scratch org (attempt 1)
                      Creating crm-arbeidsforhold"
                `);
        expect(rendered).not.toContain('\u001b[');
    });

    it('includes sanitized diagnostic events only in verbose mode', () => {
        expect(render({ color: false, verbose: false }).stdout.join('\n')).not.toContain('sf org create');
        expect(render({ color: false, verbose: true }).stdout.join('\n')).toContain(
            '    sf org create scratch --alias crm-arbeidsforhold'
        );
    });

    it('keeps stdout data-only NDJSON in JSON mode', () => {
        const rendered = render({ color: true, verbose: true, json: true });

        expect(rendered.stderr).toEqual([]);
        expect(rendered.stdout).toHaveLength(events.length);
        expect(rendered.stdout.every((line) => JSON.parse(line))).toBe(true);
        expect(rendered.stdout.map((line) => JSON.parse(line).kind)).toEqual(events.map((event) => event.kind));
        expect(JSON.parse(rendered.stdout.at(-1) ?? '')).toMatchObject({
            kind: 'operation-completed',
            resources: { created: 0, installed: 0, updated: 0, skipped: 0, failed: 0, restored: 0 }
        });
    });

    it('renders the failed step, cause, and next action', () => {
        const stdout: string[] = [];
        const write = createEventWriter({
            color: false,
            verbose: false,
            json: false,
            output: { stdout: (line) => stdout.push(line), stderr: () => undefined }
        });

        write({
            ...common,
            kind: 'step-failed',
            stepId: 'authenticate',
            step: 'Read org access',
            exitCode: 4,
            durationMs: 40,
            error: 'No authenticated org is available',
            nextAction: 'Run sf org login web and retry.'
        });

        expect(stdout.join('\n')).toMatchInlineSnapshot(`
          "  FAILED Read org access (0.04s)
            Cause: No authenticated org is available
            Next action: Run sf org login web and retry."
        `);
    });
});
