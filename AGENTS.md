# Agent Instructions: crm-arbeidsforhold

## Project

This repository is a Salesforce DX project for Aa-registeret. It contains the `crm-arbeidsforhold` Unlocked Package and references several separately owned Unlocked Package dependencies.

Team Arbeidsforhold owns this repository and product. The GitHub team `@navikt/crm-arbeidsforhold` represents repository contributors and reviewers; see `CODEOWNERS`. Team Platforce provides platform guidance and performs production verification and deletion.

The main application source is under `force-app/`. The package directories listed in `sfdx-project.json` are dependencies or package-owned reference content. Read them for context, but do not modify them unless the user explicitly approves the change.

Detailed Apex and LWC rules for the main package are in `force-app/main/default/AGENTS.md`.

Agent workflow details are in `.github/instructions/agentic-development.instructions.md`.
Use `.github/skills/tdd-salesforce/SKILL.md` for test-first feature work and
`.github/skills/code-review-two-axis/SKILL.md` before commit or pull request review.
The active setup backlog is `.github/AI-SETUP-TODO.md`.
Shared domain language and verification vocabulary are in `CONTEXT.md`; read it before planning feature work, TDD slices, or architecture reviews.

Technical documentation is organized under `docs/`: ADRs in `docs/adr/`, cross-cutting architecture in `docs/architecture/`, domain guidance in `docs/domain/`, surface guidance in `docs/surfaces/`, integration documentation in `docs/integrations/`, and shared development standards in `docs/utviklingsstandarder.md`.

## Standards hierarchy

Apply standards in this order:

1. Nav-specific rules in `force-app/main/default/AGENTS.md` and [Platforce documentation](https://navikt.github.io/platforce-doc/).
2. Salesforce platform guidance in the [Architecture Center](https://architect.salesforce.com/) and [Well-Architected Framework](https://architect.salesforce.com/docs/architect/well-architected/guide/overview).
3. Current official Salesforce documentation for the relevant API version.
4. Existing repository patterns, unless they conflict with a higher-priority rule or the requested change explicitly preserves a legacy contract.

When standards conflict, preserve deployed public contracts and record the deviation for human review. Do not rename existing metadata or public Apex APIs only to make legacy code conform.

## Source boundaries

- Make product changes in `force-app/` unless the task explicitly targets another area.
- Place Apex test classes and reusable Apex test utilities under `force-app/tests/classes/<matching-area>/`; keep production Apex classes under their feature or integration package paths.
- Treat these directories as read-only by default: `src-temp`, `platform-data-model`, `custom-metadata-dao`, `custom-permission-helper`, `feature-toggle`, `record-type-cache`, `crm-platform-base`, `crm-platform-reporting`, `crm-platform-access-control`, `crm-thread-view`, `crm-shared-timeline`, `crm-community-base`, `crm-platform-integration`, `crm-platform-email-scheduling`, `crm-journal-utilities`, `crm-shared-user-notification`, `crm-shared-flowComponents`, `crm-platform-oppgave`, `crm-henvendelse-base`, and `crm-henvendelse`.
- Do not edit generated, cache, log, scratch-org, or dependency-installation output.
- Never commit secrets, package installation keys, Salesforce credentials, session files, or real personal data.
- Do not change deployment workflows, package versions, dependency versions, or production configuration as part of an unrelated code change.

## Salesforce conventions

### Org safety

- Agents may work in the existing `crm-arbeidsforhold` scratch org without renewed user approval, including reads, previews, retrievals, Apex tests/scripts, package installation, deployments, publishing, and data or metadata changes/deletions. Verify before acting that the explicit target is the intended scratch org, not merely an alias with the expected name. This authorization does not cover org creation/replacement, access to a Dev Hub or another org, package creation/promotion, CI/auth changes, or live external integrations. Production access is prohibited.
- Use Salesforce CLI 2.158.7 installed on the macOS host for this repository.
- Target the `crm-arbeidsforhold` scratch org for Salesforce development operations unless the user explicitly authorizes another non-production org.
- Execute authenticated Salesforce CLI commands through the supported VS Code host-terminal mechanism. Respect native tool approvals; the scratch-org authorization does not bypass host security controls or require an additional conversational approval. Do not execute authenticated Salesforce CLI commands inside `cplt`, which cannot access the host authentication. If the approved host-terminal mechanism is unavailable, stop and ask for an approved alternative.
- Never modify Salesforce authentication, encryption settings, Keychain entries, credential files, or CLI auth state.
- Metadata deployments to the verified `crm-arbeidsforhold` scratch org need no renewed user approval. Deployments to any other non-production org require fresh approval of the exact target and action; approval for a preview or test does not authorize those deployments.
- Explain the technical reason and obtain explicit approval before using any other non-production org, including SIT2 or a Dev Hub.
- Outside the authorized `crm-arbeidsforhold` scratch org, obtain fresh confirmation of the exact non-production target and action before each org-access command. Authentication, default aliases, scripts, and previous approvals do not authorize those operations.
- Agents must never access production, even on request or with approval. Do not authenticate, query, retrieve, test, deploy, or access a production-backed Dev Hub. Arrange human execution instead.
- Human changes to production metadata require explicit Team Platforce approval. Team Platforce performs production verification and deletion; approval for human execution does not permit agent access.
- For metadata deletion or renaming, require a runbook listing all affected API names, old and new names, applicable approvals, scripts, rollback, and verification evidence. Execution in the verified `crm-arbeidsforhold` scratch org needs no renewed approval. Verify deletion in SIT2 after explicit target/action approval; Team Platforce verifies production. Never report these steps complete without evidence.

- Preserve Salesforce metadata XML and source format. Do not rename metadata only to make it look cleaner.
- Apex must follow `force-app/main/default/AGENTS.md`: use `with sharing` by default, bulkify SOQL/DML, avoid hardcoded IDs and URLs, and use the established error-logging pattern.
- Add or update focused Apex tests and LWC Jest tests when behavior changes.
- After modifying Apex or Salesforce metadata, run the relevant focused tests and validation. Run org-dependent Apex tests only through the approved host-terminal workflow.
- In Apex tests, always call the Salesforce framework with the fully qualified namespace: use `System.Assert.*` for assertions and `System.Test.*` for lifecycle APIs such as `System.Test.startTest()` and `System.Test.stopTest()`. Do not use bare `Assert` or unqualified `Test` calls.
- Include at least one `System.runAs(minimumAccessUser)` in Apex test classes when the behaviour under test does not require elevated permissions. Use a user created from the minimum-access profile (`Profile.Name = 'Minimum Access - Salesforce'`) unless the scenario genuinely requires a stronger profile.
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
- `sf project deploy preview --source-dir force-app --target-org crm-arbeidsforhold` after verifying the scratch target; no renewed user approval is needed.
- `sf project deploy start --source-dir force-app --target-org crm-arbeidsforhold --test-level RunLocalTests` after verifying the scratch target; no renewed user approval is needed. Other non-production targets require fresh target/action approval for each command.
- Use `bin/create-scratch-org.sh` for the documented scratch-org setup flow; inspect its options before running it.

A change is not complete until the relevant local checks pass or any environmental limitation is reported clearly.

## Agent workflow

1. Inspect the nearest implementation, related tests, and applicable instructions before editing.
2. State the intended scope when a change crosses package or deployment boundaries.
3. Make the smallest focused change and preserve unrelated user work.
4. Validate with the narrowest executable check available.
5. Summarize changed files, validation performed, and any checks that could not run.

Ask for explicit confirmation before modifying read-only package directories, accessing any org other than the verified `crm-arbeidsforhold` scratch org, creating/replacing an org, creating/releasing a package version, or changing CI/CD and authentication configuration. Production access is prohibited for agents regardless of approval. Keep operations traceable through Issue/PR records and approved operational records; activity may be checked against audit logs.
