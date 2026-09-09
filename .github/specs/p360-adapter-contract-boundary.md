---
slug: p360-adapter-contract-boundary
status: active
jira-epic: CRMAAREG-83
jira-user-story: CRMAAREG-89
jira-subtask: CRMAAREG-100
github-issue: 1001
---

# P360 adapter contract boundary

## Problem statement

The archive adapter must validate requests locally and make the unresolved external P360 contract boundary explicit instead of attempting an unconfirmed transport call.

## Desired outcome

Invalid requests fail with stable contract errors, while valid temporary requests stop with the documented not-implemented contract exception until the P360/SIF contract is confirmed.

## Acceptance criteria

- The explicitly injected local stub returns a controlled success response for a valid request.
- The local stub tolerates a null request and returns no external case id.
- A null archive request is rejected before transport.
- A request without `externalId` is rejected before transport.
- A structurally valid temporary request stops with the explicit unresolved-contract exception.
- The adapter never calls the injected RPC client for these cases.
- Tests run under a minimum-access user and use fully qualified `System.Assert.*` APIs.
- No external P360 payload, mapping, authentication, or retry behavior is inferred.

## Behavioural test seam

`P360_ArchiveAdapter.archive(P360_ArchiveRequestDto)` with an injected `P360_TestRpcClient` transport guard.

## Current evidence

- Focused deploy ID: `0AfRR00000fx2iw0AA`.
- `P360_StubArchiveAdapterTest`: 2 passed, 0 failed.
- The local stub behavior is intentionally separate from the real adapter's strict request validation.

## Out of scope

- Implementing the real P360/SIF transport.
- Defining request/response JSON or RPC envelope fields.
- Adding authentication, mapping, or retry behavior.
