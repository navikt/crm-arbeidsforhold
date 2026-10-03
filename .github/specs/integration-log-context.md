---
slug: integration-log-context
status: proposed
github-issue: 1086
---

# Shared integration log context

## Problem statement

Integration flows need a small, transport-independent value object for the technical fields that describe an integration event. The correlation identifier must be propagated from the existing shared `CorrelationContext`.

## Desired outcome

Callers can construct a context containing system name, operation name, status, and correlation ID without carrying payloads, personal data, persistence behavior, or P360-specific details.

## Acceptance criteria

- The context exposes the supplied system name, operation name, and status unchanged.
- A missing correlation ID is generated through `CorrelationContext`.
- A supplied nonblank correlation ID is preserved unchanged.
- Tests cover these outcomes under the minimum-access user context using synthetic values.
- The class is compiled with API 67, matching the project source API target.
- No existing production code on `main` calls the class; this change introduces no trigger, Flow, REST, Aura, invocable, callout, or automatic logging path.

## Behavioural test seam

`IntegrationLogContext(String systemName, String operationName, String status)`, `withCorrelationId(String suppliedCorrelationId)`, and the public read-only properties.

## Implementation decisions

- Place the class in `force-app/integration/common/classes/`.
- Generate the initial correlation ID using the existing `CorrelationContext` implementation.
- Keep the context limited to technical fields. Do not store event payloads or business records.
- No feature toggle is required while there is no runtime caller.

## Out of scope

- Sensitive-value redaction.
- Persisting logs through `LoggerUtility`, platform events, or `Application_Log__c`.
- Adding any caller to P360 or existing integrations.
- Defining transport headers, RPC formats, or cross-transaction correlation persistence.

## Validation

- Run focused Apex tests in an explicitly approved scratch org before merge.
- Run Prettier and `git diff --check` locally.
- Do not claim org-dependent checks as passed unless the authenticated command completes successfully.