@IsTest
public class AAREG_MyApplicationsControllerTest {
    @TestSetup
    static void makeData() {
        Account account = AAREG_TestDataFactory.getAccountCounty();
        insert account;

        Application__c application = AAREG_TestDataFactory.getApplicationCounty(account);
        application.OrganizationNumber__c = '123456789';
        insert application;
    }

    @IsTest
    static void getUsersApplications() {
        User user = AAREG_TestDataFactory.getStandardUser();
        user.LastUsedOrganization__c = '123456789';
        insert user;

        Account account = [
            SELECT Id, name, INT_OrganizationNumber__c, ShippingStreet, ShippingPostalCode, ShippingCity
            FROM Account
            LIMIT 1
        ];

        Application__c application = AAREG_TestDataFactory.getApplicationCounty(account);
        application.OrganizationNumber__c = '123456788';
        insert application;

        System.test.startTest();
        List<Application__c> applications = AAREG_MyApplicationsController.getUsersApplications(user.Id);
        System.assertEquals(1, applications.size(), 'Only on application returned');
        System.test.stoptest();
    }

    @IsTest
    static void noLastUsedOrganization() {
        User user = AAREG_TestDataFactory.getStandardUser();
        user.LastUsedOrganization__c = '';
        insert user;

        Account account = [
            SELECT Id, name, INT_OrganizationNumber__c, ShippingStreet, ShippingPostalCode, ShippingCity
            FROM Account
            LIMIT 1
        ];

        Application__c application = AAREG_TestDataFactory.getApplicationCounty(account);
        application.OrganizationNumber__c = '123456788';
        insert application;

        System.test.startTest();
        List<Application__c> applications = AAREG_MyApplicationsController.getUsersApplications(user.Id);
        System.debug(applications);
        System.assertEquals(true, applications.isEmpty(), 'Empty list returned');
        System.test.stoptest();
    }

    @IsTest
    static void getDecisionPDF_returnsDownloadUrl() {
        Application__c application = [SELECT Id FROM Application__c LIMIT 1];
        Application_Decision__c decision = new Application_Decision__c(Application__c = application.Id);
        insert decision;

        ContentVersion cv = new ContentVersion(
            Title = 'Vedtak til søknad 1',
            PathOnClient = 'vedtak.pdf',
            VersionData = Blob.valueOf('pdf-data')
        );
        insert cv;

        cv = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id LIMIT 1];
        insert new ContentDocumentLink(
            LinkedEntityId = decision.Id,
            ContentDocumentId = cv.ContentDocumentId,
            ShareType = 'V'
        );

        Test.startTest();
        String url = AAREG_MyApplicationsController.getDecisionPDF(application.Id);
        Test.stopTest();

        System.assert(url.contains('/sfc/servlet.shepherd/document/download/'), 'Expected document download URL.');
        System.assert(
            url.contains(String.valueOf(cv.ContentDocumentId)),
            'Expected linked content document id in URL.'
        );
    }

    @IsTest
    static void getDecisionPDF_noDecision_throws() {
        Account account = AAREG_TestDataFactory.getAccountCounty();
        insert account;
        Application__c application = AAREG_TestDataFactory.getApplicationCounty(account);
        insert application;

        Boolean thrown = false;
        Test.startTest();
        try {
            AAREG_MyApplicationsController.getDecisionPDF(application.Id);
        } catch (AuraHandledException e) {
            thrown = true;
        }
        Test.stopTest();

        System.assertEquals(true, thrown, 'Expected exception when no decision exists.');
    }

    @IsTest
    static void getDecisionPDF_noLinkedDocuments_throws() {
        Application__c application = [SELECT Id FROM Application__c LIMIT 1];
        Application_Decision__c decision = new Application_Decision__c(Application__c = application.Id);
        insert decision;

        Boolean thrown = false;
        Test.startTest();
        try {
            AAREG_MyApplicationsController.getDecisionPDF(application.Id);
        } catch (AuraHandledException e) {
            thrown = true;
        }
        Test.stopTest();

        System.assertEquals(true, thrown, 'Expected exception when no documents are linked.');
    }

    @IsTest
    static void getDecisionPDF_noMatchingTitle_throws() {
        Application__c application = [SELECT Id FROM Application__c LIMIT 1];
        Application_Decision__c decision = new Application_Decision__c(Application__c = application.Id);
        insert decision;

        ContentVersion cv = new ContentVersion(
            Title = 'Annen fil',
            PathOnClient = 'annen.pdf',
            VersionData = Blob.valueOf('not-matching-title')
        );
        insert cv;
        cv = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id LIMIT 1];
        insert new ContentDocumentLink(
            LinkedEntityId = decision.Id,
            ContentDocumentId = cv.ContentDocumentId,
            ShareType = 'V'
        );

        Boolean thrown = false;
        Test.startTest();
        try {
            AAREG_MyApplicationsController.getDecisionPDF(application.Id);
        } catch (AuraHandledException e) {
            thrown = true;
        }
        Test.stopTest();

        System.assertEquals(true, thrown, 'Expected exception when no matching title exists.');
    }

    @IsTest
    static void getUsersApplications_permissionDenied_throws() {
        User user = AAREG_TestDataFactory.getStandardUser();
        user.LastUsedOrganization__c = '123456789';
        insert user;

        AAREG_MyApplicationsController.forceNoApplicationAccess = true;
        Boolean thrown = false;
        Test.startTest();
        try {
            AAREG_MyApplicationsController.getUsersApplications(user.Id);
        } catch (AuraHandledException e) {
            thrown = true;
        }
        Test.stopTest();
        AAREG_MyApplicationsController.forceNoApplicationAccess = false;

        System.assertEquals(true, thrown, 'Expected permission exception when access is denied.');
    }

    @IsTest
    static void translateStatus_unknown_returnsFallback() {
        System.assertEquals(
            'Ukjent status',
            AAREG_MyApplicationsController.translateStatusForTest('TotallyUnknownStatus')
        );
        System.assertEquals('Under behandling', AAREG_MyApplicationsController.translateStatusForTest('In Progress'));
    }

    @IsTest
    static void getDecisionPDF_unexpectedError_wrapsInAuraHandledException() {
        Application__c application = [SELECT Id FROM Application__c LIMIT 1];

        AAREG_MyApplicationsController.forceUnexpectedGetDecisionPdfError = true;
        Boolean thrown = false;
        String message = null;

        Test.startTest();
        try {
            AAREG_MyApplicationsController.getDecisionPDF(application.Id);
        } catch (AuraHandledException e) {
            thrown = true;
            message = e.getMessage();
        }
        Test.stopTest();

        AAREG_MyApplicationsController.forceUnexpectedGetDecisionPdfError = false;

        System.assertEquals(true, thrown, 'Expected wrapped AuraHandledException for unexpected errors.');
        System.assertNotEquals(null, message, 'Expected an exception message.');
    }
}
