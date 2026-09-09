---
slug: p360-domain-service-boundaries
status: active
jira-epic: CRMAAREG-83
jira-user-story: CRMAAREG-89
jira-subtasks: CRMAAREG-95, CRMAAREG-96
jira-related-subtask: CRMAAREG-100
github-issue: 1003
---

# P360 domain service boundaries

## Problem statement

The Application and Agreement domain-service skeletons need explicit tests proving that unfinished typed domain contexts do not silently return placeholders or cross into P360 transport.

## Desired outcome

Both domain services fail with stable `P360_ContractException` messages at the documented F3 boundary until typed domain contexts are implemented.

## Acceptance criteria

- Application archive-context loading raises the documented F3 contract exception.
- Agreement archive-context loading raises the documented F3 contract exception.
- Tests run under minimum-access user context.
- Domain services do not know about P360 DTOs, endpoints, auth, or transport.
- No Salesforce records or external calls are required by this boundary test.

## Behavioural test seam

- `AAREG_ApplicationDomainService.getApplicationArchiveContext(Id)`
- `AAREG_AgreementDomainService.getAgreementArchiveContext(Id)`

## Out of scope

- Defining typed `Application` or `Agreement` archive contexts.
- SOQL, mapping, P360 transport, authentication, or persistence.
- Deciding the external P360/SIF contract.
