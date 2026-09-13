# Operations and troubleshooting

The tool runs with the developer’s local filesystem access and Salesforce CLI credentials. Treat both CLI and web operations as privileged developer tooling. Start diagnosis with read-only checks and dry runs.

## Prerequisites

- Node.js 22 or newer
- npm dependencies installed for module development
- `sf` installed for Salesforce queries and operations
- authenticated org access for commands that inspect or mutate orgs
- a valid Salesforce project with `sfdx-project.json`
- `sfp` only when scratch-org pool use is configured
- the configured package installation key environment variable only for packages marked as requiring a key
- installed Chrome for local Playwright E2E tests

## First diagnostic steps

```bash
sf-project doctor --project-dir /path/to/project
sf-project --verbose doctor --project-dir /path/to/project
sf-project doctor --project-dir /path/to/project --json
```

Verbose mode prints sanitized attempted command lines. JSON mode emits NDJSON suitable for event-aware tooling. Do not post raw command output until it has been reviewed for org usernames, IDs, access tokens, auth URLs, installation keys, or personal data.

`doctor` reports Node, Salesforce CLI, project configuration, authentication/read access, and optional `sfp` checks. It skips auth when `sf` is unavailable and skips `sfp` when pool use is disabled.

## Exit-code triage

| Code | Diagnose                                        | Safe next action                                                                |
| ---: | ----------------------------------------------- | ------------------------------------------------------------------------------- |
|  `0` | Completed successfully                          | Review warnings and summaries if present                                        |
|  `1` | Operation or validation failure                 | Read the failed step and `nextAction`; use a dry run before retrying            |
|  `2` | Invalid CLI input or project/tool configuration | Correct arguments or JSON schema violations                                     |
|  `3` | Missing runtime, executable, or required file   | Install/restore the named prerequisite                                          |
|  `4` | Authentication or authorization                 | Authenticate the intended org and verify access; do not switch targets silently |
|  `5` | Partial completion                              | Inventory completed side effects before resuming                                |

## Authentication and target failures

Use `org list`, `org status`, or `org info` to inspect normalized state without exposing instance URLs. Remember the target rules:

- `org status` without an alias uses Salesforce CLI `target-org`
- create/delete/configure use explicit alias options, then `defaultOrgAlias`
- package operations use explicit target, then `defaultOrgAlias`, then Salesforce CLI resolution
- dependency refresh omits `--target-org` when none is provided

Specify targets explicitly when defaults could differ. Production, Dev Hub, and unknown orgs are read-only in web policy. Real deletion is scratch-only. An expired or unauthenticated delete target returns authentication failure before mutation.

Never invent an alias or authenticate to a different org merely to make a command pass.

## Configuration failures

Malformed JSON and schema violations return `2`; missing `sfdx-project.json` can return `3`. Common causes are an empty package directory list, invalid duration, unsupported schema version, empty required string, invalid post-step, or dependency package with no matching source directory.

The loader does not verify referenced scratch definitions, data plans, or dependency directories at load time. A later operation may therefore report a missing file. Resolve relative paths against `--project-dir`, not the module directory.

## Interrupted `.forceignore` transaction

Dependency refresh owns these project-root artifacts while `.forceignore` is disabled:

- marker: `.forceignore.sf-project.lock`
- backup: `.forceignore.sf-project-<operation-id>.backup`

Inspect recovery without changing files:

```bash
sf-project dependencies recover --project-dir /path/to/project --dry-run
```

Perform validated recovery:

```bash
sf-project dependencies recover --project-dir /path/to/project
```

Recovery validates the canonical project path, marker schema, transaction identity, backup location and type, byte length, SHA-256, and encoded original content. If an active `.forceignore` differs from the recorded original, recovery fails rather than overwrite it. Inspect the marker, its named backup, and active file; resolve the conflict manually only after preserving all versions and understanding which content is authoritative. Do not rename, delete, or edit transaction artifacts merely to bypass validation.

A normal refresh restores in `finally`. SIGINT and SIGTERM trigger best-effort restoration, but abrupt process or machine termination can leave the durable transaction for the next refresh or explicit recover command.

## Dependency clear and retrieve failures

Cleanup rejects project-root escapes, root replacement, symbolic-link roots, and symbolic-link children. Treat these as safety failures, not files to force-delete through the tool. Verify `packageDirectories`, directory ownership, and real paths.

Missing dependency roots are skipped. Retrieve runs sequentially and stops at the first failure. After a partial retrieve, `.forceignore` should still be restored; confirm recovery state, correct authentication/metadata issues, and rerun the dry-run before retrying. Earlier dependency directories may already contain newly retrieved content.

## Package failures

Planning fails when a dependency lacks a package alias or configured version, no released version matches, Salesforce JSON is malformed, or version queries fail. Correct `sfdx-project.json` or org access before mutation.

A required installation key must exist in the configured environment variable. Do not print it while diagnosing. The tool redacts known secret values, but Salesforce CLI receives the key as a process argument and same-user process inspection remains a residual risk.

Recognized transient transport signatures retry up to three total attempts with five-second delays. Other failures are not retried. Package mutations are ordered and stop on first failure; rerunning is normally safe because current and higher installed versions are skipped, but review the package summary and target org first.

## Pool and org creation failures

Pool use requires `sfp` and a resolvable Dev Hub. The resolver prefers `--pool-devhub`, then `pool.devHub`, then Salesforce CLI `target-dev-hub`. Pool listing failure returns a classified error. Empty or unparseable availability either falls back to direct creation or fails according to configuration.

Direct creation warns and continues when preliminary same-alias deletion fails. Confirm the resulting alias and Salesforce default after creation. If org acquisition succeeded but package/post-step setup failed, exit `5` means the org remains and needs inspection; the workflow does not roll it back.

## Project configuration failures

The workflow stops at the first package or post-step failure. Missing permission-set, data-plan, or community configuration is a warning and skips that selected step. A deployment failure prevents later post-steps and dependency refresh. Inventory completed package installs and post-steps before rerunning.

Use `--dry-run` to inspect the selected steps. Dry-run does not guarantee later Salesforce acceptance and does not execute package planning inside the composed configuration workflow.

## Web startup

`web start` requires valid project configuration and built `web-dist` assets. Port values must be integers from `0` through `65535`. A bind conflict fails startup; select another loopback port. `GET /` returns `404 {"error":"Web application is not built"}` when assets are absent.

The server accepts only `127.0.0.1`. Requests with a hostname, IPv6 loopback, proxy-rewritten host, or wrong port in `Host` receive `421`. Do not expose the server through port forwarding, reverse proxies, shared hosts, or tunnels.

## Token, Origin, and API failures

- `401 Unauthorized`: private API request lacks the current process token or uses a stale token after restart.
- `403 Origin does not match Host`: POST has missing/mismatched origin or did not use exact loopback origin.
- `403 Mutation is not allowed for this org`: target policy is read-only.
- `400 Invalid operation request`: unknown command/field, wrong type, invalid string, duration, post-step, or missing delete confirmation.
- `413 Request body is too large`: body exceeded 64 KiB.
- `409 Cancellation is not supported`: expected with the standard facade.

Reload the server-served page after restart so the frontend receives the new bootstrap token. Never place the token in a URL, file, issue, terminal history intended for sharing, or browser storage.

## SSE and history

An unknown operation ID returns `404`. Subscriber limits return `429`; close stale tabs or streams before retrying. The standard limits are 32 total and four per operation. The stream has no heartbeat or resume ID, so network interruption requires refetching operation history and opening a new stream. History contains at most 100 operations and 500 events per operation and is lost at process exit.

The current frontend may append replayed events already loaded in operation history. Duplicate display entries are a known client limitation, not evidence that the underlying command ran twice. Confirm operation ID and server-side status before taking recovery action.

## Safe diagnostics and redaction

Prefer normalized JSON/NDJSON, event kind, step ID, exit code, and timestamp over raw Salesforce output. Before sharing diagnostics:

1. Remove access and refresh tokens, auth URLs, installation keys, authorization headers, environment values, aliases/usernames when sensitive, org IDs, and personal data.
2. Retain command name, sanitized option names, event kinds, exit category, and non-sensitive timing.
3. State whether the result came from fake-backed local tests or an approved authenticated validation.

See [Security](../SECURITY.md) for reporting requirements and residual risks.
