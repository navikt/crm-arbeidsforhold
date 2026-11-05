---
slug: p360-contact-parameter-dto
status: completed
jira-epic: CRMAAREG-83
jira-user-story: CRMAAREG-101
jira-subtasks: CRMAAREG-102, CRMAAREG-103, CRMAAREG-104, CRMAAREG-117
github-issue: 1011
---

# P360 registered contact parameter DTO

## Problem statement

SIF Case and Document contracts use registered contact references with shared identity, role and screening fields. These fields need a reusable DTO before contact mapping is implemented.

## Desired outcome

Case and Document operation DTOs can represent registered contact references without coupling the DTO to Salesforce objects or transport.

## Implemented scope

- `P360_ContactParameterDto`
- Reference number or external ID identity
- Role
- Unofficial/screening flag
- Document dispatch channel
- JSON round-trip test coverage

## Completion boundary

The completed status applies only to the shared registered contact parameter DTO.
The linked Jira subtasks identify related context and mapping work; they are not
completed by this DTO delivery. In particular, CRMAAREG-104
(`SalesforceJournalpostUpdateContext`) remains separate work. GitHub issue #1011
was closed for the shared DTO slices, not Salesforce context classes, mapping or
authorization rules.

## Acceptance criteria

- Contact fields survive JSON serialization/deserialization.
- The DTO supports both Case and Document contact parameter needs documented in the SIF PDF.
- No Salesforce SObject, SOQL, DML, mapping or callout dependency is introduced.
- The DTO does not decide whether reference number or external ID is used; that belongs to mapping/validation.

## Out of scope

- Unregistered contact DTO.
- Contact result DTOs.
- Case/Document mapping.
- Permissions and additional fields.
