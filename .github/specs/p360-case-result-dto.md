---
slug: p360-case-result-dto
status: active
jira-epic: CRMAAREG-83
jira-user-story: CRMAAREG-101
github-issue: 1009
---

# P360 CaseResult DTO

## Problem statement

GetCases returns a `CaseResult` object with core case metadata and optional nested result contracts. The integration needs a stable primitive result model before nested result mapping is implemented.

## Implemented scope

- `P360_CaseResultDto`
- `P360_CaseContactResultDto`
- Case identity, title and external ID
- Start and last-changed dates
- Status and responsible-person/enterprise names
- Subarchive, access-code, paragraph, notes and case-type fields
- UID and UID origin
- JSON round-trip test coverage

## Acceptance criteria

- Implemented primitive fields survive JSON serialization/deserialization.
- The SIF `Date` result field is represented by the semantically precise Apex property `startDate`, because `date` is a reserved Apex identifier.
- No Salesforce SObject, SOQL, DML, mapping or callout dependency is introduced.

## Out of scope

- Documents, estates, permissions, remarks, keywords, milestones and stages.
- GetCases orchestration and RPC client integration.