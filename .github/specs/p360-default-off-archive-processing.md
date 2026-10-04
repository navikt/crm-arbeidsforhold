---
slug: p360-default-off-archive-processing
status: completed
---

# P360 default-off archive processing gate

## Outcome

P360 source can be merged to `main` and deployed for validation without changing current application behavior. P360 archive processing runs only after an explicit enablement decision.

## Gate contract

- Use the existing `feature-toggle` package and add the `Feature_Flag__mdt` record `P360_Archive_Processing` with `Is_Enabled__c=false` by default and `Feature_flag_owner__c` referencing `Nav_Team.Arbeidsforhold`.
- Load the flag using `FeatureToggleBase.getFeatureFlag(name)` and enable processing only when `Is_Enabled__c` is explicitly true and `Required_Custom_Permission__c` is blank. Do not use `isFeatureEnabled(String)`, which also accepts a Custom Permission.
- A missing flag, unset value, feature-toggle lookup error, false value, or nonblank required permission means disabled.
- The gate is independent of `Use_Mock_Transport__c`, which selects mock versus real transport, and `P360_Archive_Release`, which authorizes a user to release a decision for archiving.
- The gate takes precedence over active `MyTriggerSetting` records. Those records must not cause P360 behavior while the gate is disabled.

## Required entry points

- `P360_ContentVersionArchiveHandler`: while disabled, do not create attachment archive jobs.
- `P360_ArchiveGuardHandler`: while disabled, do not apply P360-specific decision locking/release validation or create decision archive jobs.
- `P360_ArchiveJobScheduler`: while disabled, do not claim jobs or enqueue workers.
- `P360_ArchiveJobWorker`: check again before adapter invocation so already-enqueued work cannot call transport after disablement. Safely return any claimed job to a retryable state without consuming an attempt or losing it.

## Acceptance criteria

- Missing, `null`, and explicit `false` setting tests prove that the gate is off.
- With the gate off, inserting an Application-linked `ContentVersion` creates no P360 archive job and does not otherwise change the normal insert outcome.
- With the gate off, `Application_Decision__c` insert/update preserves existing non-P360 DML behavior: no P360-only errors, lock, or archive job.
- With the gate off, the scheduler claims no jobs and a worker makes no adapter/callout invocation; an already-claimed job remains recoverable when processing is later enabled.
- With the gate explicitly enabled, existing focused P360 tests continue to prove job creation, release guard, scheduling, and worker behavior.
- Tests inject Custom Metadata through `CustomMetadataDAO` and distinguish the feature flag from mock transport and user permission.
- The deployed default remains off; no org data or workflow silently enables processing.

## Out of scope

- Implementing or enabling live P360/SIF transport.
- Defining endpoint, authentication, payload mapping, or external error semantics.
- Assigning permissions or enabling processing in production.