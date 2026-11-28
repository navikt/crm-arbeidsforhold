/**
 * Scratch-only synthetic receiver at the existing RPC seam; never calls Public 360.
 * Only the environment safety check reads Organization in system mode; receipts use user mode.
 *
 * @since 2026-11
 * @group P360 Scratch Contract
 */
public with sharing class P360_ScratchRpcClient implements P360_IRpcClient {
    private static Boolean scratchEnvironment;

    /**
     * Records one synthetic request using the caller's object and field permissions.
     *
     * @param request Synthetic SIF-shaped request without authentication headers.
     * @return Clearly marked simulated RPC response.
     * @throws P360_ContractException When capture cannot safely accept the request.
     * @throws P360_RetryableException For a configured failure before simulated acceptance.
     * @throws P360_TimeoutException For simulated acceptance followed by a lost response; not automatically retryable.
     */
    public P360_RpcResponse send(P360_RpcRequest request) {
        P360ScratchSetting__c setting = requireConfiguration();
        Map<String, Object> parameter = requireParameter(request);
        if (
            (request.serviceName == 'CaseService' && request.operationName == 'GetCases') ||
            (request.serviceName == 'DocumentService' &&
            request.operationName == 'GetDocuments')
        ) {
            return lookup(request, parameter);
        }
        if (
            !((request.serviceName == 'CaseService' && request.operationName == 'CreateCase') ||
            (request.serviceName == 'DocumentService' &&
            request.operationName == 'CreateDocument'))
        ) {
            throw new P360_ContractException('Unsupported scratch RPC operation.');
        }
        String identity = requireIdentity(parameter);
        requireString(parameter, 'Title');
        if (request.operationName == 'CreateDocument') {
            requireString(parameter, 'CaseNumber');
            requireString(parameter, 'Category');
            requireString(parameter, 'Status');
            validateFiles(parameter, setting.MaxFileBytes__c.intValue());
        }
        String operation = request.serviceName + '/' + request.operationName;
        String key = digest(operation + '\n' + identity);
        List<P360ScratchCapture__c> receipts = [
            SELECT Id, Name, PayloadHash__c, ResponseBody__c, Attempts__c, Outcome__c
            FROM P360ScratchCapture__c
            WHERE RequestKey__c = :key
            WITH USER_MODE
            LIMIT 1
            FOR UPDATE
        ];
        P360ScratchCapture__c receipt;
        if (receipts.isEmpty()) {
            receipt = new P360ScratchCapture__c(
                RequestKey__c = key,
                Operation__c = operation,
                RequestBody__c = request.body,
                PayloadHash__c = digest(request.body),
                Attempts__c = 0
            );
            describe(receipt, parameter);
            linkParentCases(new List<P360ScratchCapture__c>{ receipt });
            insert as user receipt;
            insert as user openableFiles(receipt.Id, parameter);
            receipt = [
                SELECT Id, Name, PayloadHash__c, ResponseBody__c, Attempts__c, Outcome__c
                FROM P360ScratchCapture__c
                WHERE Id = :receipt.Id
                WITH USER_MODE
            ];
        } else {
            receipt = receipts[0];
            if (receipt.PayloadHash__c != digest(request.body)) {
                throw new P360_ContractException('An external identity cannot be reused with a changed payload.');
            }
            if (receipt.Outcome__c == 'UnknownOutcome') {
                throw new P360_ContractException('Lookup is required before repeating an unknown create.');
            }
        }
        receipt.Attempts__c++;
        if (receipt.ResponseBody__c == null && setting.Scenario__c == 'RetryableFailure') {
            receipt.Outcome__c = 'RetryableFailure';
            update as user receipt;
            throw new P360_RetryableException('Synthetic rejection before acceptance.');
        }
        if (receipt.ResponseBody__c == null && setting.Scenario__c == 'PermanentFailure') {
            receipt.ResponseBody__c = JSON.serialize(
                new Map<String, Object>{ 'Successful' => false, 'ErrorMessage' => 'Synthetic validation rejection.' }
            );
            receipt.Outcome__c = 'Rejected';
        }
        if (receipt.ResponseBody__c == null) {
            Map<String, Object> body = new Map<String, Object>{
                'Successful' => true,
                'Recno' => Integer.valueOf(receipt.Name.substringAfter('SCRATCH-'))
            };
            body.put(request.operationName == 'CreateCase' ? 'CaseNumber' : 'DocumentNumber', receipt.Name);
            receipt.P360Number__c = receipt.Name;
            receipt.ResponseBody__c = JSON.serialize(body);
            receipt.Outcome__c = setting.Scenario__c == 'UnknownOutcome' ? 'UnknownOutcome' : 'Accepted';
        }
        update as user receipt;
        if (receipt.Outcome__c == 'UnknownOutcome') {
            throw new P360_TimeoutException('Synthetic response lost after acceptance; lookup is required.');
        }
        return response(receipt.ResponseBody__c);
    }

    private static P360_RpcResponse lookup(P360_RpcRequest request, Map<String, Object> parameter) {
        String operation = request.operationName == 'GetCases' ? 'CreateCase' : 'CreateDocument';
        String key = digest(request.serviceName + '/' + operation + '\n' + requireIdentity(parameter));
        List<Object> matches = new List<Object>();
        for (P360ScratchCapture__c receipt : [
            SELECT ResponseBody__c, Outcome__c
            FROM P360ScratchCapture__c
            WHERE RequestKey__c = :key
            WITH USER_MODE
        ]) {
            if (receipt.Outcome__c == 'Accepted' || receipt.Outcome__c == 'UnknownOutcome') {
                matches.add(JSON.deserializeUntyped(receipt.ResponseBody__c));
            }
        }
        Map<String, Object> body = new Map<String, Object>{ 'Successful' => true };
        body.put(request.operationName == 'GetCases' ? 'Cases' : 'Documents', matches);
        return response(JSON.serialize(body));
    }

    /**
     * Returns `<Type>\n<Id>` for the SIF ExternalId; the capture itself is restricted to enabled scratch orgs.
     */
    private static String requireIdentity(Map<String, Object> parameter) {
        Map<String, Object> externalId = requireObject(parameter.get('ExternalId'));
        String identity = requireString(externalId, 'Id');
        String externalSystem = requireString(externalId, 'Type');
        if (
            !Pattern.matches('^[A-Za-z0-9._:-]{1,160}$', identity) ||
            !Pattern.matches('^[A-Za-z0-9 ._:-]{1,100}$', externalSystem)
        ) {
            throw new P360_ContractException('The external identity has an unsupported format.');
        }
        return externalSystem + '\n' + identity;
    }

    /**
     * Fills the readable fields, case links and openable files of receipts captured before those existed.
     * Reads only the stored synthetic request and response; it never contacts Public 360.
     *
     * @return Number of receipts that received a summary.
     */
    public static Integer describeExisting() {
        List<P360ScratchCapture__c> described = new List<P360ScratchCapture__c>();
        List<ContentVersion> files = new List<ContentVersion>();
        for (P360ScratchCapture__c receipt : [
            SELECT Id, RequestBody__c, ResponseBody__c, RequestFields__c, ParentCaseNumber__c
            FROM P360ScratchCapture__c
            WITH USER_MODE
            ORDER BY Name
            LIMIT 200
        ]) {
            if (receipt.RequestFields__c != null) {
                continue;
            }
            P360_RpcRequest stored = new P360_RpcRequest();
            stored.body = receipt.RequestBody__c;
            try {
                Map<String, Object> parameter = requireParameter(stored);
                describe(receipt, parameter);
                receipt.P360Number__c = returnedNumber(receipt.ResponseBody__c);
                files.addAll(openableFiles(receipt.Id, parameter));
            } catch (Exception unreadable) {
                continue;
            }
            described.add(receipt);
        }
        linkParentCases(described);
        update as user described;
        insert as user files;
        return described.size();
    }

    private static String returnedNumber(String responseBody) {
        Object response = String.isBlank(responseBody) ? null : JSON.deserializeUntyped(responseBody);
        if (!(response instanceof Map<String, Object>)) {
            return null;
        }
        Map<String, Object> answer = (Map<String, Object>) response;
        Object value = answer.containsKey('DocumentNumber') ? answer.get('DocumentNumber') : answer.get('CaseNumber');
        return value instanceof String ? (String) value : null;
    }

    private static void linkParentCases(List<P360ScratchCapture__c> receipts) {
        Set<String> caseNumbers = new Set<String>();
        for (P360ScratchCapture__c receipt : receipts) {
            if (receipt.ParentCaseNumber__c != null) {
                caseNumbers.add(receipt.ParentCaseNumber__c);
            }
        }
        if (caseNumbers.isEmpty()) {
            return;
        }
        Map<String, Id> caseByNumber = new Map<String, Id>();
        for (P360ScratchCapture__c caseCapture : [
            SELECT Id, P360Number__c
            FROM P360ScratchCapture__c
            WHERE Operation__c = 'CaseService/CreateCase' AND P360Number__c IN :caseNumbers
            WITH USER_MODE
        ]) {
            caseByNumber.put(caseCapture.P360Number__c, caseCapture.Id);
        }
        for (P360ScratchCapture__c receipt : receipts) {
            receipt.ParentCapture__c = caseByNumber.get(receipt.ParentCaseNumber__c);
        }
    }

    private static List<ContentVersion> openableFiles(Id receiptId, Map<String, Object> parameter) {
        List<ContentVersion> files = new List<ContentVersion>();
        if (!(parameter.get('Files') instanceof List<Object>)) {
            return files;
        }
        for (Object suppliedFile : (List<Object>) parameter.get('Files')) {
            Map<String, Object> file = (Map<String, Object>) suppliedFile;
            String title = (String) file.get('Title');
            String format = (String) file.get('Format');
            String suffix = '.' + format;
            files.add(
                new ContentVersion(
                    Title = title,
                    PathOnClient = title.endsWithIgnoreCase(suffix) ? title : title + suffix,
                    VersionData = EncodingUtil.base64Decode((String) file.get('Base64Data')),
                    FirstPublishLocationId = receiptId
                )
            );
        }
        return files;
    }

    private static void flatten(String path, Object value, List<String> lines) {
        if (value instanceof Map<String, Object>) {
            Map<String, Object> values = (Map<String, Object>) value;
            List<String> names = new List<String>(values.keySet());
            names.sort();
            for (String name : names) {
                flatten(String.isBlank(path) ? name : path + '.' + name, values.get(name), lines);
            }
        } else if (value instanceof List<Object>) {
            List<Object> items = (List<Object>) value;
            for (Integer index = 0; index < items.size(); index++) {
                flatten(path + '[' + (index + 1) + ']', items[index], lines);
            }
        } else if (path.endsWith('.Base64Data') && value instanceof String) {
            Integer bytes = EncodingUtil.base64Decode((String) value).size();
            lines.add(path + ': (' + bytes + ' bytes, open the file under Files)');
        } else {
            lines.add(path + ': ' + (value == null ? '' : String.valueOf(value)));
        }
    }

    /**
     * Copies the reviewer-relevant parts of an already validated request into readable fields.
     */
    private static void describe(P360ScratchCapture__c receipt, Map<String, Object> parameter) {
        Map<String, Object> externalId = (Map<String, Object>) parameter.get('ExternalId');
        String identity = (String) externalId.get('Id');
        receipt.Title__c = ((String) parameter.get('Title')).left(255);
        receipt.ExternalSystem__c = (String) externalId.get('Type');
        receipt.ExternalId__c = identity;
        List<String> lines = new List<String>();
        flatten('', parameter, lines);
        receipt.RequestFields__c = String.join(lines, '\n').left(131072);
        String candidate = identity.substringAfterLast(':');
        if (candidate instanceof Id) {
            receipt.SourceRecordId__c = Id.valueOf(candidate);
        }
        if (parameter.get('CaseNumber') instanceof String && parameter.containsKey('Files')) {
            receipt.ParentCaseNumber__c = ((String) parameter.get('CaseNumber')).left(80);
        }
        if (!(parameter.get('Files') instanceof List<Object>)) {
            return;
        }
        List<String> details = new List<String>();
        for (Object suppliedFile : (List<Object>) parameter.get('Files')) {
            Map<String, Object> file = (Map<String, Object>) suppliedFile;
            String format = (String) file.get('Format');
            Blob decoded = EncodingUtil.base64Decode((String) file.get('Base64Data'));
            String line = file.get('Title') + ' (' + format + ', ' + decoded.size() + ' bytes)';
            if (format.equalsIgnoreCase('txt')) {
                line += '\n' + decoded.toString().left(4000);
            }
            details.add(line);
        }
        receipt.FileCount__c = details.size();
        receipt.FileDetails__c = String.join(details, '\n\n----------\n\n').left(131072);
    }

    private static P360ScratchSetting__c requireConfiguration() {
        if (scratchEnvironment == null) {
            scratchEnvironment =
                URL.getOrgDomainUrl().getHost().endsWith('.scratch.my.salesforce.com') &&
                [SELECT IsSandbox FROM Organization WITH SYSTEM_MODE LIMIT 1]
                .IsSandbox;
        }
        if (!scratchEnvironment) {
            throw new P360_ContractException('Synthetic capture is restricted to scratch orgs.');
        }
        P360ScratchSetting__c setting = P360ScratchSetting__c.getOrgDefaults();
        if (setting.Enabled__c != true) {
            throw new P360_ContractException('Synthetic capture must be explicitly enabled.');
        }
        if (
            !new Set<String>{ 'Success', 'RetryableFailure', 'PermanentFailure', 'UnknownOutcome' }
                .contains(setting.Scenario__c)
        ) {
            throw new P360_ContractException('Unsupported scratch scenario.');
        }
        if (setting.MaxFileBytes__c == null || setting.MaxFileBytes__c < 1 || setting.MaxFileBytes__c > 32768) {
            throw new P360_ContractException('Maximum synthetic file bytes must be between 1 and 32768.');
        }
        return setting;
    }

    private static Map<String, Object> requireParameter(P360_RpcRequest request) {
        if (request == null || String.isBlank(request.body) || request.body.length() > 100000) {
            throw new P360_ContractException('A synthetic request body of at most 100000 characters is required.');
        }
        if (request.headers != null && !request.headers.isEmpty()) {
            throw new P360_ContractException('Capture requests must not contain transport headers or credentials.');
        }
        try {
            return requireObject(requireObject(JSON.deserializeUntyped(request.body)).get('parameter'));
        } catch (System.JSONException failure) {
            throw new P360_ContractException('The synthetic request must contain valid JSON.');
        }
    }

    private static Map<String, Object> requireObject(Object value) {
        if (!(value instanceof Map<String, Object>)) {
            throw new P360_ContractException(
                'The synthetic request must contain a parameter object and external identity.'
            );
        }
        return (Map<String, Object>) value;
    }

    private static String requireString(Map<String, Object> parameter, String name) {
        Object value = parameter.get(name);
        if (!(value instanceof String) || String.isBlank((String) value)) {
            throw new P360_ContractException('A required synthetic string field is missing: ' + name + '.');
        }
        return (String) value;
    }

    private static void validateFiles(Map<String, Object> parameter, Integer maximumBytes) {
        Object suppliedFiles = parameter.get('Files');
        if (!(suppliedFiles instanceof List<Object>) || ((List<Object>) suppliedFiles).isEmpty()) {
            throw new P360_ContractException('At least one synthetic document file is required.');
        }
        for (Object suppliedFile : (List<Object>) suppliedFiles) {
            Map<String, Object> file = requireObject(suppliedFile);
            requireString(file, 'Title');
            requireString(file, 'Format');
            if (file.containsKey('UploadedFileReference') || file.containsKey('Data')) {
                throw new P360_ContractException('This capture slice accepts inline Base64Data only.');
            }
            String encoded = requireString(file, 'Base64Data');
            Blob decoded;
            try {
                decoded = EncodingUtil.base64Decode(encoded);
            } catch (System.StringException failure) {
                throw new P360_ContractException('Synthetic file data must be valid base64.');
            }
            if (EncodingUtil.base64Encode(decoded) != encoded) {
                throw new P360_ContractException('Synthetic file data must be valid base64.');
            }
            if (decoded.size() == 0 || decoded.size() > maximumBytes) {
                throw new P360_ContractException('Synthetic file exceeds the configured byte limit or is empty.');
            }
        }
    }

    private static String digest(String value) {
        return EncodingUtil.convertToHex(Crypto.generateDigest('SHA-256', Blob.valueOf(value)));
    }

    private static P360_RpcResponse response(String body) {
        P360_RpcResponse result = new P360_RpcResponse();
        result.statusCode = 200;
        result.body = body;
        result.headers = new Map<String, String>{ 'X-P360-Simulation' => 'scratch-only' };
        return result;
    }
}
