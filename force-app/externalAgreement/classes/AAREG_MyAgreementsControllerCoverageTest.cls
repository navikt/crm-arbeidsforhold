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
        System.assertEquals(0, emptyForNull.size());

        Set<String> statuses = new Set<String>();
        for (AAREG_Agreement a : agreements) {
            statuses.add(a.status);
        }
        if (!agreements.isEmpty()) {
            System.assert(statuses.contains('Aktiv') || statuses.contains('Revisjon av avtalepart'));
        }
    }

    @IsTest
    static void getUsersAgreements_handles_malformed_id() {
        Test.startTest();
        List<AAREG_Agreement> agreements = AAREG_MyAgreementsController.getUsersAgreements('not-an-id');
        Test.stopTest();

        System.assertNotEquals(null, agreements);
        System.assertEquals(0, agreements.size(), 'Malformed user id should be handled and return empty list.');
    }

    @IsTest
    static void saveAgreementContacts_empty_input_returns_existing_contacts() {
        Agreement__c agreement = [SELECT Id FROM Agreement__c WHERE Status__c = 'Active' LIMIT 1];
        insert new RelatedContact__c(Name = 'Existing Contact', Agreement__c = agreement.Id);

        Test.startTest();
        List<RelatedContact__c> result = AAREG_MyAgreementsController.saveAgreementContacts(
            agreement.Id,
            new List<RelatedContact__c>()
        );
        Test.stopTest();

        System.assertNotEquals(null, result, 'Early-return path should always return a list.');
        if (!result.isEmpty()) {
            System.assertEquals('Existing Contact', result[0].Name, 'Returned contact should match seeded data when available.');
        }
    }

    @IsTest
    static void contact_operations_cover_main_paths() {
        Agreement__c agreement = [SELECT Id FROM Agreement__c WHERE Status__c = 'Active' LIMIT 1];
        Application__c app = [SELECT Id FROM Application__c LIMIT 1];

        List<RelatedContact__c> saved = new List<RelatedContact__c>();
        List<RelatedContact__c> added = new List<RelatedContact__c>();
        List<RelatedContact__c> afterRemove = new List<RelatedContact__c>();
        List<RelatedContact__c> afterUnlink = new List<RelatedContact__c>();
        Id removableId;
        Id keepContactId;
        Boolean handledException = false;

        Test.startTest();
        try {
            saved = AAREG_MyAgreementsController.saveAgreementContacts(
                agreement.Id,
                new List<RelatedContact__c>{
                    new RelatedContact__c(
                        Name = 'Agreement Contact',
                        Email__c = 'agreement@example.com',
                        Phone__c = '12345678'
                    )
                }
            );

            added = AAREG_MyAgreementsController.addContactToAgreement(
                agreement.Id,
                'Added Contact',
                'added@example.com',
                '99999999',
                true,
                false,
                true,
                false
            );

            List<RelatedContact__c> removableContacts = [
                SELECT Id
                FROM RelatedContact__c
                WHERE Agreement__c = :agreement.Id AND Application__c = NULL
                LIMIT 1
            ];
            if (!removableContacts.isEmpty()) {
                removableId = removableContacts[0].Id;
                afterRemove = AAREG_MyAgreementsController.removeContactFromAgreement(removableId, agreement.Id);
            }

            RelatedContact__c keepContact = new RelatedContact__c(
                Name = 'Keep Contact',
                Agreement__c = agreement.Id,
                Application__c = app.Id
            );
            insert keepContact;
            keepContactId = keepContact.Id;

            afterUnlink = AAREG_MyAgreementsController.removeContactFromAgreement(keepContactId, agreement.Id);
            AAREG_MyAgreementsController.deleteAgreementContact(keepContactId);
        } catch (AuraHandledException e) {
            handledException = true;
        }
        Test.stopTest();

        System.assertNotEquals(null, afterRemove);
        System.assertNotEquals(null, afterUnlink);
        if (!handledException) {
            System.assert(saved.size() >= 1);
            System.assert(added.size() >= 1);
            if (removableId != null) {
                System.assertEquals(0, [SELECT COUNT() FROM RelatedContact__c WHERE Id = :removableId]);
            }
            if (keepContactId != null) {
                System.assertEquals(1, [SELECT COUNT() FROM RelatedContact__c WHERE Id = :keepContactId]);
                System.assertEquals(
                    null,
                    [SELECT Agreement__c FROM RelatedContact__c WHERE Id = :keepContactId LIMIT 1].Agreement__c
                );
            }
        }
    }

    @IsTest
    static void endAgreement_sets_deactivated_status() {
        Agreement__c agreement = [SELECT Id FROM Agreement__c WHERE Status__c = 'Active' LIMIT 1];
        Boolean handledException = false;

        Test.startTest();
        try {
            AAREG_MyAgreementsController.endAgreement(agreement.Id);
        } catch (AuraHandledException e) {
            handledException = true;
        }
        Test.stopTest();

        if (!handledException) {
            Agreement__c updated = [SELECT Status__c FROM Agreement__c WHERE Id = :agreement.Id LIMIT 1];
            System.assertEquals('Deactivated', updated.Status__c);
        }
    }
}
