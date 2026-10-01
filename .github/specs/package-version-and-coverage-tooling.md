---
slug: package-version-and-coverage-tooling
status: in-progress
github-issue: 1070
---

# Package version maintenance and coverage tooling

## Problem

The repository has three setup entry paths: the macOS/Linux Bash script, the Windows PowerShell/CMD scripts, and the standalone `sf-project` CLI. Two useful operations remain outside that shared capability set:

- `bin/check-sfdx-versions.js` compares package versions and interactively writes newer `.LATEST` constraints into `sfdx-project.json` with a backup.
- `bin/post-package-coverage-check.ps1` optionally installs a package, deploys source, runs a test class or the full Apex suite, and enforces a coverage threshold.

The package CLI can plan/install/update org packages but does not update the project's package constraints. Coverage checks are not available through the Bash or `sf-project` CLI.

## Desired outcome

All three supported command-line workflows provide equivalent package-version maintenance and post-package coverage checks without invoking `sf-project` from Bash or PowerShell. `sf-project` is a peer implementation, not a runtime dependency of the scripts.

## Behavior baseline

- Package version check: inspect each dependency's latest released version via its package alias, report current and latest versions, and propose `<major>.<minor>.<patch>.LATEST` when the configured base differs.
- Project update: default to preview only. Require an explicit `--apply` / `-Apply` to write. Before writing, create `sfdx-project.json.backup`; preserve unrelated JSON structure and update matching dependencies across package directories. All entry points use the same comparison and backup behavior.
- Coverage: preserve this repository's existing utility behavior through project config: threshold 75%, test class `AAREG_ApplicationDecisionControllerTest`, optional package install, optional deploy, and aggregate query restricted to `AAREG_%` Apex classes. Portable defaults are threshold 75%, all tests, and `%`. Make package ID, install key environment, threshold, test mode/class, class pattern, and skip-install/deploy configurable.
- Coverage operations require an explicit target org. `sf-project` applies its existing scratch-only mutation policy, with the existing exact confirmation override for other org classes.

## Requirements

- **REQ-400:** Bash provides package version check/preview and explicit project-file update modes using package aliases and latest released versions.
- **REQ-401:** PowerShell provides equivalent package version check/preview and explicit project-file update modes; it remains standalone and does not call Bash or `sf-project`.
- **REQ-402:** `sf-project` provides terminal commands to check package versions and update configured constraints. Preview is read-only; writing requires an explicit apply flag.
- **REQ-403:** Every project-file update creates a `.backup` copy before the atomic write, preserves unrelated JSON, and updates all matching dependency declarations.
- **REQ-404:** All three entry points provide post-package coverage check with configurable target, package ID, minimum threshold, optional install/deploy, and selected-class or run-all Apex tests.
- **REQ-405:** Coverage calculation uses aggregate Apex coverage for the configured class-name LIKE pattern (portable default `%`), returns failure below threshold, and reports measured coverage and threshold.
- **REQ-406:** `sf-project` coverage mutation is scratch-only by default and uses the existing exact mutation confirmation contract for non-scratch orgs. Script entry points require explicit target org selection/configuration and never silently select production.
- **REQ-407:** Unit/contract and script tests mock Salesforce commands. No test creates/deletes an org, installs a package, deploys metadata, or runs tests against a real org.
- **REQ-408:** The old `check-sfdx-versions.js` and `post-package-coverage-check.ps1` remain until all three replacements have passing local tests and documentation parity. Remove them only after that gate.

## Scope

- Bash (`bin/create-scratch-org.sh` or a focused sourced helper).
- PowerShell (`bin/create-scratch-org.ps1`) and its CMD launcher.
- `sf-project` terminal CLI commands and their unit/contract tests.
- CLI/configuration docs, `bin/README.md`, root README, and the legacy behavior matrix.

## Out of scope

- Adding these operations to the browser dashboard/web API in this delivery.
- Running any Salesforce command against an authenticated org as a validation step.
- Changing default package versions or coverage thresholds in project config.

## Verification

- Run focused tests for each command/service and script harness.
- Run `npm run check` in `tools/salesforce-project-cli` and the Bash offline suite.
- Run the PowerShell test harness on Windows before closing this spec; the current macOS host may only perform static/editor checks.
- Search references before removing either old utility.
