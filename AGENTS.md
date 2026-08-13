# Agent Instructions: crm-arbeidsforhold

## Project

This repository is a Salesforce DX project for Aa-registeret. It contains the `crm-arbeidsforhold` Unlocked Package and references several separately owned Unlocked Package dependencies.

The main application source is under `force-app/`. The package directories listed in `sfdx-project.json` are dependencies or package-owned reference content. Read them for context, but do not modify them unless the user explicitly approves the change.

Detailed Apex and LWC rules for the main package are in `force-app/main/default/AGENTS.md`.

Agent workflow details are in `.github/instructions/agentic-development.instructions.md`.
Use `.github/skills/tdd-salesforce/SKILL.md` for test-first feature work and
`.github/skills/code-review-two-axis/SKILL.md` before commit or pull request review.
The active setup backlog is `.github/AI-SETUP-TODO.md`.
Shared domain language and verification vocabulary are in `CONTEXT.md`; read it before planning feature work, TDD slices, or architecture reviews.

## Standards hierarchy

Apply standards in this order:

1. Nav-specific rules in `force-app/main/default/AGENTS.md` and [Platforce documentation](https://navikt.github.io/platforce-doc/).
2. Salesforce platform guidance in the [Architecture Center](https://architect.salesforce.com/) and [Well-Architected Framework](https://architect.salesforce.com/docs/architect/well-architected/guide/overview).
3. Current official Salesforce documentation for the relevant API version.
4. Existing repository patterns, unless they conflict with a higher-priority rule or the requested change explicitly preserves a legacy contract.

When standards conflict, preserve deployed public contracts and record the deviation for human review. Do not rename existing metadata or public Apex APIs only to make legacy code conform.

## Source boundaries

- Make product changes in `force-app/` unless the task explicitly targets another area.
- Treat these directories as read-only by default: `src-temp`, `platform-data-model`, `custom-metadata-dao`, `custom-permission-helper`, `feature-toggle`, `record-type-cache`, `crm-platform-base`, `crm-platform-reporting`, `crm-platform-access-control`, `crm-thread-view`, `crm-shared-timeline`, `crm-community-base`, `crm-platform-integration`, `crm-platform-email-scheduling`, `crm-journal-utilities`, `crm-shared-user-notification`, `crm-shared-flowComponents`, `crm-platform-oppgave`, `crm-henvendelse-base`, and `crm-henvendelse`.
- Do not edit generated, cache, log, scratch-org, or dependency-installation output.
- Never commit secrets, package installation keys, Salesforce credentials, session files, or real personal data.
- Do not change deployment workflows, package versions, dependency versions, or production configuration as part of an unrelated code change.

## Salesforce conventions

- Preserve Salesforce metadata XML and source format. Do not rename metadata only to make it look cleaner.
- Apex must follow `force-app/main/default/AGENTS.md`: use `with sharing` by default, bulkify SOQL/DML, avoid hardcoded IDs and URLs, and use the established error-logging pattern.
- Add or update focused Apex tests and LWC Jest tests when behavior changes.
- Keep package dependencies and package aliases consistent with `sfdx-project.json`.
- Prefer existing utilities, Custom Metadata, Custom Labels, and permission sets over new hardcoded configuration.
- Use English for metadata labels, API names, Apex, and backend identifiers; use Translation Workbench for user-facing Norwegian text.
- Use descriptive whole-word names: PascalCase for custom objects and fields, verb-first camelCase for Apex methods, and the established `<Namespace>_<ClassName><Suffix>` shape for Apex classes.
- Name Apex tests after the class under test without an underscore before `Test`; name test methods after the business scenario or expected behaviour, not the method under test.
- Keep code clean and readable: small cohesive methods, clear names, shallow control flow, explicit boundaries, and no speculative abstractions.
- For new or materially changed Apex, use ApexDoc (`/** ... */`) for public classes, interfaces, enums, methods, constructors, public properties, and significant annotations. Include `@param`, `@return`, `@throws`, `@see`, `@since`, or `@deprecated` where applicable.
- Keep triggers thin and delegate business logic to a handler or service. Make sharing, security, data ownership, error behaviour, and integration contracts explicit.

## Well-Architected review

For design changes, review the relevant dimensions:

- **Trusted:** secure access, compliant handling of personal data, and reliable failure/recovery behaviour.
- **Easy:** intentional scope, maintainable/readable code, appropriate automation, and an understandable user workflow.
- **Adaptable:** resilient operations, separation of concerns, interoperability, and packageability.

The review should state the main tradeoff and the evidence used to support the choice.

## Local validation

Run the narrowest relevant check first:

- `npm test -- --runInBand` for LWC Jest tests.
- `npm run prettier:check` for formatting.
- `npm run prettier:write` only when formatting changes are intended.
- `sf project deploy preview --source-dir force-app` to inspect a metadata deployment without changing an org.
- `sf project deploy start --source-dir force-app --target-org <alias> --test-level RunLocalTests` only when the user has named the target org and requested deployment.
- Use `bin/create-scratch-org.sh` for the documented scratch-org setup flow; inspect its options before running it.

A change is not complete until the relevant local checks pass or any environmental limitation is reported clearly.

## Agent workflow

1. Inspect the nearest implementation, related tests, and applicable instructions before editing.
2. State the intended scope when a change crosses package or deployment boundaries.
3. Make the smallest focused change and preserve unrelated user work.
4. Validate with the narrowest executable check available.
5. Summarize changed files, validation performed, and any checks that could not run.

Ask for explicit confirmation before modifying read-only package directories, deploying to a shared or production org, creating/releasing a package version, or changing CI/CD and authentication configuration.
