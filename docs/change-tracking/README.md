# Change tracking specification for crm-arbeidsforhold

## Purpose

This folder contains the repository-grounded specification for an application-scoped change tracking design in crm-arbeidsforhold.

The goal is to capture meaningful business changes made by this application while avoiding false positives from unrelated activity in the same Salesforce org.

## Scope

This design applies to:

- application workflows and business state transitions,
- record mutations performed by crm-arbeidsforhold,
- integration actions and async execution context,
- operational diagnostics and troubleshooting.

This is intentionally not an org-wide audit of all Salesforce activity.

## Design principles

- Application-owned tracking only
- Clear separation between business events and technical logs
- Correlation IDs for user, request, and async execution context
- Minimal but meaningful payload capture
- Security-conscious handling of personal data and secrets
- Readability and supportability over generic event spam

## Document set

- [repository-analysis.md](repository-analysis.md) — repository-grounded findings
- [target-architecture.md](target-architecture.md) — recommended solution design
- [data-model-and-logging.md](data-model-and-logging.md) — event model and logging split
- [implementation-roadmap.md](implementation-roadmap.md) — phased delivery plan
- [security-and-testing.md](security-and-testing.md) — security, privacy, and validation

## Recommended conclusion

The best fit for this codebase is a small AAREG activity log built as a custom object, with a shared helper used by the app when meaningful business actions happen. This keeps the solution focused on the application, easy to query, and far simpler than a generic org-wide audit architecture.
