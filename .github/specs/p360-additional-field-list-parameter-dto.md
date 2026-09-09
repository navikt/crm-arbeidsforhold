---
slug: p360-additional-field-list-parameter-dto
status: active
jira-epic: CRMAAREG-83
jira-user-story: CRMAAREG-101
github-issue: 1011
---

# P360 AdditionalFieldListParameter DTO

## Problem statement

SIF uses `AdditionalFieldListParameter` for multi-value fields on Case and Document operations. The integration needs a transport-independent DTO before additional-field mapping is implemented.

## Implemented scope

- `P360_AdditionalFieldListParameterDto`
- Meta-model field name
- Multi-value `Value` list
- JSON round-trip test coverage using a minimum-access user

## Acceptance criteria

- The documented `Name` and list-valued `Value` fields survive JSON serialization/deserialization.
- DTO field names and value shape match the SIF contract.
- No Salesforce SObject, SOQL, DML, mapping or callout dependency is introduced.
- The DTO does not validate field names or values; those remain operation and mapping concerns.

## Out of scope

- Case and Document additional-field mapping.
- UpdateCase/GetCases and UpdateDocument/GetDocuments DTOs.