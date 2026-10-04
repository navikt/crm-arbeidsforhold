---
slug: p360-case-contact-result-dto
status: completed
jira-epic: CRMAAREG-83
jira-user-story: CRMAAREG-101
github-issue: 1009
---

# P360 CaseContactResult DTO

## Problem statement

GetCases can return case contacts as part of `CaseResult`. The integration needs a stable primitive contact-result model before nested address and action-class mapping is implemented.

## Implemented scope

- `P360_CaseContactResultDto`
- Contact name, role, recno, reference number and contact type
- Contact external ID and unofficial flag
- Nested contact address
- Nested action class
- Subject area, notes and role recno
- JSON round-trip test coverage

## Acceptance criteria

- Implemented primitive fields survive JSON serialization/deserialization.
- The DTO remains independent of CaseResult until the result collection model is defined.
- No Salesforce SObject, SOQL, DML, mapping or callout dependency is introduced.

## Out of scope

- GetCases orchestration and RPC client integration.