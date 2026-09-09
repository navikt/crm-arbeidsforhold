---
slug: p360-dto-serialization
status: active
jira-epic: CRMAAREG-83
jira-user-story: CRMAAREG-101
jira-subtask: CRMAAREG-114
github-issue: 1005
---

# P360 DTO serialization

## Problem statement

The temporary P360 archive and RPC wrappers need explicit JSON round-trip coverage before later mapping and transport work builds on them.

## Desired outcome

Current internal DTO wrappers preserve their public fields through Apex JSON serialization and deserialization without implying a final SIF envelope or external field contract.

## Acceptance criteria

- Archive request and response DTO fields survive JSON round-trip serialization.
- RPC request and response wrapper fields, including headers, survive JSON round-trip serialization.
- Tests use synthetic values and minimum-access user context.
- The test documents current placeholder behaviour only; it does not define the external P360/SIF contract.

## Behavioural test seam

`JSON.serialize` and `JSON.deserialize` for `P360_ArchiveRequestDto`, `P360_ArchiveResponseDto`, `P360_RpcRequest`, and `P360_RpcResponse`.

## Implementation decisions

- Keep the DTO classes unchanged until the external P360 contract and naming decisions are confirmed.
- Treat this as internal wrapper compatibility, not an API contract test.

## Out of scope

- Introducing the F3 operation-specific DTOs.
- Defining SIF JSON/XML envelope fields.
- Implementing mapping, transport, authentication, or response error parsing.
