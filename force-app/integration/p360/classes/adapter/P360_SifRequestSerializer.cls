/**
 * Serialises P360 request DTOs to the SIF RPC wire format: `{"parameter": {...}}` with PascalCase fields.
 * `ExternalId` is sent as an `{Id, Type}` object, where the DTO's external system becomes `Type`.
 * Null values are omitted so P360 applies its own defaults, and dates use `yyyy-MM-dd`.
 *
 * @author Kenneth Sørensen
 * @since 2026-11
 * @group P360 Adapter
 */
public with sharing class P360_SifRequestSerializer {
    /**
     * Serialises a CreateCase request.
     *
     * @param request CreateCase parameters.
     * @return SIF RPC request body.
     */
    public static String createCase(P360_CreateCaseRequestDto request) {
        Map<String, Object> parameter = new Map<String, Object>();
        put(parameter, 'ADContextUser', request.adContextUser);
        put(parameter, 'Title', request.title);
        put(parameter, 'UnofficialTitle', request.unofficialTitle);
        put(parameter, 'DefaultValueSet', request.defaultValueSet);
        put(parameter, 'ExternalId', externalId(request.externalId, request.externalSystem));
        put(parameter, 'ExternalName', request.externalName);
        put(parameter, 'StartDate', formatDate(request.startDate));
        put(parameter, 'Status', request.status);
        put(parameter, 'ClosedDate', formatDate(request.closedDate));
        put(parameter, 'JournalUnit', request.journalUnit);
        put(parameter, 'SubArchive', request.subArchive);
        put(parameter, 'ArchiveCodes', archiveCodes(request.archiveCodes));
        put(parameter, 'CaseType', request.caseType);
        put(parameter, 'AccessCode', request.accessCode);
        put(parameter, 'AccessGroup', request.accessGroup);
        put(parameter, 'ResponsibleEnterpriseNumber', request.responsibleEnterpriseNumber);
        put(parameter, 'Category', request.category);
        return envelope(parameter);
    }

    /**
     * Serialises a CreateDocument request.
     *
     * @param request CreateDocument parameters.
     * @return SIF RPC request body.
     */
    public static String createDocument(P360_CreateDocumentRequestDto request) {
        Map<String, Object> parameter = new Map<String, Object>();
        put(parameter, 'ADUserContext', request.adUserContext);
        put(parameter, 'Title', request.title);
        put(parameter, 'DocumentDate', formatDate(request.documentDate));
        put(parameter, 'Archive', request.archive);
        put(parameter, 'Category', request.category);
        put(parameter, 'Status', request.status);
        put(parameter, 'AccessCode', request.accessCode);
        put(parameter, 'AccessGroup', request.accessGroup);
        put(parameter, 'CaseNumber', request.caseNumber);
        put(parameter, 'CaseExternalId', externalId(request.caseExternalId, request.externalSystem));
        put(parameter, 'ExternalId', externalId(request.externalId, request.externalSystem));
        put(parameter, 'JournalDate', formatDate(request.journalDate));
        put(parameter, 'DispatchedDate', formatDate(request.dispatchedDate));
        put(parameter, 'Files', files(request.files));
        return envelope(parameter);
    }

    private static List<Object> archiveCodes(List<P360_ClassCodeParameterDto> codes) {
        if (codes == null || codes.isEmpty()) {
            return null;
        }
        List<Object> result = new List<Object>();
        for (P360_ClassCodeParameterDto code : codes) {
            Map<String, Object> item = new Map<String, Object>();
            put(item, 'Sort', code.sortOrder);
            put(item, 'ArchiveType', code.archiveType);
            put(item, 'IsManualText', code.isManualText);
            put(item, 'ArchiveCode', code.archiveCode);
            result.add(item);
        }
        return result;
    }

    private static List<Object> files(List<P360_FileParameterDto> files) {
        if (files == null || files.isEmpty()) {
            return null;
        }
        List<Object> result = new List<Object>();
        for (P360_FileParameterDto file : files) {
            Map<String, Object> item = new Map<String, Object>();
            put(item, 'Title', file.title);
            put(item, 'Format', file.format);
            put(item, 'Data', file.data);
            put(item, 'Base64Data', file.base64Data);
            put(item, 'UploadedFileReference', file.uploadedFileReference);
            put(item, 'RelationType', file.relationType);
            put(item, 'VersionFormat', file.versionFormat);
            result.add(item);
        }
        return result;
    }

    private static Map<String, Object> externalId(String id, String type) {
        if (String.isBlank(id)) {
            return null;
        }
        Map<String, Object> result = new Map<String, Object>{ 'Id' => id };
        put(result, 'Type', type);
        return result;
    }

    private static String formatDate(Date value) {
        return value == null
            ? null
            : DateTime.newInstanceGmt(value, Time.newInstance(0, 0, 0, 0)).formatGmt('yyyy-MM-dd');
    }

    private static void put(Map<String, Object> target, String key, Object value) {
        if (value != null) {
            target.put(key, value);
        }
    }

    private static String envelope(Map<String, Object> parameter) {
        return JSON.serialize(new Map<String, Object>{ 'parameter' => parameter });
    }
}
