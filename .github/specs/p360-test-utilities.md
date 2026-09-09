---
slug: p360-test-utilities
status: active
jira-epic: CRMAAREG-295
jira-user-story: CRMAAREG-296
jira-related-story: CRMAAREG-135
jira-subtask: CRMAAREG-141
jira-related-subtask: CRMAAREG-136 (related F7 fake-service context)
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
- The factory can build standard archive response DTO fixtures with readable fluent methods.
- The factory can build temporary RPC request fixtures with readable fluent methods.
- The factory can build temporary RPC response fixtures with readable fluent methods.
- A shared RPC fake can guard that invalid adapter requests do not reach transport.
- P360 adapter and exception tests use `System.runAs(minimumAccessUser)` where elevated access is not required.
- Apex tests use fully qualified `System.Assert.*` and `System.Test.*` APIs.
- The shared utilities are test-only and do not change the production RPC contract.
- The focused P360 Apex tests pass in the authenticated `crm-arbeidsforhold` scratch org after the new source is deployed there.
- The explicitly injected stub adapter has a focused happy-path test that verifies a controlled response without transport.
- The request and response builders have focused tests covering fluent overrides.

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

## Current evidence

- Focused deploy of the four changed Apex classes succeeded in scratch org `crm-arbeidsforhold`.
- Deploy ID: `0AfRR00000fvq5W0AQ`.
- `P360_ArchiveAdapterTest` and `P360_ExceptionHierarchyTest` ran during deploy: 4 passed, 0 failed.
- Focused deploy of `P360_StubArchiveAdapterTest` succeeded.
- Stub test deploy ID: `0AfRR00000fvlp10AA`; `P360_StubArchiveAdapterTest`: 1 passed, 0 failed.
- Response-builder deploy ID: `0AfRR00000fwTZu0AM`; `P360_StubArchiveAdapterTest`: 1 passed, 0 failed.
- Factory-builder deploy ID: `0AfRR00000fwSva0AE`; `P360_TestDataFactoryTest`: 2 passed, 0 failed.
- RPC-builder deploy ID: `0AfRR00000fwuGj0AI`; `P360_TestDataFactoryTest` and `P360_RpcClientTest`: 5 passed, 0 failed.
- RPC-response-builder deploy ID: `0AfRR00000fx5da0AA`; `P360_TestDataFactoryTest`: 4 passed, 0 failed.
- DTO serialization redeploy succeeded with conflict/warning/error override flags.
- DTO serialization deploy ID: `0AfRR00000fxCVN0A2`; `P360_TestDataFactoryTest` and `P360_DtoSerializationTest`: 6 passed, 0 failed.

## Out of scope

- Implementing the real P360 RPC transport.
- Deciding the external P360 request/response schema.
- Introducing a service locator.
- Adding authentication, Named Credential, metadata visibility, or production callout behaviour.
- Creating or assigning an undocumented Jira subtask key.

## Open questions

- `CRMAAREG-141` is the primary Jira subtask for the test-data builder slice. `CRMAAREG-136` remains related F7 context only.
- When should the external P360 team confirm the RPC contract needed for the first real adapter call?
