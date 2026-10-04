---
slug: p360-action-class-dto
status: completed
jira-epic: CRMAAREG-83
jira-user-story: CRMAAREG-101
github-issue: 1009
---

# P360 ActionClass DTO

## Problem statement

SIF `CaseContactResult` can return an ActionClass code-table object. The integration needs a small transport-independent model before action-class mapping is implemented.

## Implemented scope

- `P360_ActionClassDto`
- Action-class code, description and recno
- JSON round-trip test coverage
- Nested ActionClass on `P360_CaseContactResultDto`

## Acceptance criteria

- All documented ActionClass fields survive JSON serialization/deserialization.
- CaseContactResult preserves its nested ActionClass fields.
- No Salesforce SObject, SOQL, DML, mapping or callout dependency is introduced.

## Out of scope

- Code-table lookup or validation.
- Salesforce action-class mapping.
- GetCases orchestration and RPC client integration.