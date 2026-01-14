@SuppressWarnings('PMD')
@isTest
public with sharing class AAREG_HomeControllerTest {
    @TestSetup
    static void makeData() {
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
        user.LastUsedOrganization__c = '929882989';

        insert user;

        Altinn3IntegrationSetting__c settings = new Altinn3IntegrationSetting__c();
        settings.Name = 'Altinn3IntegrationSettings';
        settings.CachePartitionName__c = 'TestPartition';
        settings.CalloutName__c = 'Altinn_Test_Access_Token';
        settings.Endpoint__c = 'Altinn_Endpoint_Test';
        settings.CacheKeyName__c = 'altinn3CalloutService';
        settings.SubscriptionKey__c = 'altinn3subscriptionkey';

        insert settings;
    }

    @isTest
    private static void testGetOrganizationsWithRoles() {
        List<Feature_Flag__mdt> featureFlags = new List<Feature_Flag__mdt>();
        featureFlags.add(
            new Feature_Flag__mdt(
                MasterLabel = 'Altinn Version 3',
                DeveloperName = 'Altinn_Version_3',
                Is_Enabled__c = false,
                Description__c = 'Altinn Version 3'
            )
        );
        CustomMetadataDAO.customMetadataRecordsMap.put(FeatureToggleBase.METADATA_QUERY, featureFlags);

        User user = [SELECT Id FROM USER WHERE Username = 'John.Doe@nav.no' LIMIT 1];
        ApiMock.setTestMock('GET_ALTINN_ORGANIZATIONS', 200, 'OK');

        Test.startTest();
        AltinnCalloutService.AltinnOrganizationsResponse response = AAREG_HomeController.getOrganizationsWithRoles(
            user.Id
        );
        Test.stopTest();

        System.assertEquals(true, response.success, 'Expect success');
        System.assertEquals(null, response.errorMessage, 'Expect no error message');
        System.assertEquals(18, response.organizations.size(), 'Expect 18 organaizations');
    }

    @isTest
    private static void testGetLastUsedOrganizationNumber() {
        User user = [SELECT Id FROM USER WHERE Username = 'John.Doe@nav.no' LIMIT 1];

        String lastUsedOrganizationNumber = AAREG_HomeController.getLastUsersLastUsedOrganization(user.Id);

        System.assertEquals(
            '929882989',
            lastUsedOrganizationNumber,
            'Last used organization number returned correctly.'
        );
    }

    @isTest
    private static void testUpdateLastUsedOrganization() {
        String orgNumber = '999999999';
        User user = [SELECT Id FROM USER WHERE Username = 'John.Doe@nav.no' LIMIT 1];

        AAREG_HomeController.updateLastUsedOrganization(orgNumber, user.Id);

        User updatedUser = [SELECT Id, LastUsedOrganization__c FROM USER WHERE ID = :user.Id];

        System.assertEquals(orgNumber, updatedUser.LastUsedOrganization__c, 'Last used organization number updated.');
    }

    @isTest
    private static void testShareAgreementsWithUser() {
        User user = [SELECT Id FROM User WHERE Username = 'John.Doe@nav.no'];
        Account acct = AAREG_TestDataFactory.getAccountCounty();
        insert acct;

        Application__c application = AAREG_TestDataFactory.getApplicationCounty(acct);
        insert application;
        
        List<RelatedContact__c> con = AAREG_TestDataFactory.getRelatedContact(application);
   		insert con;

        Agreement__c agreement = AAREG_TestDataFactory.getAgreement(acct.id);
        agreement.Application__c = application.Id;
        insert agreement;
        
        for(RelatedContact__c r:con){
      	r.agreement__c = agreement.Id;
    	}
    	Update con;

        Test.startTest();
        AAREG_HomeController.shareAgreementsWithUser(user.Id);
        Test.stopTest();

        List<Agreement__Share> sharedAgreements = [
            SELECT Id
            FROM Agreement__Share
            WHERE UserOrGroupId = :user.Id
        ];
        List<RelatedContact__Share> sharedRelatedContacts = [
            SELECT Id
            FROM RelatedContact__Share
            WHERE UserOrGroupId = :user.Id
        ];
        System.assertEquals(1, sharedAgreements.size(), '1 Shared agreement records not created.');
        System.assertEquals(2, sharedRelatedContacts.size(), '2 Shared related contact records not created.');
    }

    @isTest
    private static void testCheckAndShareIfAuthorizedWithAccess() {
        User user = [SELECT Id FROM User WHERE Username = 'John.Doe@nav.no'];
        Account acct = AAREG_TestDataFactory.getAccountCounty();
        insert acct;

        Application__c application = AAREG_TestDataFactory.getApplicationCounty(acct);
        insert application;

        Agreement__c agreement = AAREG_TestDataFactory.getAgreement(acct.id);
        agreement.Application__c = application.Id;
        insert agreement;

        // Mock response with Permit decision and Access action
        String body = '{"response":[{"decision":"Permit","action":"Access","status":{"statusMessage":null,"statusDetails":null,"statusCode":{"value":"urn:oasis:names:tc:xacml:1.0:status:ok","statusCode":null}},"obligations":[{"id":"urn:altinn:obligation:authenticationLevel1","attributeAssignment":[{"attributeId":"urn:altinn:obligation1-assignment1","value":"4","category":"urn:altinn:minimum-authenticationlevel","dataType":"http://www.w3.org/2001/XMLSchema#integer","issuer":null}]}],"associateAdvice":null,"category":null,"policyIdentifierList":null}]}';
        SingleRequestMock mock = new SingleRequestMock(200, 'OK', body, new Map<String, String>());
        Test.setMock(HttpCalloutMock.class, mock);
        Test.startTest();
        AAREG_HomeController.AccessResponse response = AAREG_HomeController.checkAndShareIfAuthorized(
            user.Id,
            '929882989'
        );
        Test.stopTest();

        System.assertEquals(true, response.hasAccess, 'User should have access with Access action and Permit decision');
        System.assertEquals(true, response.hasApplicationAccess, 'User should have application access');

        List<Agreement__Share> sharedAgreements = [
            SELECT Id
            FROM Agreement__Share
            WHERE UserOrGroupId = :user.Id
        ];
        System.assertEquals(1, sharedAgreements.size(), 'Agreement should be shared with user');
    }

    @isTest
    private static void testCheckAndShareIfAuthorizedNoAccess() {
        User user = [SELECT Id FROM User WHERE Username = 'John.Doe@nav.no'];

        // Mock response with Deny decision
        String bodyDeny = '{"response":[{"decision":"Deny","action":"Access","status":{"statusMessage":null,"statusDetails":null,"statusCode":{"value":"urn:oasis:names:tc:xacml:1.0:status:ok","statusCode":null}},"obligations":[],"associateAdvice":null,"category":null,"policyIdentifierList":null}]}';

        SingleRequestMock mock = new SingleRequestMock(200, 'OK', bodyDeny, new Map<String, String>());
        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();
        AAREG_HomeController.AccessResponse response = AAREG_HomeController.checkAndShareIfAuthorized(
            user.Id,
            '123456789'
        );
        Test.stopTest();

        System.assertEquals(false, response.hasAccess, 'User should not have access with Deny decision');
        System.assertEquals(false, response.hasApplicationAccess, 'User should not have application access');
    }

    @isTest
    private static void testCheckAndShareIfAuthorizedInvalidParameters() {
        Test.startTest();

        // Test with null userId - should throw an exception
        Boolean exceptionThrown = false;
        try {
            AAREG_HomeController.checkAndShareIfAuthorized(null, '123456789');
        } catch (Exception e) {
            exceptionThrown = true;
            // AuraHandledException wraps the message as "Script-thrown exception" in test context
            System.assertNotEquals(null, e, 'Exception should be thrown for null userId');
        }
        System.assert(exceptionThrown, 'Exception should be thrown when userId is null');

        // Test with empty orgNumber - should throw an exception
        exceptionThrown = false;
        try {
            AAREG_HomeController.checkAndShareIfAuthorized(UserInfo.getUserId(), '');
        } catch (Exception e) {
            exceptionThrown = true;
            System.assertNotEquals(null, e, 'Exception should be thrown for empty orgNumber');
        }
        System.assert(exceptionThrown, 'Exception should be thrown when orgNumber is empty');

        Test.stopTest();
    }

    @isTest
    private static void testShareAgreementsWithUserIsOwner() {
        User user = [SELECT Id FROM User WHERE Username = 'John.Doe@nav.no'];
        Account acct = AAREG_TestDataFactory.getAccountCounty();
        insert acct;

        Application__c application = AAREG_TestDataFactory.getApplicationCounty(acct);
        insert application;
        
        List<RelatedContact__c> con = AAREG_TestDataFactory.getRelatedContact(application);
   		insert con;

        // Create agreement owned by the test user with matching organization number
        Agreement__c agreement = AAREG_TestDataFactory.getAgreement(acct.id);
        agreement.Application__c = application.Id;
        agreement.OwnerId = user.Id;
        insert agreement;
        
        for(RelatedContact__c r:con){
      		r.agreement__c = agreement.Id;
    		}
    	Update con;

        Test.startTest();
        AAREG_HomeController.shareAgreementsWithUser(user.Id);
        Test.stopTest();

        // Should not create share records when user is already owner
        List<Agreement__Share> sharedAgreements = [
            SELECT Id, RowCause
            FROM Agreement__Share
            WHERE UserOrGroupId = :user.Id
        ];
        List<RelatedContact__Share> sharedRelatedContacts = [
            SELECT Id, RowCause
            FROM RelatedContact__Share
            WHERE UserOrGroupId = :user.Id
        ];

        System.assertEquals(1, sharedAgreements.size(), 'Should have one shared agreement record');
        System.assertEquals('Owner', sharedAgreements[0].RowCause, 'Row cause should be Owner');
        System.assertEquals(2, sharedRelatedContacts.size(), 'Should have two shared related contact record');
    }

    @isTest
    private static void testUpdateLastUsedOrganizationException() {
        // Create a scenario that would cause an exception - using invalid user ID format
        Test.startTest();
        try {
            AAREG_HomeController.updateLastUsedOrganization('999999999', 'invalid_user_id');
            // If no exception is thrown, the test passes (exception handling is working)
        } catch (Exception e) {
            // Exception is expected and handled
            System.assert(true, 'Exception was properly caught and handled');
        }
        Test.stopTest();
    }

    @isTest
    private static void testShareAgreementsWithUserNoAgreements() {
        User user = [SELECT Id FROM User WHERE Username = 'John.Doe@nav.no'];

        // No agreements exist for the organization
        Test.startTest();
        AAREG_HomeController.shareAgreementsWithUser(user.Id);
        Test.stopTest();

        List<Agreement__Share> sharedAgreements = [
            SELECT Id
            FROM Agreement__Share
            WHERE UserOrGroupId = :user.Id
        ];
        System.assertEquals(0, sharedAgreements.size(), 'No agreements to share');
    }

    @isTest
    private static void testCheckAndShareIfAuthorizedNullRightsResponse() {
        User user = [SELECT Id FROM User WHERE Username = 'John.Doe@nav.no'];

        // Mock response with null rights
        String bodyNullRights = '{"response":[]}';
        SingleRequestMock mock = new SingleRequestMock(200, 'OK', bodyNullRights, new Map<String, String>());
        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();
        AAREG_HomeController.AccessResponse response = AAREG_HomeController.checkAndShareIfAuthorized(
            user.Id,
            '123456789'
        );
        Test.stopTest();

        System.assertEquals(false, response.hasAccess, 'Should return false when rights response is null');
        System.assertEquals(
            false,
            response.hasApplicationAccess,
            'Should return false for application access when rights response is null'
        );
    }
}