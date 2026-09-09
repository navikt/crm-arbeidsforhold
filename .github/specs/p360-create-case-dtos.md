---
slug: p360-create-case-dtos
status: active
jira-epic: CRMAAREG-83
jira-user-story: CRMAAREG-101
jira-subtasks: CRMAAREG-106, CRMAAREG-114
github-issue: 1009
---

# P360 CreateCase DTOs

## Problem statement

The SIF PDF defines a concrete `CreateCaseParameter` and `CaseOperationResult` contract, while the repository still only has temporary archive DTOs.

## Desired outcome

The Salesforce integration has explicit internal Apex DTOs for the first Case-create boundary without implementing transport, auth, or domain mapping.

## Implemented scope

- `P360_CreateCaseRequestDto`
- `P360_CreateCaseResponseDto`
- `P360_ClassCodeParameterDto`
- Core Case fields from the SIF PDF: context user, title, external identity, dates, status, journal unit, subarchive, case type, category and archive codes.
- JSON round-trip test coverage.

## Acceptance criteria

- Request fields survive JSON serialization/deserialization.
- Archive code fields preserve sort order, archive type, manual-text flag and archive code.
- Response fields preserve recno, case number, imported case number, UID, UID origin and error fields.
- DTOs use the repository `P360_` naming convention.
- No endpoint, auth header, SIF envelope, SOQL, DML or callout is introduced.

## Out of scope

- Responsible person and enterprise subcontracts.
- Case contacts, unregistered contacts and additional fields.
- RPC client implementation and Salesforce-to-P360 mapping.
