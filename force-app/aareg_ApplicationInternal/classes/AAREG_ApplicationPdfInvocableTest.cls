@IsTest
private class AAREG_ApplicationPdfInvocableTest {

    @TestSetup
    static void setup() {
        Account acc = new Account(Name = 'Test Konsument');
        insert acc;
    }

    @IsTest
    static void testInvocableGeneratesPdf() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Application__c app = new Application__c(
            Account__c = acc.Id,
            Status__c = 'New'
        );
        insert app;

        AAREG_ApplicationPdfInvocable.PdfRequest req = 
            new AAREG_ApplicationPdfInvocable.PdfRequest();
        req.applicationId = app.Id;

        Test.startTest();
        AAREG_ApplicationPdfInvocable.generatePdfs(
            new List<AAREG_ApplicationPdfInvocable.PdfRequest>{ req }
        );
        Test.stopTest();

        List<ContentDocumentLink> links = [
            SELECT ContentDocumentId
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :app.Id
        ];

        System.Assert.areEqual(1, links.size(), 'Skal være én PDF-link.');
    }

    @IsTest
    static void testFlowTriggersOnNewStatus() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Test.startTest();
        // Insert trigger flowen som kaller invocable
        Application__c app = new Application__c(
            Account__c = acc.Id,
            Status__c = 'New'
        );
        insert app;
        Test.stopTest();

        List<ContentDocumentLink> links = [
            SELECT ContentDocumentId
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :app.Id
        ];

        System.Assert.areEqual(
            1, links.size(),
            'Flowen skal ha trigget PDF-generering ved status=New.'
        );
    }

    @IsTest
    static void testNewVersionOnStatusReturn() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Application__c app = new Application__c(
            Account__c = acc.Id,
            Status__c = 'New'
        );
        insert app;

        Test.startTest();
        app.Status__c = 'Additional Information Required';
        update app;

        app.Status__c = 'In progress';
        update app;
        Test.stopTest();

        List<ContentDocumentLink> links = [
            SELECT ContentDocumentId
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :app.Id
        ];

        System.Assert.areEqual(
            1, links.size(),
            'Skal fortsatt være ÉN ContentDocument-link (ny versjon).'
        );

        Integer versionCount = [
            SELECT COUNT()
            FROM ContentVersion
            WHERE ContentDocumentId = :links[0].ContentDocumentId
        ];

        System.Assert.areEqual(
            2, versionCount,
            'Skal være to versjoner etter status-endringene.'
        );
    }
}