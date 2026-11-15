---
slug: p360-update-document-dtos
status: in-progress
jira-subtask: CRMAAREG-110
github-issue: 1174
---

# P360 UpdateDocument DTOs

## Source and boundary

The [SIF API source](../../docs/integrations/p360/source/sif-api.pdf), pages 100–104, defines `UpdateDocumentParameter` and its `DocumentOperationResult`. This slice adds internal DTOs only; their JSON is not the SIF request envelope.

## Field selection

The request contains:

- Context and identity: `adUserContext`, `documentNumber`, `externalId` and `externalSystem`.
- Document fields: `title`, `unofficialTitle`, `documentDate`, `category`, `status`, `accessCode`, `paragraph`, `accessGroup`, `journalDate`, `dispatchedDate` and `filedOnPaper`.
- Contact updates: `contacts`, `unregisteredContacts`, `syncDocumentContacts` and `removeResponsiblePerson`.
- Added files: `files`.

The contact and file lists reuse `P360_ContactParameterDto`, `P360_UnregisteredContactParameterDto` and `P360_FileParameterDto`. Remaining optional SIF fields are outside this slice.

SIF requires one document identity: either `DocumentNumber` or nested `ExternalId.Id`, with optional `ExternalId.Type`. The service defaults the type to `SIF WS Document` when omitted; the DTO itself does not apply that default. The internal DTO keeps these nested fields as `externalId` and `externalSystem`. `adUserContext` is context-dependent; authentication is outside this slice.

The selected update fields are optional. The DTO does not enforce identity or other SIF rules. A future mapper must construct the SIF shape. SIF can add files when `DocumentNumber` is supplied, but cannot update or delete existing files through this operation. Contact synchronization can remove existing contacts when enabled.

The response contains `recno`, `documentNumber`, `successful`, `errorMessage` and `errorDetails`, as documented for this operation.

## Serialization and validation

- DTO fields have no default values or business validation.
- A null update field means no change in SIF; an explicit empty string clears a supported string field. Tests cover both, including null suppression with `JSON.serialize(value, true)`.
- Tests cover each identity alternative, selected update and nested fields, and successful and failed results with synthetic data.
- Mapping, SIF envelope creation, transport, authentication, SOQL, DML, callouts and file upload are out of scope.

Tracking: [GitHub issue #1174](https://github.com/navikt/crm-arbeidsforhold/issues/1174) and [CRMAAREG-110](https://nav.atlassian.net/browse/CRMAAREG-110).
