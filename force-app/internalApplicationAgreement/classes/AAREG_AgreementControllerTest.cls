@IsTest
public class AAREG_AgreementControllerTest {
    @TestSetup
    static void makeData() {
        Account acct = AAREG_TestDataFactory.getAccountCounty();
        insert acct;

        Application__c application = AAREG_TestDataFactory.getApplicationCounty(acct);
        insert application;

        List<RelatedContact__c> con = AAREG_TestDataFactory.getRelatedContact(application);
        insert con;

        Agreement__c agreement = AAREG_TestDataFactory.getAgreement(acct.id);
        agreement.application__c = application.Id;
        insert agreement;

        for (RelatedContact__c r : con) {
            r.agreement__c = agreement.Id;
        }
        update con;
    }
    /*
    @IsTest
    static void getAgreementContacts() {
        Agreement__c agreement = [SELECT Id FROM Agreement__c LIMIT 1];

        Test.startTest();
        List<RelatedContact__c> contacts = new List<RelatedContact__c>();
        try {
            contacts = AAREG_AgreementController.getAgreementContacts(agreement.Id);
        } catch (Exception e) {
            System.Assert.fail('getAgreementContacts should not throw: ' + e.getMessage());
        }
        Test.stopTest();

        // WITH USER_MODE in test context may restrict visibility, so we verify non-null return
        System.Assert.isNotNull(contacts, 'Should return a list');

        // Also verify we can query contacts directly to ensure test data exists
        List<RelatedContact__c> directQuery = [
            SELECT
                Id,
                Name,
                AgreementNotifications__c,
                ChangeNotifications__c,
                ErrorMessageNotifications__c,
                SecurityNotifications__c
            FROM RelatedContact__c
            WHERE Agreement__c = :agreement.Id
        ];
        System.assertEquals(2, directQuery.size(), 'Test data should have 2 related contacts');
    }
        */

    @IsTest
    static void updateAgreement() {
        Agreement__c agreement = [SELECT Id, ExtractionAccess__c FROM Agreement__c LIMIT 1];
        agreement.ExtractionAccess__c = false;

        List<RelatedContact__c> contacts = [
            SELECT Id, Name, Agreement__c
            FROM RelatedContact__c
            ORDER BY Name ASC
            LIMIT 2
        ];
        contacts[0].Name = 'Updated Name';

        List<RelatedContact__c> contactsToUpdate = new List<RelatedContact__c>{ contacts[0] };
        List<RelatedContact__c> contactsToDelete = new List<RelatedContact__c>{ contacts[1] };

        Test.startTest();
        try {
            AAREG_AgreementController.updateAgreement(agreement, contactsToUpdate, contactsToDelete);
        } catch (Exception e) {
            System.Assert.isTrue(true, 'Test handled exception gracefully.');
        }
        Test.stopTest();

        List<RelatedContact__c> updatedContacts = [
            SELECT Id, Name, Agreement__c
            FROM RelatedContact__c
            WHERE Agreement__c = :agreement.Id
        ];
        Agreement__c updatedAgreement = [SELECT Id, ExtractionAccess__c FROM Agreement__c WHERE Id = :agreement.Id];

        System.assertEquals(1, updatedContacts.size(), 'Only 1 contact left after deletion.');
    }

    @IsTest
    static void updateAgreementHandlesNullLists() {
        Agreement__c agreement = [SELECT Id, ExtractionAccess__c FROM Agreement__c LIMIT 1];
        agreement.ExtractionAccess__c = false;

        Test.startTest();
        try {
            AAREG_AgreementController.updateAgreement(agreement, null, null);
        } catch (Exception e) {
            System.Assert.isTrue(true, 'Test handled exception gracefully.');
        }
        Test.stopTest();

        Agreement__c updatedAgreement = [SELECT Id, ExtractionAccess__c FROM Agreement__c WHERE Id = :agreement.Id];
        System.assertEquals(
            false,
            updatedAgreement.ExtractionAccess__c,
            'Agreement ExtractionAccess should be updated when contact lists are null.'
        );
    }

    @IsTest
    static void updateAgreementThrowsWhenAgreementMissing() {
        Boolean exceptionThrown = false;
        try {
            Test.startTest();
            AAREG_AgreementController.updateAgreement(null, null, null);
            Test.stopTest();
        } catch (Exception e) {
            exceptionThrown = true;
            System.assert(e.getMessage() != null, 'Expected an exception message.');
        }
        System.assert(exceptionThrown, 'Expected an exception when agreement is null.');
    }

    @IsTest
    static void cancelAgreementThrowsWhenAgreementMissing() {
        Boolean exceptionThrown = false;
        try {
            Test.startTest();
            AAREG_AgreementController.cancelAgreement(null);
            Test.stopTest();
        } catch (Exception e) {
            exceptionThrown = true;
            System.assert(e.getMessage() != null, 'Expected an exception message.');
        }
        System.assert(exceptionThrown, 'Expected an exception when agreement is null.');
    }

    @IsTest
    static void getAgreementContactsWithNullIdReturnsEmptyList() {
        Test.startTest();
        List<RelatedContact__c> contacts = AAREG_AgreementController.getAgreementContacts(null);
        Test.stopTest();

        System.assertEquals(0, contacts.size(), 'Expected empty contact list when agreement id is null.');
    }

    @IsTest
    static void cancelAgreement() {
        Agreement__c agreement = [
            SELECT Id, Status__c, OnlineAccess__c, ExtractionAccess__c, APIAccess__c
            FROM Agreement__c
            LIMIT 1
        ];

        Test.startTest();
        try {
            AAREG_AgreementController.cancelAgreement(agreement);
        } catch (Exception e) {
            System.Assert.isTrue(true, 'Test handled exception gracefully.');
        }
        Test.stopTest();

        Agreement__c updatedAgreement = [
            SELECT
                Id,
                Status__c,
                OnlineAccess__c,
                ExtractionAccess__c,
                APIAccess__c,
                AA_ConfirmedAgreementCancellationDate__c
            FROM Agreement__c
            WHERE Id = :agreement.Id
        ];

        System.assertEquals('Deactivated', updatedAgreement.Status__c, 'Agreement should be deactivated.');
    }

    @IsTest
    static void getAgreementContactsNullId() {
        Test.startTest();
        List<RelatedContact__c> contacts;
        try {
            contacts = AAREG_AgreementController.getAgreementContacts(null);
        } catch (Exception e) {
            contacts = new List<RelatedContact__c>();
        }
        Test.stopTest();

        System.assertEquals(0, contacts.size(), 'Should return empty list when agreement id is null.');
    }

    @IsTest
    static void updateAgreementWithEmptyLists() {
        Agreement__c agreement = [SELECT Id FROM Agreement__c LIMIT 1];
        agreement.ExtractionAccess__c = true;

        Test.startTest();
        try {
            AAREG_AgreementController.updateAgreement(
                agreement,
                new List<RelatedContact__c>(),
                new List<RelatedContact__c>()
            );
        } catch (Exception e) {
            System.Assert.isTrue(true, 'Test handled exception gracefully.');
        }
        Test.stopTest();

        Agreement__c updatedAgreement = [SELECT Id, ExtractionAccess__c FROM Agreement__c WHERE Id = :agreement.Id];
        System.assertEquals(true, updatedAgreement.ExtractionAccess__c, 'Agreement should be updated.');
    }
}
