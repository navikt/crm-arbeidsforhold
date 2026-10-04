---
slug: p360-completion-roadmap
status: proposed
---

# P360 completion roadmap

## Outcome

Complete the agreed Salesforce-to-Public 360 archive flows without guessing external contracts or changing current application behavior before explicit activation. The implementation must be supportable, testable, observable, recoverable, and independently deployable from production activation.

The P360 feature set is merged into `main` by PR #1094. The `P360_Archive_Processing` feature flag is shipped false. This roadmap describes work after that integration; merge is not approval to deploy to production, assign production permissions, release a package, or enable processing.

## Current baseline

Implemented in `main` and covered by CI:

- Fail-closed feature gate using `FeatureToggleBase.getFeatureFlag`; the default flag is false.
- Gate coverage for decision guard/job creation, application-linked ContentVersion jobs, job claims, scheduler dispatch, and worker execution.
- Idempotent internal jobs for ApplicationDocument, ApplicationAttachment, DecisionDocument, and AgreementDocument.
- Decision release permission, one-way release signal, and post-release field lock.
- DTO, mapper, adapter, domain, mock transport, claim/lease, retry classification, and test-suite foundations.
- The P360 Apex suite passed 90/90 in the approved default scratch org before the mainline merge; PR CI passed metadata compilation, Apex tests, and coverage on the merged source.

Still to verify or complete:

- Repeat disabled and mock-enabled runtime validation after merge; issue #1092 is open.
- The bounded shared logger from #1096 is merged by PR #1097. It has no production callers yet; wire it into approved flows only after reviewing each caller's technical-field allowlist and privacy boundary.
- Replace the current unresolved SIF transport boundary with an approved live contract only after external decisions are recorded.
- Complete the agreed Salesforce-to-SIF mappings, file strategy, duplicate/recovery semantics, operations ownership, and end-to-end evidence.
- Refresh repo-owned technical status documents and prepare Jira updates. Jira remains the authority for Jira status; mirrored Jira/Confluence exports must not be edited as substitutes for the source.

## Target architecture

For every approved archive event, Salesforce creates or reuses one idempotent archive job. A scheduled dispatcher claims due jobs under a lease. The worker rechecks the feature gate, maps the approved domain context to an operation-specific SIF request, calls an adapter and RPC client configured through approved credentials, then persists the outcome and correlation context. Retryable failures follow the agreed retry policy; terminal failures enter a staffed manual-recovery path.

```text
Salesforce event
    -> domain context and approved mapper
    -> idempotent P360_Archive_Job__c
    -> gated scheduler / claim lease
    -> worker and retry policy
    -> adapter contract
    -> RPC client / Named Credential
    -> Public 360 SIF
```

The mock adapter remains an explicit test/development choice, never an automatic live-transport fallback. The feature flag remains the processing kill switch. The release custom permission remains a separate user authorization control. When the gate is off, normal Salesforce DML must be preserved and no P360 job processing or callout may occur.

Business scope is not assumed by the diagram. The product owner and P360 owner must approve which events and objects are in MVP, including case creation/update, decision documents, journalpost metadata, application attachments, and agreement documents.

## Work phases

### 1. Establish post-merge baseline

- Run the approved non-production disabled-path verification and mock smoke flow; retain component-level deploy output and test run IDs.
- Confirm the effective feature flag is false after the test and mock transport cannot select the live adapter during smoke validation.
- Reconcile the P360 implementation status document and close completed mainline-integration tracking only after the evidence is recorded.

### 2. Resolve contract and ownership decisions

No live transport or production mapping is implemented from assumptions. Record decisions, owners, and evidence for:

- RPC endpoint, operation names, envelope, authentication, headers, timeout, rate limits, and environment ownership (#1017).
- Salesforce-to-SIF field mapping, code values, conditional requirements, data minimization, and event scope (#1016).
- File representation, ContentVersion limits, upload operation, cleanup, and partial-failure recovery (#1018).
- External idempotency, duplicate detection, external ID ownership/lookup, retryable error taxonomy, and recovery semantics (#1015).
- Exception contract and naming alignment between ADR-0001, implementation, and Jira (#993, #994).
- Runbook ownership, alert response, and support handover (#997, #1093).

### 3. Complete approved business flows

After the relevant decisions are accepted:

- Implement and test the agreed case create/update flow.
- Implement the agreed decision and journalpost document flows, with explicit field mapping and job lifecycle.
- Implement file handling only to the approved size and transport limits.
- Decide whether AgreementDocument is MVP; retain it as an internal job type only until its business event and mapping are approved.
- Persist and query external identifiers according to the agreed ownership and recovery contract.

### 4. Operational readiness

- Define and test scheduler frequency, overlap behavior, lease expiry, retry/backoff, dead-letter/manual-review handling, and safe reprocessing.
- Define operational ownership, dashboards/alerts, correlation, runbooks, access reviews, and retention/privacy controls.
- Ensure deploy/package workflows do not activate P360 implicitly. Keep production deployment, permission assignment, and flag activation as separately approved actions.

### 5. End-to-end verification and release decision

- Run focused Apex tests for every supported event and failure path, the full P360 suite, and relevant existing application regression tests.
- Verify the flag absent/null/false path preserves normal DML and cannot create jobs, claim jobs, dispatch workers, or call an adapter.
- Verify the explicitly enabled mock path from event through job and worker, with zero live callouts.
- Run live integration tests only in an approved non-production P360 environment after endpoint/auth/data approvals.
- Obtain security, product, P360-owner, operations, and platform sign-off; document rollback by disabling the flag first and handling queued/in-flight jobs.
- Make a separate human go/no-go decision for production deployment and activation. Issue #1093 remains the activation gate.

## Jira synchronization

Use `docs/context/p360/jira-oppdateringsoversikt.md` for the current proposed Jira changes. Jira has not been updated from this roadmap. Do not manually edit files marked `speilkopi: ja`; obtain a new Jira/Confluence export after source updates.

## Acceptance criteria

- The supported business events, object ownership, mapping, and failure behavior are approved and documented.
- Every supported event has an idempotent job and tested mapping/worker path; unsupported events cannot enter the processing path.
- The feature remains off by default, and the off path is regression-tested at all runtime entry points.
- Live transport uses approved environment configuration and secrets; no credentials or real personal data are stored in the repository or tests.
- Retry, duplicate, manual recovery, scheduling, observability, and operational ownership are agreed and tested/documented.
- CI, focused org validation, mock end-to-end validation, and approved non-production integration evidence pass.
- Production deployment, permission assignment, package release, and flag activation each receive their own explicit approval.

## Explicit exclusions

- Guessing RPC details, authentication, code values, business mappings, external duplicate semantics, or file endpoints.
- Enabling live processing as a side effect of merge, package creation, deployment, mock setup, or permission assignment.
- Treating a mock response or internal DTO test as proof of SIF interoperability.