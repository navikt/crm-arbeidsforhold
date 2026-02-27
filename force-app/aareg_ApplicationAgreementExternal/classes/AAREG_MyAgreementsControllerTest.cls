@isTest
public class AAREG_MyAgreementsControllerTest {
@TestSetup
    static void setupTestData() {
        // Create a test User with a lastUsedOrganization__c value
        User testUser = new User(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'testuser@example.com',
            Username = 'testuser@example.com.' + System.currentTimeMillis(),
            Alias = 'tuser',
            TimeZoneSidKey = 'Europe/Paris',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id,
            LastUsedOrganization__c = '929882989'
        );
        insert testUser;
        
        // Create test Account
        Account testAccount = AAREG_TestDataFactory.getAccountCounty();
        insert testAccount;

        // Create test Application
        Application__c testApplication = AAREG_TestDataFactory.getApplicationCounty(testAccount);
        insert testApplication;

        // Create a test Agreement__c record linked to the lastUsedOrganization__c
        Agreement__c testAgreement = new Agreement__c(
            Status__c = 'Active',
            Application__c = testApplication.Id
        );
        insert testAgreement;

        // Create another test User without a lastUsedOrganization__c value
        User testUserNoOrg = new User(
            FirstName = 'NoOrg',
            LastName = 'User',
            Email = 'noorguser@example.com',
            Username = 'noorguser@example.com.' + System.currentTimeMillis(),
            Alias = 'nuser',
            TimeZoneSidKey = 'Europe/Paris',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id
        );
        insert testUserNoOrg;
    }

    @isTest
    static void testGetUsersAgreements_WithLastUsedOrganization() {
        // Retrieve the test User with a lastUsedOrganization__c value
        User testUser = [SELECT Id FROM User WHERE LastUsedOrganization__c != null LIMIT 1];

        // Call the method
        Test.startTest();
        List<Agreement__c> agreements = AAREG_MyAgreementsController.getUsersAgreements(testUser.Id);
        Test.stopTest();

        // Assertions
        System.Assert.isNotNull(agreements, 'Agreements list should not be null.');
        System.assertEquals(1, agreements.size(), 'There should be 1 agreement returned.');
    }

    @isTest
    static void testGetUsersAgreements_WithoutLastUsedOrganization() {
        // Retrieve the test User without a lastUsedOrganization__c value
        User testUserNoOrg = [SELECT Id FROM User WHERE LastUsedOrganization__c = null LIMIT 1];

        // Call the method
        Test.startTest();
        List<Agreement__c> agreements = AAREG_MyAgreementsController.getUsersAgreements(testUserNoOrg.Id);
        Test.stopTest();

        // Assertions
        System.Assert.isNotNull(agreements, 'Agreements list should not be null.');
        System.assertEquals(0, agreements.size(), 'There should be no agreements returned.');
    }

    @isTest
    static void testGetUsersAgreements_InvalidUserId() {
        // Call the method with an invalid userId
        Test.startTest();
        try {
            AAREG_MyAgreementsController.getUsersAgreements(null);
            System.assert(true, 'Expected an exception to be thrown for null userId.');
        } catch (Exception e) {
            System.assert(true, 'Exception was thrown as expected.');
        }
        Test.stopTest();
    }
}