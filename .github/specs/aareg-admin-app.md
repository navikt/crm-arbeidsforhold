---
slug: aareg-admin-app
status: proposed
---

# Aa-register Admin app

Plan og bakgrunn: [docs/surfaces/aareg-admin-app.md](../../docs/surfaces/aareg-admin-app.md).
Epic: [#1186](https://github.com/navikt/crm-arbeidsforhold/issues/1186) (F0–F8: [#1187](https://github.com/navikt/crm-arbeidsforhold/issues/1187)–[#1195](https://github.com/navikt/crm-arbeidsforhold/issues/1195)).

## Outcome

An internal Lightning app gives Team Arbeidsforhold one place to see the current state of Aa-registeret, follow one application from submission to archive, inspect integration and configuration status, diagnose access, and — in scratch orgs only — create, run, and reset synthetic test scenarios.

## Users

- **Developer/tester** in the `crm-arbeidsforhold` scratch org: needs everything, including the test lab.
- **Admin/support** in SIT2 or production (after approval): needs read-only overview, journey, monitor, configuration, and access diagnosis.

## Contract

### General

- Extend the existing `Arbeidsforhold_Admin` app. Do not rename its API name. A label change requires product-owner approval.
- Packaged components are read-only. They must not perform DML on domain objects, enqueue jobs, invoke callouts, or change configuration.
- Packaged Apex uses `with sharing` and `WITH USER_MODE` (or `Security.stripInaccessible`) for every query. Missing access shows an explanation, never an unhandled error.
- Queries are bounded with `LIMIT` and aggregated where possible. A page load makes no more than a fixed number of SOQL queries regardless of data volume.
- No component reads or displays secrets, tokens, auth headers, cookies, Named Credential endpoints, or full national identity numbers.
- Every page starts with a short explanation of what it shows, what is normal, and where to read more.
- Thresholds (for example "stuck after N days") come from Custom Metadata, not code.
- Scratch-only metadata lives under `scripts/scratch/admin/` (or the existing `scripts/scratch/p360/`) and is excluded from the package.

### Permissions

- Packaged permission set `AAREG_Admin_Viewer`: app visibility, tab visibility, Apex class access for admin services, read on objects included in the decision. No modify, no `View All` until approved.
- Scratch-only permission set `AAREG_Scratch_Test_Operator`: test lab, `P360ScratchCapture__c`, scenario seeding and reset.
- A user with only the minimum-access profile sees no data and receives an access explanation.

## Modules and acceptance criteria

### M1 App shell and navigation

- Given `AAREG_Admin_Viewer`, when the user opens the App Launcher, then the admin app is visible with tabs for Application, Access Request, Application Decision, Agreement, Inquiry, P360 Archive Job, and Application Log.
- Given a scratch org with the scratch overlay deployed, the app also shows P360 Scratch Capture and Test Lab.
- Given a SIT2/prod deployment, no scratch tab or component is present.

### M2 Operations overview

- The home page shows counts for applications by status, applications stuck beyond threshold, decisions waiting for P360 release, P360 jobs by status (including expired lease), error logs in the last 24 hours grouped by source class, and unowned open inquiries.
- Each tile links to a filtered list view or report showing exactly the counted records.
- With no data, tiles show 0 and the explanation text; no error.

### M3 Application journey

- On an Application record, a timeline lists, in chronological order: creation, submission, tracked status changes, decisions, agreements, files, P360 jobs (status, attempts, correlation ID, last error), related `Application_Log__c` entries, email, SMS, and threads.
- Each entry shows timestamp, source object, and a link.
- Missing expected steps are shown as "not recorded", not hidden.
- Records the user cannot read are omitted and counted as "hidden due to access".
- Status changes depend on the field-history decision; until made, the journey uses timestamps and related records only and states that field history is not tracked.

### M4 Integration monitor

- P360: lists jobs by status with attempts, next attempt, lease expiry, correlation ID, and last error code/message; links job to application/decision.
- Distribution access, Altinn, SMS, and email: show last activity and errors from existing records.
- Log payloads (`Pay_Load__c`) are not shown unless the payload decision allows it.
- In scratch, P360 Scratch Capture receipts are linked from the related job or application.

### M5 Configuration view

- Shows the `P360_Archive_Processing` feature flag state, `P360_Integration_Setting__c` mock-transport state, relevant `MyTriggerSetting__mdt` records, `AAREG_Default_Settings__c`, and notification metadata.
- Each value has a one-sentence explanation and a Setup link.
- Named Credentials are listed by name and presence only.
- The view performs no writes.

### M6 Access diagnosis

- For the current user: profile, relevant permission sets/groups, custom permissions (including `P360_Archive_Release`), and object read/edit access for the main objects.
- Diagnosis of other users is disabled until the access decision allows it.
- Output explains why access is present or missing; it never grants access.

### M7 Test lab (scratch only)

- Before any write, verifies the target is a scratch org (`Organization.IsSandbox = true` and a scratch domain) and refuses otherwise.
- Seeds named synthetic scenarios from the test-data strategy; all records are tagged so they can be found and reset.
- Runs scenario steps and stores evidence (records created, statuses, P360 capture IDs).
- Resets only tagged synthetic records.
- Uses the existing Node runner (`npm run p360:scratch` pattern) so it works on macOS, Linux, and Windows.
- Makes zero external callouts; P360 uses the simulated receiver.

### M8 Help, review, and rollout

- Utility bar links to the architecture overview, Flow catalog, P360 scratch guide, and scenario test plan.
- Security review covers sharing, USER_MODE, payload exposure, and permission sets before PR.
- SIT2 deployment happens only after explicit target/action approval; production requires Team Platforce approval and human execution.

## Open decisions

1. App label change to "Aa-register Admin".
2. Who gets `AAREG_Admin_Viewer`, and whether it grants `View All` on main objects.
3. Fields to set `trackHistory=true` on (proposal: status, owner, deadline, decision outcome; max 20 per object).
4. Whether log payloads may be displayed.
5. Whether access diagnosis may inspect other users.
6. Whether the app is rolled out to production or kept to scratch and SIT2.

## Out of scope

- Writing to domain data, retrying or releasing P360 jobs from the packaged app (existing actions remain where they are).
- Live calls to P360, Altinn, distribution access, KRR, or other external services.
- Changing package-owned dependency directories.
- Changing existing labels, descriptions, or metadata names without approval.
