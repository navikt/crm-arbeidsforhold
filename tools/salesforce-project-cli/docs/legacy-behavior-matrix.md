# Legacy behaviour matrix

This matrix records the migration baseline. The TypeScript CLI does not silently reproduce unsafe or platform-specific behaviour.

| Legacy behaviour                                           | TypeScript command                            | Status              | Deliberate difference                                                               |
| ---------------------------------------------------------- | --------------------------------------------- | ------------------- | ----------------------------------------------------------------------------------- |
| Default delete, create, package install and post-steps     | `sf-project org create`                       | Implemented         | Configuration is explicit and validated before mutation.                            |
| Delete scratch org                                         | `sf-project org delete --alias <alias> --yes` | Implemented         | Destructive confirmation is mandatory outside dry-run.                              |
| Scratch-org pool fetch and fallback                        | `sf-project org create --use-pool`            | Implemented         | Pool and fallback policy are independently configured.                              |
| Install configured package versions                        | `sf-project packages install`                 | Implemented         | Exact selected `04t` and all outcomes are reported.                                 |
| Update missing or older packages                           | `sf-project packages update`                  | Implemented         | Higher versions are never downgraded.                                               |
| Read-only package comparison                               | `sf-project packages plan`                    | Implemented         | Human and NDJSON output share one result model.                                     |
| Clear dependency source folders                            | `sf-project dependencies clear`               | Implemented         | Declared paths, real paths and symlinks are validated.                              |
| Clear and retrieve dependency sources                      | `sf-project dependencies refresh`             | Implemented         | Durable transaction recovery protects `.forceignore`.                               |
| Recover interrupted source refresh                         | `sf-project dependencies recover`             | New safety feature  | Restores only a validated project-owned transaction.                                |
| Deploy, permission sets, data and community                | `sf-project project configure`                | Implemented         | Post-steps are configuration-driven and individually reported.                      |
| Self-check                                                 | `sf-project doctor`                           | Implemented         | Uses stable exit categories and actionable results.                                 |
| Inspect authenticated orgs                                 | `sf-project org list/status/info`             | New capability      | Missing values remain unknown rather than inferred.                                 |
| Interactive terminal summary                               | All operation commands                        | Implemented         | Typed steps, retries, warnings, durations and next actions.                         |
| Machine-readable output                                    | `--json`                                      | Implemented         | NDJSON events and stable exit codes replace text parsing.                           |
| macOS Keychain key lookup                                  | None                                          | Deferred            | Environment-based secret injection is portable; no keychain abstraction is shipped. |
| Windows Batch opens org browser                            | None                                          | Not carried forward | Browser launch is not part of project setup.                                        |
| Batch legacy source-push fallback                          | None                                          | Not carried forward | Deprecated fallback is not hidden behind successful output.                         |
| Batch partial permission/data failures return success      | Typed partial completion                      | Corrected           | Partial completion returns exit code 5.                                             |
| Version updater rewrites `sfdx-project.json` interactively | Package planning only                         | Deferred            | Automated config rewrite needs its own reviewed contract.                           |
| Full shell option forwarding                               | Existing scripts remain                       | Deferred            | Wrapping waits for exact option and environment parity tests.                       |

## Stable exit categories

| Code | Meaning                                 |
| ---: | --------------------------------------- |
|    0 | Success                                 |
|    1 | Operation failure                       |
|    2 | Invalid input or configuration          |
|    3 | Missing prerequisite                    |
|    4 | Authentication or authorization failure |
|    5 | Partial completion requiring attention  |

## Validation boundary

Unit, contract, component and browser tests use fake Salesforce responses. They prove local behaviour but do not prove authenticated Salesforce compatibility. Any real org create, package install, deployment or test run requires an explicitly selected org and human approval.
