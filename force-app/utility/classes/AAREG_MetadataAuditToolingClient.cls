/**
 * Checks ApexClass existence with a same-org Salesforce Tooling API REST query.
 *
 * @author Kenneth Sørensen
 * @since 2026-10-12
 * @group AAREG Utility
 */
public with sharing class AAREG_MetadataAuditToolingClient {
    private static final String API_VERSION = '67.0';

    /**
     * Queries one exact Apex class name without retrieving class source or other fields.
     * @param fullName Unnamespaced ApexClass Metadata API fullName.
     * @param sessionId Current caller session ID used only in the HTTPS authorization header.
     * @return Sanitized audit result; incomplete or ambiguous queries remain UNKNOWN.
     */
    public static Map<String, String> checkApexClass(String fullName, String sessionId) {
        if (fullName.contains('__') || !Pattern.compile('^[A-Za-z_][A-Za-z0-9_]*$').matcher(fullName).matches()) {
            return result('UNKNOWN', 'NAMESPACE_OR_UNSUPPORTED_APEX_CLASS_NAME');
        }

        try {
            HttpResponse response = sendQuery(buildQuery(fullName), sessionId);
            return parseQueryResponse(fullName, response);
        } catch (System.Exception error) {
            return result('UNKNOWN', 'TOOLING_QUERY_FAILED');
        }
    }

    private static String buildQuery(String fullName) {
        String quote = String.fromCharArray(new List<Integer>{ 39 });
        return 'SELECT Name FROM ApexClass WHERE Name = ' + quote + String.escapeSingleQuotes(fullName) + quote;
    }

    private static HttpResponse sendQuery(String soql, String sessionId) {
        HttpRequest request = new HttpRequest();
        request.setEndpoint(
            URL.getOrgDomainUrl().toExternalForm() +
                '/services/data/v' +
                API_VERSION +
                '/tooling/query/?q=' +
                EncodingUtil.urlEncode(soql, 'UTF-8')
        );
        request.setMethod('GET');
        request.setHeader('Authorization', 'Bearer ' + sessionId);
        request.setHeader('Accept', 'application/json');
        request.setTimeout(10000);
        return new Http().send(request);
    }

    private static Map<String, String> parseQueryResponse(String fullName, HttpResponse response) {
        if (response.getStatusCode() != 200) {
            return result('UNKNOWN', getHttpErrorCode(response));
        }
        if (String.isBlank(response.getBody()) || response.getBody().length() > 1000000) {
            return result('UNKNOWN', 'RESPONSE_EMPTY_OR_TOO_LARGE');
        }

        Map<String, Object> queryResult = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
        return classifyQueryResult(fullName, queryResult);
    }

    private static String getHttpErrorCode(HttpResponse response) {
        String httpErrorCode = 'HTTP_' + response.getStatusCode();
        try {
            List<Object> errors = (List<Object>) JSON.deserializeUntyped(response.getBody());
            if (!errors.isEmpty()) {
                String apiErrorCode = (String) ((Map<String, Object>) errors[0]).get('errorCode');
                if (apiErrorCode != null && Pattern.compile('^[A-Za-z0-9_]+$').matcher(apiErrorCode).matches()) {
                    return httpErrorCode + '_' + apiErrorCode;
                }
            }
        } catch (System.Exception ignored) {
        }
        return httpErrorCode;
    }

    private static Map<String, String> classifyQueryResult(String fullName, Map<String, Object> queryResult) {
        List<Object> records = (List<Object>) queryResult.get('records');
        Integer totalSize = Integer.valueOf(String.valueOf(queryResult.get('totalSize')));
        if (queryResult.get('done') != true || records == null || totalSize != records.size()) {
            return result('UNKNOWN', 'INCOMPLETE_QUERY');
        }
        if (totalSize == 0) {
            return result('NOT_FOUND', null);
        }
        if (totalSize != 1) {
            return result('UNKNOWN', 'AMBIGUOUS_QUERY_RESULT');
        }

        return classifySingleRecord(fullName, (Map<String, Object>) records[0]);
    }

    private static Map<String, String> classifySingleRecord(String fullName, Map<String, Object> record) {
        String returnedName = (String) record.get('Name');
        if (returnedName != null && returnedName.equals(fullName)) {
            return result('FOUND', null);
        }
        return result('UNKNOWN', 'NAME_MISMATCH_OR_MISSING');
    }

    private static Map<String, String> result(String status, String errorCode) {
        return new Map<String, String>{ 'status' => status, 'errorCode' => errorCode };
    }
}
