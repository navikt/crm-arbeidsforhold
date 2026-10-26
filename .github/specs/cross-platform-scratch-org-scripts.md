---
slug: cross-platform-scratch-org-scripts
status: implemented-local-validation
---

# Cross-platform standalone scratch-org setup scripts

## Reading this historical baseline

The problem statement and desired outcome below record the original migration,
not today's runtime or file inventory. Later approved work requires PowerShell 7
only and adds a shared Node dependency preflight. `newScratchOrg.bat` is not
present in the current checkout. Use the maintained
[command reference](../../bin/COMMANDS.md) and
[compatibility/evidence matrices](../../bin/COMPATIBILITY.md) for actual entry
points, Node requirements, known parity differences and verification limits.

## Problem

`bin/create-scratch-org.sh` is the maintained standalone workflow for macOS/Linux and reads `sf-project.config.json`. The documented Windows entry point, `bin/newScratchOrg.bat`, is an older implementation with hardcoded project values, requires the install key as a positional argument, and delegates package resolution to `resolve_packages.ps1`. It does not provide the current Bash script's modes or configuration parity. Windows users should not need the separate `tools/salesforce-project-cli` installation.

## Desired outcome

- Keep `create-scratch-org.sh` as the standalone macOS/Linux entry point.
- Provide `create-scratch-org.ps1` as a standalone PowerShell implementation using only PowerShell and the installed Salesforce CLI (`sf`), not `sf-project` or Node tooling.
- Provide `create-scratch-org.bat` as a CMD-compatible launcher for that PowerShell script. Keep `newScratchOrg.bat` as a compatibility launcher during migration.
- Keep supported settings in `sf-project.config.json`; do not duplicate repository-specific values in platform scripts.
- Remove only legacy `bin` utilities verified to have no current callers and superseded by the new supported paths.

## Requirements

- **REQ-300:** PowerShell loads and validates the same project config fields, defaults, precedence, paths, `dummyUsers.profileAssignments`, and post-step declarations as the Bash script.
- **REQ-301:** PowerShell uses direct `sf` invocations and supports create/delete, pool acquisition, package install/update/plan, deploy, permission sets, dummy data/users, community, self-check, dry-run, dependency cleanup/retrieval, post-steps-only, and custom post-steps.
- **REQ-302:** PowerShell handles subprocess arguments without string-evaluated commands, checks every exit code, and never prints install-key values. Installation keys come from the configured environment variable.
- **REQ-303:** CMD launcher forwards every argument to PowerShell, propagates the exit code, and does not require the Salesforce Project CLI.
- **REQ-304:** Offline tests use a fake `sf`/injected command runner and temporary projects. No authenticated org is needed for tests.
- **REQ-305:** Delete `install-scratch.sh`, `get-latest-released-packages-posix.sh`, `resolve_packages.ps1`, and `check-version.js` only after verifying no callers remain. Preserve `check-sfdx-versions.js`, `post-package-coverage-check.ps1`, and the `p360-mock-smoke.sh` npm test. Remove documentation image assets only when they no longer have a reference.
- **REQ-306:** `newScratchOrg.bat` remains as a compatibility shim to the supported CMD entry point until a separately approved removal.

## Verification

- Shell tests continue to pass on macOS/Linux.
- PowerShell tests run on Windows with mocked `sf`; additionally run PowerShell parser validation on the script and tests.
- Verify the CMD launcher preserves parameters and exit codes with a stub PowerShell executable.
- Verify removed-file references with repository-wide search before deletion.
- No scratch org is created/deleted, no package is installed, and no deployment is performed during local tests.

## Cleanup policy

Age alone is not sufficient evidence for deletion. Keep scripts with documented workflows, current references, or distinct supported functions. Candidate removal is limited to files listed by REQ-305.

## Current implementation status

The Windows PowerShell engine, CMD/npm launchers and portable offline harness
are implemented. The legacy compatibility launcher is no longer present.
PowerShell 7 tests now run locally on macOS, and this repository has a green
Windows offline run at SHA `1979ef2c15529652cdd26cdff8ccd80f8155935b`
([run 40043090089](https://github.com/navikt/crm-arbeidsforhold/actions/runs/40043090089)).
That run predates later local reporting changes. Exact evidence and remaining
gaps are tracked in [the matrices](../../bin/COMPATIBILITY.md), not by the old
assertion count in this baseline. No live Salesforce installation or deployment
is certified by offline tests.
