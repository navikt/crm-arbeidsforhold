@IsTest
private class AAREG_ApplicationPdfServiceTest {

    @TestSetup
    static void setup() {
        Account acc = new Account(Name = 'Test Konsument');
        insert acc;
    }

    @IsTest
    static void testCreatePdfOnNewStatus() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Test.startTest();
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

        System.Assert.areEqual(1, links.size(), 'Skal være én PDF-link.');

        List<ContentVersion> versions = [
            SELECT VersionNumber, Title
            FROM ContentVersion
            WHERE ContentDocumentId = :links[0].ContentDocumentId
        ];

        System.Assert.areEqual(1, versions.size(), 'Skal være versjon 1.');
        System.Assert.isTrue(
            versions[0].Title.startsWith('Soknad_'),
            'Tittel skal følge konvensjon.'
        );
    }

    @IsTest
    static void testNewVersionWhenStatusReturnsToInProgress() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Application__c app = new Application__c(
            Account__c = acc.Id,
            Status__c = 'New'
        );
        insert app;

        // Simuler første kjøring av Queueable
        Test.getEventBus().deliver();

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
            'Skal fortsatt være ÉN ContentDocument-link (ny versjon, ikke nytt dokument).'
        );

        List<ContentVersion> versions = [
            SELECT VersionNumber, Title
            FROM ContentVersion
            WHERE ContentDocumentId = :links[0].ContentDocumentId
            ORDER BY VersionNumber ASC
        ];

        System.Assert.areEqual(
            2, versions.size(),
            'Skal være to versjoner etter status-endringene.'
        );
    }

    @IsTest
    static void testNoPdfWhenStatusUnchanged() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Application__c app = new Application__c(
            Account__c = acc.Id,
            Status__c = 'In progress'
        );
        insert app;

        Test.startTest();
        app.Email__c = 'test@example.com';
        update app;
        Test.stopTest();

        Integer count = [
            SELECT COUNT()
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :app.Id
        ];

        System.Assert.areEqual(0, count, 'Skal ikke generere PDF ved statusløse oppdateringer.');
    }
}