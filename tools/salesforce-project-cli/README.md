# Salesforce Project CLI

Cross-platform Node.js CLI for Salesforce project setup, package maintenance, org inspection, and diagnostics. It requires Node.js 22 or newer and delegates Salesforce operations to the installed `sf` CLI without shell interpolation.

## Documentation

Start with the [documentation map](docs/README.md). Key references are the [CLI reference](docs/cli-reference.md), [configuration](docs/configuration.md), [workflows](docs/workflows.md), [web API](docs/web-api.md), and [operations and troubleshooting](docs/operations-and-troubleshooting.md). Architecture decisions and migration parity remain in [ADR-0001](docs/adr/0001-cli-first-shared-application-core.md) and the [legacy behaviour matrix](docs/legacy-behavior-matrix.md). See [SECURITY.md](SECURITY.md) for the local trust boundary and residual risks.

### API reference

The public TypeScript API is documented with TypeDoc and generated from the package entrypoint in [src/index.ts](src/index.ts). To build the reference locally:

```bash
npm run docs:build
```

This writes HTML output to `api-docs/` and leaves generated content out of version control. To validate the public API and declaration links without emitting files:

```bash
npm run docs:check
```

Use `npm run check` to combine docs validation with type-checking and the project test suite.

## Installation

Run setup from this directory:

```bash
npm run setup
```

The single setup command installs dependencies, builds the CLI and web assets, reviews the host project's `sf-project.config.json`, and links the local `sf-project` executable. Every setting shows its current value and default value. Press Enter to preserve the current value; when a setting is missing, Enter uses the default.

From the host project root, use the linked executable. The setup flow places the project configuration in that root, and the CLI uses the current directory automatically:

```bash
sf-project doctor
```

To verify the extractable npm artifact, run `npm run test:pack`. The smoke test packs the module, installs the tarball into a temporary independent project, runs `sf-project --help`, and removes the fixture. It does not contact Salesforce.

## Configuration

Run commands from a Salesforce DX project or pass `--project-dir <path>`. Package declarations and aliases come from `sfdx-project.json`. Optional behavior comes from `sf-project.config.json`:

```json
{
    "schemaVersion": 1,
    "defaultOrgAlias": "crm-arbeidsforhold",
    "scratchDefinition": "config/project-scratch-def.json",
    "scratchDurationDays": 14,
    "permissionSets": [],
    "dummyDataPlan": null,
    "communityName": null,
    "postSteps": ["deploy"],
    "pool": {
        "use": false,
        "tag": "dev",
        "fallbackToCreate": true
    },
    "packageInstallKeyEnvironmentVariable": "PACKAGE_INSTALL_KEY",
    "dependencySourcePolicy": {
        "preserveRootFiles": ["README.md"]
    }
}
```

Keep installation keys in the configured environment variable. Do not place secrets, access tokens, auth URLs, or credentials in either configuration file.

## Commands

```text
sf-project doctor
sf-project org create
sf-project org delete
sf-project org list
sf-project org status [alias]
sf-project org info <alias>
sf-project project configure
sf-project packages plan
sf-project packages install
sf-project packages update
sf-project dependencies clear
sf-project dependencies recover
sf-project dependencies refresh
sf-project web start
```

Use `--project-dir` on commands that read a project, `--dry-run` on mutating workflows, and `--yes` where destructive confirmation is required. Global `--no-color` disables ANSI styling. Global `--verbose` adds sanitized command diagnostics. Put global options before the command, for example:

```bash
sf-project --no-color --verbose packages plan --target-org my-org
```

`doctor` performs read-only checks for Node.js 22, Salesforce CLI availability, project configuration, Salesforce authentication/org read access, and `sfp` when pool support is configured. It reports each check as pass, fail, or skip and never prints raw subprocess errors that may contain secrets.

Mutating commands are restricted to scratch orgs by default. This includes package installation/update, project configuration, and org deletion. Read-only commands such as `org list`, `org status`, `org info`, `doctor`, and `packages plan` can target any authenticated org. To deliberately override the policy for a non-scratch org, provide the exact command-and-org token shown in the error, for example:

```bash
sf-project packages install --target-org sandbox-org --confirm-mutation "MUTATE packages.install sandbox-org"
```

The token must match both the command and the selected org. A token for one command or alias cannot authorize another operation.

### Dependency source safety

`dependencies refresh` temporarily disables `.forceignore` under a durable project-root transaction marker. The marker records the canonical project path, the exact original content and checksum, and a unique backup identity before `.forceignore` is removed. A later refresh automatically restores an interrupted transaction only when the marker, backup, project path, and active file state agree unambiguously.

Use `dependencies recover --project-dir <path> --dry-run` to inspect the recovery plan without changing files. Remove `--dry-run` to perform the validated recovery; add `--json` for NDJSON events. Recovery never overwrites an active `.forceignore`. Invalid markers, mismatched backups, changed project paths, and conflicting active files fail closed and remain available for manual inspection.

`dependencies clear` rejects symbolic-link dependency roots and children. It revalidates each dependency root immediately before deleting a child and deletes only through a canonical path contained by that validated root.

## Local Web Dashboard And API

Start the versioned local API on the default port `1717`, or select another local port:

```bash
sf-project web start
sf-project web start --port 4310
```

Open the printed loopback URL to use the operational dashboard. Its first view lists connected Salesforce orgs with type, authentication, connection, expiration, and default-org state. Selecting an org shows normalized details, package status availability, approved command forms, and active or recent operations with live Server-Sent Event progress. Production and unknown orgs are read-only. Deleting an allowed org requires an alert dialog that names the target explicitly.

The UI uses Aksel 8.16.2 with Norwegian Nynorsk component translations and responsive desktop, tablet, and mobile layouts. Package status is loaded for the selected org from installed package data and the project dependency plan. Values that Salesforce or project configuration cannot determine are shown explicitly as unknown.

The server binds only to `127.0.0.1`; non-loopback binding is not supported. It generates a new 256-bit session token for each process and injects it into the served same-origin HTML as an ephemeral meta value. The token is never written to normal CLI output. Embedded callers using `startWebServer` receive it in memory through the returned server handle.

Read endpoints:

```text
GET /api/v1/health
GET /api/v1/orgs
GET /api/v1/orgs/:alias
GET /api/v1/orgs/:alias/packages
GET /api/v1/operations
GET /api/v1/operations/:id
GET /api/v1/operations/:id/events
```

The events endpoint uses Server-Sent Events and replays retained events before streaming live events. Operation and event history is bounded in memory and is discarded when the process exits.

`POST /api/v1/operations` accepts only `dependencies.clear`, `dependencies.refresh`, `packages.plan`, `packages.install`, `packages.update`, `org.create`, `org.delete`, and `project.configure`. Payloads reject unknown fields. Mutations against production or unknown orgs are rejected; dry runs remain available. `POST /api/v1/operations/:id/cancel` returns a conflict response unless the injected service facade supports cancellation.

Every POST requires both `Authorization: Bearer <session-token>` and an `Origin` header matching the loopback `Host` exactly. Responses and retained events redact Salesforce access tokens and configured installation keys, and omit auth-file and environment fields. The server does not expose raw command environments or Salesforce credentials.

The frontend is built separately under `web/`, then emitted to `web-dist/`. Core and server sources do not import React or Aksel. The server applies a restrictive Content Security Policy, denies framing and MIME sniffing, disables referrer data, and serves only allowlisted asset types from the built asset directory.

## Web Development And Validation

```bash
npm run test:web
npm run typecheck
npm run build
npm run test:e2e
npm run test:pack
```

Component tests use Vitest, Testing Library, and axe. Playwright starts a deterministic in-memory facade that never invokes Salesforce, then checks desktop and mobile-emulation layouts, viewport overflow, screenshots, accessibility, destructive confirmation, and live events. The local Playwright configuration uses the installed Chrome channel; no browser download is performed by these commands.

## Output And Exit Codes

Human output groups operations, steps, progress, retries, warnings, durations, failures, next actions, and resource summaries. Color is enabled only for a TTY and can always be disabled with `--no-color`.

For operation commands, `--json` writes one JSON event per line to stdout and ends with `operation-completed`. Non-JSON diagnostics and parser errors go to stderr. Org query commands emit one normalized JSON document. Never parse human output in automation.

| Code | Meaning                                 |
| ---: | --------------------------------------- |
|    0 | Success                                 |
|    1 | Operation failure                       |
|    2 | Invalid input or configuration          |
|    3 | Missing prerequisite                    |
|    4 | Authentication or authorization failure |
|    5 | Partial completion requiring attention  |

## Migration From create-scratch-org.sh

Prefer the new CLI for new automation. Typical mappings are:

| Legacy invocation                                       | CLI equivalent                             |
| ------------------------------------------------------- | ------------------------------------------ |
| `create-scratch-org.sh --self-check`                    | `sf-project doctor`                        |
| `create-scratch-org.sh --clear-dependency-sources-only` | `sf-project dependencies clear`            |
| `create-scratch-org.sh --package-plan`                  | `sf-project packages plan`                 |
| `create-scratch-org.sh --update-packages`               | `sf-project packages update`               |
| `create-scratch-org.sh --delete-org-only --alias NAME`  | `sf-project org delete --alias NAME --yes` |
| `create-scratch-org.sh --dry-run`                       | `sf-project org create --dry-run`          |

The Bash script remains the authoritative compatibility implementation for now. It has options and environment behavior without safe one-to-one CLI mappings, including custom project/definition files, macOS Keychain install-key lookup, version-check suppression, and combinations of `--skip-org`, `--skip-packages`, and post-step selection. Converting it to a forwarding wrapper before those contracts have parity tests would lose behavior. Batch and PowerShell entry points are likewise unchanged.

Migration is complete only when a legacy invocation has an explicit equivalent and matching argument, environment, summary, and exit-code tests. Until then, existing automation may continue using the script while new workflows adopt `sf-project` directly.
