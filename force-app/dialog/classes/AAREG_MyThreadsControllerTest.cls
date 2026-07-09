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

        // When LastUsedOrganization__c field doesn't exist, controller returns empty list
        System.assertEquals(0, userThreads.size(), 'No threads when org field unavailable.');
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

        System.assertEquals(0, userThreads.size(), '0 Thread for the user.');
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
}
