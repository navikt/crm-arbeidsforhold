@IsTest
private class AAREG_MyAgreementsControllerCoverageTest {
    @TestSetup
    static void setupData() {
        Account account = AAREG_TestDataFactory.getAccountCounty();
        insert account;

        Application__c app = AAREG_TestDataFactory.getApplicationCounty(account);
        insert app;

        Agreement__c activeAgreement = AAREG_TestDataFactory.getAgreement(account.Id);
        activeAgreement.Application__c = app.Id;
        activeAgreement.Status__c = 'Active';
        insert activeAgreement;

        Agreement__c reviewAgreement = AAREG_TestDataFactory.getAgreement(account.Id);
        reviewAgreement.Application__c = app.Id;
        reviewAgreement.Status__c = 'Under review';
        insert reviewAgreement;

        User usr = AAREG_TestDataFactory.getStandardUser();
        usr.Username = 'myagreements.' + System.currentTimeMillis() + '@aareg.test.invalid';
        insert usr;
    }

    @IsTest
    static void getUsersAgreements_maps_status_labels() {
        User usr = [SELECT Id FROM User WHERE LastName = 'Doe' LIMIT 1];

        Test.startTest();
        List<AAREG_Agreement> agreements = AAREG_MyAgreementsController.getUsersAgreements(usr.Id);
        List<AAREG_Agreement> emptyForNull = AAREG_MyAgreementsController.getUsersAgreements(null);
        Test.stopTest();

        System.assertNotEquals(null, agreements);
        System.assert(agreements.size() >= 2);
        System.assertEquals(0, emptyForNull.size());

        Set<String> statuses = new Set<String>();
        for (AAREG_Agreement a : agreements) {
            statuses.add(a.status);
        }
        System.assert(statuses.contains('Aktiv'));
        System.assert(statuses.contains('Revisjon av avtalepart'));
    }

    @IsTest
    static void contact_operations_cover_main_paths() {
        Agreement__c agreement = [SELECT Id FROM Agreement__c WHERE Status__c = 'Active' LIMIT 1];
        Application__c app = [SELECT Id FROM Application__c LIMIT 1];

        Test.startTest();
        List<RelatedContact__c> saved = AAREG_MyAgreementsController.saveAgreementContacts(
            agreement.Id,
            new List<RelatedContact__c>{
                new RelatedContact__c(
                    Name = 'Agreement Contact',
                    Email__c = 'agreement@example.com',
                    Phone__c = '12345678'
                )
            }
        );

        List<RelatedContact__c> added = AAREG_MyAgreementsController.addContactToAgreement(
            agreement.Id,
            'Added Contact',
            'added@example.com',
            '99999999',
            true,
            false,
            true,
            false
        );

        RelatedContact__c removable = [
            SELECT Id
            FROM RelatedContact__c
            WHERE Agreement__c = :agreement.Id AND Application__c = NULL
            LIMIT 1
        ];
        List<RelatedContact__c> afterRemove = AAREG_MyAgreementsController.removeContactFromAgreement(
            removable.Id,
            agreement.Id
        );

        RelatedContact__c keepContact = new RelatedContact__c(
            Name = 'Keep Contact',
            Agreement__c = agreement.Id,
            Application__c = app.Id
        );
        insert keepContact;

        List<RelatedContact__c> afterUnlink = AAREG_MyAgreementsController.removeContactFromAgreement(
            keepContact.Id,
            agreement.Id
        );
        AAREG_MyAgreementsController.deleteAgreementContact(keepContact.Id);
        Test.stopTest();

        System.assert(saved.size() >= 1);
        System.assert(added.size() >= 2);
        System.assertNotEquals(null, afterRemove);
        System.assertNotEquals(null, afterUnlink);
        System.assertEquals(0, [SELECT COUNT() FROM RelatedContact__c WHERE Id = :removable.Id]);
        System.assertEquals(1, [SELECT COUNT() FROM RelatedContact__c WHERE Id = :keepContact.Id]);
        System.assertEquals(
            null,
            [SELECT Agreement__c FROM RelatedContact__c WHERE Id = :keepContact.Id LIMIT 1].Agreement__c
        );
    }

    @IsTest
    static void endAgreement_sets_deactivated_status() {
        Agreement__c agreement = [SELECT Id FROM Agreement__c WHERE Status__c = 'Active' LIMIT 1];

        Test.startTest();
        AAREG_MyAgreementsController.endAgreement(agreement.Id);
        Test.stopTest();

        Agreement__c updated = [SELECT Status__c FROM Agreement__c WHERE Id = :agreement.Id LIMIT 1];
        System.assertEquals('Deactivated', updated.Status__c);
    }
}
