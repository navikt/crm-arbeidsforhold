---
slug: p360-decision-release-lock
status: completed
---

# P360 decision release and lock

## Outcome

`Application_Decision__c.Ready_For_P360_Archive__c` is a one-way release signal guarded by a dedicated custom permission and the MyTriggers framework.

## Acceptance criteria

- Only users with `P360_Archive_Release` can set the release flag.
- A released decision cannot reset the flag.
- Regular decision fields are locked after release.
- Only the three P360 technical reference fields may change after release.
- Trigger execution is registered through `MyTriggerSetting__mdt`.
- The release guard cannot be disabled through the MyTriggers bypass permission.
- Tests cover authorized release, unauthorized release, one-way reset, post-release locking and technical-field updates.

## Evidence

- `P360_ApplicationDecisionArchiveGuard`
- `P360_ArchiveGuardHandler`
- `P360_ApplicationDecisionArchiveGuard.trigger`
- `P360_ApplicationDecisionArchiveGuardTest`
- Focused dry-run validation `0AfRR00000g2QhN0AU`: 11/11 components and 5/5 tests.

## Out of scope

- Business-completeness validation before release.
- Automatic creation of a `DecisionDocument` archive job.
- Correcting a released decision through a new version.
