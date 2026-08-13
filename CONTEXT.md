# Project Context: crm-arbeidsforhold

## Product

`crm-arbeidsforhold` supports Aa-registeret, NAV's work around employment data. The Salesforce solution serves both external organizations and internal case handlers.

Core product areas include:

- applications for access to employment data;
- agreements and agreement changes;
- decisions and decision letters;
- distribution access and integration with external services;
- support and dialogue flows;
- Experience Cloud for external users and Salesforce for internal users.

## Repository shape

- `force-app/` is the main product source and the default location for product changes.
- `force-app/main/default/` contains shared metadata and package-level configuration.
- Feature folders under `force-app/` contain Apex, LWC, Aura, Visualforce, and related metadata.
- The directories listed as reference-only in `.copilot/reference-only.instructions.md` are package-owned or dependency content. They may be read for context but are not edited without explicit approval.
- `sfdx-project.json` defines the `crm-arbeidsforhold` Unlocked Package and its dependencies.
- `.github/workflows/` contains reusable Nav workflows for validation, package creation, deployment, and scratch-org operations.

## Domain language

- **Aa-registeret:** the employment register and product domain.
- **Application:** an organization's request for access to employment data.
- **Agreement:** an approved access arrangement and its terms.
- **Decision:** the internal decision and user-facing decision material.
- **Distribution access:** access granted to a consumer through the integration layer.
- **External user:** an organization user working through Experience Cloud.
- **Case handler:** an internal NAV user processing applications and decisions.

Use English for Apex, metadata, API, and backend identifiers. User-facing Norwegian belongs in labels and translations using the repository's established Salesforce patterns.

## Architectural boundaries

- Keep Experience Cloud concerns, internal case-handler concerns, integration callouts, and shared utilities in their existing feature boundaries.
- Prefer existing utilities, test-data factories, Custom Metadata, Custom Labels, permission sets, Named Credentials, and package dependencies before adding new abstractions or configuration.
- Treat access control, personal data, authentication, callouts, and metadata visibility as red-zone work requiring human review.
- Preserve deployed public contracts and legacy metadata names unless the task includes an approved migration plan.

## Verification vocabulary

- **Local:** formatting, static checks, and LWC Jest can run without a Salesforce org.
- **Org-dependent:** Apex compilation/tests, dependency installation, deployment preview against org state, and package operations may require Salesforce authentication or a DevHub.
- **Red-green-refactor:** write a focused behavioural test, observe red, implement the smallest change, observe green, then refactor and run broader validation.
- **Trusted / Easy / Adaptable:** review Salesforce design for security/compliance/reliability, maintainability/clarity/intentionality, and resilience/separation/packageability.

Never report an org-dependent check as successful unless the command completed successfully.
