---
slug: salesforce-project-cli-portability
status: proposed
github-epic: 1040
---

# Salesforce project CLI: portability and configurability

## Problem statement

`sf-project` (`tools/salesforce-project-cli/`) was built as a cross-platform replacement for `bin/create-scratch-org.sh` and its Batch/PowerShell equivalents, with an explicit long-term goal of extraction into its own, independently reusable package (see [ADR-0001](../../tools/salesforce-project-cli/docs/adr/0001-cli-first-shared-application-core.md) and the [packaging and extraction guide](../../tools/salesforce-project-cli/docs/packaging-and-extraction.md)).

Two concrete gaps were found while extending `bin/create-scratch-org.sh` on 2026-09-18 to add a `--post-steps-only` shortcut (run selected post-steps against an already-created org, skipping org create/delete and package installation):

1. **No post-steps-only capability in `sf-project`.** `project configure` always installs configured packages before running post-steps, and `org create` always attempts org acquisition first. There is no `sf-project` command that runs only post-steps against an already-set-up target org — the most common inner-loop operation once a project's org and packages already exist.
2. **Dependency source folders are mandatory for every project.** `docs/configuration.md` documents, as current behavior, that "a dependency without a matching source directory fails configuration loading." Every project that adopts `sf-project` must vendor a local folder for every dependency package declared in `sfdx-project.json`, even if that project never runs `dependencies clear`/`dependencies refresh`. This is `crm-arbeidsforhold`'s own layout leaking into a tool meant for reuse.

Investigating these two gaps surfaced two related portability gaps that block adoption by a project shaped differently than `crm-arbeidsforhold`:

3. The post-step catalog (`deploy`, `permsets`, `data`, `community`) is a fixed, hardcoded list. A project without Experience Cloud, or with an extra project-specific setup step, cannot express that today.
4. Configuration documentation and defaults are written from `crm-arbeidsforhold`'s point of view (multiple private dependency packages, a configured community, org pool usage). There is no guide describing the minimal configuration for a simpler project.

## Desired outcome

A team can adopt `sf-project` for a Salesforce DX project that does not look like `crm-arbeidsforhold` — no private dependency packages, no Experience Cloud community, a different set of post-setup steps — without hitting mandatory behavior that only serves this repository. Existing `crm-arbeidsforhold` behavior does not change unless this repository's own configuration is updated.

## Guiding decisions

- Preserve current `crm-arbeidsforhold` behavior by default; new flexibility is opt-in through configuration, not a breaking change to this repository's `sf-project.config.json`.
- Prefer lazy validation (required only when a workflow actually needs the data) over eager, whole-config validation that fails for capabilities a project does not use.
- Extend the existing typed configuration schema (Zod-validated `sf-project.config.json`) rather than introducing a second configuration mechanism.
- Keep the CLI as the authoritative contract: any new command or flag needs the same dry-run, `--json`, and stable-exit-code behavior as existing commands (see [CLI reference](../../tools/salesforce-project-cli/docs/cli-reference.md)).
- Document what remains repository-specific alongside what is now genuinely portable, rather than implying full portability once part of this backlog lands.

## Scope

- A way to run only post-steps against an existing, already-configured org, without org lifecycle or package installation.
- Dependency source folder resolution that does not fail configuration loading for a project with no local dependency folders.
- A post-step catalog a project can extend beyond the built-in `deploy`/`permsets`/`data`/`community` set.
- A portability guide and minimal-configuration profile for a project with no private dependency packages, no community, and no custom post-steps.

## Functional requirements

- **REQ-100:** Existing `crm-arbeidsforhold` `sf-project.config.json` behavior does not change unless this repository's configuration is explicitly updated.
- **REQ-101:** A command or flag runs only the selected post-steps against a resolved target org, issuing no org creation/deletion command and no package plan/install/update command.
- **REQ-102:** The post-steps-only path supports `--dry-run` and `--json` with the same event and exit-code contract as other operation commands.
- **REQ-110:** Configuration loading succeeds for a project whose `sfdx-project.json` dependencies have no matching local package directory, unless that project's configuration explicitly requires local directories.
- **REQ-111:** `dependencies clear` and `dependencies refresh` report a clear, typed failure or warning for a missing dependency directory depending on the configured mode; they never silently no-op.
- **REQ-120:** A project can declare at least one post-step beyond the built-in four that participates in post-step selection, canonical ordering, dry-run reporting, and `--json` events.
- **REQ-121:** Built-in post-step behavior and default ordering (`deploy`, `permsets`, `data`, `community`) are unchanged.
- **REQ-130:** A documented minimal `sf-project.config.json`/`sfdx-project.json` pair exists for a project with a single package directory, no dependencies, and no community.
- **REQ-131:** Documentation distinguishes tool-required configuration from `crm-arbeidsforhold`-specific convenience defaults.

## Delivery order

| Step | Issue  | Title                                                                             | Requirements        |
| ---: | ------ | ---------------------------------------------------------------------------------- | -------------------- |
|    1 | #1041 | Add a post-steps-only command/flag (skip org lifecycle and package install)       | REQ-100, REQ-101, REQ-102 |
|    2 | #1042 | Make dependency source folder validation configurable and non-fatal by default    | REQ-100, REQ-110, REQ-111 |
|    3 | #1043 | Make the post-step catalog configurable/extensible                                | REQ-100, REQ-120, REQ-121 |
|    4 | #1044 | Write a portability guide and minimal configuration profile for other projects    | REQ-130, REQ-131     |

Steps are independent of each other and may be delivered in any order; the numbering reflects the order they were identified in, not a dependency chain.

## Verification strategy

- Unit tests cover the new configuration fields/modes (lazy dependency-directory resolution, extensible post-step declarations) without Salesforce authentication, following the existing pattern in `tools/salesforce-project-cli/test/unit`.
- Contract tests exercise the new post-steps-only path and the extensible post-step catalog through the existing fake command runner, following the pattern in `tools/salesforce-project-cli/test/contract`.
- `crm-arbeidsforhold`'s own `sf-project.config.json` and existing test fixtures must keep passing unchanged, proving REQ-100.
- Authenticated verification against a disposable scratch org is optional per the existing [release validation gates](../../tools/salesforce-project-cli/docs/packaging-and-extraction.md#release-validation-gates) and must not be reported as passed without being explicitly run.

## Completion criteria

- All requirements in this spec have passing automated evidence.
- `tools/salesforce-project-cli/docs/configuration.md`, `docs/cli-reference.md`, `docs/workflows.md`, and `README.md`'s migration table are updated to match implemented behavior.
- `docs/legacy-behavior-matrix.md` gains a row for the new post-steps-only parity mapping.
- A new portability guide is linked from `tools/salesforce-project-cli/docs/README.md`.

## Out of scope

- Extracting the module into its own repository (tracked separately in the [packaging and extraction guide](../../tools/salesforce-project-cli/docs/packaging-and-extraction.md)).
- A general-purpose plugin/marketplace system for post-steps; the extensibility mechanism only needs to support a project declaring its own additional steps.
- Removing or changing `crm-arbeidsforhold`'s own current dependency-package layout.
- Any change to production or shared-org mutation policy.

## Issue mapping

- Epic: #1040
- Delivery issues: #1041, #1042, #1043, #1044
