---
slug: p360-idempotency-keys
status: completed
jira-epic: CRMAAREG-267
jira-user-story: CRMAAREG-268
---

# P360 idempotency keys

## Outcome

Internal archive events use deterministic keys without depending on an external P360 transport contract.

## Acceptance criteria

- Application documents use `APPLICATION_DOCUMENT:{ApplicationId}`.
- Application attachments use `APPLICATION_ATTACHMENT:{ApplicationId}:{ContentVersionId}`.
- Decision documents use `DECISION_DOCUMENT:{ApplicationDecisionId}`.
- Agreement documents use `AGREEMENT_DOCUMENT:{AgreementId}`.
- Missing identifiers raise `P360_ContractException`.

## Evidence

- `P360_IdempotencyKey`
- `P360_IdempotencyKeyTest`
- Test run `707RR00001XtOIQ`: 2 idempotency tests passed.
- Coverage: 100 percent for `P360_IdempotencyKey`.

## Out of scope

- External P360 duplicate semantics.
- Recovery lookup against P360.
- External-ID mapping.
