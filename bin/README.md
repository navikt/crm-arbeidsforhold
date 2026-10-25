# Scratch-org and utility scripts

## Generic Community Plus test user

The `altinn-scenario-users` post-step now seeds or migrates one
**Synthetic Community Test User**, not one user per scenario. It preserves the
former Permit user's identity/history, deactivates legacy scenario users,
deletes settings belonging to the four exact inactive legacy seed users, and
restores the generic user's setting to S01/subject-a.
Historical users, contacts and accounts are retained; unrelated settings are
not changed. The scenario setting type and its three fields remain necessary
for switching scenarios.
It changes data; do not run it during an ongoing scenario test.

For the approved `nav-community-dev` scratch org, see the
[standalone Altinn GUI/CLI test guide](../docs/integrations/altinn/test-guide.md).
The read-only `bin/verify-altinn-test-user.apex` script checks the resulting
user, license, permission assignments and explicit scenario setting.

## Documentation map

- [Complete command reference](COMMANDS.md): every entry point and custom flag,
  examples, environment/configuration reference, side effects, legacy warnings
  and a complete inventory of the bin test/support files.
- [Cross-script and operating-system matrices](COMPATIBILITY.md): what is shared,
  where the engines differ, and what actual tests do and do not establish.
- [Supporting scripts](../scripts/README.md): hooks, staged formatting, P360 smoke
  checks, Apex helpers and their tests.

This README is the starting guide; the reference pages hold exhaustive details.

## Choose a workflow

| Task                                                           | Where to start                                                                                                          |
| -------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------- |
| First setup, prerequisites or Windows migration                | Requirements and first-run checklist below                                                                              |
| Read dependencies without creating an org                      | [Complete package dependency preflight](#complete-package-dependency-preflight)                                         |
| Understand PASS/FAIL, prompts and automatic fixes              | [Scenario examples](#scenario-examples) and [apply behavior](#apply-fixes-without-starting-setup)                       |
| Full setup, pool, package update, deployment, data or coverage | [Command examples](COMMANDS.md#4-eksempelbibliotek)                                                                     |
| Custom project/config, flags and environment variables         | [Complete reference](COMMANDS.md)                                                                                       |
| Reports, no-colour output, backups or failed checks            | [Preflight guide](#complete-package-dependency-preflight) and [troubleshooting](COMMANDS.md#9-feilsøking-og-exitstatus) |
| Offline tests and supported platforms                          | [Offline tests](#offline-tests) and [compatibility](COMPATIBILITY.md)                                                   |
| Hooks, CI filtering, formatting or P360 smoke checks           | [Supporting scripts](../scripts/README.md)                                                                              |
| Optional `sf-project` CLI                                      | [Separate CLI documentation](../tools/salesforce-project-cli/README.md)                                                 |

Standalone scratch-org setup is available without the Salesforce Project CLI. All three entry points use `sf-project.config.json` beside `sfdx-project.json`:

| Platform           | Entry point                  |
| ------------------ | ---------------------------- |
| macOS/Linux        | `bin/create-scratch-org.sh`  |
| Windows CMD        | `bin/create-scratch-org.bat` |
| Windows PowerShell | `bin/create-scratch-org.ps1` |

The CMD file launches PowerShell and forwards its arguments and exit code.
The old `newScratchOrg.bat` file is not present in this checkout; use the entry
points above. The Windows engine calls Salesforce CLI (`sf`) directly and does
not use Bash or `sf-project`, but normal installation/update now requires Node.js
for the shared dependency preflight. PowerShell 7 can also run the `.ps1` engine
directly on macOS; npm still selects Bash on macOS/Linux.

## Requirements

- Salesforce CLI (`sf`) installed and authenticated to an appropriate Dev Hub.
- `jq` for the Bash script only. The PowerShell implementation uses built-in JSON support.
- `sfp` only if scratch-org pool acquisition is enabled.
- Node.js 22+ for the shared dependency preflight, including direct Bash/PowerShell setup.
- Bash for macOS/Linux; PowerShell 7 LTS for Windows. The local PowerShell test baseline is 7.6 LTS.

For a full root npm development installation, use a Node version satisfying all
devDependency engine requirements: `lint-staged` 17.6.0 requires >=22.22.1.
The helper's Node 22+ requirement alone does not guarantee a supported npm install.

### First-run checklist

1. Install the required runtime and Salesforce tools. Run from the repository root.
2. Have the intended packaging Dev Hub and scratch-org actions approved. Authentication
   does not itself grant permission to use another org. If login is needed, use your
   approved interactive authentication flow; do not put tokens or auth URLs in commands.
3. Review `sfdx-project.json` and `sf-project.config.json`. This repository enables
   pool use and multiple post-steps; generic script defaults are different.
4. Arrange the installation key through the configured environment variable or the
   Bash macOS Keychain lookup. Never pass a real key in a command, config or commit.
5. Read the effective help/settings, check dependencies, then run approved setup.

```bash
npm run scratch-org -- --help
npm run scratch-org -- --check-dependencies
npm run scratch-org -- --dry-run
npm run scratch-org
```

On Windows CMD, replace the Bash options with `-Help`, `-CheckDependencies` and
`-DryRun`. In Windows PowerShell, quote npm's separator, for example
`npm run scratch-org '--' -CheckDependencies`. To choose the PowerShell engine
on macOS, run `pwsh -File ./bin/create-scratch-org.ps1 -CheckDependencies`
directly; npm on macOS still selects Bash.

Only help is offline in this sequence. Check and dry-run can contact Salesforce;
normal setup can replace an org, install packages and execute post-steps.
`sf-project` is not needed. Root devDependencies are needed for Jest, formatting
and the full npm test suite, not for the dependency helper's core graph logic.

### Migrating from Windows PowerShell 5.1

Install PowerShell 7 LTS through your approved software channel, open a new terminal,
and check `pwsh -NoLogo -NoProfile -Command '$PSVersionTable'`. PowerShell 7 is
installed alongside Windows PowerShell; it does not require removing the Windows component.
CMD and npm now select `pwsh.exe` only. They fail with installation guidance if it
is missing rather than falling back to `powershell.exe`. Direct invocation from
Windows PowerShell 5.1 is rejected before configuration or org access.

Use a PowerShell 7 terminal for direct `.ps1` commands, or explicitly start
`pwsh -NoProfile -File .\bin\create-scratch-org.ps1 -Help`.
Do not bypass execution policy, AppLocker/WDAC, or other managed-machine restrictions
to run the scripts; resolve installation and policy requirements through the approved channel.

## Windows

Run these in CMD:

```cmd
bin\create-scratch-org.bat -Help
bin\create-scratch-org.bat -DryRun
bin\create-scratch-org.bat
bin\create-scratch-org.bat -PostStepsOnly -PostSteps data
```

Or run PowerShell directly:

```powershell
.\bin\create-scratch-org.ps1 -Help
.\bin\create-scratch-org.ps1 -DryRun
.\bin\create-scratch-org.ps1 -PostStepsOnly -PostSteps data
.\bin\create-scratch-org.ps1 -UpdatePackages -InstallLatest
```

When using npm from PowerShell, quote the separator: `npm run scratch-org '--' -Help`.
PowerShell removes an unquoted `--` before `npm.ps1` receives it, so npm consumes the flags.

From the repository root, npm selects the platform-specific script:

```powershell
npm run scratch-org '--' -Help
npm run scratch-org '--' -DryRun
```

The npm launcher accepts `--help`, `--Help`, `-Help`, and `-h` on every platform.
For other options, use PowerShell parameter names on Windows; on macOS/Linux, use the Bash options shown below.

Parameters use PowerShell names such as `-OrgAlias`, `-DurationDays`, `-DefinitionFile`, `-PostSteps`, `-UsePool`, `-PackagePlan`, and `-RefreshDependencySources`. `-DryRun` plans mutations without running them. The old positional installation-key argument is no longer supported. Supply package keys through the environment variable named by `packageInstallKeyEnvironmentVariable`; never put a key in the config file or command history.

Dry-run is not an offline test: package-version resolution and pool status can still
contact Salesforce. Org/environment access requires the normal target/action approval.

## macOS/Linux

```bash
./bin/create-scratch-org.sh --help
./bin/create-scratch-org.sh --self-check
./bin/create-scratch-org.sh --dry-run
./bin/create-scratch-org.sh
./bin/create-scratch-org.sh --post-steps-only --post-steps data
./bin/create-scratch-org.sh --redeploy
npm run scratch-org -- --help
npm run scratch-org -- --dry-run
```

### Complete package dependency preflight

Both scripts now check the complete version-specific dependency graph before the
normal package install/update flow starts, **before scratch-org deletion, pool
fetch, creation or dependency-folder cleanup**. The shared implementation is
`bin/package-dependencies.js`; it requires Node.js even when invoking Bash or
PowerShell directly.

Run only the check, without setting up an org:

```bash
bash bin/create-scratch-org.sh --check-dependencies
```

```powershell
pwsh -NoLogo -NoProfile -File ./bin/create-scratch-org.ps1 -CheckDependencies
```

The check reads `sf package version list --released`, then
`sf package version report --verbose --json` recursively for the selected
subscriber versions. It uses the packaging Dev Hub configured in Salesforce CLI
or `SF_TARGET_DEV_HUB`; the pool Dev Hub is not implicitly substituted for it.
To specify the approved packaging Dev Hub for a standalone check explicitly:

```bash
node bin/package-dependencies.js --dev-hub '<approved-dev-hub-alias>'
```

These are authenticated, read-only Salesforce commands, not offline tests.
Confirm the exact target and action before agent execution. All dependencies
must be visible to that Dev Hub; missing authorization or unreadable metadata
fails the check rather than claiming completeness. Nothing is inferred from
local reference-package folders. Managed or external packages whose version
metadata is unavailable cannot be certified by this check.

The checker treats dependency versions as **minimum requirements**, comparing
major, minor, patch and build numerically. It checks each package directory and
the dependencies of the version actually selected for installation.

| Condition                                                              | Check result          | Normal interactive setup                                        |
| ---------------------------------------------------------------------- | --------------------- | --------------------------------------------------------------- |
| Selected equals required                                               | PASS                  | Continue automatically                                          |
| Selected is higher                                                     | PASS: HIGHER VERSION  | Show an informational review notice; continue without prompting |
| Selected is lower                                                      | FAIL: VERSION TOO LOW | Explain the requirement, impact and fix; ask what to do         |
| Dependency is not declared                                             | FAIL: MISSING         | Explain which package requires it; ask what to do               |
| Dependencies are in the wrong order                                    | ACTION REQUIRED       | Show current and required order; ask what to do                 |
| Metadata cannot be read, a cycle is found, or declarations are invalid | FAILED                | Stop; do not offer an unchecked installation plan               |

For example, selected `0.1.49.3` satisfies required `0.1.33.1`, and build
`1.0.0.10` satisfies `1.0.0.2`. Higher selections are never downgraded merely
to match an older requirement. Passing is a manifest-policy result, not proof
of Salesforce upgrade lineage, installability, permissions or runtime compatibility.

#### Choose a fix or stop

Only **actual issues** trigger a question during interactive installation or
update. Higher-version review notices do not. Immediately above the question,
the terminal repeats the package, directory, required minimum, selected version,
requiring package, impact and proposed fix, or the current and required order.
These details appear after the graph so they are visible when deciding.

```text
[c] Continue unchanged | [f] Apply safe fixes and continue | [s] Stop (default):
```

- `c` explicitly accepts the unresolved issues, keeps the manifest unchanged
  and lets setup continue. Installation can still fail; this is not a passing check.
- `f` upgrades low selections, adds missing declarations and fixes installation
  order. The proposed complete graph must pass before the manifest is written.
  Setup then continues with the validated version IDs.
- `s`, Enter, or closed input stops setup without manifest changes or org setup.
  No answer is treated as approval. Metadata-read failures stop before this menu.

Unattended runs do not ask questions: passing checks continue, actual issues fail
unless autofix was explicitly requested. `--dry-run` / `-DryRun` never asks for
an apply decision and never changes the manifest, although metadata reads and
local report writes still occur. `--skip-version-check` / `-SkipVersionCheck`
only disables newer-release warnings; it does not bypass dependency preflight.

#### Apply fixes without starting setup

Review the findings and request autofix explicitly:

```bash
bash bin/create-scratch-org.sh --apply-dependencies
```

```powershell
pwsh -NoLogo -NoProfile -File ./bin/create-scratch-org.ps1 -ApplyDependencies
```

These standalone wrapper modes fix the manifest, then exit **without starting
org setup**. In contrast, choosing `f` during normal setup fixes and continues
within that run. The shared helper can also be used directly:

```bash
node bin/package-dependencies.js --apply --report dependency-review.md
```

Autofix uses version IDs found in actual dependency metadata, not invented
versions or an unconditional latest-release upgrade. If several packages require
different minimums, it selects the highest required version, rechecks that
version's dependencies, and repeats as needed. Already-higher selections stay
unchanged. New dependencies are added and put before their dependants. Metadata
is cached within the process; each new run still reads current Salesforce metadata.

The complete proposed graph must pass before any manifest write. Unreadable
metadata, cycles, unresolved issues or lack of progress stop autofix without a
partially updated manifest. Other project fields are preserved. Before writing,
the checker verifies that the manifest has not changed since it was read.

The exact original bytes are saved as `sfdx-project.json.dependencies.backup`
(or `<custom-project-file>.dependencies.backup`). An existing backup is never
overwritten: preserve or move it after reviewing its contents, then rerun.
The new manifest is written through a temporary file. Review its Git diff after
autofix. Do not restore an old backup blindly over subsequent manual changes.
Applying and dry-run cannot be combined. An actual Salesforce installation can
still fail after local manifest validation; autofix does not roll back org changes.

During normal setup the successfully checked root versions are held in a
temporary plan and used for installation; symbolic `LATEST` is not resolved
again after preflight. Dry-run still performs metadata reads but never applies
manifest changes. Post-steps-only/deploy-only and standalone coverage workflows
are not manifest package installation and do not invoke this preflight.

Offline verification: `node --test bin/tests/package-dependencies.test.js`
tests the graph/provider contract, minimum-version comparison, recursive upgrades,
no-downgrade behavior, safe failure, prompts, reports and colour output. The Bash
and PowerShell harnesses use fake CLI responses. Passing local tests does not
establish actual Salesforce installation success or native Windows compatibility.

The checker prints the active package as `[current/total]`, its selected version,
and each metadata read as it starts and finishes. A slow read prints a
`Still running:` heartbeat every five seconds with elapsed time. This output is
streamed immediately through both wrappers, including PowerShell; it is not
buffered until the check ends. The counter covers declared packages, not an
estimated percentage: recursively discovered metadata can add work.

The result groups version differences by dependency and directory, showing the
selected version once and each required version with the packages requiring it.
The **What is missing?** section counts missing package declarations separately
from version differences and installation-order problems, including an explicit
message when no missing declarations were found in the inspected graph.
Missing dependencies are listed first with exact versions and requiring packages,
followed by version differences, installation-order problems and numbered next
steps.

An ASCII **Dependency graph** shows parent-to-dependency relationships with
colour-independent labels: `[PASS]`, `[PASS: HIGHER VERSION]`, `[FAIL: MISSING]`
and `[FAIL: VERSION TOO LOW]`. Non-exact entries put the required minimum and
selected version on a separate line. Higher-version notices remain informational.
When terminal colour is enabled, passes use green, notices/warnings use **bold
magenta rather than yellow**, and failures use red. Required/selected details
use the terminal's default text colour. The labels remain complete with
`--no-color`, `-NoColor` or `NO_COLOR=1`.
Vertical continuation lines and spacing separate top-level packages without
hiding any dependency edges. Shared subtrees expand once and subsequent references
say `(shared subtree)`; repeated leaves have no redundant reference annotation.
Below-minimum requirement branches are not expanded; the selected versions are
checked instead. A zero missing count does not mean the graph passed when lower
versions or order issues remain. The graph describes manifest requirements, not
packages installed in a scratch org. Markdown/HTML retain their own status labels
and graph colours; the terminal palette does not change the HTML palette.

Every completed check also writes `package-dependencies-report.md` beside the
project file, including checks that return a nonzero exit code because they
found problems. This generated default filename is ignored by Git and replaces
the previous report. The report contains a timestamp, summary, missing
declarations, all version-difference requirements and IDs, installation-order
findings, version inventories and a coloured Mermaid flowchart per package
directory. Shared nodes retain every incoming edge. Mermaid-capable Markdown
viewers (including GitHub) render the graph; other viewers show its source.
No Mermaid renderer, SVG tooling or extra npm dependency is required.

The full **Dependency graph** is retained. A supplementary **Dependency graphs
per package** section shows a smaller Mermaid diagram for each declared
top-level package and its direct requirements. These are deliberately one-hop
views for readability; the full graph still contains the inspected transitive
connections and version inventory.

The checker also writes a companion `package-dependencies-report.html` and
links it from Markdown. Open the HTML file locally in a browser for interactive
SVG graphs:

- Hover or focus a node to highlight its direct connections and dim unrelated
  nodes/arrows. The side panel lists the connected packages with exact versions.
- Solid blue arrows show **requires** (outgoing); dashed orange arrows show
  **required by** (incoming). Arrowheads preserve direction.
- Click a node, press Enter/Space or choose it in the node selector to lock the
  selection. Click again, use **Clear selection** or press Escape to unlock.
- Use zoom buttons or scroll to zoom; drag the graph background to pan. Focus
  the graph itself and use arrow keys for keyboard panning. **Fit graph** resets
  the view.

The HTML is self-contained and offline: no CDN, server, analytics or external
requests. It uses native SVG rather than embedding a Mermaid runtime, includes
text statuses in addition to colour, and works with keyboard focus. Its content
security policy disables network resources and permits only the generated
script. With JavaScript disabled, the static SVG and Markdown remain available.
The default HTML filename is ignored by Git, like the Markdown file.

Interactive DOM behaviour is covered by `npm run test:dependency-report`, using
the repository's existing Jest/jsdom tooling after installing its development
dependencies. This tests direction tracing, hover/focus, pinning, keyboard
controls, zoom, independent directories and inert untrusted labels. It does not
substitute for checking SVG layout and pointer gestures in a real browser.
The dependency-free `npm run test:node` checks report output and graph edges.

Choose another report path with the helper's `--report <file.md>`, Bash's
`--dependency-report <file.md>` or PowerShell's `-DependencyReport <file.md>`.
The companion HTML uses the same basename (for example, `dependency-review.html`).
Custom paths resolve from the working directory and must have an existing parent
directory. Either report write failure stops the check before setup continues. A metadata
read failure does not replace the previous report: check its timestamp, and do
not mistake an old report for the failed run. The report covers the inspected
graph only; below-minimum requirement descendants are not expanded. Reports from an
apply run describe the findings **before** manifest repair; rerun to refresh.
Dry-run writes both reports but still never applies manifest changes.

#### Scenario examples

These shortened excerpts omit progress, IDs and report paths. They illustrate
terminal behavior; package names and versions are examples, not installation instructions.

**Exact version: no decision required**

```text
Result: PASSED
+-- crm-shared-flowComponents 0.4.0.3 [PASS]
Dependency preflight PASSED: complete, minimum-version, dependency-first manifest.
```

**Higher version: visible notice, automatic continuation**

```text
+-- platform-data-model [PASS: HIGHER VERSION]
|   Required: >= 0.1.33.1; selected: 0.1.49.3
Higher selected versions are informational only; no decision is required.
```

**Missing declaration: fix, explicitly accept the risk, or stop**

```text
ISSUE: Missing dependency declaration
Package: child (force-app)
Required minimum: 1.0.0.1; selected: NOT DECLARED
Required by: parent 1.0.0.1
Impact: setup will not install a dependency required by this package.
Fix: add the missing dependency to the manifest.
[c] Continue unchanged | [f] Apply safe fixes and continue | [s] Stop (default):
```

**Lower version: autofix upgrades it after approval**

```text
ISSUE: Selected version is too low
Package: child (force-app)
Required minimum: 2.0.0.1; selected: 1.0.0.1
Required by: parent 1.0.0.1
Impact: the selected version does not meet this requirement; installation may fail.
Fix: upgrade the selected version to meet all required minimums.
[c] Continue unchanged | [f] Apply safe fixes and continue | [s] Stop (default): f
Upgrade: child 1.0.0.1 -> 2.0.0.1
Autofix validation PASSED: upgraded versions, dependencies and installation order checked.
```

If another requiring package needs `3.0.0.1`, autofix chooses at least that
version and validates any newly introduced dependencies. If a selected version
was already `4.0.0.1`, no downgrade to `2.0.0.1` or `3.0.0.1` is proposed.

**Incorrect order: show the exact correction**

```text
ISSUE: Incorrect installation order (force-app)
Current order: parent -> child
Required order: child -> parent
Impact: a package may be installed before a dependency it needs.
Fix: reorder the manifest so dependencies are installed first.
```

**Metadata unavailable or autofix cannot validate**

```text
Dependency preflight FAILED:
  Missing dependency metadata; completeness cannot be verified.
```

Stop and resolve access, metadata or the reported graph issue. Do not use
`Continue unchanged` to bypass a failed metadata read: that choice is not offered.
The manifest is not partially written. Reports from an earlier completed check
can still exist; inspect their timestamp before using them.

**Existing backup or manifest changed during the check**

The checker refuses to overwrite the backup or a concurrently edited manifest.
Preserve the backup, review the current diff and rerun against the current file.
Do not delete backups automatically or assume an earlier installation plan is current.

**Stop, redirected input, and no colour**

With actual issues, `s`, Enter or EOF stops interactive setup. With only higher
versions, setup does not ask even in an interactive terminal. With redirected
input, issues fail instead of waiting for an answer; standalone `--apply` remains
an explicit opt-in. Capturing stdout alone does not disable questions: terminal
detection uses stdin, and `CI=true` is not a universal noninteractive override.
Close/redirect stdin in automated callers. The following command changes only
output presentation:

```bash
bash bin/create-scratch-org.sh --check-dependencies --no-color
```

```bash
node bin/package-dependencies.js --dev-hub '<approved-dev-hub-alias>' --report dependency-review.md
```

Preflight terminal output uses cyan headings/progress, green success, **bold
magenta** higher-version notices/warnings and red failures. Status labels remain readable without
colour. The helper supports `--color` / `--no-color`, `NO_COLOR` and `FORCE_COLOR`;
explicit flags take precedence, then `NO_COLOR`, then `FORCE_COLOR`, then terminal
detection. Both wrappers forward their effective colour setting (PowerShell:
`-Color` / `-NoColor`). Redirected logs are plain by default. Text is wrapped at
100 visible columns before colouring, without spinner frames.
Equal or higher versions pass without a decision. Lower versions can be upgraded
by explicitly selected autofix; no downgrade is performed. See the scenarios above.

## Setup output and package maintenance

The `deploy` post-step only sends changes that source tracking has recorded, and tracking is reset after the post-steps. If the org is missing metadata but a deploy reports "No changes to deploy", run `--redeploy` (Windows: `-Redeploy`). It deletes local source tracking for the org and deploys all local source; org data is untouched. `--full-deploy` / `-FullDeploy` adds the same behaviour to any run that includes the deploy step.

The Bash script supports org create/delete, pool acquisition, package install/update/plan, post-steps, dummy users, dry-run, self-check, dependency cleanup/retrieval, and `--init-config`. See `create-scratch-org.sh --help` for options.

Output is grouped into numbered phases (`[1/3] Scratch org`, `[2/3] Packages`, `[3/3] Post-steps`) with `[i/N]` counters per package and post-step. Package installs show a spinner with elapsed time in an interactive terminal; Salesforce CLI output from a successful install is hidden unless you pass `--verbose`, and is always shown when an install fails. Colour is used only in a terminal: `NO_COLOR=1` or `--no-color` turns it off, and `FORCE_COLOR=1` or `--color` turns it on for CI logs. Icons fall back to ASCII when the locale is not UTF-8. See [the output specification](../.github/specs/create-scratch-org-output-ux.md).

PowerShell uses the same output structure: grouped settings, numbered active phases,
package/post-step counters, operation start/result lines and a final run summary on
success or failure. Long CLI commands (including org creation, pool acquisition,
package resolution/installation and deployment) show a spinner with elapsed seconds
in an interactive terminal. Redirected output and CI instead get plain start/result
lines plus a `Still running:` heartbeat every five seconds while waiting. This is
elapsed-time feedback, not a fabricated percentage of Salesforce work completed.

PowerShell captures CLI output for internal JSON parsing; it does not stream raw CLI
JSON into the progress display. Successful CLI details are hidden by default and
available with `-Verbose`. Failure details are always shown, with the configured
installation key redacted. `-Color` / `-NoColor` override `NO_COLOR`, then `FORCE_COLOR`,
then terminal detection. CI never animates the output. These flags work through
CMD and npm as well:

```powershell
.\bin\create-scratch-org.ps1 -PostStepsOnly -Verbose -NoColor
```

The summary distinguishes installed/updated/current/higher-version/planned packages,
completed/skipped post-steps, and warnings. Dry-run labels mutations as planned;
it never reports them as actually installed or deployed. A failed operation stays
failed and shows its label and elapsed duration; no later steps are claimed as run.
Output changes do not change Salesforce CLI arguments, org targets or deployment scope.

Package-version maintenance is preview-only unless explicitly applied. Coverage uses the target project config unless flags override it:

```bash
./bin/create-scratch-org.sh --check-versions
./bin/create-scratch-org.sh --apply-project-versions
./bin/create-scratch-org.sh --coverage-check --alias crm-arbeidsforhold --coverage-skip-install --coverage-skip-deploy
```

Windows offers matching `-CheckVersions`, `-ApplyProjectVersions`, and `-CoverageCheck` PowerShell parameters. `sf-project` provides `packages check-versions [--apply]` and `coverage check`; its coverage mutations are scratch-only by default. The scripts run Salesforce CLI directly and do not depend on `sf-project`.

### Recover from a failed or interrupted setup

The dependency decision menu is not a general repair system for every later
Salesforce failure. Autofix changes manifest versions, declarations and order;
it does not repair authentication, missing metadata access, package keys, org
permissions, Salesforce installation errors or failing application tests.

| Failure or interruption                                                                                | What to do before retrying                                                                                                        |
| ------------------------------------------------------------------------------------------------------ | --------------------------------------------------------------------------------------------------------------------------------- |
| Missing authentication or metadata access                                                              | Resolve access to the approved target; do not silently switch Dev Hubs or orgs                                                    |
| Invalid/duplicate declarations, inconsistent selections across directories, alias collisions or cycles | Correct the reported manifest/graph problem; do not guess a package identity or skip unreadable metadata                          |
| Autofix validation fails                                                                               | The proposed manifest is not written; resolve the metadata/graph cause and rerun the check                                        |
| Package installation fails after preflight                                                             | Inspect the failed package and actual installed state; a passing graph does not guarantee installation                            |
| Deploy fails or reports no changes unexpectedly                                                        | Review the deployment result and tracking; use an approved redeploy only when appropriate                                         |
| Data import, community publish or custom step fails                                                    | Review what already ran before repeating it; there is no generic data rollback or idempotency guarantee                           |
| Ctrl+C during setup                                                                                    | Inspect the last completed operation and org state; interruption does not undo earlier installations, deployments or data changes |
| Existing backup or concurrently edited manifest                                                        | Preserve the backup/current diff and rerun against the current file; do not overwrite either automatically                        |

Known transient **installation** failures have bounded retry controlled by
`PACKAGE_INSTALL_MAX_ATTEMPTS` and `PACKAGE_INSTALL_RETRY_DELAY_SECONDS`.
This is not a retry policy for every metadata-read, deployment or validation
failure. Do not wrap full setup in an unconditional retry loop: full setup can
delete/replace the org, and post-steps may already have changed data.

After reviewing the current state and obtaining approval for the remaining
actions, choose an existing-org workflow rather than blindly repeating creation:

```bash
bash bin/create-scratch-org.sh --alias crm-arbeidsforhold --update-packages
bash bin/create-scratch-org.sh --alias crm-arbeidsforhold --post-steps-only --post-steps deploy
```

PowerShell equivalents are `-OrgAlias crm-arbeidsforhold -UpdatePackages` and
`-OrgAlias crm-arbeidsforhold -PostStepsOnly -PostSteps deploy`. They still
perform the named org actions and require the normal approval. For all modes,
read nonzero exits and operation details rather than treating an old report,
heartbeat, planned step or isolated success line as evidence that setup finished.

## Shared config

Settings are resolved in this order: command-line option, environment variable, `sf-project.config.json`, generic default. `--init-config` in Bash and `-InitConfig` in PowerShell create a config preview with dry-run; overwriting an existing config requires `--force` or `-Force`. Unmanaged settings are preserved.

`dummyUsers.profileName` is the fallback profile. Optional `dummyUsers.profileAssignments` maps groups of usernames to other profile names. Profiles must already exist in the target org. Existing users are not modified; profile mappings apply when the script creates new users. See [sf-project configuration](../tools/salesforce-project-cli/docs/configuration.md) for the shared schema and [the script specification](../.github/specs/create-scratch-org-script-config.md) for parity details.

Coverage defaults are in `coverage.minimumPercent`, `coverage.testClass`, and `coverage.classNamePattern`. A `null` test class runs all tests; `%` selects all Apex classes in the aggregate query. The standalone scripts expose `--coverage-check` / `-CoverageCheck`; `sf-project` exposes `coverage check`.

## Offline tests

Bash tests use a fake `sf` and temporary project directories:

```bash
bash bin/tests/create-scratch-org.test.sh
node --test bin/tests/create-scratch-org-launcher.test.js
```

The portable PowerShell harness runs on macOS and Windows:

```powershell
pwsh -NoLogo -NoProfile -File ./bin/tests/create-scratch-org.Tests.ps1
npm run test:scratch-org:powershell
```

It starts the real script against temporary projects with spaces and Unicode in the
path. A restricted subprocess PATH contains fake `sf`/`sfp` programs that record
arguments and exit codes, reject unexpected calls, and cannot fall back to an
authenticated CLI. Synthetic fixtures exercise configuration, pool acquisition,
packages, post-steps, JSON/error handling and install-key redaction. Test projects
and journals are removed on exit. Windows uses `.cmd` fakes; macOS uses executable
shell wrappers. Neither harness contacts Salesforce.

CMD/npm process execution and missing-runtime tests run only on Windows. On Mac
they are explicitly reported as skipped, not passed. Simulating version 5.1 in a
child process tests the runtime guard only; it is not an actual Windows PowerShell test.
Windows CI is tracked by [#1148](https://github.com/navikt/crm-arbeidsforhold/issues/1148).
The approved [offline workflow](../.github/workflows/scratch-org-offline.yml)
uses Windows 2025 and checksum-pinned PowerShell 7.6.6 LTS. It runs
`pwsh -NoLogo -NoProfile -File bin/tests/create-scratch-org.Tests.ps1 -RequireWindows`,
which rejects non-Windows hosts or skipped mandatory Windows groups. Actions are
pinned to immutable commits, repository permissions are read-only, checkout
credentials are not persisted, and no Salesforce secrets are supplied.
Node regression runs on Windows and Ubuntu; Ubuntu also runs the Bash harness.
The jobs record the checkout revision, OS and tool versions. Missing tools fail
the job rather than skipping coverage.

Windows fixes are ported from the failing-then-green real runner results in
[navikt/crm-platform-integration#475](https://github.com/navikt/crm-platform-integration/pull/475):
explicit standard native argument passing preserves empty/quoted arguments,
the harness uses CMD-specific launch quoting, and output tests distinguish CRLF
line endings from terminal animation. This repository's own
[run 40043090089](https://github.com/navikt/crm-arbeidsforhold/actions/runs/40043090089)
passed at SHA `1979ef2c15529652cdd26cdff8ccd80f8155935b` with 210 Windows
PowerShell assertions and no skipped Windows groups. Later local output/report
changes are not covered by that historical run. See the
[verification matrix](COMPATIBILITY.md#5-verifikasjonsmatrise-og-vedlikehald)
for the exact evidence and limitations.

Mac results do not establish Windows support, and even green Windows offline tests
do not verify real Salesforce CLI, `sfp`, authentication, pool contents or deployment.

### PowerShell tests on Mac

On Apple Silicon, install the current supported PowerShell 7 LTS **macOS ARM64**
package from [Microsoft's installation guide](https://learn.microsoft.com/en-us/powershell/scripting/install/install-powershell-on-macos)
through your approved software channel. Choose the signed/notarized `.pkg`, not
Preview or the x64 build. Use the x64 package on an Intel Mac.

Open a new terminal after installation and check:

```bash
command -v pwsh
pwsh -NoLogo -NoProfile -Command '$PSVersionTable'
pwsh -NoLogo -NoProfile -File ./bin/tests/create-scratch-org.Tests.ps1
```

No Docker, Windows licence, VM, separate .NET SDK, Salesforce CLI, `sfp`, `jq`,
Salesforce login or package key is needed for this PowerShell harness.
Node is required even for direct Mac PowerShell tests because the harness
exercises the shared dependency preflight. npm is required for the npm convenience
command and Windows npm-launcher scenarios. Installation may require approval on a managed
machine; do not disable Gatekeeper, execution policy or sandbox restrictions.
The harness uses `$TMPDIR` when set and otherwise the OS temporary directory.

## Scratch-org pool

Pool commands require `sfp` and an authorized Dev Hub. To inspect a pool or orgs manually:

```text
sfp pool list --tag <tag> --targetdevhubusername <devhub>
sf org list
sf org open --target-org <alias>
```

## Other utilities

- `check-sfdx-versions.js` and `post-package-coverage-check.ps1` are legacy
  standalone utilities, not the preferred workflow. Their limitations, including
  incomplete success reporting and coverage fallback semantics, are documented in the
  [legacy reference](COMMANDS.md#6-legacy-og-interne-modular). Do not use them as
  equivalent validation gates.
- `../scripts/p360-mock-smoke.sh` is run by the root `npm run test:p360:mock`.
  It contacts an org and can create data; see [scripts documentation](../scripts/README.md).

The unused legacy `install-scratch.sh`, `get-latest-released-packages-posix.sh`,
`resolve_packages.ps1`, `check-version.js`, and `newScratchOrg.bat` are not
present. Do not copy old commands that refer to them.
