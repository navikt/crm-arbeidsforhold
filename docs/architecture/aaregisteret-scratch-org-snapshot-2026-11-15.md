# Aa-registeret scratch-org snapshot — 2026-11-15

This is a dated, partial snapshot of read-only checks and test runs against
the non-production scratch org `crm-arbeidsforhold`. It records only the
observations below; it is not a complete org inventory or a sign-off.

## Target verification

Before org queries and Apex tests, `sf org display --target-org
crm-arbeidsforhold` resolved to a `*.scratch.my.salesforce.com` domain, and
`SELECT IsSandbox FROM Organization` returned `true`. Org URLs and IDs are
intentionally omitted.

The previous snapshot also omitted org IDs. Therefore, the alias name alone
does not establish that both dated snapshots refer to the same scratch-org
instance.

## Installed packages

Command: `sf package installed list --target-org crm-arbeidsforhold`

The CLI returned 19 installed-package rows. Their package names match the 19
direct Salesforce dependencies declared in [`sfdx-project.json`](../../sfdx-project.json).

| Package                         | Installed version |
| ------------------------------- | ----------------- |
| `crm-platform-email-scheduling` | `1.8.0.2`         |
| `crm-shared-timeline`           | `1.45.0.3`        |
| `crm-henvendelse`               | `0.209.0.2`       |
| `crm-journal-utilities`         | `0.55.0.1`        |
| `crm-platform-oppgave`          | `0.84.0.1`        |
| `crm-shared-user-notification`  | `0.27.0.2`        |
| `crm-shared-flowComponents`     | `0.4.0.3`         |
| `crm-platform-access-control`   | `0.179.0.1`       |
| `crm-platform-base`             | `0.311.0.1`       |
| `crm-platform-integration`      | `0.177.0.4`       |
| `crm-platform-reporting`        | `0.47.0.2`        |
| `crm-community-base`            | `0.146.0.1`       |
| `crm-henvendelse-base`          | `0.42.0.1`        |
| `crm-thread-view`               | `0.8.0.1`         |
| `platform-data-model`           | `0.1.49.3`        |
| `custom-metadata-dao`           | `0.1.49.3`        |
| `feature-toggle`                | `0.1.50.3`        |
| `custom-permission-helper`      | `0.1.49.3`        |
| `record-type-cache`             | `0.1.17.3`        |

Compared with the [`2026-11-14 snapshot`](./aaregisteret-scratch-org-snapshot-2026-11-14.md),
the observed versions differ for `crm-platform-oppgave` (`0.84.0.5` then,
`0.84.0.1` now) and `crm-platform-base` (`0.311.0.3` then, `0.311.0.1` now).
The other 17 rows match. Because continuity of the org instance is unverified,
these are differences between two observations, not evidence of an upgrade,
downgrade, or package operation.

All 19 manifest dependencies use `LATEST` selectors. Installed versions are
observed org state and do not resolve those selectors for other orgs. Package
IDs and version IDs are intentionally omitted.

## Experience Cloud network

Read-only queries returned one `Aa-registret` network with status `Live` and
three `NetworkMemberGroup` rows. The parent records were not resolved to
names. This does not establish which exact profiles or permission sets are
members, or prove effective access for any particular user. No network
settings were changed.

## Apex test evidence

All commands targeted the verified scratch org. These synthetic tests created
Salesforce test records and archive-job records; they did not invoke live
Altinn or P360 transport.

| Command                                                                                                                                               | Result                                                                    | Evidence boundary                                                                                                                                                                                                                     |
| ----------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `sf apex run test --target-org crm-arbeidsforhold --class-names AAREG_ApplicationControllerTest --code-coverage --result-format json --wait 20`       | 20 tests: 19 passed, 1 failed; `AAREG_ApplicationController` coverage 99% | All five attachment tests passed: legacy selection default, internal-only file exclusion, wrong organization denial, Altinn Deny, and unverifiable S07. The unrelated existing status test expected `New` but observed `In Progress`. |
| `sf apex run test --target-org crm-arbeidsforhold --class-names P360_ContentVersionArchiveHandlerTest --code-coverage --result-format json --wait 30` | 4/4 passed; handler coverage 85%                                          | Direct `FirstPublishLocationId` handler entry and feature-gate cases only; no worker or external transport.                                                                                                                           |
| `sf apex run test --target-org crm-arbeidsforhold --class-names P360_ArchiveJobServiceTest --result-format json --wait 30`                            | 5/5 passed                                                                | Internal sequential reuse of archive jobs only; not external P360 duplicate or unknown-outcome recovery.                                                                                                                              |

These are runtime test results for the current scratch-org state, not evidence
that portal submission archives its files or that a full application journey
works.

## Still to verify

- Establish whether this is the same scratch-org instance as the
  `2026-11-14` snapshot before interpreting version differences as changes.
- Resolve network membership parent records and verify effective access through
  an approved Experience Cloud user journey.
- Verify the portal upload and submission path against the P360 archive
  contract; the direct-publish handler test is not a substitute.
- Approve a persistent attachment-selection and immutable submission-set
  model before implementing draft persistence or snapshot behavior.

Issue evidence and remaining limits are tracked in
[#1179](https://github.com/navikt/crm-arbeidsforhold/issues/1179),
[#1180](https://github.com/navikt/crm-arbeidsforhold/issues/1180),
[#1181](https://github.com/navikt/crm-arbeidsforhold/issues/1181),
[#1182](https://github.com/navikt/crm-arbeidsforhold/issues/1182),
[#1015](https://github.com/navikt/crm-arbeidsforhold/issues/1015), and
[#1018](https://github.com/navikt/crm-arbeidsforhold/issues/1018).
