---
slug: p360-test-utilities
status: active
jira-epic: CRMAAREG-295
jira-user-story: CRMAAREG-296
jira-related-story: CRMAAREG-135
jira-subtask: not documented in repository
github-issue: 999
---

# P360 test utilities

## Problem statement

P360 adapter tests currently create request DTOs and transport fakes locally. This makes the first contract-boundary tests harder to extend consistently and encourages duplicated fixtures.

## Desired user-visible outcome

Developers can write readable P360 Apex tests using shared test utilities while keeping the production contract boundary narrow and the external P360 transport contract unresolved until it is confirmed.

## User stories

As a P360 developer, I want reusable test builders and fakes so that adapter tests state the scenario and expected outcome directly.

As a reviewer, I want the test utility dependencies to be explicit so that shared test code does not become a hidden service locator or production dependency.

## Acceptance criteria

- A test-only P360 factory can create a minimum-access Salesforce user for tests that do not require elevated permissions.
- The factory can build the temporary archive request DTO with readable fluent methods.
- A shared RPC fake can guard that invalid adapter requests do not reach transport.
- P360 adapter and exception tests use `System.runAs(minimumAccessUser)` where elevated access is not required.
- Apex tests use fully qualified `System.Assert.*` and `System.Test.*` APIs.
- The shared utilities are test-only and do not change the production RPC contract.
- The focused P360 Apex tests pass in the authenticated `crm-arbeidsforhold` scratch org after the new source is deployed there.

## Behavioural test seam

The primary seam is `P360_IArchiveAdapter.archive(P360_ArchiveRequestDto)`. Invalid requests must fail at the adapter boundary before `P360_IRpcClient.send(...)` is reached. The exception hierarchy remains verified through runtime type and inheritance outcomes.

## Implementation decisions

- Place reusable P360 test utilities under `force-app/integration/p360/classes/test/`.
- Use `P360_TestDataFactory` for minimum-access users and archive request builders.
- Use `P360_TestRpcClient` as a focused transport guard for pre-transport validation tests.
- Keep constructor injection as the production dependency pattern. `P360_AdapterFactory` remains a composition root, not a service locator.
- Do not implement or infer the external P360 RPC payload, authentication, mapping, or retry contract in this slice.

## Security and data considerations

- Test users use the Salesforce `Minimum Access - Salesforce` profile unless a scenario genuinely requires stronger permissions.
- Fixtures use synthetic values only.
- No credentials, package keys, Salesforce IDs, or external URLs are stored in the spec or test utilities.
- Creating a user and running Apex tests are org-dependent operations and require an approved scratch org.

## Testing decisions

- Use red-green-refactor for each new observable adapter behaviour when an authenticated org is available.
- Run focused Apex tests against the named scratch org after deployment.
- Run Prettier and `git diff --check` locally for changed Apex and metadata files.

## Out of scope

- Implementing the real P360 RPC transport.
- Deciding the external P360 request/response schema.
- Introducing a service locator.
- Adding authentication, Named Credential, metadata visibility, or production callout behaviour.
- Creating or assigning an undocumented Jira subtask key.

## Open questions

- Which Jira subtask key should own this concrete test-utility slice? The repository contains no verified key; do not invent one.
- When should the external P360 team confirm the RPC contract needed for the first real adapter call?
