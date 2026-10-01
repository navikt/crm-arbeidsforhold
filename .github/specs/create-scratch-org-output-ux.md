---
slug: create-scratch-org-output-ux
status: implemented-local-validation
github-epic: 1075
---

# create-scratch-org.sh: readable, coloured output and progress indicators

## Problem statement

`bin/create-scratch-org.sh` prints long, flat output. Settings appear as a list of more than 40 unaligned lines, phases are not separated, and statuses are hard to see. Only warnings and the final status use colour. Package installation can take many minutes per package without a sign that the script is still working, and there is no position indicator such as "package 3 of 12". The full Salesforce CLI output of every successful package install is printed, which hides the important lines.

Several flows also lack offline tests: package installation retries, `--update-packages` version comparison, `--package-plan`, `--self-check`, `--delete-org-only`, `--help`, and the run summary.

## Desired outcome

A developer can see at a glance which phase is running, how far it has come, and whether each step succeeded, was skipped, or failed. Colour and icons support the text but never replace it, so the output stays readable in CI logs, with `NO_COLOR`, and in terminals without UTF-8. Existing messages that tests and users depend on keep their wording.

## Guiding decisions

- Use a small set of output helpers (section, phase, step, success, warning, failure, key/value, progress) instead of ad hoc `echo` calls.
- Colour precedence is **`--color`/`--no-color` > `NO_COLOR` > `FORCE_COLOR` > terminal detection**, following <https://no-color.org> and the common `FORCE_COLOR` convention.
- Use Unicode icons only when the locale is UTF-8; otherwise use ASCII equivalents.
- Show animated spinners only on an interactive terminal outside CI. Non-interactive output prints one start line and one result line.
- Keep the dry-run `Would run:` lines, error messages, and documented messages unchanged in wording so existing tests and habits keep working.
- Do not change behaviour, defaults, or the commands the script runs.
- PowerShell parity (`bin/create-scratch-org.ps1`) is out of scope.

## Functional requirements

### Output foundation

- **REQ-300:** All status output goes through shared helpers with consistent styling: green check for success, yellow warning sign for warnings, red cross for failures, cyan marker for steps, dimmed text for secondary detail.
- **REQ-301:** Colour is enabled only when stdout is a terminal and `TERM` is not `dumb`. `NO_COLOR` (any non-empty value) disables colour; `FORCE_COLOR` (non-empty, not `0`) enables it in non-terminal output; `--color` and `--no-color` override both.
- **REQ-302:** Icons are Unicode when `LC_ALL`, `LC_CTYPE`, or `LANG` declares UTF-8, otherwise ASCII.
- **REQ-303:** Errors are printed as a single highlighted failure block without the misleading generic "Installation failed." line for non-installation errors.

### Progress

- **REQ-310:** The main run is divided into numbered phases (`[n/N]`) covering only the phases that actually run: scratch org, packages, post-steps, and dependency retrieval.
- **REQ-311:** Package install, update, and plan loops show the position of each package (`[i/N] package-name`).
- **REQ-312:** Selected post-steps show their position (`[i/N] step`); unselected post-steps are listed on one line instead of one line each.
- **REQ-313:** Package installation shows a spinner with elapsed time on an interactive terminal and a start line plus a result line with duration otherwise. Retries show the attempt number.
- **REQ-314:** Salesforce CLI output from a successful package install is hidden unless `--verbose` is given. Output from a failed install is always shown.

### Readable summaries

- **REQ-320:** Settings are grouped (target, scratch org, project and packages, post-steps, pool, install key) with aligned labels, and active modes are listed on one line.
- **REQ-321:** The run summary shows a coloured status, timing, org action, package counts with icons, post-steps, and actions.
- **REQ-322:** Self-check results use the same icons, and the summary table colours the status column without breaking alignment.

### Tests

- **REQ-330:** Offline tests verify that non-terminal output has no ANSI escape sequences, that `FORCE_COLOR` and `--color` enable colour, and that `NO_COLOR` and `--no-color` disable it.
- **REQ-331:** Offline tests verify phase, package, and post-step progress counters.
- **REQ-332:** Offline tests verify package install retries for transient errors, no retry for other errors, and that failed CLI output is shown.
- **REQ-333:** Offline tests cover `--update-packages` (install missing, update lower, skip equal, no downgrade), `--package-plan`, `--self-check`, `--delete-org-only`, `--help`, and the run summary for success and failure.

## Delivery order

| Step | Issue | Title | Requirements |
| ---: | ----- | ----- | ------------ |
| 1 | #1071 | Output foundation: colours, icons and helpers | REQ-300 to REQ-303 |
| 2 | #1072 | Progress indicators for phases, packages and post-steps | REQ-310 to REQ-314 |
| 3 | #1073 | Readable settings, run summary and self-check | REQ-320 to REQ-322 |
| 4 | #1074 | Offline tests for output and untested flows | REQ-330 to REQ-333 |

## Verification strategy

- `bash -n` on the script and the test.
- `bash bin/tests/create-scratch-org.test.sh` with the fake `sf` on `PATH`. No Salesforce org is contacted.
- Manual visual check of a dry run in an interactive terminal (`./bin/create-scratch-org.sh --dry-run`) and with `NO_COLOR=1`.
- Authenticated scratch-org verification is not part of this work and must not be reported as passed.

## Out of scope

- PowerShell and CMD launchers.
- Changing which Salesforce CLI commands run, or their arguments.
- Moving warnings and errors from stdout to stderr.

## Issue mapping

- Epic: #1075
- Delivery issues: #1071, #1072, #1073, #1074

## Implementation status

All delivery issues are implemented on the working branch (not yet committed or merged). Validation run on 2026-10-02:

- New offline tests were written first and failed (26 failing assertions) before the implementation.
- `bash bin/tests/create-scratch-org.test.sh` passes 258 assertions offline (Bash 5.3), including 25 new tests for colour, icons, phases, progress counters, install retries, `--verbose`, `--update-packages`, `--package-plan`, `--self-check`, `--delete-org-only`, `--help`, and the run summary.
- The spinner path was checked under a pseudo-terminal (`script`) with a fake `sf`.
- With macOS `/bin/bash` 3.2, `test_empty_preserve_list_keeps_nothing` fails. The failure already exists in the committed script (empty array under `set -u` in `is_preserved_root_file`) and is outside this specification.

Authenticated verification against a scratch org was not run and is not claimed as passed.
