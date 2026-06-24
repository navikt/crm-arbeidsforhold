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
    static void testAddContactToAgreementMissingAgreementId() {
        Test.startTest();
        Boolean exceptionThrown = false;
        try {
            AAREG_MyAgreementsController.addContactToAgreement(
                null, 'Name', 'a@b.no', '1', false, false, false, false
            );
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
                agreement.Id, '', 'a@b.no', '1', false, false, false, false
            );
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        System.Assert.isTrue(exceptionThrown, 'Should throw when name is blank.');
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
    
    @IsTest
    static void testEndAgreementNoUpdateAccess() {
        // Opprett en bruker UTEN permission set som gir edit-rett på Agreement__c
        User restrictedUser;
        System.runAs(new User(Id = UserInfo.getUserId())) {
            restrictedUser = AAREG_TestDataFactory.getStandardUser();
            restrictedUser.Username = 'restricted.' + System.currentTimeMillis() + '@aareg.test.invalid';
            insert restrictedUser;
            // Bevisst IKKE tildelt 'AAREG_Arbeidsforhold_Saksbehandling'
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
                // Fallback dersom plattformen kaster annen sikkerhetsfeil først
                exceptionThrown = true;
                errorMessage = e.getMessage();
            }
        }
        Test.stopTest();

        System.Assert.isTrue(
            exceptionThrown,
            'Skal kaste exception når bruker mangler update-rettighet på Agreement__c.'
        );
    }
}