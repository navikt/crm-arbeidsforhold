/**
 * Builds the complete P360 archive request for a submitted Aa-registeret application.
 * The document contains a generated organisation-level summary file followed by every current attachment
 * linked to the application. A new case is requested only when the access request has no P360 case number.
 *
 * Internal choices (configurable, pending confirmation by the P360 team): the external system defaults to
 * `Salesforce Aa-registeret` and can be overridden by `P360_Integration_Setting__c.External_System__c`;
 * the case identity is `ACCESS_REQUEST:<id>`; the document identity is the archive job idempotency key.
 *
 * Data access: the archive source (the application, its access request case number and its linked files) is read
 * in system mode without sharing, limited to the application referenced by the claimed archive job. The processing user is
 * therefore not granted record or field access to applications, access requests or files.
 *
 * @author Kenneth Sørensen
 * @since 2026-11
 * @group P360 Mapper
 */
public with sharing class AAREG_ApplicationArchiveRequestBuilder {
    /** External system used when no override is configured. */
    public static final String DEFAULT_EXTERNAL_SYSTEM = 'Salesforce Aa-registeret';

    @TestVisible
    private static final Integer MAX_INLINE_BASE64_LENGTH = 4000000;
    private static final String CASE_EXTERNAL_ID_PREFIX = 'ACCESS_REQUEST:';
    private static final String TITLE = 'Søknad om tilgang til Aa-registeret';

    private final P360_ICodeTableService codeTableService;

    /**
     * Creates a builder that resolves P360 defaults from the code-table custom metadata.
     */
    public AAREG_ApplicationArchiveRequestBuilder() {
        this(new P360_CodeTableMetadataService());
    }

    /**
     * Creates a builder with an injected code-table service.
     *
     * @param codeTableService Service used to resolve P360 default values.
     */
    public AAREG_ApplicationArchiveRequestBuilder(P360_ICodeTableService codeTableService) {
        this.codeTableService = codeTableService;
    }

    /**
     * Builds the archive request for one application document job.
     *
     * @param job Archive job with `Application__c`, `Idempotency_Key__c` and `Correlation_Id__c`.
     * @return Archive request with CreateDocument and, for a new case, CreateCase parameters.
     * @throws P360_ContractException When the application cannot be read or the files exceed the inline limit.
     * @throws P360_MissingCodeTableMappingException When a P360 default value is not configured or readable.
     */
    public P360_ArchiveRequestDto build(P360_Archive_Job__c job) {
        try {
            return buildRequest(job);
        } catch (P360_IntegrationException integrationError) {
            throw integrationError;
        } catch (Exception unexpectedError) {
            throw new P360_ContractException(
                'Application archive request could not be built: ' + unexpectedError.getTypeName()
            );
        }
    }

    private P360_ArchiveRequestDto buildRequest(P360_Archive_Job__c job) {
        if (job == null || job.Application__c == null || String.isBlank(job.Idempotency_Key__c)) {
            throw new P360_ContractException('Application archive job is incomplete.');
        }
        List<Application__c> applications = new ArchiveSourceReader().application(job.Application__c);
        if (applications.isEmpty() || applications[0].Access_Request__c == null) {
            throw new P360_ContractException('Application archive source is unavailable.');
        }
        Application__c application = applications[0];
        String externalSystem = externalSystem();
        String existingCaseNumber = application.Access_Request__r.P360_Case_Number__c;
        String title = TITLE + ' ' + application.Name;
        Date documentDate = application.ApplicationSubmittedDate__c == null
            ? System.today()
            : application.ApplicationSubmittedDate__c;

        List<ContentVersion> attachments = new ArchiveSourceReader().currentAttachments(application.Id);
        List<AAREG_ApplicationFileToP360FileMapper.Input> files = new List<AAREG_ApplicationFileToP360FileMapper.Input>{
            summaryFile(application, documentDate, attachments.size())
        };
        for (ContentVersion version : attachments) {
            files.add(file(version.Title, version.FileExtension, EncodingUtil.base64Encode(version.VersionData)));
        }
        requireInlineSize(files);

        AAREG_ApplicationToP360DocumentMapper.Input documentInput = new AAREG_ApplicationToP360DocumentMapper.Input();
        documentInput.title = title;
        documentInput.documentDate = documentDate;
        documentInput.caseNumber = existingCaseNumber;
        documentInput.externalId = job.Idempotency_Key__c;
        documentInput.externalSystem = externalSystem;
        documentInput.files = files;

        P360_ArchiveRequestDto request = new P360_ArchiveRequestDto();
        request.correlationId = job.Correlation_Id__c;
        request.externalId = job.Idempotency_Key__c;
        request.title = title;
        request.createDocument = new AAREG_ApplicationToP360DocumentMapper(codeTableService)
            .mapToCreateDocument(documentInput);
        if (String.isBlank(existingCaseNumber)) {
            AAREG_ApplicationToP360CaseMapper.Input caseInput = new AAREG_ApplicationToP360CaseMapper.Input();
            caseInput.title = title;
            caseInput.externalId = CASE_EXTERNAL_ID_PREFIX + application.Access_Request__c;
            caseInput.externalSystem = externalSystem;
            request.createCase = new AAREG_ApplicationToP360CaseMapper(codeTableService).mapToCreateCase(caseInput);
        }
        return request;
    }

    private static AAREG_ApplicationFileToP360FileMapper.Input summaryFile(
        Application__c application,
        Date documentDate,
        Integer attachmentCount
    ) {
        List<String> lines = new List<String>{
            TITLE,
            'Salesforce-søknad: ' + application.Id,
            'Søknadsnummer: ' + valueOrBlank(application.Name),
            'Organisasjon: ' + valueOrBlank(application.AccountName__c),
            'Organisasjonsnummer: ' + valueOrBlank(application.OrganizationNumber__c),
            'Tilgangstypar: ' + valueOrBlank(application.AA_AccessTypes__c),
            'Status: ' + valueOrBlank(application.Status__c),
            'Innsendt: ' + String.valueOf(documentDate),
            'Tal på vedlegg: ' + attachmentCount
        };
        return file(
            'Søknadssamandrag ' + application.Name,
            'txt',
            EncodingUtil.base64Encode(Blob.valueOf(String.join(lines, '\n')))
        );
    }

    private static AAREG_ApplicationFileToP360FileMapper.Input file(String title, String format, String base64Data) {
        AAREG_ApplicationFileToP360FileMapper.Input input = new AAREG_ApplicationFileToP360FileMapper.Input();
        input.title = title;
        input.format = String.isBlank(format) ? null : format.toLowerCase();
        input.base64Data = base64Data;
        return input;
    }

    private static void requireInlineSize(List<AAREG_ApplicationFileToP360FileMapper.Input> files) {
        Integer totalLength = 0;
        for (AAREG_ApplicationFileToP360FileMapper.Input input : files) {
            totalLength += input.base64Data == null ? 0 : input.base64Data.length();
        }
        if (totalLength > MAX_INLINE_BASE64_LENGTH) {
            throw new P360_ContractException('Application files exceed the inline P360 upload limit.');
        }
    }

    private static String externalSystem() {
        P360_Integration_Setting__c settings = P360_Integration_Setting__c.getOrgDefaults();
        return settings == null || String.isBlank(settings.External_System__c)
            ? DEFAULT_EXTERNAL_SYSTEM
            : settings.External_System__c.trim();
    }

    private static String valueOrBlank(Object value) {
        return value == null ? '' : String.valueOf(value);
    }

    /**
     * Reads the archive source independent of the processing user's sharing and field access,
     * limited to the single application referenced by a claimed archive job.
     */
    private without sharing class ArchiveSourceReader {
        List<Application__c> application(Id applicationId) {
            return [
                SELECT
                    Id,
                    Name,
                    AccountName__c,
                    OrganizationNumber__c,
                    ApplicationSubmittedDate__c,
                    AA_AccessTypes__c,
                    Status__c,
                    Access_Request__c,
                    Access_Request__r.P360_Case_Number__c
                FROM Application__c
                WHERE Id = :applicationId
                WITH SYSTEM_MODE
                LIMIT 1
            ];
        }

        List<ContentVersion> currentAttachments(Id applicationId) {
            Set<Id> documentIds = new Set<Id>();
            for (ContentDocumentLink link : [
                SELECT ContentDocumentId
                FROM ContentDocumentLink
                WHERE LinkedEntityId = :applicationId
                WITH SYSTEM_MODE
            ]) {
                documentIds.add(link.ContentDocumentId);
            }
            if (documentIds.isEmpty()) {
                return new List<ContentVersion>();
            }
            return [
                SELECT Title, FileExtension, VersionData
                FROM ContentVersion
                WHERE ContentDocumentId IN :documentIds AND IsLatest = TRUE
                WITH SYSTEM_MODE
                ORDER BY CreatedDate ASC, Id ASC
            ];
        }
    }
}
