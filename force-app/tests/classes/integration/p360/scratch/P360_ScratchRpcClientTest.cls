/**
 * Exercises synthetic RPC capture without a P360 server or product archive side effects.
 * Existing-user runAs blocks activate permission-set grants made in test setup.
 *
 * @since 2026-11
 * @group P360 Scratch Contract
 */
@IsTest
private class P360_ScratchRpcClientTest {
    /**
     * Separates permission setup from configuration data before each isolated scenario.
     *
     * @since 2026-11
     */
    @TestSetup
    static void configureReceiver() {
        Id permissionSetId = [SELECT Id FROM PermissionSet WHERE Name = 'P360_Scratch_Capture_Access'].Id;
        if (
            [
                SELECT COUNT()
                FROM PermissionSetAssignment
                WHERE AssigneeId = :UserInfo.getUserId() AND PermissionSetId = :permissionSetId
            ] == 0
        ) {
            insert new PermissionSetAssignment(AssigneeId = UserInfo.getUserId(), PermissionSetId = permissionSetId);
        }
        System.runAs(new User(Id = UserInfo.getUserId())) {
            insert new P360ScratchSetting__c(
                SetupOwnerId = UserInfo.getOrganizationId(),
                Enabled__c = true,
                Scenario__c = 'Success',
                MaxFileBytes__c = 32
            );
        }
    }

    /**
     * Stores inspectable file bytes and returns the same simulated identity on repeated requests.
     *
     * @since 2026-11
     */
    @IsTest
    static void shouldCaptureSyntheticDocumentWithoutMakingCallouts() {
        User minimumAccessUser = P360_TestDataFactory.createMinimumAccessUser();
        insert new PermissionSetAssignment(
            AssigneeId = minimumAccessUser.Id,
            PermissionSetId = [SELECT Id FROM PermissionSet WHERE Name = 'P360_Scratch_Capture_Access']
            .Id
        );
        System.runAs(minimumAccessUser) {
            P360_RpcRequest request = documentRequest('scratch-p360-document-1', 'synthetic attachment');
            P360_IRpcClient receiver = new P360_ScratchRpcClient();

            System.Test.startTest();
            P360_RpcResponse first = receiver.send(request);
            P360_RpcResponse repeated = receiver.send(request);
            System.Assert.areEqual(0, Limits.getCallouts(), 'Capture must never send an HTTP request.');
            System.Test.stopTest();

            List<P360ScratchCapture__c> receipts = [
                SELECT RequestBody__c, ResponseBody__c, Attempts__c, Outcome__c
                FROM P360ScratchCapture__c
                WITH USER_MODE
            ];
            System.Assert.areEqual(1, receipts.size(), 'Identical retries must not create another simulated document.');
            System.Assert.areEqual(request.body, receipts[0].RequestBody__c);
            System.Assert.areEqual(2, receipts[0].Attempts__c);
            System.Assert.areEqual('Accepted', receipts[0].Outcome__c);
            System.Assert.areEqual(200, first.statusCode);
            System.Assert.areEqual('scratch-only', first.headers.get('X-P360-Simulation'));
            System.Assert.areEqual(first.body, repeated.body);
            System.Assert.areEqual(first.body, receipts[0].ResponseBody__c);
            Map<String, Object> response = (Map<String, Object>) JSON.deserializeUntyped(first.body);
            System.Assert.areEqual(true, response.get('Successful'));
            System.Assert.isNotNull(response.get('Recno'));
        }
        System.Assert.areEqual(0, [SELECT COUNT() FROM P360_Archive_Job__c], 'Capture is not product archiving.');
    }

    /**
     * Preserves an accepted but unacknowledged document for explicit recovery by external identity.
     *
     * @since 2026-11
     */
    @IsTest
    static void shouldResolveUnknownOutcomeByLookupWithoutRecreatingDocument() {
        System.runAs(new User(Id = UserInfo.getUserId())) {
            configureScenario('UnknownOutcome');
            P360_RpcRequest request = documentRequest('scratch-p360-unknown', 'synthetic');
            P360_IRpcClient receiver = new P360_ScratchRpcClient();

            System.Test.startTest();
            try {
                receiver.send(request);
                System.Assert.fail('The response must be lost after simulated acceptance.');
            } catch (P360_TimeoutException expected) {
                System.Assert.isFalse(expected.isRetryable, 'An unknown create outcome is not safe to retry blindly.');
            }
            try {
                receiver.send(request);
                System.Assert.fail('A repeated create must require explicit reconciliation.');
            } catch (P360_ContractException expected) {
                System.Assert.areEqual('Lookup is required before repeating an unknown create.', expected.getMessage());
            }
            request.operationName = 'GetDocuments';
            P360_RpcResponse lookup = receiver.send(request);
            System.Test.stopTest();

            P360ScratchCapture__c receipt = [
                SELECT ResponseBody__c, Outcome__c, Attempts__c
                FROM P360ScratchCapture__c
            ];
            Map<String, Object> recovered = (Map<String, Object>) JSON.deserializeUntyped(lookup.body);
            List<Object> documents = (List<Object>) recovered.get('Documents');
            System.Assert.areEqual(1, documents.size());
            Map<String, Object> original = (Map<String, Object>) JSON.deserializeUntyped(receipt.ResponseBody__c);
            System.Assert.areEqual(original.get('Recno'), ((Map<String, Object>) documents[0]).get('Recno'));
            System.Assert.areEqual(
                'UnknownOutcome',
                receipt.Outcome__c,
                'Lookup does not silently mark work reconciled.'
            );
            System.Assert.areEqual(1, receipt.Attempts__c);
            System.Assert.areEqual(1, [SELECT COUNT() FROM P360ScratchCapture__c]);
        }
    }

    /**
     * Allows a definitely unaccepted transient request to succeed after a configuration change.
     *
     * @since 2026-11
     */
    @IsTest
    static void shouldRetryOnlyDefinitelyUnacceptedRequests() {
        System.runAs(new User(Id = UserInfo.getUserId())) {
            configureScenario('RetryableFailure');
            P360_RpcRequest request = documentRequest('scratch-p360-retry', 'synthetic');
            P360_IRpcClient receiver = new P360_ScratchRpcClient();

            System.Test.startTest();
            try {
                receiver.send(request);
                System.Assert.fail('A configured transient rejection must be visible to the caller.');
            } catch (P360_RetryableException expected) {
                System.Assert.isTrue(expected.isRetryable);
            }
            P360ScratchCapture__c rejected = [SELECT Outcome__c, ResponseBody__c FROM P360ScratchCapture__c];
            System.Assert.areEqual('RetryableFailure', rejected.Outcome__c);
            System.Assert.isNull(rejected.ResponseBody__c, 'A failed request has no simulated archive identity.');
            configureScenario('Success');
            P360_RpcResponse accepted = receiver.send(request);
            System.Test.stopTest();

            P360ScratchCapture__c receipt = [SELECT Id, Outcome__c, Attempts__c FROM P360ScratchCapture__c];
            System.Assert.areEqual(rejected.Id, receipt.Id);
            System.Assert.areEqual(2, receipt.Attempts__c);
            System.Assert.areEqual('Accepted', receipt.Outcome__c);
            System.Assert.areEqual(
                true,
                ((Map<String, Object>) JSON.deserializeUntyped(accepted.body)).get('Successful')
            );
        }
    }

    /**
     * Returns an explicit unsuccessful SIF-shaped result for a permanent synthetic rejection.
     *
     * @since 2026-11
     */
    @IsTest
    static void shouldKeepPermanentRejectionDistinctFromAcceptance() {
        System.runAs(new User(Id = UserInfo.getUserId())) {
            configureScenario('PermanentFailure');
            System.Test.startTest();
            P360_RpcResponse result = new P360_ScratchRpcClient()
                .send(documentRequest('scratch-p360-permanent', 'synthetic'));
            System.Test.stopTest();
            Map<String, Object> rejected = (Map<String, Object>) JSON.deserializeUntyped(result.body);
            System.Assert.areEqual(false, rejected.get('Successful'));
            System.Assert.isNotNull(rejected.get('ErrorMessage'));
            System.Assert.isFalse(
                rejected.containsKey('Recno'),
                'A rejected request must not receive an archive identity.'
            );
            System.Assert.areEqual('Rejected', [SELECT Outcome__c FROM P360ScratchCapture__c].Outcome__c);
        }
    }

    /**
     * Rejects changed content instead of overwriting an earlier receipt with the same external identity.
     *
     * @since 2026-11
     */
    @IsTest
    static void shouldRejectChangedContentForAnExistingIdentity() {
        System.runAs(new User(Id = UserInfo.getUserId())) {
            P360_IRpcClient receiver = new P360_ScratchRpcClient();
            P360_RpcRequest original = documentRequest('scratch-p360-immutable', 'original synthetic bytes');
            System.Test.startTest();
            receiver.send(original);
            assertRejected(
                documentRequest('scratch-p360-immutable', 'changed synthetic bytes'),
                'An external identity cannot be reused with a changed payload.'
            );
            System.Test.stopTest();
            System.Assert.areEqual(original.body, [SELECT RequestBody__c FROM P360ScratchCapture__c].RequestBody__c);
        }
    }

    /**
     * Enforces the configured decoded-byte boundary and rejects malformed encoded content without persisting it.
     *
     * @since 2026-11
     */
    @IsTest
    static void shouldEnforceExactFileLimitAndRejectMalformedBase64() {
        System.runAs(new User(Id = UserInfo.getUserId())) {
            System.Test.startTest();
            new P360_ScratchRpcClient().send(documentRequest('scratch-p360-at-limit', 'x'.repeat(32)));
            assertRejected(
                documentRequest('scratch-p360-over-limit', 'x'.repeat(33)),
                'Synthetic file exceeds the configured byte limit or is empty.'
            );
            P360_RpcRequest malformed = documentRequest('scratch-p360-invalid-base64', 'synthetic');
            malformed.body = malformed.body.replace(EncodingUtil.base64Encode(Blob.valueOf('synthetic')), '%%%');
            assertRejected(malformed, 'Synthetic file data must be valid base64.');
            System.Test.stopTest();
            System.Assert.areEqual(1, [SELECT COUNT() FROM P360ScratchCapture__c]);
        }
    }

    /**
     * Fails closed for disabled capture, invalid configuration and credential-bearing requests.
     *
     * @since 2026-11
     */
    @IsTest
    static void shouldRejectUnsafeConfigurationAndHeaders() {
        P360ScratchSetting__c setting = P360ScratchSetting__c.getOrgDefaults();
        setting.Enabled__c = false;
        update setting;
        P360_RpcRequest request = documentRequest('scratch-p360-guard', 'synthetic');
        System.Test.startTest();
        assertRejected(request, 'Synthetic capture must be explicitly enabled.');
        setting.Enabled__c = true;
        setting.Scenario__c = 'typo';
        update setting;
        assertRejected(request, 'Unsupported scratch scenario.');
        setting.Scenario__c = 'Success';
        setting.MaxFileBytes__c = 32769;
        update setting;
        assertRejected(request, 'Maximum synthetic file bytes must be between 1 and 32768.');
        setting.MaxFileBytes__c = 32;
        update setting;
        request.headers = new Map<String, String>{ 'Authorization' => 'synthetic-not-a-credential' };
        assertRejected(request, 'Capture requests must not contain transport headers or credentials.');
        System.Test.stopTest();
        System.Assert.areEqual(0, [SELECT COUNT() FROM P360ScratchCapture__c]);
    }

    /**
     * Refuses capture for a minimum-access user who has not received the scratch-only permission set.
     *
     * @since 2026-11
     */
    @IsTest
    static void shouldDenyUsersWithoutCapturePermissions() {
        User minimumAccessUser = P360_TestDataFactory.createMinimumAccessUser();
        System.runAs(minimumAccessUser) {
            System.Test.startTest();
            try {
                new P360_ScratchRpcClient().send(documentRequest('scratch-p360-denied', 'synthetic'));
                System.Assert.fail('Capture must respect the caller object permissions.');
            } catch (System.QueryException expected) {
                System.Assert.isNotNull(expected.getMessage());
            } catch (System.SecurityException expected) {
                System.Assert.isNotNull(expected.getMessage());
            }
            System.Test.stopTest();
        }
        System.Assert.areEqual(0, [SELECT COUNT() FROM P360ScratchCapture__c]);
    }

    private static void configureScenario(String scenario) {
        P360ScratchSetting__c setting = P360ScratchSetting__c.getOrgDefaults();
        setting.Scenario__c = scenario;
        update setting;
    }

    private static void assertRejected(P360_RpcRequest request, String expectedMessage) {
        try {
            new P360_ScratchRpcClient().send(request);
            System.Assert.fail('The request must be explicitly rejected.');
        } catch (P360_ContractException expected) {
            System.Assert.areEqual(expectedMessage, expected.getMessage());
        }
    }

    private static P360_RpcRequest documentRequest(String externalId, String content) {
        P360_RpcRequest request = new P360_RpcRequest();
        request.serviceName = 'DocumentService';
        request.operationName = 'CreateDocument';
        request.body = JSON.serialize(
            new Map<String, Object>{
                'parameter' => new Map<String, Object>{
                    'Title' => 'Synthetic scratch document',
                    'ExternalId' => new Map<String, Object>{ 'Id' => externalId, 'Type' => 'Scratch P360' },
                    'ADUserContext' => 'scratch-p360-user',
                    'CaseNumber' => 'SCRATCH-CASE-1',
                    'Category' => 'Synthetic',
                    'Status' => 'Synthetic',
                    'Files' => new List<Object>{
                        new Map<String, Object>{
                            'Title' => 'Synthetic attachment',
                            'Format' => 'txt',
                            'Base64Data' => EncodingUtil.base64Encode(Blob.valueOf(content))
                        }
                    }
                }
            }
        );
        return request;
    }
}
