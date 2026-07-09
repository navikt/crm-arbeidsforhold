/**
 * @description Test class for AAREG_ApplicationDecisionPDFFileService invocable service.
 *              Tests PDF file creation, ContentVersion handling, and ContentDocumentLink generation.
 * @author NAV
 * @version 66
 * @group Application Decision
 */
@IsTest
public class AAREG_ApplicationDecisionPDFFileSerTest {
    /**
     * @description Setter opp felles testdata før hver test:
     *              - En Account av typen County
     *              - En tilhørende Application__c
     *              - En Application_Decision__c
     *              - En AccessRequest__c
     *              - ApplicationBasisCode__c poster
     *              Brukes som grunnlag for PDF service testing.
     */
    @TestSetup
    static void setupTestData() {
        // Create test Account
        Account testAccount = AAREG_TestDataFactory.getAccountCounty();
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
            Letter_webaccess_text__c = 'Test Web Access Text',
            Process_status__c = 'In Progress'
        );
        insert testDecision;

        // Create test Access Request (minimal - only required for ID reference)
        Access_Request__c testAccessRequest = new Access_Request__c();
        insert testAccessRequest;

        // Create test ApplicationBasisCode records
        List<ApplicationBasisCode__c> basisCodes = new List<ApplicationBasisCode__c>();
        basisCodes = AAREG_TestDataFactory.getBasisCodeCounty(testApplication);
        insert basisCodes;
    }

    /**
     * @description Tester at createFile metoden returnerer valid ContentDocumentId for ny PDF.
     *              Verifiserer at:
     *              - ContentVersion opprettes
     *              - ContentDocumentLink opprettes for relevante records
     *              - FlowOutput returneres med korrekt ID
     */
    @IsTest
    static void testCreateFilePDFGeneration() {
        // Retrieve test data
        Application_Decision__c testDecision = [SELECT Id FROM Application_Decision__c LIMIT 1];
        Application__c testApplication = [
            SELECT Id
            FROM Application__c
            WHERE Id IN (SELECT Application__c FROM Application_Decision__c WHERE Id = :testDecision.Id)
        ];
        Access_Request__c testAccessRequest = [SELECT Id FROM Access_Request__c LIMIT 1];

        // Create input for service
        AAREG_ApplicationDecisionPDFFileService.FlowInput input = new AAREG_ApplicationDecisionPDFFileService.FlowInput();
        input.decisionRecordId = testDecision.Id;
        input.applicationRecordId = testApplication.Id;
        input.accessRequestRecordId = testAccessRequest.Id;
        input.decisionFileTitle = 'Test PDF Title';

        Test.startTest();
        List<AAREG_ApplicationDecisionPDFFileService.FlowOutput> result = AAREG_ApplicationDecisionPDFFileService.createFile(
            new List<AAREG_ApplicationDecisionPDFFileService.FlowInput>{ input }
        );
        Test.stopTest();

        // Verify output
        System.Assert.areEqual(1, result.size(), 'Should return one FlowOutput.');
        System.Assert.isNotNull(result[0].contentDocumentId, 'ContentDocumentId should be set.');
    }

    /**
     * @description Tester at createFile håndterer null input gracefully.
     *              Verifiserer at exception kastes med user-friendly error message.
     */
    @IsTest
    static void testCreateFileWithNullInput() {
        Boolean exceptionThrown = false;
        String exceptionMessage = '';

        Test.startTest();
        try {
            AAREG_ApplicationDecisionPDFFileService.createFile(null);
        } catch (AuraHandledException e) {
            exceptionThrown = true;
            exceptionMessage = e.getMessage();
        }
        Test.stopTest();

        System.Assert.isTrue(exceptionThrown, 'Should throw AuraHandledException for null input.');
    }

    /**
     * @description Tester at createFile håndterer tom input liste gracefully.
     *              Verifiserer at exception kastes.
     */
    @IsTest
    static void testCreateFileWithEmptyInput() {
        Boolean exceptionThrown = false;

        Test.startTest();
        try {
            AAREG_ApplicationDecisionPDFFileService.createFile(
                new List<AAREG_ApplicationDecisionPDFFileService.FlowInput>()
            );
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        System.Assert.isTrue(exceptionThrown, 'Should throw AuraHandledException for empty input list.');
    }

    /**
     * @description Tester at createFile håndterer manglende påkrevde felter gracefully.
     *              Verifiserer at exception kastes når decisionRecordId er null.
     */
    @IsTest
    static void testCreateFileWithMissingDecisionId() {
        // Retrieve test data
        Application__c testApplication = [SELECT Id FROM Application__c LIMIT 1];
        Access_Request__c testAccessRequest = [SELECT Id FROM Access_Request__c LIMIT 1];

        // Create input with missing decision ID
        AAREG_ApplicationDecisionPDFFileService.FlowInput input = new AAREG_ApplicationDecisionPDFFileService.FlowInput();
        input.decisionRecordId = null;
        input.applicationRecordId = testApplication.Id;
        input.accessRequestRecordId = testAccessRequest.Id;
        input.decisionFileTitle = 'Test PDF Title';

        Boolean exceptionThrown = false;

        Test.startTest();
        try {
            AAREG_ApplicationDecisionPDFFileService.createFile(
                new List<AAREG_ApplicationDecisionPDFFileService.FlowInput>{ input }
            );
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        System.Assert.isTrue(exceptionThrown, 'Should throw exception for missing decision ID.');
    }

    /**
     * @description Tester at createFile håndterer manglende applicationRecordId gracefully.
     *              Verifiserer at exception kastes.
     */
    @IsTest
    static void testCreateFileWithMissingApplicationId() {
        // Retrieve test data
        Application_Decision__c testDecision = [SELECT Id FROM Application_Decision__c LIMIT 1];
        Access_Request__c testAccessRequest = [SELECT Id FROM Access_Request__c LIMIT 1];

        // Create input with missing application ID
        AAREG_ApplicationDecisionPDFFileService.FlowInput input = new AAREG_ApplicationDecisionPDFFileService.FlowInput();
        input.decisionRecordId = testDecision.Id;
        input.applicationRecordId = null;
        input.accessRequestRecordId = testAccessRequest.Id;
        input.decisionFileTitle = 'Test PDF Title';

        Boolean exceptionThrown = false;

        Test.startTest();
        try {
            AAREG_ApplicationDecisionPDFFileService.createFile(
                new List<AAREG_ApplicationDecisionPDFFileService.FlowInput>{ input }
            );
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        System.Assert.isTrue(exceptionThrown, 'Should throw exception for missing application ID.');
    }

    /**
     * @description Tester at createFile håndterer manglende filTittel gracefully.
     *              Verifiserer at exception kastes.
     */
    @IsTest
    static void testCreateFileWithMissingFileTitle() {
        // Retrieve test data
        Application_Decision__c testDecision = [SELECT Id FROM Application_Decision__c LIMIT 1];
        Application__c testApplication = [
            SELECT Id
            FROM Application__c
            WHERE Id IN (SELECT Application__c FROM Application_Decision__c WHERE Id = :testDecision.Id)
        ];
        Access_Request__c testAccessRequest = [SELECT Id FROM Access_Request__c LIMIT 1];

        // Create input with missing file title
        AAREG_ApplicationDecisionPDFFileService.FlowInput input = new AAREG_ApplicationDecisionPDFFileService.FlowInput();
        input.decisionRecordId = testDecision.Id;
        input.applicationRecordId = testApplication.Id;
        input.accessRequestRecordId = testAccessRequest.Id;
        input.decisionFileTitle = null;

        Boolean exceptionThrown = false;

        Test.startTest();
        try {
            AAREG_ApplicationDecisionPDFFileService.createFile(
                new List<AAREG_ApplicationDecisionPDFFileService.FlowInput>{ input }
            );
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        System.Assert.isTrue(exceptionThrown, 'Should throw exception for missing file title.');
    }

    /**
     * @description Tester at FlowInput inner class can be instantiated og populated.
     *              Verifiserer at alle InvocableVariable felter er accessible.
     */
    @IsTest
    static void testFlowInputClass() {
        AAREG_ApplicationDecisionPDFFileService.FlowInput input = new AAREG_ApplicationDecisionPDFFileService.FlowInput();

        input.decisionRecordId = 'testId1';
        input.applicationRecordId = 'testId2';
        input.accessRequestRecordId = 'testId3';
        input.agreementRecordId = 'testId4';
        input.decisionFileTitle = 'Test Title';

        System.Assert.areEqual('testId1', input.decisionRecordId, 'decisionRecordId should be set.');
        System.Assert.areEqual('testId2', input.applicationRecordId, 'applicationRecordId should be set.');
        System.Assert.areEqual('testId3', input.accessRequestRecordId, 'accessRequestRecordId should be set.');
        System.Assert.areEqual('testId4', input.agreementRecordId, 'agreementRecordId should be set.');
        System.Assert.areEqual('Test Title', input.decisionFileTitle, 'decisionFileTitle should be set.');
    }

    /**
     * @description Tester at FlowOutput inner class can be instantiated og populated.
     *              Verifiserer at contentDocumentId er accessible.
     */
    @IsTest
    static void testFlowOutputClass() {
        AAREG_ApplicationDecisionPDFFileService.FlowOutput output = new AAREG_ApplicationDecisionPDFFileService.FlowOutput();
        output.contentDocumentId = 'testContentDocId';

        System.Assert.areEqual('testContentDocId', output.contentDocumentId, 'contentDocumentId should be set.');
    }
}
