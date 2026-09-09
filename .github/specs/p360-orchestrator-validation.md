---
slug: p360-orchestrator-validation
status: active
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
- A command with a valid `applicationId` stops with the documented not-implemented orchestration exception.
- Validation happens before the injected archive adapter is used.
- The test runs under a minimum-access user and uses fully qualified `System.Assert.*` APIs.
- No external P360 payload, mapping, authentication, or transport behaviour is inferred.

## Behavioural test seam

`AAREG_ArchiveApplicationOrchestrator.archive(AAREG_ArchiveApplicationCommand)` with an explicitly injected `P360_IArchiveAdapter`.

## Out of scope

- Implementing the successful orchestration path.
- Calling the real P360 RPC client.
- Deciding the external P360/SIF request or response contract.

## Testing decisions

Use a focused Apex test against the authenticated `crm-arbeidsforhold` scratch org. The injected stub adapter is sufficient because both invalid-command cases must fail before adapter invocation.

## Current evidence

- Focused deploy ID: `0AfRR00000fwS5z0AE`.
- `AAREG_ArchiveApplicationOrchestratorTest`: 3 passed, 0 failed.
