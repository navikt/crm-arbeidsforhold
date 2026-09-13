# CLI reference

The executable name is `sf-project`. It requires Node.js 22 or newer and delegates Salesforce operations to an installed `sf` CLI. Pool workflows additionally require `sfp`.

## Installation and invocation

From this module:

```bash
npm ci
npm run build
npm run dev -- --help
```

`npm run dev -- <arguments>` runs `tsx src/cli.ts`. A built or installed package exposes `sf-project` through `dist/cli.js`:

```bash
sf-project --help
sf-project doctor --project-dir /path/to/project
```

The package is currently marked `private`; there is no publish or release script. `npm run test:pack` is the supported independent-package smoke test, not a publication command.

## Global options

Global options must appear before the command:

| Option       | Default                    | Behavior             |
| ------------ | -------------------------- | -------------------- |
| `--no-color` | Color when stdout is a TTY | Disable ANSI styling |

Real deletion first inspects the org and succeeds only for an authenticated scratch org with `--yes`. A non-scratch override requires `--confirm-mutation "MUTATE org.delete <alias>"`. Dry-run does not require confirmation or org inspection.

```bash
sf-project --no-color --verbose packages plan --target-org my-scratch-org
sf-project org delete --alias sandbox-org --confirm-mutation "MUTATE org.delete sandbox-org"
```

## Commands

All `--project-dir` values default to the current working directory.

### `doctor`

```text
sf-project project configure [--project-dir <path>] [--alias <alias>] [--target-org <alias>] [--post-steps <steps>] [--refresh-dependency-sources] [--dry-run] [--json] [--confirm-mutation <text>]
```

Runs read-only checks for Node.js 22, `sf`, project configuration, org-list access, and `sfp` when pool support is configured. `--json` emits NDJSON events.

### `web start`

```text
sf-project packages install [--project-dir <path>] [--target-org <alias-or-username>] [--install-latest] [--dry-run] [--json] [--confirm-mutation <text>]
```

Real installation is restricted to scratch orgs. For another org, the exact token `MUTATE packages.install <alias-or-username>` is required.
`--port` defaults to `1717` and accepts an integer from `0` through `65535`; `0` asks the operating system for an available port. The command binds to `127.0.0.1`, prints the loopback URL, and remains active until the process stops.

### `org list`

```text
sf-project org list [--project-dir <path>] [--refresh] [--json]
```

sf-project packages update [--project-dir <path>] [--target-org <alias-or-username>] [--install-latest] [--dry-run] [--json] [--confirm-mutation <text>]
Lists normalized org summaries. `--refresh` issues a display query for every listed org with an alias or username. `--json` returns one JSON document, not NDJSON.

Real updates are restricted to scratch orgs. For another org, the exact token `MUTATE packages.update <alias-or-username>` is required.

### `org status`

```text
sf-project org status [alias] [--project-dir <path>] [--refresh] [--json]
```

Resolves the explicit alias or username. Without one, it reads Salesforce CLI `target-org`; it does not use `defaultOrgAlias`. `--refresh` enriches the result with a display query. `--json` returns one JSON document.

### `org info`

```text
sf-project org info <alias> [--project-dir <path>] [--json]
```

Displays normalized org details plus API version, edition, creation date, and Dev Hub username. Failed display calls are normalized as inaccessible or unauthenticated data. `--json` returns one JSON document.

### `org create`

```text
sf-project org create [options]
```

| Option                         | Default or precedence                                       |
| ------------------------------ | ----------------------------------------------------------- |
| `--project-dir <path>`         | Current directory                                           |
| `--alias <alias>`              | First alias choice                                          |
| `--target-org <alias>`         | Second alias choice                                         |
| `--duration-days <days>`       | Config value, then `14`; integer `1..30`                    |
| `--use-pool`                   | `pool.use`                                                  |
| `--pool-tag <tag>`             | `pool.tag`                                                  |
| `--pool-devhub <alias>`        | `pool.devHub`                                               |
| `--fallback-to-create`         | `pool.fallbackToCreate`                                     |
| `--no-fallback-to-create`      | Override fallback to `false`                                |
| `--post-steps <steps>`         | Configured `postSteps`                                      |
| `--clear-dependency-sources`   | `false`                                                     |
| `--refresh-dependency-sources` | `false`                                                     |
| `--dry-run`                    | `false`                                                     |
| `--json`                       | `false`                                                     |
| `--yes`                        | Declared, but currently not consumed by the create workflow |

Alias precedence is `--alias`, `--target-org`, then `defaultOrgAlias`. `--post-steps` accepts `all`, `none`, or a comma-separated list of `deploy`, `permsets`, `data`, and `community`. Execution always uses canonical order regardless of list order.

```bash
sf-project org create --alias feature-org --duration-days 7 --post-steps deploy,permsets --dry-run
sf-project org create --alias feature-org --use-pool --pool-devhub dev-hub --no-fallback-to-create
```

### `org delete`

```text
sf-project org delete [--project-dir <path>] [--alias <alias>] [--target-org <alias>] [--dry-run] [--json] [--yes] [--confirm-mutation <text>]
```

Alias precedence is `--alias`, `--target-org`, then `defaultOrgAlias`. A real deletion first inspects the org and succeeds only for an authenticated, policy-allowed scratch org with `--yes`. Dry-run does not require `--yes` or org inspection, but still evaluates deletion policy as scratch.

```bash
sf-project org delete --alias feature-org --dry-run
sf-project org delete --alias feature-org --yes
```

### `project configure`

```text
sf-project project configure [--project-dir <path>] [--alias <alias>] [--target-org <alias>] [--post-steps <steps>] [--refresh-dependency-sources] [--dry-run] [--json]
```

Alias and post-step precedence match `org create`. The workflow installs configured packages, executes selected post-steps, and optionally refreshes dependency sources.

### `packages plan`

```text
sf-project packages plan [--project-dir <path>] [--target-org <alias-or-username>] [--install-latest] [--dry-run] [--json]
```

This command is read-only regardless of `--dry-run`. It queries installed and released package versions and emits the selected action. `--install-latest` ignores the configured version family and selects the greatest released version.

### `packages install`

```text
sf-project packages install [--project-dir <path>] [--target-org <alias-or-username>] [--install-latest] [--dry-run] [--json]
```

Installs missing packages and upgrades older packages in declaration order. It skips equal versions and never downgrades a higher installed version. Dry-run still performs read-only Salesforce queries.

### `packages update`

```text
sf-project packages update [--project-dir <path>] [--target-org <alias-or-username>] [--install-latest] [--dry-run] [--json]
```

The current implementation has the same behavior as `packages install`: install missing, upgrade older, skip equal, and retain higher versions.

### `dependencies clear`

```text
sf-project dependencies clear [--project-dir <path>] [--dry-run] [--json]
```

Removes non-preserved entries from configured dependency source roots. Dry-run validates roots and reports intent without enumerating or deleting children.

### `dependencies recover`

```text
sf-project dependencies recover [--project-dir <path>] [--dry-run] [--json]
```

Validates and restores an interrupted `.forceignore` transaction. Dry-run reports the validated recovery plan without changing files.

### `dependencies refresh`

```text
sf-project dependencies refresh [--project-dir <path>] [--target-org <alias-or-username>] [--dry-run] [--json]
```

Recovers any prior transaction, temporarily disables `.forceignore`, clears dependency roots, retrieves each dependency in order, and restores `.forceignore`. Without `--target-org`, Salesforce CLI target resolution applies.

## Target resolution

- `org create`, `org delete`, and `project configure`: `--alias` → `--target-org` → `defaultOrgAlias`; absence is invalid.
- Package commands: `--target-org` → `defaultOrgAlias` → omit the Salesforce option and let `sf` resolve its default.
- Dependency refresh: explicit `--target-org` or omit it and let `sf` resolve its default.
- `org status`: explicit positional alias or Salesforce CLI `target-org`.

## Output contracts

Human operation output groups operation and step state, progress, retries, warnings, durations, failures, next actions, and summaries. Diagnostic progress is shown only with `--verbose`. Automation must not parse human output.

Operation commands with `--json` emit one `OperationEvent` JSON object per stdout line and finish with `operation-completed`. The terminal event includes the stable exit code, duration, dry-run state, and renderer-added resource summary. Parser errors and non-JSON diagnostics go to stderr.

`org list`, `org status`, and `org info` use `--json` for one normalized JSON document instead of NDJSON.

## Exit codes

| Code | Meaning                                 |
| ---: | --------------------------------------- |
|  `0` | Success                                 |
|  `1` | Operation failure                       |
|  `2` | Invalid input or configuration          |
|  `3` | Missing prerequisite                    |
|  `4` | Authentication or authorization failure |
|  `5` | Partial completion requiring attention  |

Commander validation, malformed JSON configuration, and schema errors map to `2`. Missing files can map to `3`. Salesforce failures are classified when possible. Package or retrieve failure after earlier successful mutations uses `5` unless authentication classification is more specific. `org create` also uses `5` when acquisition succeeded but later configuration failed, except authentication/authorization remains `4`.

## Destructive confirmation

- Real `org delete` requires `--yes`, an authenticated inspection result, and scratch classification.
- Dry-run `org delete` does not require `--yes`.
- Web deletion uses a separate `confirmed: true` payload contract and a target-naming alert dialog.
- `org create` attempts to delete an existing same-alias scratch org before direct creation using Salesforce `--no-prompt`; the declared create `--yes` option does not control this behavior.
- Dependency clear, dependency refresh, package install/update, and project configuration do not have interactive confirmation prompts. Use `--dry-run` first where available.
