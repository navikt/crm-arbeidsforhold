---
slug: p360-unregistered-contact-parameter-dto
status: active
jira-epic: CRMAAREG-83
jira-user-story: CRMAAREG-101
github-issue: 1011
---

# P360 UnregisteredContactParameter DTO

## Problem statement

SIF uses `UnregisteredContactParameter` for document contacts that do not already exist as registered contacts in Public 360. The integration needs a transport-independent DTO before document-contact mapping is implemented.

## Implemented scope

- `P360_UnregisteredContactParameterDto`
- Required role and contact name
- Unofficial flag and dispatch channel
- Company, reference, address, location, postal, email, phone and fax fields from the SIF PDF
- JSON round-trip test coverage using a minimum-access user

## Acceptance criteria

- All documented fields survive JSON serialization/deserialization.
- DTO field names match the SIF `UnregisteredContactParameter` contract.
- No Salesforce SObject, SOQL, DML, mapping or callout dependency is introduced.
- The DTO does not validate role, screening or dispatch rules; those remain operation and mapping concerns.

## Out of scope

- Registered-contact mapping and document orchestration.
- Contact result DTOs.
- Permissions and additional fields.
- UpdateDocument/GetDocuments DTOs.