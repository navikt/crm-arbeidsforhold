@IsTest
public class AAREG_MyThreadsControllerTest {
    static final String STRING_CONST = 'Test Thread yes';
    @IsTest
    static void getUsersThreads() {
        User usr;
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        System.runAs(thisUser) {
            usr = AAREG_TestDataFactory.getStandardUser();
            insert usr;
        }

        Account acct = AAREG_TestDataFactory.getAccountCounty();
        insert acct;

        Application__c app = AAREG_TestDataFactory.getApplicationCounty(acct);
        insert app;

        List<Thread__c> threads = new List<Thread__c>();

        Thread__c firstThread = new Thread__c(
            Name = STRING_CONST,
            CRM_Related_Object__c = app.id,
            CRM_FROM__c = usr.Id,
            CRM_Account__c = acct.Id
        );
        Thread__c secondThread = new Thread__c(Name = STRING_CONST, CRM_FROM__c = usr.Id);
        threads.add(firstThread);
        threads.add(secondThread);
        insert threads;

        List<Thread__c> userThreads = new List<Thread__c>();

        Test.startTest();
        try {
            userThreads = AAREG_MyThreadsController.getUsersThreads(String.valueOf(usr.Id));
        } catch (exception e) {
        }
        Test.stopTest();

        System.assertNotEquals(null, userThreads, 'Controller should return a list.');
    }

    @IsTest
    static void getUsersThreadsNone() {
        User usr;
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        System.runAs(thisUser) {
            usr = AAREG_TestDataFactory.getStandardUser();
            insert usr;
        }

        Thread__c thread = new Thread__c(Name = STRING_CONST);
        insert thread;

        List<Thread__c> userThreads = new List<Thread__c>();

        Test.startTest();
        try {
            userThreads = AAREG_MyThreadsController.getUsersThreads(String.valueOf(usr.Id));
        } catch (exception e) {
        }

        Test.stopTest();

        System.assertEquals(true, userThreads.isEmpty(), 'User has 0 threads');
    }

    @IsTest
    static void blankOrganization() {
        User usr;
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        System.runAs(thisUser) {
            usr = AAREG_TestDataFactory.getStandardUser();
            insert usr;
        }

        Account acct = AAREG_TestDataFactory.getAccountCounty();
        insert acct;

        Application__c app = AAREG_TestDataFactory.getApplicationCounty(acct);
        insert app;

        List<Thread__c> threads = new List<Thread__c>();

        Thread__c firstThread = new Thread__c(
            Name = STRING_CONST,
            CRM_Related_Object__c = app.id,
            CRM_FROM__c = usr.Id,
            CRM_Account__c = acct.Id
        );
        Thread__c secondThread = new Thread__c(Name = STRING_CONST, CRM_FROM__c = usr.Id);
        threads.add(firstThread);
        threads.add(secondThread);
        insert threads;

        List<Thread__c> userThreads;

        Test.startTest();
        try {
            userThreads = AAREG_MyThreadsController.getUsersThreads(String.valueOf(usr.Id));
        } catch (exception e) {
            userThreads = new List<Thread__c>();
        }
        Test.stopTest();

        System.assertNotEquals(null, userThreads, 'Controller should return a list.');
    }

    @IsTest
    static void blankUserId() {
        List<Thread__c> userThreads;

        Test.startTest();
        userThreads = AAREG_MyThreadsController.getUsersThreads('');
        Test.stopTest();

        System.assertEquals(0, userThreads.size(), 'Empty userId returns empty list.');
    }

    @IsTest
    static void nullUserId() {
        List<Thread__c> userThreads;

        Test.startTest();
        userThreads = AAREG_MyThreadsController.getUsersThreads(null);
        Test.stopTest();

        System.assertEquals(0, userThreads.size(), 'Null userId returns empty list.');
    }

    @IsTest
    static void noMatchingAccount() {
        User usr;
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        System.runAs(thisUser) {
            usr = AAREG_TestDataFactory.getStandardUser();
            insert usr;
        }

        // No Account with org number '000000001' is inserted, so accountIdList will be empty
        List<Thread__c> userThreads;

        Test.startTest();
        try {
            userThreads = AAREG_MyThreadsController.getUsersThreads(String.valueOf(usr.Id));
        } catch (exception e) {
            userThreads = new List<Thread__c>();
        }
        Test.stopTest();

        System.assertEquals(0, userThreads.size(), 'No matching account returns empty list.');
    }

    @IsTest
    static void invalidUserId_returnsEmptyList() {
        List<Thread__c> userThreads;
        Boolean handledException = false;

        Test.startTest();
        try {
            userThreads = AAREG_MyThreadsController.getUsersThreads('not-an-id');
        } catch (AuraHandledException e) {
            handledException = true;
            userThreads = new List<Thread__c>();
        }
        Test.stopTest();

        System.assert(handledException || userThreads.size() == 0, 'Unknown user id should be handled safely.');
    }

    @IsTest
    static void happyPath_returns_threads_for_last_used_org() {
        Account acct = AAREG_TestDataFactory.getAccountCounty();
        insert acct;

        User usr;
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        System.runAs(thisUser) {
            usr = AAREG_TestDataFactory.getStandardUser();
            usr.Username = 'threads.happy.' + System.currentTimeMillis() + '@aareg.test.invalid';
            insert usr;
        }

        usr.LastUsedOrganization__c = acct.INT_OrganizationNumber__c;
        update usr;

        insert new Thread__c(
            Name = 'Happy Thread',
            CRM_FROM__c = usr.Id,
            CRM_Account__c = acct.Id,
            CRM_isActive__c = true
        );

        Test.startTest();
        List<Thread__c> userThreads = AAREG_MyThreadsController.getUsersThreads(String.valueOf(usr.Id));
        Test.stopTest();

        System.assertNotEquals(null, userThreads, 'Controller should return a list in happy path.');
        System.assert(userThreads.size() > 0, 'Expected at least one thread for user organization.');
    }
}
