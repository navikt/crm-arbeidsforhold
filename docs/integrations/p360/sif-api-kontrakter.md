---
tittel: P360 SIF API-kontrakter for Case, Document og File
status: extracted and represented by internal DTOs; environment validation open
kilde: docs/integrations/p360/source/sif-api.pdf
hentet: 2026-09-12
github-issue: 1008
---

# P360 SIF API-kontrakter

Dette dokumentet er et repo-lokalt oppslag basert på `sif-api.pdf`, utgitt av Tietoevry Industry for Public 360. Det beskriver kontraktene som er relevante for Aa-registeret-integrasjonen, uten å legge inn miljøspesifikke URL-er, AuthKey, tokens eller credentials.

PDF-en er kjelda for SIF-namn og felt. Salesforce-namna under er implementerte interne DTO-namn med fokuserte serialiseringstestar. Dei skal ikkje forvekslast med ein miljøverifisert ekstern SIF wire-kontrakt.

## Implementeringsstatus

- DTO-ar for dokumenterte delar av `CreateCase`, `UpdateCase`, `GetCases`, `CreateDocument`, `GetDocuments` og File-parameteren er implementerte.
- Kontakt-, permission-, additional-field-, case-result- og document-result-kontraktar er implementerte som avgrensa DTO-slicer.
- Adapter og RPC-klient stoppar kontrollert før callout.
- Endpoint, auth, RPC-envelope, mapping, code tables og P360-feilkodar er ikkje implementerte.
- Intern Salesforce-idempotens og første `ApplicationDocument`-jobb er implementert; ekstern P360-recovery er ikkje stadfesta.

Sjå [teknisk oversikt](teknisk-oversikt.md) for samanheng og diagram.

## Første integrasjonsomfang

### Fase 1: nødvendige operasjoner

| SIF-service      | Operasjon        | Formål                                                          |
| ---------------- | ---------------- | --------------------------------------------------------------- |
| Case service     | `CreateCase`     | Opprette P360-sak                                               |
| Case service     | `UpdateCase`     | Oppdatere P360-sak                                              |
| Case service     | `GetCases`       | Finne eksisterende sak ved oppslag/gjenopptaking                |
| Document service | `CreateDocument` | Opprette journalpost/dokumentmetadata på sak                    |
| Document service | `UpdateDocument` | Oppdatere dokumentmetadata                                      |
| Document service | `GetDocuments`   | Oppslag av dokumentmetadata og eventuelle filer                 |
| File service     | `Upload`         | Laste opp fil midlertidig før `CreateDocument`/`UpdateDocument` |

### Senere eller betingede operasjoner

- `SignOffDocument`: signere innkommende dokument med response code.
- `DispatchDocuments`: starte utsendelsesflyt.
- `Upload large file`: separat `/v2/support/Uploadfile`-endpoint for store filer.
- `CreateFileFromTemplate`: brukes via Document-service sin `FilesFromTemplate`-parameter.

Fase 1 bør starte med `CreateCase`, `CreateDocument` og `Upload`. `Update*` og `Get*` trengs for idempotens, recovery og statusavstemming, men bør implementeres bak samme adaptergrense.

## Transport-endepunkter fra PDF-en

PDF-en viser følgende mønstre:

| Service  | SOAP                                                          | REST                                                         | RPC                                                                                          |
| -------- | ------------------------------------------------------------- | ------------------------------------------------------------ | -------------------------------------------------------------------------------------------- |
| Case     | `http://[servername]:4000/SI.WS.Core/SIF/CaseService.svc`     | `http://[servername]:4000/SI.WS.Core/SIFREST/api/cases/`     | `https://[customer-specific-domain]/Biz/v2/api/call/SI.Data.RPC/SI.Data.RPC/CaseService`     |
| Document | `http://[servername]:4000/SI.WS.Core/SIF/DocumentService.svc` | `http://[servername]:4000/SI.WS.Core/SIFREST/api/documents/` | `https://[customer-specific-domain]/Biz/v2/api/call/SI.Data.RPC/SI.Data.RPC/DocumentService` |
| File     | `http://[servername]:4000/SI.WS.Core/SIF/FileService.svc`     | `http://[servername]:4000/SI.WS.Core/SIFREST/api/files/`     | `https://[customer-specific-domain]/Biz/v2/api/call/SI.Data.RPC/SI.Data.RPC/FileService`     |

The SOAP bridge URLs are deprecated from SIF v5.14. The actual customer-specific RPC domain remains environment configuration and must not be hardcoded.

## RPC invocation contract

The SIF PDF gives the RPC URL pattern as:

```text
https://[customer-specific-url]/Biz/v2/api/call/SI.Data.RPC/SI.Data.RPC/[service]/[operation]?authkey=[auth-key]
```

For this integration the service/operation path is expected to be one of:

```text
CaseService/CreateCase
CaseService/UpdateCase
CaseService/GetCases
DocumentService/CreateDocument
DocumentService/UpdateDocument
DocumentService/GetDocuments
FileService/Upload
```

The PDF recommends sending `authkey` in a request header instead of exposing it in the URL. The exact header name and the Salesforce Named Credential/External Credential arrangement must be confirmed for the NAV environment before implementation.

The PDF also documents:

- Swagger: `https://[customer-specific-domain]/Biz/v2/api/swagger/SI.Data.RPC`
- Postman examples: `https://github.com/Public360/sif-rpc-postman-examples`

The public Postman collection adds these RPC wire-format details:

- Method: `POST`.
- Header: `Content-Type: application/json`.
- Request body wrapper: `{"parameter": { ... }}`.
- `authkey` is present as a URL query parameter in the examples, while the SIF PDF recommends moving it to a request header for security.
- Case, Document and File calls use the same wrapper and service/operation URL pattern.
- `CreateDocument` examples show both `Files[].UploadedFileReference` and inline `Files[].Base64Data`.
- `FileService/Upload` uses `FileData`, `FileName` and `FileFormat`.
- `GetDocuments` is a POST with filter fields inside `parameter`, including `DocumentNumber` and `CaseExternalId` examples.

The Postman collection is a usage example, not the environment's security decision. The Salesforce implementation should not put a real auth key in a URL or repository source.

The PDF does not define the Salesforce-side OAuth/Entra configuration. The repo's earlier OAuth/Entra description must be reconciled with the concrete P360 endpoint configuration; no credential or token assumptions should be implemented from this PDF alone.

## Shared rules

- SIF data contracts accept code values or `recno` for many code-table fields.
- If a field supports both code and `recno`, the implementation must preserve the documented precedence and format. The PDF uses examples such as `recno:60001`.
- Properties set to `null` on update are not changed. For supported string fields, an explicit empty string clears the field.
- `ADContextUser`/`ADUserContext` represents the authenticated 360 user context and is a required security boundary for the relevant operations.
- The SIF PDF defines the RPC URL with `[service]/[operation]` and an `authkey`; it recommends sending the auth key in a request header rather than the URL.
- File service operations require `User`; the uploaded file is stored in that user's 360 cache and the same user must be used when the file is referenced later.
- Results contain a success indicator or identifiers plus short and detailed error fields where documented.
- The PDF contains no environment secrets. AuthKey, OAuth tokens and customer credentials belong in approved Salesforce credential configuration.

## Case service

### `CreateCase`

**SIF contract:** `CreateCaseParameter` → `CaseOperationResult`.

#### Input fields

| Field                         | Required    | Meaning / rule                                                         |
| ----------------------------- | ----------- | ---------------------------------------------------------------------- |
| `ADContextUser`               | Context     | Authentication and 360 user context.                                   |
| `Title`                       | Yes         | Case description/title.                                                |
| `UnofficialTitle`             | No          | If omitted, `Title` is used.                                           |
| `ExternalId`                  | No          | External ID for the case.                                              |
| `ExternalSystem`              | No          | External ID type; default is `SIF WS Case`.                            |
| `ExternalName`                | No          | Optional name of the external key.                                     |
| `StartDate`                   | No          | Defaults to case creation date.                                        |
| `Status`                      | No          | Case status code or `recno`; closing status requires archive code.     |
| `ClosedDate`                  | Conditional | Used with closing status; otherwise ignored.                           |
| `JournalUnit`                 | No          | Code or `recno`, e.g. `Sentralarkiv`.                                  |
| `SubArchive`                  | No          | Code or `recno`, e.g. `Sakarkiv` or `recno:60001`.                     |
| `ArchiveCodes`                | Conditional | Required to close a case; list of `ClassCodeParameter`.                |
| `FiledOnPaper`                | No          | Boolean.                                                               |
| `Keywords`                    | No          | List of keyword values.                                                |
| `AccessCode`                  | Conditional | Code or `recno`; some values require `Paragraph`.                      |
| `Paragraph`                   | Conditional | Code value only; required for some access codes.                       |
| `AccessGroup`                 | Conditional | Code or `recno`; e.g. `Public`.                                        |
| `Notes`                       | No          | Case notes.                                                            |
| `CaseType`                    | No          | Code or `recno`; default is Noark case, recno 2.                       |
| `ResponsiblePerson*`          | Conditional | Exactly one of ID number, recno, email or user ID.                     |
| `ResponsibleEnterpriseNumber` | Conditional | Responsible enterprise external/reference number.                      |
| `ResponsibleEnterpriseRecno`  | Conditional | Fallback enterprise recno.                                             |
| `Contacts`                    | No          | Existing contacts with roles.                                          |
| `UnregisteredContacts`        | No          | Unregistered contacts with roles.                                      |
| `ReferringCases`              | No          | Referring case numbers.                                                |
| `Project`                     | No          | Project number.                                                        |
| `Remarks`                     | No          | List of title/content/type notes; remark type is mandatory per remark. |
| `ScrapCode`                   | No          | Code or `recno`.                                                       |
| `Category`                    | No          | Code or `recno`.                                                       |
| `Estates`                     | No          | Existing estates to connect.                                           |
| `AdditionalFields`            | No          | Additional single-value fields.                                        |
| `AdditionalListFields`        | No          | Additional multi-value fields.                                         |
| `DefaultValueSet`             | No          | Default value set.                                                     |
| `ProgressPlanId`              | No          | Progress plan recno, workunit ID or description.                       |
| `Permissions`                 | No          | Row permissions.                                                       |
| `eArchiveXMLFragment`         | Versioned   | Available from 5.11 and only used on eArchive installations.           |
| `ImportedCaseNumber`          | Versioned   | Available from 5.12.                                                   |

#### Output: `CaseOperationResult`

- `Recno`: unique 360 case ID.
- `CaseNumber`: case number assigned by 360.
- `ImportedCaseNumber`: eArchive imported number when applicable.
- `UID`: globally unique identifier.
- `UIDOrigin`: origin of UID.
- `ErrorMessage`: short error message on failure.
- `ErrorDetails`: detailed error/stack information on failure.

### `UpdateCase`

**SIF contract:** `UpdateCaseParameter` → `CaseOperationResult`.

Identity must use exactly one of:

- `CaseNumber`
- `ExternalId` plus optional `ExternalSystem` type

Important rules:

- Case number cannot be changed.
- `null` means no update; explicit empty string clears supported string fields.
- Closed cases require archivist permissions.
- Archive codes cannot be modified after case creation through this operation.
- `SyncCaseContacts`, `SyncCaseEstates` and `SyncArchiveCodes` control synchronization behavior and default to false.
- `RemoveResponsiblePerson` explicitly removes responsible person and defaults to false.

Output contains `Recno`, `CaseNumber`, `Successful`, `ErrorMessage` and `ErrorDetails`.

### `GetCases`

**SIF contract:** query parameter contract → list of `CaseResult`.

The operation retrieves cases matching all nonblank criteria. Relevant filters documented by the PDF include:

- `Type`
- `Title`
- `ArchiveCode`
- `ProjectNumber`
- `CategoryCode`
- `LastDate`
- `ContactReferenceNumber`
- `ContactExternalId`
- `ContactRecnos`
- `ExternalSystem`
- `SubArchive`
- `CaseType`
- `DateCriteria`
- `AdditionalFields`
- `OnlyPublicInfo`
- `IncludeReferringCases`
- `IncludeReferringDocuments`
- `IncludeCaseContacts`
- `IncludeCustomFields`
- versioned flags such as `AdditionalRelations`, `IncludeRemarks`, `IncludeKeywords`, `IncludeMilestones`, `MyCasesConfig`, `UID`, `UIDOrigin` and `IncludeStages`

The response uses `CaseResult` and related subcontracts such as `CaseContactResult`, `CaseDocumentResult`, `CaseDocumentFileResult`, `DocumentCategoryResult`, `RemarkInfo`, `Keyword`, `Milestone`, `CaseProgressPlanActivityResult` and `Stage`.

## Shared Case/Document subcontracts

### `ClassCodeParameter`

Used by Case and Document `ArchiveCodes`.

- `Sort` is required and starts at 1; primary classification is 1.
- `ArchiveType` is required and accepts code or `recno`.
- `IsManualText` indicates whether the value is user-supplied text.
- `ArchiveCode` is the classification value or code, including `recno:...` when applicable.

### Contacts

Case contacts use `CaseContactParameter`; document contacts use `DocumentContactParameter`.

Common rules:

- `Role` is required and accepts code or `recno`.
- A registered contact can be identified by a reference number, external ID or recno according to the service contract.
- `IsUnofficial` controls screening from the public journal and must not be set for unclassified access code `U`.
- Unregistered contacts require `ContactName`; optional data includes company, reference number, address, country, state, postal data, email and phone.
- Document contacts also support `DispatchChannel`.
- Case contact results expose contact name, role, recno, reference number, type, address, external ID and optional subject/action metadata.
- Document contact results expose reference number, external ID, role, search name, contact recno, address, email, contact domain and unofficial flag.

### `Permission`

Used for Case and Document row permissions.

- Identity is by `AccessGroup` or `ContactExternalId`.
- `AccessLevel` accepts `AccessLevel`, `Read`, `Insert`, `Edit` or `Delete`; default is `Read`.
- `Grant` controls whether the right is granted.
- Document-specific rights include `ViewFile`, `InsertFile`, `ModifyFile`, `InsertRev` and `ModifyRev`.
- Case-specific right includes `InsertDoc`.
- `Reference` is the permission description; the PDF default is `SIF`.

### Additional fields

`AdditionalFieldParameter` supports single-value fields using `Name`, `Value` and optional `OperatorType` for Get operations. Supported operators include `=`, `!=`, `LIKE`, `GT`, `GT=`, `LT=`, `IS NULL` and `IS NOT NULL`.

`AdditionalFieldListParameter` supports multi-value fields using `Name` and a list of values. Unknown field names are ignored by 360 rather than returned as errors. These fields should only be used after consulting the 360 meta model.

## Document service

### `CreateDocument`

**SIF contract:** `CreateDocumentParameter` → `DocumentOperationResult`.

#### Input fields

| Field                         | Required    | Meaning / rule                                                        |
| ----------------------------- | ----------- | --------------------------------------------------------------------- |
| `ADUserContext`               | Context     | Authentication and 360 user context.                                  |
| `Title`                       | Yes         | Document title.                                                       |
| `UnofficialTitle`             | No          | If omitted, `Title` is used.                                          |
| `DocumentDate`                | No          | Document date.                                                        |
| `Archive`                     | No          | Archive code or `recno`; default is `Saksdokument`, recno 2.          |
| `Category`                    | Yes         | Document category code or `recno`.                                    |
| `Status`                      | Yes         | Journal status code or `recno`.                                       |
| `CaseNumber`                  | Conditional | Case number to connect document to. Exactly one case identity method. |
| `CaseExternalId`              | Conditional | Case external ID; alternative to `CaseNumber`.                        |
| `ExternalId`                  | No          | External ID for the document.                                         |
| `ExternalSystem`              | No          | External ID type; default is `SIF WS Document`.                       |
| `ExternalName`                | No          | Optional external key name.                                           |
| `ResponsiblePerson*`          | Conditional | Exactly one of ID number, recno, email or user ID.                    |
| `ResponsibleEnterpriseNumber` | Conditional | Responsible enterprise number.                                        |
| `ResponsibleEnterpriseRecno`  | Conditional | Fallback enterprise recno.                                            |
| `Contacts`                    | Conditional | Existing document contacts with roles.                                |
| `UnregisteredContacts`        | No          | Unregistered document contacts.                                       |
| `SendersReference`            | No          | External reference number.                                            |
| `AccessCode`                  | Conditional | Code or `recno`; may require `Paragraph`.                             |
| `Paragraph`                   | Conditional | Code value only.                                                      |
| `AccessGroup`                 | No          | Code or `recno`.                                                      |
| `JournalDate`                 | Conditional | Closing/journal date.                                                 |
| `DispatchedDate`              | No          | Must be after `DocumentDate` and before `JournalDate`.                |
| `FiledOnPaper`                | No          | Boolean.                                                              |
| `Keywords`                    | No          | Keyword values.                                                       |
| `Notes`                       | No          | Document notes.                                                       |
| `ReferringCases`              | No          | Case numbers to reference.                                            |
| `ReferringDocuments`          | No          | Document numbers to reference.                                        |
| `FilesFromTemplate`           | No          | Template IDs.                                                         |
| `Files`                       | No          | List of `File` contracts; can refer to File-service uploads.          |
| `Remarks`                     | No          | Notes with title/content/type.                                        |
| `Project`                     | No          | Project number.                                                       |
| `AdditionalFields`            | No          | Additional single-value fields.                                       |
| `AdditionalListFields`        | No          | Additional multi-value fields.                                        |
| `DefaultValueSet`             | No          | Default value set.                                                    |
| `SubArchive`                  | No          | Code or `recno`.                                                      |
| `ArchiveCodes`                | No          | List of class-code parameters.                                        |
| `RecordType`                  | No          | Code or `recno`.                                                      |
| `Permissions`                 | No          | Row permissions.                                                      |
| `SignOffWithResponseCode`     | No          | Boolean; signs off incoming document when true.                       |
| `ResponseCode`                | Conditional | Required with sign-off and must be valid response-code value.         |
| `eArchiveXMLFragment`         | Versioned   | eArchive-only virtual data.                                           |
| `ImportedDocumentNumber`      | Versioned   | eArchive imported document number.                                    |
| `RunFilesInDocumentBatch`     | Versioned   | Controls file insertion batching.                                     |
| `SearchUnregisteredDocument`  | Versioned   | Searches unregistered document archive.                               |
| `UnregisteredDocumentOrigin`  | Versioned   | Origin used with unregistered-document search.                        |

#### Date rules

The PDF states:

- `DocumentDate` must be before `DispatchedDate` and `JournalDate`.
- `DispatchedDate` must be after `DocumentDate` and before `JournalDate`.
- `JournalDate` must be after both.

#### Output: `DocumentOperationResult`

- `Recno`: unique 360 document ID.
- `DocumentNumber`: document number assigned by 360.
- `ImportedDocumentNumber`: eArchive imported number.
- `UID`: globally unique identifier.
- `UIDOrigin`: origin of UID.
- `ErrorMessage`: short error message.
- `ErrorDetails`: detailed error/stack information.

#### Document errors explicitly documented

- Categories requiring an external recipient fail unless a contact or unregistered contact with `Recipient` role is provided.
- Categories requiring an external sender fail unless a contact or unregistered contact with `Sender` role is provided.

### `UpdateDocument`

Identity must use exactly one of the supported document identity combinations, principally document number or external ID/type. `null` fields are not updated; explicit empty strings clear supported string fields.

The update contract supports metadata, contacts, case references, files, remarks, permissions, `ExternalId`, `ExternalSystem`, `SyncDocumentContacts` and related document fields.

### `GetDocuments`

The operation retrieves document metadata and can also return file metadata. The PDF documents filters including:

- `Type`
- `DocumentNumber`
- `Title`
- `LastDate`
- `DocumentArchive`
- `ContactReferenceNumber`
- `ContactExternalId`
- `ContactRecnos`
- `ExternalSystem`
- additional document filters and include flags

The response uses `DocumentResult`, `DocumentContactResult`, `File`, `ClassCodeParameter` and related subcontracts.

## Document `File` contract

The `File` contract is used inside `CreateDocument` and `UpdateDocument`. A file can contain data directly or refer to a previous File-service upload.

- `Title` is required.
- `Format` is required and accepts code or `recno`.
- `Data` is the preferred byte-array file content.
- `Base64Data` is supported but semi-deprecated.
- `UploadedFileReference` is the reference returned by `FileService/Upload`.
- `RelationType` accepts code or `recno`.
- `VersionFormat` accepts code or `recno`.
- Optional metadata includes `Note`, `Category`, `Status`, `AccessCode`, `DegradeCode`, `DegradeDate`, `FiledOnPaper`, `PaperLocation`, `AdditionalFields`, `ExternalId` and `ExternalSystem`.

The first concrete cross-service flow is:

```text
FileService.Upload(FileData, User, FileName, FileFormat)
	-> UploadFileResult.FileReference
	-> DocumentService.CreateDocument.Files[].UploadedFileReference
```

## File service

### `Upload`

**SIF contract:** `Upload` → `UploadFileResult`.

`Upload` streams a file to the 360 server's temporary cache. The returned `FileReference` is then used by `CreateDocument` or `UpdateDocument`.

#### Input fields

| Field        | Required             | Meaning / rule                                                                                       |
| ------------ | -------------------- | ---------------------------------------------------------------------------------------------------- |
| `FileData`   | Yes for RPC          | File data as byte array. SOAP uses `FileStream` as a stream.                                         |
| `User`       | Yes                  | Must be the same 360 user used for `ADContextUser`/authentication when the file is referenced later. |
| `FileName`   | Strongly recommended | Include file extension.                                                                              |
| `FileFormat` | Recommended          | Controls file variant/format when supplied.                                                          |

If neither `FileName` with extension nor `FileFormat` is supplied, the file defaults to production format regardless of the `Format` value later used in document operations.

#### Output: `UploadFileResult`

- `Successful`: whether upload succeeded.
- `FileReference`: temporary file reference for Document-service `Files`/`UploadedFileReference` usage.
- `ErrorMessage`: short error message.
- `ErrorDetails`: detailed error/stack information.

### Large files

The PDF documents a separate `/v2/support/Uploadfile` endpoint configured through 360° web administration. This is a later-phase option and must not be confused with SIF `FileService/Upload`.

## Proposed internal DTO mapping

These names are repo-internal proposals and should be implemented only after review:

| SIF contract              | Proposed Apex DTO                                                      |
| ------------------------- | ---------------------------------------------------------------------- |
| `CreateCaseParameter`     | `P360_CreateCaseRequestDto`                                            |
| `CaseOperationResult`     | `P360_CreateCaseResponseDto` or shared `P360_CaseOperationResponseDto` |
| `UpdateCaseParameter`     | `P360_UpdateCaseRequestDto`                                            |
| `GetCases` criteria       | `P360_GetCasesRequestDto`                                              |
| `CaseResult`              | `P360_CaseResultDto`                                                   |
| `CreateDocumentParameter` | `P360_CreateDocumentRequestDto`                                        |
| `DocumentOperationResult` | `P360_DocumentOperationResponseDto`                                    |
| `UpdateDocumentParameter` | `P360_UpdateDocumentRequestDto`                                        |
| `GetDocuments` criteria   | `P360_GetDocumentsRequestDto`                                          |
| `DocumentResult`          | `P360_DocumentResultDto`                                               |
| `Upload`                  | `P360_UploadFileRequestDto`                                            |
| `UploadFileResult`        | `P360_UploadFileResponseDto`                                           |

The existing `P360_ArchiveRequestDto` and `P360_RpcRequest` are F2 placeholders and should not be silently treated as the final operation DTOs.

## Still required before production transport

The PDF supplies the operation contracts and endpoint patterns, but the project still needs environment-specific confirmation for:

- customer-specific RPC domain and test/prod endpoints
- actual auth mechanism and AuthKey/header configuration
- Entra audience/scope if OAuth is used in this deployment
- serialization/envelope details for the selected RPC transport
- Salesforce-to-SIF mapping for Application, Agreement, case, document and file
- code-table values for CaseType, Category, Status, Archive, AccessCode and JournalUnit
- retry/idempotency policy and storage of returned `Recno`, case/document number and UID
- file size limits and whether large-file endpoint is required for MVP

## Source references

- SIF API PDF, pages 66-74: Case service.
- SIF API PDF, pages 93-99: Document service and `CreateDocument`.
- SIF API PDF, pages 100-114: Document update/get operations and subcontracts.
- SIF API PDF, pages 137-140: File service `Upload` and large-file endpoint.
- SIF API PDF, pages 81-92: Case subcontracts, class codes, permissions and additional fields.
- SIF API PDF, pages 114-124: Document contacts, DocumentResult, File and Document class-code contracts.
- [P360 SIF contract lookup](sif-rpc-kontrakt-oppslag.md)
- [P360 SIF operations](sif-rpc-operasjonar.md)
