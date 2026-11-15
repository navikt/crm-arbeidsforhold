System.Assert.isTrue(
    URL.getOrgDomainUrl().getHost().endsWith('.scratch.my.salesforce.com') &&
    [SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox,
    'This synthetic fixture is scratch-only.'
);
P360ScratchSetting__c setting = P360ScratchSetting__c.getOrgDefaults();
if (setting.Id == null) {
    setting.SetupOwnerId = UserInfo.getOrganizationId();
    setting.Enabled__c = true;
    setting.Scenario__c = 'Success';
    setting.MaxFileBytes__c = 1024;
    insert setting;
}
System.Assert.isTrue(setting.Enabled__c && setting.Scenario__c == 'Success', 'Enable the Success scenario before running the smoke fixture. Existing configuration is not overwritten.');

Integer productJobsBefore = [SELECT COUNT() FROM P360_Archive_Job__c];
P360_IRpcClient receiver = new P360_ScratchRpcClient();
P360_RpcRequest caseRequest = new P360_RpcRequest();
caseRequest.serviceName = 'CaseService';
caseRequest.operationName = 'CreateCase';
caseRequest.body = JSON.serialize(new Map<String, Object>{
    'parameter' => new Map<String, Object>{
        'Title' => 'Synthetic Aa-registeret scratch case',
        'ExternalId' => new Map<String, Object>{'Id' => 'scratch-p360-smoke-case-v1', 'Type' => 'Scratch P360'},
        'ADContextUser' => 'scratch-p360-user'
    }
});
P360_RpcResponse caseResult = receiver.send(caseRequest);
Map<String, Object> caseBody = (Map<String, Object>) JSON.deserializeUntyped(caseResult.body);
System.Assert.areEqual(true, caseBody.get('Successful'));

String applicationContent = '{"kind":"synthetic-application","submission":1}';
String attachmentContent = 'Synthetic attachment without personal data.';
P360_RpcRequest documentRequest = new P360_RpcRequest();
documentRequest.serviceName = 'DocumentService';
documentRequest.operationName = 'CreateDocument';
documentRequest.body = JSON.serialize(new Map<String, Object>{
    'parameter' => new Map<String, Object>{
        'Title' => 'Synthetic application with attachment',
        'ExternalId' => new Map<String, Object>{'Id' => 'scratch-p360-smoke-document-v1', 'Type' => 'Scratch P360'},
        'ADUserContext' => 'scratch-p360-user',
        'CaseNumber' => caseBody.get('CaseNumber'),
        'Category' => 'Synthetic',
        'Status' => 'Synthetic',
        'Files' => new List<Object>{
            new Map<String, Object>{
                'Title' => 'synthetic-application.json',
                'Format' => 'json',
                'Base64Data' => EncodingUtil.base64Encode(Blob.valueOf(applicationContent))
            },
            new Map<String, Object>{
                'Title' => 'synthetic-attachment.txt',
                'Format' => 'txt',
                'Base64Data' => EncodingUtil.base64Encode(Blob.valueOf(attachmentContent))
            }
        }
    }
});
P360_RpcResponse documentResult = receiver.send(documentRequest);
System.Assert.areEqual(documentResult.body, receiver.send(documentRequest).body, 'A repeated document must reuse its simulated identity.');
System.Assert.areEqual('scratch-only', documentResult.headers.get('X-P360-Simulation'));

Set<String> keys = new Set<String>{
    EncodingUtil.convertToHex(Crypto.generateDigest('SHA-256', Blob.valueOf('CaseService/CreateCase\nScratch P360\nscratch-p360-smoke-case-v1'))),
    EncodingUtil.convertToHex(Crypto.generateDigest('SHA-256', Blob.valueOf('DocumentService/CreateDocument\nScratch P360\nscratch-p360-smoke-document-v1')))
};
List<P360ScratchCapture__c> receipts = [
    SELECT Name, Operation__c, RequestBody__c, ResponseBody__c, Outcome__c
    FROM P360ScratchCapture__c
    WHERE RequestKey__c IN :keys
    WITH USER_MODE
];
System.Assert.areEqual(2, receipts.size());
List<String> receiptNames = new List<String>();
Boolean filesVerified = false;
for (P360ScratchCapture__c receipt : receipts) {
    receiptNames.add(receipt.Name);
    System.Assert.areEqual('Accepted', receipt.Outcome__c);
    if (receipt.Operation__c == 'DocumentService/CreateDocument') {
        Map<String, Object> captured = (Map<String, Object>) JSON.deserializeUntyped(receipt.RequestBody__c);
        Map<String, Object> parameter = (Map<String, Object>) captured.get('parameter');
        List<Object> files = (List<Object>) parameter.get('Files');
        System.Assert.areEqual(2, files.size());
        System.Assert.areEqual(applicationContent, EncodingUtil.base64Decode((String)((Map<String, Object>)files[0]).get('Base64Data')).toString());
        System.Assert.areEqual(attachmentContent, EncodingUtil.base64Decode((String)((Map<String, Object>)files[1]).get('Base64Data')).toString());
        filesVerified = true;
    }
}
System.Assert.isTrue(filesVerified);
System.Assert.areEqual(0, Limits.getCallouts());
System.Assert.areEqual(productJobsBefore, [SELECT COUNT() FROM P360_Archive_Job__c]);
Integer backfilledSummaries = P360_ScratchRpcClient.describeExisting();
System.debug('P360_SCRATCH_RESULT=' + JSON.serialize(new Map<String, Object>{
    'backfilledSummaries' => backfilledSummaries,
    'receipts' => receiptNames,
    'filesVerified' => 2,
    'callouts' => Limits.getCallouts(),
    'productJobCountUnchanged' => true,
    'simulationOnly' => true
}));
