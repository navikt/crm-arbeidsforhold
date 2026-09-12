---
slug: p360-archive-job-creation
status: completed
jira-epic: CRMAAREG-267
jira-user-story: CRMAAREG-268
---

# P360 archive job creation

## Outcome

Application-document archive requests create or reuse one durable `P360_Archive_Job__c` record per idempotency key.

## Acceptance criteria

- A new application-document event creates a `Pending` job.
- The job stores access-request context, application context, correlation ID, queue time and idempotency key.
- A repeated request returns the existing job without resetting its original context.
- The unique key handles concurrent duplicate creation safely.
- Processing access is isolated in `P360_Archive_Job_Processing`.

## Evidence

- `P360_ArchiveJobService`
- `P360_ArchiveJobServiceTest`
- `P360_Archive_Job_Processing`
- Deploy `0AfRR00000g2PtN0AU`: 27/27 components and 4/4 tests.
- Test run `707RR00001XtOIQ`: 2 service tests passed.
- Coverage: 84 percent for `P360_ArchiveJobService`.

## Out of scope

- Attachment, decision and agreement job creation.
- Queueable worker execution.
- Retry scheduling, leases and manual release.
- P360 callouts.
