/**
 * Test class for AAREG_MyApplicationsController.
 *
 * @author Jordan Mathews
 * @author Kenneth Sørensen
 * @since July 2021
 * @group AAREG External Application
 */
@IsTest
public class AAREG_MyApplicationsControllerTest {
    /**
     * Creates a county account and application with an organization number.
     *
     * @since July 2021
     */
    @TestSetup
    static void makeData() {
        Account account = AAREG_TestDataFactory.getAccountCounty();
        insert account;

        Application__c application = AAREG_TestDataFactory.getApplicationCounty(account);
        application.OrganizationNumber__c = '123456789';
        insert application;
    }

    /**
     * getUsersApplications should return only the applications for the user's last used organization.
     *
     * @since August 2021
     */
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

    /**
     * getUsersApplications should return an empty list when the user has no last used organization.
     *
     * @since August 2021
     */
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

    /**
     * getDecisionPDF should return a download URL when a matching decision file exists.
     *
     * @since August 2026
     */
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

    /**
     * getDecisionPDFs should return decision URLs for applications that have matching decision files.
     *
     * @since September 2026
     */
    @IsTest
    static void getDecisionPDFs_returnsDecisionUrls() {
        Application__c firstApplication = [SELECT Id FROM Application__c LIMIT 1];
        Account secondAccount = AAREG_TestDataFactory.getAccountCounty();
        insert secondAccount;
        Application__c secondApplication = AAREG_TestDataFactory.getApplicationCounty(secondAccount);
        secondApplication.OrganizationNumber__c = '987654321';
        insert secondApplication;

        Application_Decision__c firstDecision = new Application_Decision__c(Application__c = firstApplication.Id);
        Application_Decision__c secondDecision = new Application_Decision__c(Application__c = secondApplication.Id);
        insert new List<Application_Decision__c>{ firstDecision, secondDecision };

        ContentVersion firstVersion = new ContentVersion(
            Title = 'Vedtak til søknad 1',
            PathOnClient = 'vedtak-1.pdf',
            VersionData = Blob.valueOf('pdf-data-1')
        );
        ContentVersion secondVersion = new ContentVersion(
            Title = 'Vedtak til søknad 2',
            PathOnClient = 'vedtak-2.pdf',
            VersionData = Blob.valueOf('pdf-data-2')
        );
        insert new List<ContentVersion>{ firstVersion, secondVersion };

        firstVersion = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :firstVersion.Id LIMIT 1];
        secondVersion = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :secondVersion.Id LIMIT 1];
        insert new List<ContentDocumentLink>{
            new ContentDocumentLink(
                LinkedEntityId = firstDecision.Id,
                ContentDocumentId = firstVersion.ContentDocumentId,
                ShareType = 'V'
            ),
            new ContentDocumentLink(
                LinkedEntityId = secondDecision.Id,
                ContentDocumentId = secondVersion.ContentDocumentId,
                ShareType = 'V'
            )
        };

        Test.startTest();
        Map<Id, String> result = AAREG_MyApplicationsController.getDecisionPDFs(
            new List<Id>{ firstApplication.Id, secondApplication.Id }
        );
        Test.stopTest();

        System.assertEquals(2, result.size(), 'Expected URLs for both applications.');
        System.assert(
            result.get(firstApplication.Id).contains(String.valueOf(firstVersion.ContentDocumentId)),
            'Expected first application URL to include first content document id.'
        );
        System.assert(
            result.get(secondApplication.Id).contains(String.valueOf(secondVersion.ContentDocumentId)),
            'Expected second application URL to include second content document id.'
        );
    }

    /**
     * getDecisionPDF should throw when no Application_Decision__c exists for the application.
     *
     * @since August 2026
     */
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

    /**
     * getDecisionPDF should throw when the decision has no linked documents.
     *
     * @since August 2026
     */
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

    /**
     * getDecisionPDF should throw when no linked document matches the expected decision title.
     *
     * @since August 2026
     */
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

    /**
     * getUsersApplications should throw when access is denied.
     *
     * @since August 2026
     */
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

    /**
     * translateStatusForTest should return a fallback label for unknown statuses.
     *
     * @since August 2026
     */
    @IsTest
    static void translateStatus_unknown_returnsFallback() {
        System.assertEquals(
            'Ukjent status',
            AAREG_MyApplicationsController.translateStatusForTest('TotallyUnknownStatus')
        );
        System.assertEquals('Under behandling', AAREG_MyApplicationsController.translateStatusForTest('In Progress'));
    }

    /**
     * getDecisionPDF should wrap unexpected errors in an AuraHandledException.
     *
     * @since August 2026
     */
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
