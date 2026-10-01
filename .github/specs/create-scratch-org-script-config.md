---
slug: create-scratch-org-script-config
status: implemented-local-validation
github-epic: 1058
---

# create-scratch-org.sh: shared project configuration and repository independence

## Problem statement

`bin/create-scratch-org.sh` is still the authoritative Bash implementation for scratch-org setup (see the migration section in [tools/salesforce-project-cli/README.md](../../tools/salesforce-project-cli/README.md)). It does not read `sf-project.config.json`. The file was introduced for `sf-project` and already holds this repository's org alias, permission sets, data plan, community and post-steps. Two sources of truth therefore exist for the same settings.

The script also hardcodes values that only make sense in `crm-arbeidsforhold`:

- default org alias `crm-arbeidsforhold`
- community name `Aa-registret`
- data plan `dummy-data/plan.json`
- permission sets `AAREG_Arbeidsforhold_Saksbehandling`, `AAREG_Arbeidsforhold_Support`, `AAREG_CommunityPermission`
- dummy user permission-set assignments and usernames (`DUMMY_SAKSBEHANDLER_*`, `DUMMY_SUPPORT_*`)
- the list of packages that do not need an installation key, which duplicates `packageKeyConfig` in `sfdx-project.json`
- the Keychain service name `crm-arbeidsforhold-package-install-key`
- `README.md` as the only root entry kept during dependency cleanup, and the assumption that a dependency directory is named after the package
- `NAV DevHub` in the help text and error messages

Because of this, the script cannot be copied into another Salesforce DX project without editing it. It also cannot create the configuration file it should read.

## Desired outcome

The same script works in any Salesforce DX project. Project-specific values come from `sf-project.config.json`, environment variables, or CLI options. The script contains only generic defaults. It can create `sf-project.config.json` through its own command. Existing `crm-arbeidsforhold` behavior is preserved by moving the repository-specific values into this repository's `sf-project.config.json`.

## Guiding decisions

- Precedence is **CLI option > environment variable > `sf-project.config.json` > built-in generic default**, matching `sf-project`'s CLI > config > default order, with environment variables kept as the script's existing override channel.
- Read the same `sf-project.config.json` schema that `sf-project` uses (see [configuration.md](../../tools/salesforce-project-cli/docs/configuration.md)). Do not introduce a second format.
- Dummy user import is configured in the `dummyUsers` section. `sf-project` supports the same section in its schema and `data` post-step, so the configuration file contains nothing that `sf-project` cannot handle. `setup-project.mjs` must preserve it when it rewrites the file.
- The script accepts and rejects exactly the configuration files that `sf-project` accepts and rejects, and uses the same defaults.
- A post-step with no configured value is skipped with a warning instead of failing. This matches `sf-project` behavior.
- Never write installation keys or other secrets to the configuration file.

## Functional requirements

- **REQ-200:** When `sf-project.config.json` exists next to the project file, the script reads it. `--config <file>` or `SF_PROJECT_CONFIG` selects another file, and `--no-config` disables loading.
- **REQ-201:** Supported fields: `defaultOrgAlias`, `scratchDefinition`, `scratchDurationDays`, `permissionSets`, `dummyDataPlan`, `communityName`, `postSteps`, `customPostSteps`, `pool.use`, `pool.tag`, `pool.devHub`, `pool.fallbackToCreate`, `packageInstallKeyEnvironmentVariable`, `dependencySourcePolicy.preserveRootFiles`, `dependencySourcePolicy.requireLocalDirectories`, and `dummyUsers`. Relative paths resolve from the project root, as in `sf-project`.
- **REQ-202:** A CLI option or environment variable overrides the matching configuration value.
- **REQ-203:** An org alias from the CLI, the environment, or `defaultOrgAlias` is the target for partial modes such as `--post-steps-only` and `--update-packages`. Only when no alias exists does the script fall back to `sf config get target-org`.
- **REQ-204:** Invalid JSON or an unsupported `schemaVersion` fails before any org command runs.
- **REQ-210:** `--init-config` writes `sf-project.config.json` from the effective settings (options, environment, existing configuration, and defaults), then exits without running org or package commands.
- **REQ-211:** `--init-config` refuses to overwrite an existing file unless `--force` is given. With `--force`, it keeps keys it does not manage. With `--dry-run`, it prints the JSON instead of writing it.
- **REQ-212:** The written file never contains an installation key.
- **REQ-220:** No repository-specific value remains in `bin/create-scratch-org.sh`. That includes aliases, community names, permission sets, usernames, package names, Keychain service names, and Dev Hub names.
- **REQ-221:** Whether a package needs an installation key comes from `packageKeyConfig` in `sfdx-project.json`. A missing entry means the key is required. `PACKAGES_NOT_REQUIRING_INSTALL_KEY` remains an optional override.
- **REQ-222:** Without an alias, the default alias is the project directory name.
- **REQ-223:** Dependency cleanup reads dependencies from every package directory. It finds each dependency's directory through `packageDirectories[].package` or the path basename, and keeps the files listed in `preserveRootFiles`.
- **REQ-224:** The `permsets`, `data`, and `community` steps, dummy user import, and dummy user permission-set assignment are skipped with a warning when they have no configured value.
- **REQ-230:** This repository's `sf-project.config.json` contains the values that were previously hardcoded, so `crm-arbeidsforhold` behaves as before.
- **REQ-231:** `bin/README.md`, `dummy-data/README.md`, and the `sf-project` configuration documentation describe how the script uses the configuration file.
- **REQ-240:** Every configuration file is either accepted by both the script and the `sf-project` loader or rejected by both. This covers types, nullability, `schemaVersion`, the 1 to 30 day duration range, unknown `postSteps` entries, `customPostSteps` name collisions and duplicates, `commandTimeouts`, and `dummyUsers`.
- **REQ-241:** Defaults and empty values match `sf-project`: `postSteps` defaults to `["deploy"]`, and an empty `postSteps` or `preserveRootFiles` array means "none".
- **REQ-242:** `dependencySourcePolicy.requireLocalDirectories` (default `true`) makes an undeclared dependency directory an error during dependency cleanup; `false` makes it a warning.
- **REQ-243:** Custom post-steps run from the project root, as in `sf-project`.
- **REQ-244:** `sf-project` supports `dummyUsers`: its `data` post-step imports missing users with the resolved profile and assigns permission sets, tolerating duplicate assignments. Both tools escape SOQL string literals the same way.

## Delivery order

| Step | Issue | Title | Requirements |
| ---: | ----- | ----- | ------------ |
| 1 | #1059 | Read `sf-project.config.json` in `create-scratch-org.sh` | REQ-200 to REQ-204 |
| 2 | #1060 | Add `--init-config` to create `sf-project.config.json` | REQ-210 to REQ-212 |
| 3 | #1061 | Remove repository-specific hardcoded values from `create-scratch-org.sh` | REQ-220 to REQ-224 |
| 4 | #1062 | Move repository values to configuration and update documentation | REQ-230, REQ-231 |
| 5 | #1064 | Align `create-scratch-org.sh` config handling with `sf-project` | REQ-240 to REQ-244 |

## Verification strategy

- Add a Bash test, `bin/tests/create-scratch-org.test.sh`, that puts a fake `sf` on `PATH` and uses temporary project directories. It exercises configuration loading, precedence, `--init-config`, and dry-run output without contacting Salesforce.
- Run `bash -n` syntax checks on the script and the test.
- Compare `--post-steps-only --dry-run` output of the previous script (from `HEAD`) and the new script against this repository's configuration, with a fake `sf`, to show that the effective commands match the previous hardcoded values (REQ-230).
- The same Bash test loads a set of valid and invalid fixtures with both the script and the `sf-project` loader (through `tsx`) and requires identical verdicts (REQ-240).
- `sf-project` unit tests cover `dummyUsers` configuration loading and the import in the `data` post-step with a fake command runner (REQ-244).
- Authenticated scratch-org verification is not part of this work and must not be reported as passed.

## Out of scope

- Applying `commandTimeouts` in the Bash script.
- Changes to `newScratchOrg.bat`, `resolve_packages.ps1`, or `install-scratch.sh`.

## Issue mapping

- Epic: #1058
- Delivery issues: #1059, #1060, #1061, #1062, #1064

## Implementation status

All delivery issues are implemented. `bash bin/tests/create-scratch-org.test.sh` passes 134 assertions offline, including the cross-tool check for 19 fixtures. `npm run check` in `tools/salesforce-project-cli` passes (175 core tests, 16 web tests, docs check, build). The parity comparison shows identical post-step commands for this repository; the only difference is that the data plan path now uses the actual file name `dummy-data/Plan.json` instead of `dummy-data/plan.json`.

Authenticated verification against a scratch org was not run and is not claimed as passed.
