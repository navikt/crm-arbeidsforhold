---
slug: p360-update-case-dtos
status: completed
jira-epic: CRMAAREG-83
jira-user-story: CRMAAREG-101
github-issue: 1009
---

# P360 UpdateCase DTOs

## Problem statement

The SIF PDF defines separate `UpdateCaseParameter` and `CaseOperationResult` contracts. The integration needs explicit DTOs for the core update boundary without implementing transport, auth or domain mapping.

## Implemented scope

- `P360_UpdateCaseRequestDto`
- `P360_UpdateCaseResponseDto`
- Case number or external identity fields
- Core mutable case fields: title, unofficial title, start date, status, journal unit, subarchive and paper flag
- Update control flags for responsible person removal and contact, estate and archive-code synchronization
- JSON round-trip test coverage

## Acceptance criteria

- Request fields survive JSON serialization/deserialization.
- Response fields preserve recno, case number, success and error fields.
- DTOs use the repository `P360_` naming convention.
- Null remains available to represent an omitted update field; DTOs do not add defaulting or validation logic.
- No endpoint, auth header, SIF envelope, SOQL, DML, callout or Salesforce-to-P360 mapping is introduced.

## Out of scope

- Responsible person and enterprise subcontracts.
- Case contacts, unregistered contacts, estates, permissions and additional fields.
- RPC client implementation and case orchestration.