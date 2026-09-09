---
slug: p360-create-document-dtos
status: active
jira-epic: CRMAAREG-83
jira-user-story: CRMAAREG-101
jira-subtasks: CRMAAREG-109, CRMAAREG-113
github-issue: 1010
---

# P360 CreateDocument DTOs

## Problem statement

The SIF PDF defines `CreateDocumentParameter`, `DocumentOperationResult` and the nested `File` contract, while the repository previously had only temporary archive and RPC wrappers.

## Desired outcome

The Salesforce integration has explicit internal DTOs for the first Document/File create boundary, including the FileService upload reference flow, without implementing transport or mapping.

## Implemented scope

- `P360_CreateDocumentRequestDto`
- `P360_CreateDocumentResponseDto`
- `P360_FileParameterDto`
- Core document metadata, case identity, external identity, date fields and file references.
- Both `UploadedFileReference` and inline `Base64Data` are represented in the file DTO.
- JSON round-trip test coverage.

## Acceptance criteria

- CreateDocument request fields survive JSON serialization/deserialization.
- File fields preserve title, format and uploaded file reference.
- CreateDocument response fields preserve recno, document number, imported number, UID and UID origin.
- DTOs use the repository `P360_` naming convention.
- No endpoint, auth header, SIF envelope, SOQL, DML or callout is introduced.

## Out of scope

- Document contacts, unregistered contacts, permissions and additional fields.
- UpdateDocument/GetDocuments DTOs.
- FileService transport implementation and large-file endpoint.
- Salesforce-to-P360 mapping.
