---
slug: p360-orchestration-contracts
status: completed
jira-epic: CRMAAREG-83
jira-user-story: CRMAAREG-89
jira-subtasks: CRMAAREG-98, CRMAAREG-99
github-issue: 1004
---

# P360 orchestration contracts

## Problem statement

The archive command and result objects define the internal use-case boundary, but their field-preservation behaviour is not explicitly tested.

## Desired outcome

Internal archive input and output context can carry Salesforce identifiers, correlation data, idempotency data, and external P360 references without depending on the external RPC contract.

## Acceptance criteria

- `AAREG_ArchiveApplicationCommand` preserves application ID, agreement ID, correlation ID, and external ID.
- `AAREG_ArchiveApplicationResult` preserves success, message, correlation ID, external case ID, and external document ID.
- Tests use synthetic values and minimum-access user context.
- These internal contracts do not introduce P360 transport, authentication, or payload assumptions.

## Behavioural test seam

Public properties on `AAREG_ArchiveApplicationCommand` and `AAREG_ArchiveApplicationResult`.

## Out of scope

- Implementing orchestration success flow.
- Mapping to P360 DTOs.
- Implementing P360/SIF transport or authentication.
