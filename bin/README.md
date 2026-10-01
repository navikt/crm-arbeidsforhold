# Scratch-org and utility scripts

Standalone scratch-org setup is available without the Salesforce Project CLI. All three entry points use `sf-project.config.json` beside `sfdx-project.json`:

| Platform           | Entry point                  |
| ------------------ | ---------------------------- |
| macOS/Linux        | `bin/create-scratch-org.sh`  |
| Windows CMD        | `bin/create-scratch-org.bat` |
| Windows PowerShell | `bin/create-scratch-org.ps1` |

The CMD file launches PowerShell and forwards its arguments and exit code. `bin/newScratchOrg.bat` remains as a compatibility name for the CMD launcher. The Windows implementation calls Salesforce CLI (`sf`) directly; it does not use Bash, Node.js, or `sf-project`.

## Requirements

- Salesforce CLI (`sf`) installed and authenticated to an appropriate Dev Hub.
- `jq` for the Bash script only. The PowerShell implementation uses built-in JSON support.
- `sfp` only if scratch-org pool acquisition is enabled.
- Bash for macOS/Linux; PowerShell 5.1 or PowerShell 7+ for Windows.

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

Parameters use PowerShell names such as `-OrgAlias`, `-DurationDays`, `-DefinitionFile`, `-PostSteps`, `-UsePool`, `-PackagePlan`, and `-RefreshDependencySources`. `-DryRun` plans mutations without running them. The old positional installation-key argument is no longer supported. Supply package keys through the environment variable named by `packageInstallKeyEnvironmentVariable`; never put a key in the config file or command history.

## macOS/Linux

```bash
./bin/create-scratch-org.sh --help
./bin/create-scratch-org.sh --self-check
./bin/create-scratch-org.sh --dry-run
./bin/create-scratch-org.sh
./bin/create-scratch-org.sh --post-steps-only --post-steps data
```

The Bash script supports org create/delete, pool acquisition, package install/update/plan, post-steps, dummy users, dry-run, self-check, dependency cleanup/retrieval, and `--init-config`. See `create-scratch-org.sh --help` for options.

## Shared config

Settings are resolved in this order: command-line option, environment variable, `sf-project.config.json`, generic default. `--init-config` in Bash and `-InitConfig` in PowerShell create a config preview with dry-run; overwriting an existing config requires `--force` or `-Force`. Unmanaged settings are preserved.

`dummyUsers.profileName` is the fallback profile. Optional `dummyUsers.profileAssignments` maps groups of usernames to other profile names. Profiles must already exist in the target org. Existing users are not modified; profile mappings apply when the script creates new users. See [sf-project configuration](../tools/salesforce-project-cli/docs/configuration.md) for the shared schema and [the script specification](../.github/specs/create-scratch-org-script-config.md) for parity details.

## Offline tests

Bash tests use a fake `sf` and temporary project directories:

```bash
bash bin/tests/create-scratch-org.test.sh
```

On Windows, run the PowerShell dry-run/config harness:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\bin\tests\create-scratch-org.Tests.ps1
```

Neither harness contacts Salesforce.

## Scratch-org pool

Pool commands require `sfp` and an authorized Dev Hub. To inspect a pool or orgs manually:

```text
sfp pool list --tag <tag> --targetdevhubusername <devhub>
sf org list
sf org open --target-org <alias>
```

## Other utilities

- `check-sfdx-versions.js` compares package versions and can update `sfdx-project.json` after confirmation; it saves a backup first.
- `post-package-coverage-check.ps1` runs the separate post-package Apex coverage workflow.
- `tests/p360-mock-smoke.sh` is run by the root `npm run test:p360:mock` script.

The unused legacy `install-scratch.sh`, `get-latest-released-packages-posix.sh`, `resolve_packages.ps1`, and `check-version.js` have been removed. The old Windows file `newScratchOrg.bat` is only a launcher now.
