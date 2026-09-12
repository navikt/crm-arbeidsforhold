---
slug: p360-permission-parameter-dto
status: completed
jira-epic: CRMAAREG-83
jira-user-story: CRMAAREG-101
github-issue: 1011
---

# P360 Permission DTO

## Problem statement

SIF uses `Permission` to define row permissions for cases and documents. The integration needs a transport-independent DTO before permission mapping is implemented.

## Implemented scope

- `P360_PermissionParameterDto`
- Access-group and contact identity fields
- Access level and grant flag
- Case and document-specific rights from the SIF PDF
- Permission reference description
- JSON round-trip test coverage using a minimum-access user

## Acceptance criteria

- All documented Permission fields survive JSON serialization/deserialization.
- DTO field names match the SIF `Permission` contract.
- No Salesforce SObject, SOQL, DML, mapping or callout dependency is introduced.
- The DTO does not validate identity combinations or access-level rules; those remain operation and mapping concerns.

## Out of scope

- Case and Document permission mapping.
- Permission validation and authorization decisions.
- UpdateCase/GetCases and UpdateDocument/GetDocuments DTOs.