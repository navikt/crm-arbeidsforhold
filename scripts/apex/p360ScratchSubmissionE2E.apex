// Scratch-only end-to-end check of the runnable submission path. Uses synthetic data and the
// P360_ScratchRpcClient receiver; it never calls Public 360. Run through npm run p360:scratch -- e2e.
System.Assert.isTrue(
    URL.getOrgDomainUrl().getHost().endsWith('.scratch.my.salesforce.com') &&
    [SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox,
    'This synthetic end-to-end check is scratch-only.'
);
P360ScratchSetting__c receiverSetting = P360ScratchSetting__c.getOrgDefaults();
System.Assert.isTrue(
    receiverSetting.Id != null && receiverSetting.Enabled__c && receiverSetting.Scenario__c == 'Success',
    'Enable the Success scenario of the scratch receiver first. Existing configuration is not overwritten.'
);
System.Assert.isTrue(P360_ArchiveProcessingGate.isEnabled(), 'The P360 archive-processing flag must be enabled in scratch.');
System.Assert.areEqual(
    0,
    [SELECT COUNT() FROM P360_Archive_Job__c WHERE Status__c IN ('Pending', 'In Progress')],
    'Other pending archive jobs exist; the check would process them too.'
);

P360_Integration_Setting__c integrationSetting = P360_Integration_Setting__c.getOrgDefaults();
String originalRpcClient = integrationSetting.Rpc_Client_Class__c;
String originalExternalSystem = integrationSetting.External_System__c;
Boolean originalUseMockTransport = integrationSetting.Use_Mock_Transport__c;
if (integrationSetting.Id == null) {
    integrationSetting.SetupOwnerId = UserInfo.getOrganizationId();
}
integrationSetting.Rpc_Client_Class__c = 'P360_ScratchRpcClient';
integrationSetting.External_System__c = 'Scratch P360';
// The stub adapter would otherwise win and report success without reaching the configured receiver.
integrationSetting.Use_Mock_Transport__c = false;
upsert integrationSetting;

Map<String, Object> result = new Map<String, Object>{ 'simulationOnly' => true };
try {
    Account account = new Account(Name = 'Syntetisk P360 scratch-organisasjon ' + System.now().getTime());
    insert account;
    String attachmentContent = 'Synthetic attachment without personal data.';
    Id applicationId = AAREG_ApplicationController.processApplication(
        new Application__c(Account__c = account.Id, IsConfirmationEmailSent__c = true),
        new List<ApplicationBasisCode__c>(),
        new List<RelatedContact__c>(),
        EncodingUtil.base64Encode(Blob.valueOf(attachmentContent)),
        'syntetisk-vedlegg.txt'
    );
    List<Id> claimedIds = P360_ArchiveJobClaimService.claimNextBatch(10);
    new P360_ArchiveJobWorker(new Set<Id>(claimedIds)).execute(null);

    P360_Archive_Job__c job = [
        SELECT Id, Status__c, Last_Error_Message__c, Access_Request__c, Idempotency_Key__c
        FROM P360_Archive_Job__c
        WHERE Application__c = :applicationId AND Archive_Event_Type__c = 'ApplicationDocument'
    ];
    String caseKey = EncodingUtil.convertToHex(
        Crypto.generateDigest('SHA-256', Blob.valueOf('CaseService/CreateCase\nScratch P360\nACCESS_REQUEST:' + job.Access_Request__c))
    );
    String documentKey = EncodingUtil.convertToHex(
        Crypto.generateDigest('SHA-256', Blob.valueOf('DocumentService/CreateDocument\nScratch P360\n' + job.Idempotency_Key__c))
    );
    List<Object> receipts = new List<Object>();
    Integer filesVerified = 0;
    for (P360ScratchCapture__c receipt : [
        SELECT Name, Operation__c, Outcome__c, RequestKey__c, RequestBody__c
        FROM P360ScratchCapture__c
        WHERE RequestKey__c IN (:caseKey, :documentKey)
        ORDER BY Name
    ]) {
        receipts.add(new Map<String, Object>{
            'name' => receipt.Name,
            'operation' => receipt.Operation__c,
            'outcome' => receipt.Outcome__c
        });
        Map<String, Object> parameter = (Map<String, Object>) ((Map<String, Object>) JSON.deserializeUntyped(receipt.RequestBody__c)).get('parameter');
        if (parameter.containsKey('Files')) {
            List<Object> files = (List<Object>) parameter.get('Files');
            String summary = EncodingUtil.base64Decode((String) ((Map<String, Object>) files[0]).get('Base64Data')).toString();
            String attachment = EncodingUtil.base64Decode((String) ((Map<String, Object>) files[1]).get('Base64Data')).toString();
            if (files.size() == 2 && summary.contains(applicationId) && attachment == attachmentContent) {
                filesVerified = 2;
            }
            result.put('documentCaseNumber', parameter.get('CaseNumber'));
        }
    }
    result.put('applicationId', applicationId);
    result.put('claimedJobs', claimedIds.size());
    result.put('jobStatus', job.Status__c);
    result.put('jobError', job.Last_Error_Message__c);
    result.put('receipts', receipts);
    result.put('filesVerified', filesVerified);
    result.put('callouts', Limits.getCallouts());
} finally {
    integrationSetting.Rpc_Client_Class__c = originalRpcClient;
    integrationSetting.External_System__c = originalExternalSystem;
    integrationSetting.Use_Mock_Transport__c = originalUseMockTransport == true;
    update integrationSetting;
}
System.debug(LoggingLevel.INFO, 'P360_E2E_RESULT=' + JSON.serialize(result));
