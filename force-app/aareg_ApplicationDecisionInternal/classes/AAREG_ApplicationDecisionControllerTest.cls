@isTest
public class AAREG_ApplicationDecisionControllerTest {
    
     @TestSetup
    static void setupTestData() {
         // Create a test Account
        Account testAccount = AAREG_TestDataFactory.getAccountCounty();
        insert testAccount;

        // Create a test Application
        Application__c testApplication = AAREG_TestDataFactory.getApplicationCounty(testAccount);
        insert testApplication;
        
         // Create test ApplicationBasisCode records
        List<ApplicationBasisCode__c> basisCodes = AAREG_TestDataFactory.getBasisCodeCounty(testApplication);
        insert basisCodes;
        
        // Create test Application_Decision__c records
        List<Application_Decision__c> decisions = new List<Application_Decision__c>();
        decisions.add(new Application_Decision__c(
            Application__c = testApplication.Id
        ));
        decisions.add(new Application_Decision__c(
            Application__c = testApplication.Id
        ));
        insert decisions;
    }
    
     @isTest
    static void testGetApplicationDecision() {
       // Retrieve the test Application
        Application__c testApplication = [SELECT Id FROM Application__c LIMIT 1];
        
        // Call the method
        Test.startTest();
        List<AAREG_ApplicationDecision> result = AAREG_ApplicationDecisionController.getApplicationDecision(testApplication.Id);
        Test.stopTest();

        // Assertions
        System.Assert.areEqual(2, result.size(), 'There should be two decisions.');
    }
    
    @isTest
    static void testCreateApplicationDecision() {
        // Retrieve the test Application
        Application__c testApplication = [SELECT Id FROM Application__c LIMIT 1];

        // Call the method
        Test.startTest();
        Id newDecisionId = AAREG_ApplicationDecisionController.createApplicationDecision(testApplication.Id);
        Test.stopTest();

        // Verify the new decision
        Application_Decision__c newDecision = [SELECT Id, Application__c, Status__c FROM Application_Decision__c WHERE Id = :newDecisionId];
        System.Assert.areEqual(testApplication.Id, newDecision.Application__c, 'Application ID should match.');
        System.Assert.areEqual('Innvilget', newDecision.Status__c, 'Status should be Innvilget.');


        // Verify the related Application_Decision_Details__c records
        List<Application_Decision_Details__c> decisionDetails = [
            SELECT Id, Application_Decision__c, API_Access__c, Extraction_Access__c, Online_Access__c, Processing_Basis__c
            FROM Application_Decision_Details__c
            WHERE Application_Decision__c = :newDecisionId
        ];
        System.Assert.areEqual(2, decisionDetails.size(), 'There should be two decision details.');
        System.Assert.areEqual(true, decisionDetails[0].API_Access__c, 'First detail API_Access__c should match.');
        System.Assert.areEqual(false, decisionDetails[1].API_Access__c, 'Second detail API_Access__c should match.');
    }
    
}