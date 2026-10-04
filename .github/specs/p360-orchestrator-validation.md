---
slug: p360-orchestrator-validation
status: completed
jira-epic: CRMAAREG-83
jira-user-story: CRMAAREG-89
jira-subtask: CRMAAREG-100
github-issue: 1000
---

# P360 orchestrator validation

## Problem statement

The P360 archive orchestrator skeleton must reject invalid archive commands before any adapter or transport operation is attempted.

## Desired outcome

The orchestrator exposes a stable validation boundary for required Salesforce application context while the real P360 transport contract remains unresolved.

## Acceptance criteria

- A null archive command raises `P360_ContractException` with the documented validation message.
- A command without `applicationId` raises `P360_ContractException` with the documented validation message.
- A command with a valid `applicationId` and `externalId` is forwarded to the injected adapter and returns a mapped internal result.
- A command without `externalId` raises `P360_ContractException` before the injected adapter is used.
- Validation happens before the injected archive adapter is used.
- The test runs under a minimum-access user and uses fully qualified `System.Assert.*` APIs.
- No external P360 payload, mapping, authentication, or transport behaviour is inferred.

## Behavioural test seam

`AAREG_ArchiveApplicationOrchestrator.archive(AAREG_ArchiveApplicationCommand)` with an explicitly injected `P360_IArchiveAdapter`.

## Out of scope

- Calling the real P360 RPC client.
- Resolving Salesforce field mapping into the full external P360/SIF request.

## Testing decisions

Use a focused Apex test against the authenticated `crm-arbeidsforhold` scratch org. The injected stub adapter verifies the internal success path without a callout, while validation tests prove invalid commands fail before adapter invocation.

## Current evidence

- Focused deploy ID: latest mock-flow verification (3 tests passed).
- `AAREG_ArchiveApplicationOrchestratorTest`: 3 passed, 0 failed.
