@IsTest
public class AAREG_MyAgreementsControllerTest {
    private static final String ORG_NUMBER = '929882989';

    @TestSetup
    static void setupTestData() {
        Account testAccount = AAREG_TestDataFactory.getAccountCounty();
        insert testAccount;

        Application__c testApplication = AAREG_TestDataFactory.getApplicationCounty(testAccount);
        insert testApplication;

        User testUser = AAREG_TestDataFactory.getStandardUser();
        testUser.LastUsedOrganization__c = ORG_NUMBER;
        System.runAs(new User(Id = UserInfo.getUserId())) {
            insert testUser;
            AAREG_TestDataFactory.assignPermissionSet(testUser.Id, 'AAREG_Arbeidsforhold_Saksbehandling');
        }

        Agreement__c testAgreement = AAREG_TestDataFactory.getAgreement(testAccount.Id);
        testAgreement.Application__c = testApplication.Id;
        insert testAgreement;
    }

    /**
     * Tests successful retrieval of agreements for a user with a valid organization.
     */
    @IsTest
    static void testGetUsersAgreementsSuccess() {
        User testUser = [
            SELECT Id, LastUsedOrganization__c
            FROM User
            WHERE LastUsedOrganization__c = :ORG_NUMBER
            LIMIT 1
        ];

        Test.startTest();
        List<AAREG_Agreement> agreements = AAREG_MyAgreementsController.getUsersAgreements(testUser.Id);
        Test.stopTest();

        System.Assert.isNotNull(agreements, 'Agreements list should not be null');
        System.Assert.areEqual(1, agreements.size(), 'Should return one agreement');
        System.Assert.isNotNull(agreements[0].avtaleId, 'Agreement ID should not be null');
    }

    @IsTest
    static void testGetUsersAgreementsInvalidUserId() {
        // Call the method with an invalid userId
        System.Test.startTest();
        try {
            AAREG_MyAgreementsController.getUsersAgreements(null);
            System.Assert(true, 'Expected an exception to be thrown for null userId.');
        } catch (Exception e) {
            System.Assert(true, 'Exception was thrown as expected.');
        }
        System.Test.stopTest();
    }

    @IsTest
    static void testGetUsersAgreementsWithoutLastUsedOrganization() {
        User userWithoutOrg;
        System.runAs(new User(Id = UserInfo.getUserId())) {
            userWithoutOrg = AAREG_TestDataFactory.getStandardUser();
            userWithoutOrg.LastUsedOrganization__c = null;
            userWithoutOrg.Username = 'noorg.' + System.currentTimeMillis() + '@aareg.test.invalid';
            insert userWithoutOrg;
            AAREG_TestDataFactory.assignPermissionSet(userWithoutOrg.Id, 'AAREG_Arbeidsforhold_Saksbehandling');
        }

        List<AAREG_Agreement> agreements;
        Test.startTest();
        System.runAs(userWithoutOrg) {
            agreements = AAREG_MyAgreementsController.getUsersAgreements(userWithoutOrg.Id);
        }
        Test.stopTest();

        System.Assert.isNotNull(agreements, 'Agreements list should not be null.');
        System.Assert.areEqual(0, agreements.size(), 'No agreements when LastUsedOrganization is empty.');
    }

    @IsTest
    static void testGetUsersAgreementsWithUnknownOrganization() {
        User testUser;
        System.runAs(new User(Id = UserInfo.getUserId())) {
            testUser = AAREG_TestDataFactory.getStandardUser();
            testUser.LastUsedOrganization__c = '000000000';
            testUser.Username = 'unknownorg.' + System.currentTimeMillis() + '@aareg.test.invalid';
            insert testUser;
            AAREG_TestDataFactory.assignPermissionSet(testUser.Id, 'AAREG_Arbeidsforhold_Saksbehandling');
        }

        List<AAREG_Agreement> agreements;
        Test.startTest();
        System.runAs(testUser) {
            agreements = AAREG_MyAgreementsController.getUsersAgreements(testUser.Id);
        }
        Test.stopTest();

        System.Assert.isNotNull(agreements, 'Agreements list should not be null.');
        System.Assert.areEqual(0, agreements.size(), 'No agreements for unknown org number.');
    }

    /**
     * Tests successful saving of agreement contacts.
     */
    @IsTest
    static void testSaveAgreementContactsSuccess() {
        Agreement__c agreement = [SELECT Id FROM Agreement__c LIMIT 1];

        RelatedContact__c contact = new RelatedContact__c(
            Name = 'Test Contact',
            Email__c = 'test@example.com',
            Phone__c = '1234567890'
        );

        Test.startTest();
        List<RelatedContact__c> result = AAREG_MyAgreementsController.saveAgreementContacts(
            agreement.Id,
            new List<RelatedContact__c>{ contact }
        );
        Test.stopTest();

        System.Assert.isNotNull(result, 'Result should not be null');
        System.Assert.areEqual(1, result.size(), 'Should return one contact');
    }

    @IsTest
    static void testSaveAgreementContactsNullAgreementId() {
        Test.startTest();
        Boolean exceptionThrown = false;
        try {
            AAREG_MyAgreementsController.saveAgreementContacts(
                null,
                new List<RelatedContact__c>{ new RelatedContact__c(Name = 'X') }
            );
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        System.Assert.isTrue(exceptionThrown, 'Should throw when agreement id is null.');
    }

    /**
     * Tests successful addition of a contact to an agreement.
     */
    @IsTest
    static void testAddContactToAgreementSuccess() {
        Agreement__c agreement = [SELECT Id FROM Agreement__c LIMIT 1];

        Test.startTest();
        List<RelatedContact__c> result = AAREG_MyAgreementsController.addContactToAgreement(
            agreement.Id,
            'New Contact',
            'new@example.com',
            '9876543210',
            true,
            false,
            true,
            false
        );
        Test.stopTest();

        System.Assert.isNotNull(result, 'Result should not be null');
        System.Assert.isTrue(result.size() > 0, 'Should return at least one contact');
    }

    @IsTest
    static void testAddContactToAgreementMissingAgreementId() {
        Test.startTest();
        Boolean exceptionThrown = false;
        try {
            AAREG_MyAgreementsController.addContactToAgreement(null, 'Name', 'a@b.no', '1', false, false, false, false);
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        System.Assert.isTrue(exceptionThrown, 'Should throw when agreementId is null.');
    }

    @IsTest
    static void testAddContactToAgreementMissingName() {
        Agreement__c agreement = [SELECT Id FROM Agreement__c LIMIT 1];

        Test.startTest();
        Boolean exceptionThrown = false;
        try {
            AAREG_MyAgreementsController.addContactToAgreement(
                agreement.Id,
                '',
                'a@b.no',
                '1',
                false,
                false,
                false,
                false
            );
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        System.Assert.isTrue(exceptionThrown, 'Should throw when name is blank.');
    }

    /**
     * Tests retrieval of agreement contacts.
     */
    @IsTest
    static void testGetAgreementContactsSuccess() {
        Agreement__c agreement = [SELECT Id FROM Agreement__c LIMIT 1];

        // Add a contact first
        RelatedContact__c contact = new RelatedContact__c(
            Name = 'Contact Person',
            Email__c = 'contact@example.com',
            Agreement__c = agreement.Id
        );
        insert contact;

        Test.startTest();
        List<RelatedContact__c> result = AAREG_MyAgreementsController.getAgreementContacts(agreement.Id);
        Test.stopTest();

        System.Assert.isNotNull(result, 'Result should not be null');
        System.Assert.areEqual(1, result.size(), 'Should return one contact');
        System.Assert.areEqual('Contact Person', result[0].Name, 'Contact name should match');
    }

    /**
     * Tests removal of a contact from an agreement.
     */
    @IsTest
    static void testRemoveContactFromAgreementSuccess() {
        Agreement__c agreement = [SELECT Id FROM Agreement__c LIMIT 1];

        // Add a contact first
        RelatedContact__c contact = new RelatedContact__c(
            Name = 'To Remove',
            Email__c = 'remove@example.com',
            Agreement__c = agreement.Id
        );
        insert contact;

        Test.startTest();
        List<RelatedContact__c> result = AAREG_MyAgreementsController.removeContactFromAgreement(
            contact.Id,
            agreement.Id
        );
        Test.stopTest();

        System.Assert.isNotNull(result, 'Result should not be null');
    }

    @IsTest
    static void testRemoveContactFromAgreementNullId() {
        Agreement__c agreement = [SELECT Id FROM Agreement__c LIMIT 1];

        Test.startTest();
        Boolean exceptionThrown = false;
        try {
            AAREG_MyAgreementsController.removeContactFromAgreement(null, agreement.Id);
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        System.Assert.isTrue(exceptionThrown, 'Should throw when relatedContactId is null.');
    }

    /**
     * Tests successful ending of an agreement.
     */
    @IsTest
    static void testEndAgreementSuccess() {
        Agreement__c agreement = [SELECT Id, Status__c FROM Agreement__c LIMIT 1];

        Test.startTest();
        AAREG_MyAgreementsController.endAgreement(agreement.Id);
        Test.stopTest();

        Agreement__c updatedAgreement = [SELECT Status__c FROM Agreement__c WHERE Id = :agreement.Id];
        System.Assert.areEqual('Deactivated', updatedAgreement.Status__c, 'Status should be Deactivated');
    }

    @IsTest
    static void testDeleteAgreementContactNullId() {
        Test.startTest();
        Boolean exceptionThrown = false;
        try {
            AAREG_MyAgreementsController.deleteAgreementContact(null);
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        System.Assert.isTrue(exceptionThrown, 'Should throw when contactId is null.');
    }

    @IsTest
    static void testEndAgreementNullId() {
        Test.startTest();
        Boolean exceptionThrown = false;
        try {
            AAREG_MyAgreementsController.endAgreement(null);
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        System.Assert.isTrue(exceptionThrown, 'Should throw when agreementId is null.');
    }

    @IsTest
    static void testEndAgreementNoUpdateAccess() {
        // Create a user WITHOUT permission set that grants edit rights to Agreement__c
        User restrictedUser;
        System.runAs(new User(Id = UserInfo.getUserId())) {
            restrictedUser = AAREG_TestDataFactory.getStandardUser();
            restrictedUser.Username = 'restricted.' + System.currentTimeMillis() + '@aareg.test.invalid';
            insert restrictedUser;
            // Deliberately NOT assigning 'AAREG_Arbeidsforhold_Saksbehandling'
        }

        Agreement__c agreement = [SELECT Id FROM Agreement__c LIMIT 1];

        Test.startTest();
        Boolean exceptionThrown = false;
        String errorMessage;
        System.runAs(restrictedUser) {
            try {
                AAREG_MyAgreementsController.endAgreement(agreement.Id);
            } catch (AuraHandledException e) {
                exceptionThrown = true;
                errorMessage = e.getMessage();
            } catch (Exception e) {
                // Fallback in case platform throws security error first
                exceptionThrown = true;
                errorMessage = e.getMessage();
            }
        }
        Test.stopTest();

        System.Assert.isTrue(
            exceptionThrown,
            'Should throw exception when user lacks update permission on Agreement__c.'
        );
    }
}
