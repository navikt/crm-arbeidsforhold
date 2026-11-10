# Implementation roadmap

## Phase 1: Scope definition

- Confirm which AAREG business actions should be logged.
- Confirm the core record types to attach to each activity entry.
- Define a small set of supported activity types.
- Define which fields are allowed in the summary payload.

## Phase 2: Shared activity helper

- Add a common service or utility such as AAREG_ActivityService.
- Add a simple method for logging activity records.
- Standardize correlation ID usage for user workflows and async jobs.
- Keep the helper small and reusable, not a generic event framework.

## Phase 3: Activity capture in business flows

Implement activity logging for:

- application creation and update,
- application submission,
- agreement updates,
- decision creation,
- related contact changes,
- inquiry submission,
- attachment linking,
- status transitions.

## Phase 4: Async and integration support

- Capture correlation IDs for queueable and future executions.
- Attach context to integration retries when relevant.
- Keep technical failure logs separate from AAREG activity entries.

## Phase 5: Reporting and support

- Add simple SOQL and reporting patterns for activity review.
- Filter records by application, record id, and activity type.
- Use the activity log for troubleshooting and operational follow-up.

## Phase 6: Validation and governance

- Review FLS and sharing implications.
- Ensure secrets and sensitive data are not logged.
- Confirm retention and ownership responsibilities.
- Sign off on the supported activity list before wider rollout.
