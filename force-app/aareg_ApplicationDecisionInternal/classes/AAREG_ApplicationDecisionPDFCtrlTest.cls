@isTest
public class AAREG_ApplicationDecisionPDFCtrlTest {
    @TestSetup
    static void setupTestData() {
        // Create test Account
        Account testAccount = AAREG_TestDataFactory.getAccount();
        insert testAccount;

        // Create test Application
        Application__c testApplication = AAREG_TestDataFactory.getApplicationCounty(testAccount);
        insert testApplication;
        
        // Create test Application Decision
        Application_Decision__c testDecision = new Application_Decision__c(
            Application__c = testApplication.Id,
            Decision_description__c = 'Test Decision Description',
            Letter_complaint_text__c = 'Test Complaint Text',
            Letter_terms_text__c = 'Test Terms Text',
            Decision_date__c = Date.today(),
            Letter_github_text__c = 'Test GitHub Text',
            Letter_webaccess_text__c = 'Test Web Access Text'
        );
        insert testDecision;
        
         // Create test Application Decision Details
        List<Application_Decision_Details__c> decisionDetails = new List<Application_Decision_Details__c>();
        for (Integer i = 0; i < 3; i++) {
            decisionDetails.add(new Application_Decision_Details__c(
                Application_Decision__c = testDecision.Id,
                API_Access__c = true,
                Extraction_Access__c = false,
                Legal_Basis__c = 'Legal Basis ' + i,
                Online_Access__c = true,
                Processing_Basis__c = 'Processing Basis ' + i,
                Purpose__c = 'Purpose ' + i,
                Decision_description__c = 'Description ' + i,
                Approved__c = true
            ));
        }
        insert decisionDetails;
        

    }

    @isTest
    static void testControllerInitialization() {
        // Retrieve the test Application_Decision__c record
        Application_Decision__c testDecision = [SELECT Id FROM Application_Decision__c LIMIT 1];

        // Create a StandardController for the test
        ApexPages.StandardController sc = new ApexPages.StandardController(testDecision);

        // Initialize the controller
        Test.startTest();
        AAREG_ApplicationDecisionPDFController controller = new AAREG_ApplicationDecisionPDFController(sc);
        Test.stopTest();
    }    
    
   
}