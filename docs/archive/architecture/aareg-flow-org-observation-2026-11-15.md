# Flow org observation — 2026-11-15

> **Arkivert observasjon:** Gjeld berre den dokumenterte kontrollen, ikkje noverande org-tilstand.

This is a dated, read-only observation of `crm-arbeidsforhold`. It supplements
the [2026-11-14 source reconciliation](./aareg-flow-org-source-reconciliation-2026-11-14.md);
it does not replace it or establish that both observations came from the same
scratch-org instance.

## Target and scope

The checks ran through the VS Code host terminal, targeting only
`crm-arbeidsforhold`. The terminal showed the target as a scratch org, and
`SELECT IsSandbox FROM Organization` returned `true`. No org ID or URL is
recorded. The repository rules allow use of this verified existing scratch org
without renewed approval; no other org was accessed.

The local terminal time was approximately 10:51–10:55 CET on 2026-11-15.
Commands were read-only. No Flow was started, no records were changed, and no
external integration was invoked.

## FlowDefinition result

The following Tooling API query completed successfully:

```text
SELECT DeveloperName, ActiveVersionId, LatestVersionId
FROM FlowDefinition
WHERE DeveloperName LIKE 'AAREG_%'
   OR DeveloperName = 'updateApplicationStatusOnCasehandlerStatusAdditionalInformationRequired'
```

Result: 37 definitions. Two have no active version:
`AAREG_deactivateAccess` and `AAREG_getObjectTypeName`. For all definitions
with an active version, `ActiveVersionId` equals `LatestVersionId`; no
active/latest drift was found.

## Interpretation limits

- The 2026-11-14 reconciliation records 37 local Flow files and an exact
  DeveloperName match for the then-observed org. This query confirms 37
  definitions and their active/latest pointers in the current target, but did
  not capture a fresh exact-name set comparison.
- Scratch-org instance continuity between dated observations remains
  unverified. Matching counts do not prove matching names or metadata bodies.
- Active/latest pointers do not prove that a Flow runs correctly. No Flow
  runtime behavior, screen-flow binding, or metadata-body equality was tested.
- The two definitions without an active version are observations, not a
  recommendation to delete or activate them.

## Evidence

- Target check: `sf org display --target-org crm-arbeidsforhold --json`
  completed with status `0`; the resolved alias was `crm-arbeidsforhold`.
- Sandbox check: `sf data query --query "SELECT IsSandbox FROM Organization" --target-org crm-arbeidsforhold --json`
  completed with status `0`; `IsSandbox` was `true`.
- Flow check: `sf data query --use-tooling-api --query "<query above>" --target-org crm-arbeidsforhold --json`
  completed with status `0`; the compact result was
  `{"n":37,"noActive":["AAREG_deactivateAccess","AAREG_getObjectTypeName"],"drift":[]}`.

This observation is relevant to [Issue #1182](https://github.com/navikt/crm-arbeidsforhold/issues/1182).
