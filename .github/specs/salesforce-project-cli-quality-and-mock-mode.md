# Salesforce Project CLI: Quality and Mock Mode

## Goal

Make `tools/salesforce-project-cli` easier to understand, safer to test, and simpler to extend without changing its deployed command contracts.

## Decisions

- Normal `--dry-run` keeps its current meaning: no mutations, but real read-only Salesforce queries are allowed.
- `--mock` is explicit and independent from `--dry-run`.
- Mock mode must never invoke `sf`, `sfp`, deploy, filesystem mutation, or other external side effects.
- Mock output must be visibly marked as simulated in human-readable output and represented by stable machine-readable events.
- Command execution remains dependency-injected through `CommandRunner`.
- Coverage is reported first; a blocking threshold is introduced only after the current baseline and gaps are known.

## Scope

### Mock execution boundary

- Add a reusable mock command runner that returns deterministic `CommandResult` fixtures.
- Support package planning/install/update and org inspection first.
- Model success, skip, higher-version, transient failure, terminal failure, timeout, and cancellation fixtures.
- Make mock mode selectable from the CLI without changing normal dry-run behavior.

### Architecture

- Keep CLI parsing, application orchestration, Salesforce command execution, and output rendering separate.
- Extract package planning, package mutation, install polling, and summary calculation behind focused interfaces where current responsibilities overlap.
- Preserve public event and exit-code contracts unless a specification explicitly adds a backwards-compatible field.

### Verification

- Unit tests cover pure planning, status classification, polling, summary calculation, output rendering, and error classification.
- Contract tests cover exact Salesforce argument vectors and event sequences.
- Mock-mode integration tests prove no external command is invoked.
- Dry-run tests prove read-only queries remain available and mutations remain disabled.
- Add V8 coverage reporting to the core test command.
- Record the initial coverage baseline before enforcing a threshold.

## Acceptance criteria

- `sf-project ... --dry-run` can still query real read-only Salesforce state and never mutates it.
- `sf-project ... --mock` never starts `sf` or `sfp` and produces deterministic output.
- `--mock --dry-run` is valid and clearly reports both modes.
- Mock and real execution use the same application services and event contracts.
- A failing mock scenario can reproduce package failure, timeout, retry, cancellation, and partial completion without an org.
- Core tests can run locally without Salesforce authentication.
- Coverage is available as a documented command and its baseline is recorded.
- Existing package, org, web, JSON, and exit-code contracts remain green except for explicitly documented changes.

## Work breakdown

1. Add mock command-runner interfaces, fixtures, mode validation, and focused tests.
2. Thread explicit mock mode through CLI command options and operation services.
3. Add deterministic scenario fixtures and mock-mode contract tests.
4. Add coverage reporting and baseline documentation.
5. Refactor package operations into focused collaborators, preserving behavior at each step.
6. Extend the same seams to org workflow, dependency refresh, and web facade paths.

## Initial baseline

Measured with `npm run coverage:core -- --exclude test/contract/org-inspection.test.ts` on 2026-09-24:

- Lines/statements: 88.21%
- Branches: 75.00%
- Functions: 95.00%

The excluded test has a date-sensitive fixture (`expirationDate: 2026-09-20`) and fails after the current date passes the fixture. It remains a separate test-maintenance task; no coverage threshold is blocking until that fixture is made deterministic and the remaining uncovered paths are reviewed.

## Risks and review points

- Mock data must never be mistaken for org state; this is a user-safety requirement.
- Reinstall/uninstall and package mutation remain org-dependent and require explicit human approval.
- SOLID refactoring must be incremental; broad rewrites risk changing Salesforce command ordering and retry semantics.