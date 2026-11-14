# Aa-registeret scratch-org snapshot — 2026-11-14

This is a dated, partial snapshot of read-only checks against the non-production
scratch org `crm-arbeidsforhold`. It records only the observations below; it is
not a complete org inventory or a sign-off.

## Installed packages

Command: `sf package installed list --target-org crm-arbeidsforhold`

The CLI returned 19 installed-package rows:

| Package                         | Installed version |
| ------------------------------- | ----------------- |
| `crm-platform-email-scheduling` | `1.8.0.2`         |
| `crm-shared-timeline`           | `1.45.0.3`        |
| `crm-henvendelse`               | `0.209.0.2`       |
| `crm-journal-utilities`         | `0.55.0.1`        |
| `crm-platform-oppgave`          | `0.84.0.5`        |
| `crm-shared-user-notification`  | `0.27.0.2`        |
| `crm-shared-flowComponents`     | `0.4.0.3`         |
| `crm-platform-access-control`   | `0.179.0.1`       |
| `crm-platform-base`             | `0.311.0.3`       |
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

The tabular output did not expose a warnings array. Package IDs, version IDs,
and user fields are intentionally omitted. Compare this list with the 19 direct
dependencies declared in [`sfdx-project.json`](../../sfdx-project.json) and the
dated analysis in [`pakkeavhengigheiter.md`](./pakkeavhengigheiter.md); do not
treat a matching count alone as proof that package ownership or API use has
been verified.

All 19 installed versions fit the version series declared in the manifest. In
comparison with the dated `2026-10-24` dependency report, three installed
versions are newer: `crm-platform-base` is `0.311.0.3` rather than `0.311.0.1`,
`crm-platform-integration` is `0.177.0.4` rather than `0.176.0.1`, and
`crm-platform-oppgave` is `0.84.0.5` rather than `0.84.0.1`. The other 16
installed versions match that report. This comparison says nothing about
runtime API use or behavioral compatibility.

## Flow definitions

Command:

```text
sf data query --use-tooling-api --target-org crm-arbeidsforhold --query "SELECT DeveloperName, ActiveVersionId, LatestVersionId FROM FlowDefinition WHERE DeveloperName LIKE 'AAREG_%'" --json
```

The query completed with `totalSize: 36`, `done: true`, and an empty warnings
array. Of these, 34 have an `ActiveVersionId` and 2 have a null
`ActiveVersionId`. Version IDs are intentionally omitted.

The local source inventory has 37 `.flow-meta.xml` files. Exact
DeveloperName-to-filename comparison confirms that all 36 org definitions
returned by this query match the 36 local Flow files whose names start with
`AAREG`. Of these, 34 have active versions matching their latest versions; the
two definitions without an active version are the local source files marked
`Obsolete`: `AAREG_deactivateAccess` and `AAREG_getObjectTypeName`. The
remaining local file, `updateApplicationStatusOnCasehandlerStatusAdditionalInformationRequired`,
does not match the query filter and its org status is not established by this
query. See the [Flow source-org reconciliation](./aareg-flow-org-source-reconciliation-2026-11-14.md)
for the exact scope and remaining evidence gaps.

## Scheduled jobs

Command:

```text
sf data query --target-org crm-arbeidsforhold --query "SELECT CronJobDetail.Name, State, NextFireTime, PreviousFireTime FROM CronTrigger WHERE CronJobDetail.Name LIKE 'AAREG%' OR CronJobDetail.Name LIKE 'P360%'" --json
```

The query completed with `totalSize: 1`, `done: true`, and an empty warnings
array. The only matching row was `AAREG_deleteDraftInquiriesANDRelatedDocuments-1`,
in `WAITING` state, with next fire time `2026-11-14T23:30:00.000+0000` and
previous fire time `2026-11-13T23:30:03.250+0000`. No P360-named scheduled job
was returned by this query. This is a point-in-time observation, not proof
that no other scheduling mechanism exists.

## P360 archive processing flag

Command:

```text
sf data query --target-org crm-arbeidsforhold --query "SELECT DeveloperName, Is_Enabled__c, Required_Custom_Permission__c FROM Feature_Flag__mdt WHERE DeveloperName = 'P360_Archive_Processing'" --json
```

The query completed with `totalSize: 1`, `done: true`, and an empty warnings
array. `P360_Archive_Processing` has `Is_Enabled__c = false` and
`Required_Custom_Permission__c = null` in this snapshot.

## Still to verify

- Reconcile the 37 local Flow files with the 36 org definitions by developer
  name and explain the unmatched item.
- Reconcile all installed package versions with the manifest and source
  call-site inventory.

The command results and their evidence limits are also tracked in
[issue 1182](https://github.com/navikt/crm-arbeidsforhold/issues/1182).
