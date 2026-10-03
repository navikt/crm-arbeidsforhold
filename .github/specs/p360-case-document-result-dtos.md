---
slug: p360-case-document-result-dtos
status: completed
jira-epic: CRMAAREG-83
jira-user-story: CRMAAREG-101
github-issue: 1009
---

# P360 CaseDocumentResult DTOs

## Problem statement

GetCases can return document metadata and connected files as part of a CaseResult. The integration needs explicit nested result DTOs before document-result mapping is implemented.

## Implemented scope

- `P360_CaseDocumentResultDto`
- `P360_CaseDocumentFileResultDto`
- Document recno, number, title and imported document number
- Nested file recno, title, format and size
- JSON round-trip test coverage

## Acceptance criteria

- Document and file result fields survive JSON serialization/deserialization.
- CaseDocumentResult preserves its nested file list.
- No Salesforce SObject, SOQL, DML, mapping or callout dependency is introduced.

## Out of scope

- Document category result DTO.
- Full CaseResult document-list composition.
- GetCases orchestration and RPC client integration.