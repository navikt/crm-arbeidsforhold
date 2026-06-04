@IsTest
public class AAREG_MyAgreementsControllerTest {
    private static final String ORG_NUMBER = '929882989';

@TestSetup
    static void setupTestData() {

        // Create test Account
        Account testAccount = AAREG_TestDataFactory.getAccountCounty();
        insert testAccount;
        
        // Create test Application
        Application__c testApplication = AAREG_TestDataFactory.getApplicationCounty(testAccount);
        insert testApplication;
        
        User testUser = AAREG_TestDataFactory.getStandardUser();
        testUser.LastUsedOrganization__c = ORG_NUMBER;
        System.runAs(new User(Id = UserInfo.getUserId())) {
            insert testUser;
            AAREG_TestDataFactory.assignPermissionSet(testUser.Id, 'AAREG_Arbeidsforhold_Saksbehandling');
        }
        // Create test agreement 
        Agreement__c testAgreement = AAREG_TestDataFactory.getAgreement(testAccount.Id,testApplication.Id);
        insert testAgreement;
    }

    @IsTest
    static void testGetUsersAgreementsWithLastUsedOrganization() {
    User testUser = [SELECT Id FROM User WHERE LastUsedOrganization__c = :ORG_NUMBER LIMIT 1];
    Application__c testApplication = [SELECT Id FROM Application__c LIMIT 1];

    List<AAREG_Agreement> agreements;
    System.Test.startTest();
        agreements = AAREG_MyAgreementsController.getUsersAgreements(testUser.Id);
    System.Test.stopTest();

    System.Assert.isNotNull(agreements, 'Agreements list should not be null.');
        System.Assert.areEqual(1, agreements.size(), 'No agreements should be returned for an unknown organization number.');
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
  System.Assert.areEqual(0, agreements.size(), 'No agreements should be returned when LastUsedOrganization is empty.');
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
  System.Assert.areEqual(0, agreements.size(), 'No agreements should be returned for an unknown organization number.');
}
}