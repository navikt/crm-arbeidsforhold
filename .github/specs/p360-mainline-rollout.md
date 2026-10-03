---
slug: p360-mainline-rollout
status: proposed
---

# P360 mainline rollout

## Outcome

The P360 implementation can be integrated into `main` and validated in a non-production org while archive processing remains disabled and existing application behavior is preserved.

## Scope

- Bring the P360 feature source, required shared integration code, metadata, and focused tests from `P360IntegrationWork` to `main`.
- Include only changes required for the P360 feature. Do not pull in unrelated tooling, scratch-org, or repository-maintenance history solely because it shares the branch.
- Keep `Feature_Flag__mdt.P360_Archive_Processing` disabled in all deployed environments until a separate activation decision; the CMT owner is `Nav_Team.Arbeidsforhold`.
- Keep the local, uncommitted `.forceignore` change out of the P360 migration unless it is separately reviewed and approved.

## Rollout stages

1. Implement and validate the gate in `.github/specs/p360-default-off-archive-processing.md` before integrating runtime entry points.
2. Merge the P360 feature set to `main` with processing disabled. A merge to `main` is not approval to create/release a package or deploy to production.
3. Deploy and run the focused P360 tests only in an explicitly approved non-production org. Verify both disabled and enabled-with-mock behavior, plus unchanged existing Application and ContentVersion behavior while disabled.
4. Keep production activation blocked until the external P360/SIF contract, endpoint, authentication, permissions, mapping, duplicate behavior, and retry/recovery policy are confirmed and reviewed by the responsible owners.
5. Treat production deployment and enabling the setting as separate, explicitly approved actions with a rollback/disable procedure.

## Acceptance criteria

- The merge contains the intended P360 feature set and tests but no unrelated branch-only changes.
- CI compiles all included metadata and runs focused P360 and existing regression tests.
- With the feature flag absent or disabled in the validation org, normal application DML is unchanged and no P360 archive job is created or processed.
- With the feature flag explicitly enabled and mock transport selected in non-production, the focused P360 archive flow tests pass without a live P360 callout.
- No production deploy, package release, permission assignment, or setting activation is performed by this work item.
- Production activation remains blocked by open external contract work, including issue #1017, until its acceptance criteria and related mapping/retry decisions are complete.

## Risks and controls

- Active triggers and `MyTriggerSetting` records can affect DML as soon as metadata is deployed; the default-off gate must guard the handler behavior, not only the transport adapter.
- Already-enqueued workers must not call transport after the setting is disabled and must leave jobs recoverable.
- `Use_Mock_Transport__c` is not an activation switch. A false value can select the live adapter.
- `--ignore-errors` is not sufficient evidence of a clean deployment; retain component-level deployment and test results.