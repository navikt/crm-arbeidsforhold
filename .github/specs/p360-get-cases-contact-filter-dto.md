---
slug: p360-get-cases-contact-filter-dto
status: completed
jira-epic: CRMAAREG-83
jira-user-story: CRMAAREG-101
github-issue: 1009
---

# P360 GetCases Contact Filter DTO

## Problem statement

SIF GetCases supports contact-based searches using a reference number, external ID or a list of contact record numbers. These fields need a stable DTO before query composition is implemented.

## Implemented scope

- `P360_GetCasesContactFilterDto`
- Contact reference number
- Contact external ID
- Contact record-number list
- JSON round-trip test coverage

## Acceptance criteria

- All documented contact-filter fields survive JSON serialization/deserialization.
- The contact record-number collection preserves order and values.
- No Salesforce SObject, SOQL, DML, mapping or callout dependency is introduced.

## Out of scope

- Combining this undercontract into `P360_GetCasesRequestDto`.
- Validation of mutually exclusive identity fields.
- GetCases orchestration and RPC client integration.