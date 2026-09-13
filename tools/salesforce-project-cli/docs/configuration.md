# Configuration

Every command that loads project configuration requires `sfdx-project.json` in the resolved project root. `sf-project.config.json` is optional. Values are normalized once into absolute paths and typed workflow settings.

## Precedence

1. Relevant CLI option
2. `sf-project.config.json`
3. Built-in default
4. Salesforce CLI target resolution only where the tool intentionally omits `--target-org`

The project root is `path.resolve(--project-dir)`, so a relative value is resolved from the CLI process working directory.

## `sfdx-project.json`

The loader reads these fields:

| Field                               | Type                        | Required             | Behavior                                                              |
| ----------------------------------- | --------------------------- | -------------------- | --------------------------------------------------------------------- |
| `packageDirectories`                | Non-empty array             | Yes                  | Each entry requires a non-empty `path`                                |
| `packageDirectories[].package`      | Non-empty string            | No                   | Associates a package name with its source directory                   |
| `packageDirectories[].dependencies` | Array                       | No                   | Contributes package dependencies in declaration order                 |
| `dependencies[].package`            | Non-empty string            | Yes                  | Package name used for aliases, keys, plans, and retrieval             |
| `dependencies[].versionNumber`      | String                      | No                   | Configured release family or exact build                              |
| `packageAliases`                    | Record of non-empty strings | No; defaults to `{}` | Maps dependency names to package aliases/IDs used for version queries |
| `packageKeyConfig`                  | Record of booleans          | No; defaults to `{}` | Controls whether a dependency requires an installation key            |

Example:

```json
{
    "packageDirectories": [
        {
            "path": "force-app",
            "package": "main-package",
            "dependencies": [
                {
                    "package": "shared-package",
                    "versionNumber": "2.4.0.LATEST"
                }
            ]
        },
        {
            "path": "shared-package",
            "package": "shared-package"
        }
    ],
    "packageAliases": {
        "shared-package": "<package-alias-or-id>"
    },
    "packageKeyConfig": {
        "shared-package": false
    }
}
```

Dependency installation order retains every declaration, including duplicate package names. Dependency source roots deduplicate package names, then choose the first package directory whose `package` equals the dependency name or whose path basename equals it. A dependency without a matching source directory fails configuration loading.

Missing `packageKeyConfig[packageName]` means the package requires an installation key. Package planning requires both a package alias and configured version for every dependency. Supported configured versions are `major.minor.patch`, `major.minor.patch.LATEST`, `major.minor.patch.NEXT`, or an exact numeric `major.minor.patch.build`.

## `sf-project.config.json`

Run `npm run sf-project:setup` from the Salesforce project root to create this file interactively. The setup keeps an existing file unless the user explicitly chooses to update it. For CI or a first bootstrap that must not prompt, use `npm run sf-project:setup:defaults` from the repository root or pass `--non-interactive` to `scripts/setup-project.mjs`.

The setup asks for project-specific values and offers portable defaults. It never asks for or writes package installation keys. Keep those keys in the configured environment variable, an approved secret store, or a platform credential manager. On macOS, Keychain can be used for one-command export:

```bash
security add-generic-password -a "$USER" -s PACKAGE_INSTALL_KEY -w
PACKAGE_INSTALL_KEY="$(security find-generic-password -a "$USER" -s PACKAGE_INSTALL_KEY -w)" npm run sf-project -- packages install --target-org my-org
```

The Keychain command is an operator convenience; the CLI still receives the secret through the environment for that process. Do not commit the value or place it in this JSON file.

The complete implemented schema is:

| Field                                      | Type                                               | Default                           | Meaning                                                                                          |
| ------------------------------------------ | -------------------------------------------------- | --------------------------------- | ------------------------------------------------------------------------------------------------ |
| `schemaVersion`                            | Literal `1`                                        | `1`                               | Configuration contract version                                                                   |
| `defaultOrgAlias`                          | Non-empty string                                   | None                              | Default target for create, delete, configure, and package operations                             |
| `scratchDefinition`                        | Non-empty string                                   | `config/project-scratch-def.json` | Scratch definition path                                                                          |
| `scratchDurationDays`                      | Integer `1..30`                                    | `14`                              | Scratch-org lifetime                                                                             |
| `permissionSets`                           | Non-empty string array                             | `[]`                              | Permission sets assigned by the `permsets` post-step                                             |
| `dummyDataPlan`                            | Non-empty string or `null`                         | `null`                            | Data tree import plan; `null` disables configured data import                                    |
| `communityName`                            | Non-empty string or `null`                         | `null`                            | Experience Cloud community to publish                                                            |
| `postSteps`                                | Array of `deploy`, `permsets`, `data`, `community` | `["deploy"]`                      | Selected project configuration steps                                                             |
| `pool.use`                                 | Boolean                                            | `false`                           | Try `sfp` pool acquisition                                                                       |
| `pool.tag`                                 | Non-empty string                                   | `dev`                             | Pool tag                                                                                         |
| `pool.devHub`                              | Non-empty string                                   | Salesforce `target-dev-hub`       | Optional explicit Dev Hub alias or username; falls back to `sf config get target-dev-hub --json` |
| `pool.fallbackToCreate`                    | Boolean                                            | `true`                            | Create directly when pool availability cannot be established                                     |
| `packageInstallKeyEnvironmentVariable`     | Non-empty string                                   | `PACKAGE_INSTALL_KEY`             | Name of the environment variable holding installation keys                                       |
| `dependencySourcePolicy.preserveRootFiles` | Non-empty string array                             | `["README.md"]`                   | Root entry names retained during dependency cleanup                                              |

Example:

```json
{
    "schemaVersion": 1,
    "defaultOrgAlias": "feature-org",
    "scratchDefinition": "config/project-scratch-def.json",
    "scratchDurationDays": 14,
    "permissionSets": ["Application_User"],
    "dummyDataPlan": "dummy-data/Plan.json",
    "communityName": null,
    "postSteps": ["deploy", "permsets", "data"],
    "pool": {
        "use": false,
        "tag": "dev",
        "devHub": "development-hub",
        "fallbackToCreate": true
    },
    "packageInstallKeyEnvironmentVariable": "PACKAGE_INSTALL_KEY",
    "dependencySourcePolicy": {
        "preserveRootFiles": ["README.md"]
    }
}
```

Unknown object keys are currently stripped by Zod rather than rejected. There is no standalone JSON Schema file. Do not rely on unknown keys being preserved.

## Path resolution

These paths become absolute relative to the resolved project root:

- `scratchDefinition`
- non-null `dummyDataPlan`
- every dependency package directory

The loader validates shape but does not check that scratch definition, data plan, or dependency directories exist. Dependency cleanup skips a missing dependency directory; later workflows may fail when they need missing files.

`dependencySourcePolicy.preserveRootFiles` contains entry names, not paths or glob patterns. Matching entries at each dependency root are retained exactly. Other root children are recursively removed only after containment and symlink checks.

## Environment variables and secrets

The value of `packageInstallKeyEnvironmentVariable` names the sole supported secret source. For example, the default configuration reads `PACKAGE_INSTALL_KEY` from the process environment when a package requiring a key is actually installed.

```bash
export PACKAGE_INSTALL_KEY='<provided-through-an-approved-secret-channel>'
sf-project packages install --target-org feature-org --dry-run
```

Dry-run package mutation does not read the key. Real installation fails if a required key is absent. The value is marked as secret for command-output redaction, but Salesforce CLI currently receives it as an argument, so it may remain visible to same-user process inspection. No Keychain, keyring, config-file secret, or alternate provider is implemented. Never put keys, access tokens, auth URLs, credentials, or personal data in either JSON file.

## Command overrides

- `--duration-days` overrides `scratchDurationDays`.
- `--post-steps` overrides `postSteps`; `all` expands to all four steps and `none` to an empty list.
- `--use-pool`, `--pool-tag`, `--pool-devhub`, and `--[no-]fallback-to-create` override the corresponding pool values.
- Explicit aliases override `defaultOrgAlias` where that config field participates.
- `--install-latest` changes package version selection from the configured version family to the greatest released version.
- `--refresh-dependency-sources` and `--clear-dependency-sources` are command flags and have no config defaults.

## Validation failures

Configuration loading fails for malformed JSON, unsupported `schemaVersion`, wrong types, empty required strings, empty `packageDirectories`, duration outside `1..30`, invalid post-step names, or a dependency with no matching package directory. CLI parsing separately rejects an invalid duration, port, post-step string, or missing required alias.

Expected syntax and schema failures return exit code `2`. A missing required file can return `3`. `doctor` reports configuration failure without printing raw configuration or secret values and gives the corrective action to fix either JSON file.
