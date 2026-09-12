---
slug: p360-f2-validation-status
status: completed
jira-epic: CRMAAREG-83
jira-user-story: CRMAAREG-89
jira-subtask: CRMAAREG-100
github-issue: 1006
---

# P360 F2 validation status

## Current implementation status

The P360 F2 skeleton boundaries are implemented and focused-test validated. The code intentionally stops before the unresolved external P360/SIF transport contract.

## Verified boundaries

- Application and Agreement domain services stop at the typed-context F3 boundary.
- Archive orchestrator validates required Application context and stops at its explicit TODO boundary.
- Archive adapter validates request and external ID before transport, then stops at its explicit unresolved-contract boundary.
- Stub archive adapter returns controlled local responses without callouts.
- RPC client stops at the unresolved transport boundary.
- Command/result objects preserve internal use-case context.
- Temporary archive and RPC DTO wrappers survive JSON round-trip serialization.
- Test factory provides minimum-access users and request/response builders.
- Exception hierarchy is verified through runtime type relationships.

## Validation evidence

- Scratch org: `crm-arbeidsforhold`
- Full focused test run: `707RR00001XXAp3`
- Result: 22 passed, 0 failed

This run is the historical completion evidence for the F2 boundary. Newer P360 tests are maintained through the `P360` Apex test suite and have separate run evidence.

## Remaining implementation blockers

- Environment-confirmed P360/SIF wire contract for the implemented DTOs.
- Endpoint and RPC envelope.
- Auth header and Entra audience/scope contract.
- Mapping between Salesforce Application/Agreement and P360 case/document model.
- External error codes, duplicate semantics and retry recovery. Internal idempotency keys and the first archive-job creation slice are implemented.

## Rule

Do not replace the controlled TODO boundaries with guessed transport or mapping behavior. Continue with tests and internal boundaries until the external contract is confirmed.
