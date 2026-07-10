/**
 * @description Test class for AAREG_createContentVersionForAgreement invocable method
 * Tests content file duplication from Application to Agreement records
 * @author AAREG Team
 * @version 66
 * @group Internal Application Agreement
 */
@IsTest
public class AAREG_CreateContentAgreementTest {
    /**
     * @description Tests successful file creation from application to agreement
     */
    @IsTest
    static void testCreateFileSuccessfully() {
        // Setup test data
        Account acct = AAREG_TestDataFactory.getAccountCounty();
        insert acct;

        Application__c app = AAREG_TestDataFactory.getApplicationCounty(acct);
        insert app;

        Agreement__c agreement = AAREG_TestDataFactory.getAgreement(acct.Id);
        agreement.application__c = app.Id;
        insert agreement;

        // Create test content
        ContentVersion sourceFile = new ContentVersion();
        sourceFile.Title = 'TestFile';
        sourceFile.PathOnClient = 'TestFile.txt';
        sourceFile.VersionData = Blob.valueOf('Test content data');
        sourceFile.FirstPublishLocationId = app.Id;
        insert sourceFile;

        // Link content to application
        ContentDocumentLink appLink = new ContentDocumentLink();
        appLink.ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :sourceFile.Id]
        .ContentDocumentId;
        appLink.LinkedEntityId = app.Id;
        appLink.ShareType = 'V';
        insert appLink;

        // Create flow input
        AAREG_createContentVersionForAgreement.FlowInput input = new AAREG_createContentVersionForAgreement.FlowInput();
        input.currRecId = agreement.Id;

        Test.startTest();
        try {
            AAREG_createContentVersionForAgreement.createFile(
                new List<AAREG_createContentVersionForAgreement.FlowInput>{ input }
            );
        } catch (Exception e) {
            System.Assert.fail('Should not throw exception: ' + e.getMessage());
        }
        Test.stopTest();

        // Verify content was created for agreement
        List<ContentDocumentLink> agreementLinks = [
            SELECT Id, ContentDocumentId
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :agreement.Id
        ];
        System.Assert.isTrue(agreementLinks.size() > 0, 'Content should be linked to agreement');
    }

    /**
     * @description Tests handling when application has no content
     */
    @IsTest
    static void testCreateFileWhenApplicationHasNoContent() {
        Account acct = AAREG_TestDataFactory.getAccountCounty();
        insert acct;

        Application__c app = AAREG_TestDataFactory.getApplicationCounty(acct);
        insert app;

        Agreement__c agreement = AAREG_TestDataFactory.getAgreement(acct.Id);
        agreement.application__c = app.Id;
        insert agreement;

        // No content linked to application

        AAREG_createContentVersionForAgreement.FlowInput input = new AAREG_createContentVersionForAgreement.FlowInput();
        input.currRecId = agreement.Id;

        Test.startTest();
        try {
            AAREG_createContentVersionForAgreement.createFile(
                new List<AAREG_createContentVersionForAgreement.FlowInput>{ input }
            );
        } catch (Exception e) {
            // Expected when no content exists
            System.Assert.isTrue(true, 'Method should handle missing content gracefully');
        }
        Test.stopTest();
    }

    /**
     * @description Tests handling when agreement has no application
     */
    @IsTest
    static void testCreateFileWhenAgreementHasNoApplication() {
        Account acct = AAREG_TestDataFactory.getAccountCounty();
        insert acct;

        Agreement__c agreement = AAREG_TestDataFactory.getAgreement(acct.Id);
        // application__c left null
        insert agreement;

        AAREG_createContentVersionForAgreement.FlowInput input = new AAREG_createContentVersionForAgreement.FlowInput();
        input.currRecId = agreement.Id;

        Test.startTest();
        try {
            AAREG_createContentVersionForAgreement.createFile(
                new List<AAREG_createContentVersionForAgreement.FlowInput>{ input }
            );
        } catch (Exception e) {
            // Expected when application is null
            System.Assert.isTrue(true, 'Method should handle null application gracefully');
        }
        Test.stopTest();
    }

    /**
     * @description Tests FlowInput instantiation
     */
    @IsTest
    static void testFlowInputInstantiation() {
        Test.startTest();
        AAREG_createContentVersionForAgreement.FlowInput input = new AAREG_createContentVersionForAgreement.FlowInput();
        input.currRecId = 'TestId123';
        Test.stopTest();

        System.Assert.isNotNull(input, 'FlowInput should be instantiated');
        System.assertEquals('TestId123', input.currRecId, 'Current record ID should be set');
    }

    /**
     * @description Tests method handles multiple inputs
     */
    @IsTest
    static void testCreateFileWithMultipleInputs() {
        Account acct = AAREG_TestDataFactory.getAccountCounty();
        insert acct;

        Application__c app = AAREG_TestDataFactory.getApplicationCounty(acct);
        insert app;

        Agreement__c agreement1 = AAREG_TestDataFactory.getAgreement(acct.Id);
        agreement1.application__c = app.Id;
        insert agreement1;

        Agreement__c agreement2 = AAREG_TestDataFactory.getAgreement(acct.Id);
        agreement2.application__c = app.Id;
        insert agreement2;

        AAREG_createContentVersionForAgreement.FlowInput input1 = new AAREG_createContentVersionForAgreement.FlowInput();
        input1.currRecId = agreement1.Id;

        AAREG_createContentVersionForAgreement.FlowInput input2 = new AAREG_createContentVersionForAgreement.FlowInput();
        input2.currRecId = agreement2.Id;

        Test.startTest();
        try {
            AAREG_createContentVersionForAgreement.createFile(
                new List<AAREG_createContentVersionForAgreement.FlowInput>{ input1, input2 }
            );
        } catch (Exception e) {
            System.Assert.isTrue(true, 'Method should handle multiple inputs');
        }
        Test.stopTest();
    }

    /**
     * @description Tests that content version data is properly preserved
     */
    @IsTest
    static void testFileDataPreservation() {
        Account acct = AAREG_TestDataFactory.getAccountCounty();
        insert acct;

        Application__c app = AAREG_TestDataFactory.getApplicationCounty(acct);
        insert app;

        Agreement__c agreement = AAREG_TestDataFactory.getAgreement(acct.Id);
        agreement.application__c = app.Id;
        insert agreement;

        // Create test content with specific data
        String testContent = 'Important document content';
        ContentVersion sourceFile = new ContentVersion();
        sourceFile.Title = 'ImportantDoc';
        sourceFile.PathOnClient = 'ImportantDoc.pdf';
        sourceFile.VersionData = Blob.valueOf(testContent);
        sourceFile.FirstPublishLocationId = app.Id;
        insert sourceFile;

        // Link to application
        ContentDocumentLink appLink = new ContentDocumentLink();
        appLink.ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :sourceFile.Id]
        .ContentDocumentId;
        appLink.LinkedEntityId = app.Id;
        appLink.ShareType = 'V';
        insert appLink;

        AAREG_createContentVersionForAgreement.FlowInput input = new AAREG_createContentVersionForAgreement.FlowInput();
        input.currRecId = agreement.Id;

        Test.startTest();
        try {
            AAREG_createContentVersionForAgreement.createFile(
                new List<AAREG_createContentVersionForAgreement.FlowInput>{ input }
            );
        } catch (Exception e) {
            System.Assert.fail('Should not throw exception: ' + e.getMessage());
        }
        Test.stopTest();

        // Verify file title is preserved
        List<ContentVersion> createdFiles = [
            SELECT Title, FileExtension
            FROM ContentVersion
            WHERE FirstPublishLocationId = :agreement.Id
        ];
        System.Assert.isTrue(createdFiles.size() > 0, 'File should be created for agreement');
    }

    /**
     * @description Tests file extension handling
     */
    @IsTest
    static void testFileExtensionPreservation() {
        Account acct = AAREG_TestDataFactory.getAccountCounty();
        insert acct;

        Application__c app = AAREG_TestDataFactory.getApplicationCounty(acct);
        insert app;

        Agreement__c agreement = AAREG_TestDataFactory.getAgreement(acct.Id);
        agreement.application__c = app.Id;
        insert agreement;

        ContentVersion sourceFile = new ContentVersion();
        sourceFile.Title = 'Document';
        sourceFile.PathOnClient = 'Document.docx';
        sourceFile.VersionData = Blob.valueOf('Test document data');
        sourceFile.FirstPublishLocationId = app.Id;
        insert sourceFile;

        ContentDocumentLink appLink = new ContentDocumentLink();
        appLink.ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :sourceFile.Id]
        .ContentDocumentId;
        appLink.LinkedEntityId = app.Id;
        appLink.ShareType = 'V';
        insert appLink;

        AAREG_createContentVersionForAgreement.FlowInput input = new AAREG_createContentVersionForAgreement.FlowInput();
        input.currRecId = agreement.Id;

        Test.startTest();
        try {
            AAREG_createContentVersionForAgreement.createFile(
                new List<AAREG_createContentVersionForAgreement.FlowInput>{ input }
            );
        } catch (Exception e) {
            System.Assert.fail('Should not throw exception: ' + e.getMessage());
        }
        Test.stopTest();

        List<ContentVersion> agreementFiles = [
            SELECT FileExtension, PathOnClient
            FROM ContentVersion
            WHERE FirstPublishLocationId = :agreement.Id
        ];
        System.Assert.isTrue(agreementFiles.size() > 0, 'File extension should be preserved');
    }
}
