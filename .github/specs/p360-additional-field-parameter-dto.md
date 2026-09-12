---
slug: p360-additional-field-parameter-dto
status: completed
jira-epic: CRMAAREG-83
jira-user-story: CRMAAREG-101
github-issue: 1011
---

# P360 AdditionalFieldParameter DTO

## Problem statement

SIF uses `AdditionalFieldParameter` for single-value fields on Case and Document operations. The integration needs a transport-independent DTO before additional-field mapping is implemented.

## Implemented scope

- `P360_AdditionalFieldParameterDto`
- Meta-model field name
- Single field value
- Optional Get-operation operator
- JSON round-trip test coverage using a minimum-access user

## Acceptance criteria

- All documented `AdditionalFieldParameter` fields survive JSON serialization/deserialization.
- DTO field names match the SIF contract.
- No Salesforce SObject, SOQL, DML, mapping or callout dependency is introduced.
- The DTO does not validate field names or operator values; those remain operation and mapping concerns.

## Out of scope

- Case and Document additional-field mapping.
- UpdateCase/GetCases and UpdateDocument/GetDocuments DTOs.