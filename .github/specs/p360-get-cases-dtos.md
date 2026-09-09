---
slug: p360-get-cases-dtos
status: active
jira-epic: CRMAAREG-83
jira-user-story: CRMAAREG-101
github-issue: 1009
---

# P360 GetCases DTOs

## Problem statement

The SIF PDF defines a query contract for finding existing cases. The integration needs an explicit DTO for the stable search and pagination boundary before lookup orchestration is implemented.

## Implemented scope

- `P360_GetCasesRequestDto`
- `P360_DateCriteriaDto`
- Context user, pagination and recno sorting
- Case identity and common search filters
- Date field, operator and value search criteria
- Public-information and relation result flags
- JSON round-trip test coverage

## Acceptance criteria

- Implemented query fields survive JSON serialization/deserialization.
- DTO field names match the documented SIF GetCasesQuery contract.
- No default page size, sort order, validation, endpoint, auth header, SOQL, DML, callout or Salesforce-to-P360 mapping is introduced.

## Out of scope

- Contact-filter request composition.
- Custom-field result flags.
- Additional-field query composition.
- Full `CaseResult` and nested result DTOs.
- GetCases orchestration and RPC client integration.