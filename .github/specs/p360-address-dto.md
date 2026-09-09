---
slug: p360-address-dto
status: active
jira-epic: CRMAAREG-83
jira-user-story: CRMAAREG-101
github-issue: 1009
---

# P360 Address DTO

## Problem statement

The SIF `Address` contract is shared by contact and estate results. The integration needs one transport-independent address model before nested result mapping is implemented.

## Implemented scope

- `P360_AddressDto`
- Street address, postal code and postal place
- Country, county, area and optional state
- JSON round-trip test coverage
- Nested address on `P360_CaseContactResultDto`

## Acceptance criteria

- All documented Address fields survive JSON serialization/deserialization.
- CaseContactResult preserves its nested Address fields.
- No Salesforce SObject, SOQL, DML, mapping or callout dependency is introduced.

## Out of scope

- Salesforce address mapping.
- Case estate result integration.
- GetCases orchestration and RPC client integration.