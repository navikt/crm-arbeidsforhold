---
slug: p360-rpc-client-boundary
status: completed
jira-epic: CRMAAREG-83
jira-user-story: CRMAAREG-89
jira-subtask: CRMAAREG-94
jira-related-subtask: CRMAAREG-100
github-issue: 1002
---

# P360 RPC client boundary

## Problem statement

The P360 RPC client skeleton must make the unfinished transport boundary explicit without guessing endpoint, headers, serialization, or the external SIF contract.

## Desired outcome

Null and temporary structured RPC requests stop with a stable `P360_TransportException` until the real P360/SIF contract is confirmed.

## Acceptance criteria

- A null RPC request raises the documented transport exception.
- A temporary structured request with service, operation, body, and headers raises the same documented transport exception.
- No endpoint, authentication header, serialization, or external call is attempted.
- The focused tests run under a minimum-access user and use fully qualified `System.Assert.*` APIs.
- The test remains valid when the eventual transport contract is implemented behind `P360_IRpcClient`.

## Behavioural test seam

`P360_RpcClient.send(P360_RpcRequest)`.

## Implementation decisions

- Keep transport details behind `P360_IRpcClient`.
- Keep `P360_RpcRequest` as a temporary compile-time boundary until the SIF contract is confirmed.
- Use `P360_TransportException` for the unfinished low-level transport boundary.

## Out of scope

- Implementing HTTP/SIF RPC transport.
- Defining endpoint URLs, auth headers, RPC envelope, serialization, retry, or response parsing.
