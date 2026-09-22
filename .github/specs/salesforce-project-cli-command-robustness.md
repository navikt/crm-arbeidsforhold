---
slug: salesforce-project-cli-command-robustness
status: proposed
github-epic: 1045
---

# Salesforce project CLI: robust and cancellable command execution

## Problem statement

`sf-project` (`tools/salesforce-project-cli/`) funnels every `sf`/`git` invocation through a single
shared runner, `runCommand` in
[`src/infrastructure/command-runner.ts`](../../tools/salesforce-project-cli/src/infrastructure/command-runner.ts).
That runner already supports a per-attempt `timeoutMs`, a cancellation `signal` (`AbortSignal`), and
a bounded `retry` policy (`maxAttempts`, `delayMs`, `shouldRetry`, `onRetry`) — but almost no call
site sets `timeoutMs` or `signal` today, and only package installation
([`src/application/package-operations.ts`](../../tools/salesforce-project-cli/src/application/package-operations.ts))
sets a `retry` policy.

Concretely:

1. **No timeouts.** Org create/delete, `project deploy start`, post-steps, dependency retrieval, and
   every read-only inspection command (`org display`, `org list`, `config get`) can hang indefinitely
   if the Salesforce CLI, network, or org itself stalls. Nothing kills the child process or surfaces a
   bounded failure.
2. **Retry is single-purpose.** Only package install retries on recognized transient network
   signatures (`TypeError: terminated`, `ECONNRESET`, `socket hang up`, `ETIMEDOUT`, `ENOTFOUND`,
   `UND_ERR_`). Org create/delete, project configure post-steps, and dependency retrieval are equally
   prone to the same transient network blips but fail on the first attempt.
3. **Cancellation is advertised but not implemented.** `WebServiceFacade.cancel?` exists in the web
   service interface, but [`src/application/web-service-facade.ts`](../../tools/salesforce-project-cli/src/application/web-service-facade.ts)
   never implements it, so the `POST /api/v1/operations/:id/cancel` endpoint in
   [`src/web/server.ts`](../../tools/salesforce-project-cli/src/web/server.ts) always returns
   `409 "Cancellation is not supported"` regardless of whether the operation could safely be stopped.
4. **User feedback conflates debug detail with status.** Diagnostic detail (redacted command line,
   full stdout/stderr) is already correctly gated behind `--verbose`/`--json` via
   [`src/infrastructure/output.ts`](../../tools/salesforce-project-cli/src/infrastructure/output.ts) and
   `createEventCommandRunner` in [`src/cli-app.ts`](../../tools/salesforce-project-cli/src/cli-app.ts).
   Once timeouts, retries, and cancellation exist, their user-facing messages must follow the same
   gate — a stalled or canceled operation should read as a short, plain-language status, not a stack
   trace or raw execa diagnostic.

## Desired outcome

Every `sf` command invocation is bounded by a timeout, transient network failures during mutating
operations are retried the same way package installation already is, an in-flight operation started
through the web API can actually be canceled, and none of this new behavior leaks raw command,
stdout/stderr, or stack detail into normal (non-`--verbose`, non-`--json`) output.

## Guiding decisions

- Timeouts are configurable: sensible per-command-type defaults ship in code, overridable through
  `sf-project.config.json` and a CLI flag — mirroring how `scratchDurationDays` /
  `--duration-days` already work.
- Retry extends to *mutating* `sf` operations (org create/delete, post-steps/deploy, project
  configure, dependency retrieval) in addition to the already-covered package install. Read-only
  inspection calls (`org display`, `org list`, `org status`, `config get`) stay single-attempt —
  a hang there is solved by the timeout, not a retry, and re-querying is cheap and safe.
- Cancellation is wired end-to-end through the existing `AbortSignal` support already present in
  `runCommand`, not built as a separate mechanism.
- Existing `crm-arbeidsforhold` behavior is unchanged by default; new timeout/retry/cancel behavior
  must not change today's exit codes or event shapes for operations that neither time out nor get
  canceled.
- Reuse the existing `OperationEvent` shapes (`retrying`, `step-failed`, `warning`) and the existing
  `--verbose`/`--json` output gate rather than inventing new event kinds or a second output channel.

## Scope

- Configurable per-command timeouts threaded through every `runCommand`/`options.runCommand` call
  site in `org-workflow.ts`, `org-inspection.ts`, `package-operations.ts`, and
  `refresh-dependencies.ts`.
- A shared transient-failure classifier (generalized from `isRetryablePackageInstallFailure`) applied
  to mutating operations' retry policies.
- Real `AbortController`-based cancellation from the web API's cancel endpoint through the
  application-service layer down to `runCommand`.
- Human-readable, non-technical status messages for timeout, retry, and cancellation outcomes in
  normal output; full diagnostic detail remains behind `--verbose`/`--json`.

## Functional requirements

- **REQ-200:** Existing `crm-arbeidsforhold` `sf-project.config.json` behavior, exit codes, and event
  shapes are unchanged for operations that neither time out, retry, nor get canceled.
- **REQ-201:** Every `sf` command invocation (org lifecycle, package plan/install/update, dependency
  retrieval, org inspection) runs with a bounded `timeoutMs` instead of no timeout.
- **REQ-202:** Timeout values have sensible built-in defaults, are overridable per project through
  configuration, and are overridable per invocation through a CLI flag.
- **REQ-203:** A timed-out command reports a distinguishable, human-readable status (not a raw execa
  diagnostic) in non-verbose, non-JSON output; the underlying diagnostic remains available via
  `--verbose`/`--json`.
- **REQ-210:** A shared transient-failure classifier (network/timeout signatures) is used by the retry
  policy for org create, org delete, project configure post-steps/deploy, and dependency retrieval, in
  addition to the already-covered package install.
- **REQ-211:** Read-only inspection commands (`org display`, `org list`, `org status`, `config get`)
  remain single-attempt; only the timeout applies to them, not retry.
- **REQ-212:** Retry attempts for mutating operations emit the existing `retrying` event with the same
  shape already used by package installation; no new event kind is introduced for this.
- **REQ-220:** `POST /api/v1/operations/:id/cancel` aborts the in-flight command(s) for that operation
  (via `AbortController`/`AbortSignal`) instead of unconditionally returning
  `409 "Cancellation is not supported"`.
- **REQ-221:** The application-service option interfaces that issue commands (`ConfigureProjectOptions`,
  `CreateOrgOptions`, `DeleteOrgOptions`, `PlanPackagesOptions`, `MutatePackagesOptions`,
  `RefreshDependenciesOptions`) accept an optional cancellation `signal` and forward it to every
  `runCommand` call they make.
- **REQ-222:** A canceled command result (`canceled: true`) is represented distinctly from a failed
  command result in emitted events and CLI/JSON/web output — it is not classified as
  `EXIT_CODES.OPERATION_FAILURE`.
- **REQ-230:** Non-verbose, non-JSON output for timeout, retry, and cancellation outcomes uses short,
  plain-language messages with no raw command line, stdout/stderr, or stack detail; that detail
  remains available only via `--verbose` or `--json`, using the existing output gate.

## Delivery order

| Step | Issue | Title                                                                          | Requirements                 |
| ---: | ----- | ------------------------------------------------------------------------------- | ----------------------------- |
|    1 | #1046 | Add configurable per-command timeouts to every `sf` invocation                  | REQ-200, REQ-201, REQ-202, REQ-203 |
|    2 | #1047 | Extend transient-failure retry to mutating org/dependency operations            | REQ-200, REQ-210, REQ-211, REQ-212 |
|    3 | #1048 | Wire real operation cancellation end-to-end (web API to command runner)         | REQ-200, REQ-220, REQ-221, REQ-222 |
|    4 | #1049 | Keep non-verbose output human-readable for timeout/retry/cancellation           | REQ-230                       |

Step 1 is a prerequisite for steps 2 and 3 (retry delays and cancellation both build on the timeout
plumbing touching the same call sites). Step 4 is a review pass that can run once steps 1-3 land, or
incrementally alongside them.

## Verification strategy

- Unit tests in `tools/salesforce-project-cli/test/unit/command-runner.test.ts` cover any new shared
  transient-failure classifier and confirm `timeoutMs`/`signal`/`retry` are honored by the runner
  (already largely true; extend only for new shared helpers).
- Contract tests in `tools/salesforce-project-cli/test/contract/` (`org-lifecycle`,
  `packages-install-update`, `dependencies-*`, `web-server`) extended with a fake `runCommand` that
  asserts `timeoutMs`/`retry`/`signal` are passed through, and that simulates `timedOut: true` /
  `canceled: true` results to assert on emitted events and exit codes.
- `test/contract/web-server.test.ts` gains a cancellation test asserting the endpoint returns `202`
  and the underlying `AbortController` is aborted, replacing today's single "not supported" assertion.
- `npm run check` (or the tool's equivalent lint/typecheck/test/build script) passes in
  `tools/salesforce-project-cli/`.
- Authenticated verification against a disposable scratch org is optional per the existing
  [release validation gates](../../tools/salesforce-project-cli/docs/packaging-and-extraction.md#release-validation-gates)
  and must not be reported as passed without being explicitly run.

## Completion criteria

- All requirements in this spec have passing automated evidence.
- `tools/salesforce-project-cli/docs/cli-reference.md`, `docs/configuration.md`, and
  `docs/operations-and-troubleshooting.md` are updated to match implemented timeout/retry/cancellation
  behavior.
- `crm-arbeidsforhold`'s own default behavior (exit codes, event shapes, existing tests) is unchanged
  throughout, proving REQ-200.

## Out of scope

- CLI-side cancellation (Ctrl+C/SIGINT handling) — this spec covers the already-designed web API
  cancel endpoint only.
- Cancellation for read-only inspection calls (`org display`/`org list`/`org status`) — only mutating
  operations are required to be cancellable by this spec; extending cancellation to reads is a
  follow-up if needed.
- Changing the numeric values of existing `EXIT_CODES` or introducing a new exit code — if
  implementation determines a new code is warranted for canceled operations, that requires explicit
  human sign-off before landing, since exit codes are a documented backward-compatible contract.
