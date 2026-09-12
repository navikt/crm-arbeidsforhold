---
slug: integration-correlation-context
status: completed
jira-epic: CRMAAREG-83
jira-user-story: CRMAAREG-129
jira-subtasks: CRMAAREG-130, CRMAAREG-133
github-issue: 1007
---

# Shared integration correlation context

## Problem statement

Integration flows need a stable correlation ID that can be preserved when supplied or generated at the integration boundary when absent.

## Desired outcome

Shared integration code can carry an opaque correlation ID without knowing P360, a specific external API, domain data, logging policy, or transport headers.

## Acceptance criteria

- A supplied correlation ID is preserved unchanged.
- A missing correlation ID produces a non-blank opaque value.
- The common class has no P360-specific dependency.
- Focused Apex tests run under minimum-access user context.
- No sensitive or business data is included in generated correlation IDs.

## Behavioural test seam

`CorrelationContext(String suppliedCorrelationId)` and its public `correlationId` property.

## Implementation decisions

- Place the class in `force-app/integration/common/classes/`.
- Use a cryptographically generated opaque value when no ID is supplied.
- Keep logging, headers, persistence and external transport outside this value object.

## Out of scope

- Structured logging implementation.
- P360 RPC headers or authentication.
- Correlation ID persistence or cross-transaction storage.
