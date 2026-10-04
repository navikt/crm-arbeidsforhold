---
title: Jira update proposal for P360
updated: 2026-10-04
status: proposal-not-applied
---

# Jira update proposal for P360

This is a proposed Jira update set based on the merged `main` tree, PR #1094, and post-merge scratch evidence. **Jira has not been changed by this document.** Jira remains authoritative for status, ownership, priority, and estimates. The last repository Jira snapshot is from 2026-09-13 and must not be treated as current state.

Do not update Confluence/Jira mirror files manually. After Jira changes are accepted, export them again and refresh files marked `speilkopi: ja`.

## Verified evidence

- PR #1094 merged to `main` as `05f7d2985b04850ac44c00a43434a3f64abbd361`.
- PR #1097 merged the bounded logger and completion documentation to `main` as `3e126df44420491616f93a4eb9787ee6e04db897`; GitHub task #1096 is closed.
- The merged code defaults `Feature_Flag__mdt.P360_Archive_Processing` to false and keeps release permission and mock transport separate.
- Post-merge P360 suite in the approved default scratch org: 90/90 passed, run `707QI00001Idq8v`.
- Logger, context, and redactor tests after PR #1097: 6/6 passed, run `707QI00001IdNeK`; P360 regression suite after the logger change: 90/90 passed, run `707QI00001IdqiI`.
- Scratch org flag query: `Is_Enabled__c=false`, `Required_Custom_Permission__c=null`.
- PR CI passed metadata compilation, Apex tests, and code coverage.
- The post-merge mock smoke path has not been run; #1092 remains open. No live P360 call was made.
- `IntegrationLogger.logFailure(IntegrationLogContext)` is in `main` after PR #1097; GitHub task #1096 is closed. It has no production callers yet. Do not mark F6 complete until approved P360 caller wiring, transport correlation, and end-to-end log behavior are verified.

## Jira changes to make first

| Jira item           | Proposed Jira action                                                                                                      | Evidence / boundary                                                                                                                                                                         |
| ------------------- | ------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| CRMAAREG-84 / F1    | Confirm `Ferdig`.                                                                                                         | Naming/architecture baseline exists.                                                                                                                                                        |
| CRMAAREG-89 / F2    | Confirm `Ferdig`, with an explicit note that the transport/orchestration stops at unresolved contracts.                   | DTO, adapter, domain, and mock boundaries are in `main`; not live interoperability.                                                                                                         |
| CRMAAREG-101 / F3   | Keep `Under arbeid`; list remaining DTO/domain contexts and approved operation scope.                                     | DTO foundations exist; not all use cases or update operations are composed.                                                                                                                 |
| CRMAAREG-115 / F4   | Keep `Under arbeid`; split mock mapper coverage from approved production mapping.                                         | Case/document/file parameter mapper foundations exist; full field mapping and live use are blocked by #1016/#1018.                                                                          |
| CRMAAREG-121 / F5   | Keep open until the Jira exception list is reconciled with implemented hierarchy and retryability.                        | Classes and tests exist; #993 tracks the contract/text decision.                                                                                                                            |
| CRMAAREG-129 / F6   | Keep `Under arbeid`; distinguish merged logger foundation from caller wiring and end-to-end transport propagation.        | `CorrelationContext`, `IntegrationLogContext`, and bounded `IntegrationLogger` are in `main` after #1097. No P360 production caller exists yet; propagation and per-flow validation remain. |
| CRMAAREG-135 / F7   | Keep `Under arbeid`; record the test factory/builders that exist and the remaining reusable fake/service requirements.    | P360 test factory, stub adapter, and test RPC client exist; not every Jira-named fake is present.                                                                                           |
| CRMAAREG-143 / K1   | Propose `Ferdig` for the metadata schema and standard records; link #1016 for domain-specific values.                     | Custom Metadata type, fields, access, and standard profile are in `main`.                                                                                                                   |
| CRMAAREG-155 / K2   | Propose `Ferdig` for the metadata lookup service; keep concrete domain mappings under #1016.                              | `P360_ICodeTableService` and `P360_CodeTableMetadataService` exist and are tested.                                                                                                          |
| CRMAAREG-163 / K3   | Mark resolved through constructor injection and `P360_AdapterFactory`; remove any work to build a service locator.        | GitHub #996 is closed; update Jira wording, not the implementation.                                                                                                                         |
| CRMAAREG-169 / K4   | Verify and propose `Ferdig` for approved non-sensitive default records only.                                              | Keep any unapproved case/document values out of Jira as accepted values; link #1016.                                                                                                        |
| CRMAAREG-175 / K5   | Keep backlog/future; document that RPC code-table lookup is not MVP unless the external contract requires it.             | Depends on #1017 and an approved need.                                                                                                                                                      |
| CRMAAREG-181 / S1   | Keep open/blocked pending endpoint and authentication decisions.                                                          | Configuration scaffolding is not a Named/External Credential or a live auth implementation; #1017.                                                                                          |
| CRMAAREG-188 / S2   | Keep `Under arbeid`; record permission-set design separately from production assignment and audit approval.               | Permission sets/group are metadata; production assignment is a separate controlled action.                                                                                                  |
| CRMAAREG-195 / C1   | Keep open until product/P360 owners approve case lifecycle, trigger event, and required data.                             | Needed before automatic ApplicationDocument/Case orchestration.                                                                                                                             |
| CRMAAREG-200 / C2   | Keep `Under arbeid` only for the tested mock mapping slice; do not call it a completed live CreateCase flow.              | Full mapping and RPC remain blocked by #1016/#1017.                                                                                                                                         |
| CRMAAREG-208 / C3   | Keep backlog until case-update semantics and triggers are approved.                                                       | No live update flow is implemented.                                                                                                                                                         |
| CRMAAREG-216 / J1   | Keep open until journalpost/business metadata rules are approved.                                                         | Required before committing final document mapping.                                                                                                                                          |
| CRMAAREG-221 / J2   | Keep `Under arbeid` for internal/mock CreateDocument mapping only; clarify whether it covers journalpost creation.        | No approved live mapping or transport.                                                                                                                                                      |
| CRMAAREG-229 / J3   | Keep backlog until update-document contract and use case are approved.                                                    | No live metadata update flow.                                                                                                                                                               |
| CRMAAREG-237 / FLS1 | Keep open and blocked on file ownership/size/upload decisions.                                                            | #1018.                                                                                                                                                                                      |
| CRMAAREG-242 / FLS2 | Keep `Under arbeid` only for file parameter/mock payload mapping; state that upload is absent.                            | #1018 blocks ContentVersion retrieval, limits, endpoint, cleanup, and live upload.                                                                                                          |
| CRMAAREG-250 / FLS3 | Keep later-phase backlog unless approved file sizes require it for MVP.                                                   | Do not select an endpoint in advance.                                                                                                                                                       |
| CRMAAREG-255 / X1   | Split “fields exist” from the external ID format/ownership decision; keep the latter open under #1016/#1015.              | P360 reference fields exist; interoperability and ownership are not fully approved.                                                                                                         |
| CRMAAREG-261 / X2   | Keep open until lookup semantics, sharing, and uniqueness are approved.                                                   | Stored fields are not a tested external-ID recovery lookup.                                                                                                                                 |
| CRMAAREG-266 / X3   | Keep future backlog; make recovery lookup dependent on #1015 and the confirmed SIF operation.                             | Do not implement guessed `GetEntitiesExternalIds` behavior.                                                                                                                                 |
| CRMAAREG-268 / R1   | Keep `Under arbeid`; mark Salesforce-side internal job idempotency as delivered, external duplicate semantics as open.    | Four internal job keys/services exist; #1015 remains external-owner blocker.                                                                                                                |
| CRMAAREG-274 / R2   | Keep `Under arbeid`; mark lease/claim/worker/backoff as implemented against stub, with live failure/recovery policy open. | P360 suite covers internal worker behavior; #1015/#1017 still block external semantics.                                                                                                     |
| CRMAAREG-284 / O1   | Keep `Under arbeid`; separate the merged bounded logger foundation from caller wiring and end-to-end transport propagation. | Main includes `CorrelationContext`, `IntegrationLogContext`, and bounded `IntegrationLogger`; no P360 production caller or end-to-end transport correlation exists yet.                              |
| CRMAAREG-290 / O2   | Keep backlog until monitoring, alert thresholds, owners, and runbook source are approved.                                 | Coordinate ownership through GitHub #997; Confluence remains operational source.                                                                                                            |
| CRMAAREG-296 / T1   | Update evidence to the 90/90 post-merge suite and retain `Under arbeid` for missing end-to-end/live contract tests.       | Run `707QI00001Idq8v`; #1092 mock smoke remains open.                                                                                                                                       |
| CRMAAREG-303 / T2   | Keep backlog/blocked until an approved non-production P360 environment and contract exist.                                | A mock test is not an integration test against P360.                                                                                                                                        |
| CRMAAREG-310 / D1   | Confirm `Ferdig` for the approved technical baseline only after the updated technical overview is reviewed.               | Link this repo's P360 technical overview and completion roadmap; do not copy runtime claims from the September mirror.                                                                      |
| CRMAAREG-315 / D2   | Keep `Under arbeid`; assign one runbook owner and define handover/support content.                                        | GitHub #997 tracks the ownership decision.                                                                                                                                                  |

## Dependency links to record in Jira

Review and add explicit Jira issue links; these are proposed dependencies, not claims that the Jira links already exist:

- Mapping/event scope (#1016 / F4, C1, C2, J1, J2) before live case/document orchestration.
- RPC endpoint/auth (#1017 / S1) before a real `P360_IRpcClient` call.
- File MVP decision (#1018 / FLS1) before ContentVersion extraction or upload.
- External idempotency/recovery (#1015 / X1-X3, R1-R2) before production retry/replay.
- Exception contract (#993) before final error mapping and Jira acceptance text; naming correction (#994) is Jira text work only.
- Runbook ownership (#997 / O2, D2, R2) before operational handover.
- Post-merge mock verification (#1092) is a prerequisite for closing the mainline integration epic (#1089), but not for production activation.

## Jira synchronization checklist

1. Confirm the current Jira issue state, assignee, and acceptance text before changing it; this repository proposal is not a Jira export.
2. Update the completed and partial stories above without marking mock-only or code-scaffold work as live integration.
3. Add the missing `issuelinks` and identify one owner for runbook creation/maintenance.
4. Correct the exception and code-table naming text in Jira (#993/#994), then export Jira again.
5. Refresh any repository files with `speilkopi: ja` only from the updated Jira/Confluence source.
