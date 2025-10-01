@SuppressWarnings('PMD')
@IsTest
private class AAREG_CommunityUtilsTest {
    @TestSetup
    private static void makeData() {
        Profile profile = [SELECT Id, UserLicense.Name FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User user = new User();

        user.FirstName = 'John';
        user.LastName = 'Doe';
        user.Email = 'John.Doe@nav.no';
        user.Username = 'John.Doe@nav.no';
        user.Alias = 'j.doe';
        user.LanguageLocaleKey = 'no';
        user.LocaleSidKey = 'no_NO';
        user.TimeZoneSidKey = 'Europe/Paris';
        user.EmailEncodingKey = 'UTF-8';
        user.ProfileId = profile.Id;
        user.Department = '1';
        user.LastUsedOrganization__c = '123456789';

        insert user;
        BaseTestFactory.insertEncryptionKey();
    }

    @IsTest
    private static void testGetUserRights() {
        User user = [SELECT Id FROM USER WHERE Username = 'John.Doe@nav.no' LIMIT 1];
        ApiMock.setTestMock('GET_ALTINN_RIGHTS', 200, 'OK');

        Test.startTest();
        AltinnCalloutService.AltinnRightsResponse response = AAREG_CommunityUtils.getUserRights(
            user.Id,
            '123456789',
            '5719'
        );
        Test.stopTest();

        System.debug(JSON.serializePretty(response));
        System.assertEquals(true, response.success, 'Expect success');
        System.assertEquals(null, response.errorMessage, 'Expect no error message');
        System.assertEquals(51, response.rights.size(), 'Expect 50 rights');
    }

    @IsTest
    private static void getUserRightsAV3ApplayForAccess() {
        Altinn3IntegrationSetting__c settings = new Altinn3IntegrationSetting__c();
        settings.Name = 'Altinn3IntegrationSettings';
        settings.CachePartitionName__c = 'local.tokens';
        settings.CalloutName__c = 'Altinn_Test_Access_Token';
        settings.Endpoint__c = 'Altinn_Endpoint_Test';
        settings.CacheKeyName__c = 'altinn3tokendata';
        settings.SubscriptionKey__c = 'altinn3subscriptionkey';

        insert settings;

        User user = [SELECT Id FROM USER WHERE Username = 'John.Doe@nav.no' LIMIT 1];
        List<Feature_Flag__mdt> featureFlags = new List<Feature_Flag__mdt>();
        featureFlags.add(
            new Feature_Flag__mdt(
                MasterLabel = 'Altinn Version 3',
                DeveloperName = 'Altinn_Version_3',
                Is_Enabled__c = true,
                Description__c = 'Altinn Version 3'
            )
        );
        CustomMetadataDAO.customMetadataRecordsMap.put(FeatureToggleBase.METADATA_QUERY, featureFlags);

        String body = '{"response":[{"decision":"Permit","status":{"statusMessage":null,"statusDetails":null,"statusCode":{"value":"urn:oasis:names:tc:xacml:1.0:status:ok","statusCode":null}},"obligations":[{"id":"urn:altinn:obligation:authenticationLevel1","attributeAssignment":[{"attributeId":"urn:altinn:obligation1-assignment1","value":"4","category":"urn:altinn:minimum-authenticationlevel","dataType":"http://www.w3.org/2001/XMLSchema#integer","issuer":null}]}],"associateAdvice":null,"category":null,"policyIdentifierList":null}]}';

        SingleRequestMock mock = new SingleRequestMock(200, 'OK', body, new Map<String, String>());
        Test.setMock(HttpCalloutMock.class, mock);

        System.Test.startTest();
        AltinnCalloutService.AltinnRightsResponse response = AAREG_CommunityUtils.getUserRights(
            user.Id,
            '123456789',
            '5719'
        );
        System.Test.stopTest();

        System.debug('Response: ' + JSON.serializePretty(response));
        System.Assert.areEqual(true, response.success, 'Expect success');
        System.Assert.areEqual(null, response.errorMessage, 'Expect no error message');
        System.Assert.areEqual(1, response.rights.size(), 'Expect 1 right');
        System.Assert.areEqual('nav_arbeidsforhold_aa-registeret-sok-tilgang', response.rights[0].Resource);
    }

    @IsTest
    private static void getUserRightsAV3ApplayForHenvendelse() {
        Altinn3IntegrationSetting__c settings = new Altinn3IntegrationSetting__c();
        settings.Name = 'Altinn3IntegrationSettings';
        settings.CachePartitionName__c = 'local.tokens';
        settings.CalloutName__c = 'Altinn_Test_Access_Token';
        settings.Endpoint__c = 'Altinn_Endpoint_Test';
        settings.CacheKeyName__c = 'altinn3tokendata';
        settings.SubscriptionKey__c = 'altinn3subscriptionkey';

        insert settings;

        User user = [SELECT Id FROM USER WHERE Username = 'John.Doe@nav.no' LIMIT 1];
        List<Feature_Flag__mdt> featureFlags = new List<Feature_Flag__mdt>();
        featureFlags.add(
            new Feature_Flag__mdt(
                MasterLabel = 'Altinn Version 3',
                DeveloperName = 'Altinn_Version_3',
                Is_Enabled__c = true,
                Description__c = 'Altinn Version 3'
            )
        );
        CustomMetadataDAO.customMetadataRecordsMap.put(FeatureToggleBase.METADATA_QUERY, featureFlags);

        String body = '{"response":[{"decision":"Permit","status":{"statusMessage":null,"statusDetails":null,"statusCode":{"value":"urn:oasis:names:tc:xacml:1.0:status:ok","statusCode":null}},"obligations":[{"id":"urn:altinn:obligation:authenticationLevel1","attributeAssignment":[{"attributeId":"urn:altinn:obligation1-assignment1","value":"4","category":"urn:altinn:minimum-authenticationlevel","dataType":"http://www.w3.org/2001/XMLSchema#integer","issuer":null}]}],"associateAdvice":null,"category":null,"policyIdentifierList":null}]}';

        SingleRequestMock mock = new SingleRequestMock(200, 'OK', body, new Map<String, String>());
        Test.setMock(HttpCalloutMock.class, mock);

        System.Test.startTest();
        AltinnCalloutService.AltinnRightsResponse response = AAREG_CommunityUtils.getUserRights(
            user.Id,
            '123456789',
            '5441'
        );
        System.Test.stopTest();

        System.debug('Response: ' + JSON.serializePretty(response));
        System.Assert.areEqual(true, response.success, 'Expect success');
        System.Assert.areEqual(null, response.errorMessage, 'Expect no error message');
        System.Assert.areEqual(1, response.rights.size(), 'Expect 1 right');
        System.Assert.areEqual('nav_arbeidsforhold_aa-registeret-brukerstotte', response.rights[0].Resource);
    }
}
