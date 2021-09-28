@isTest
public class AAREG_MyThreadsControllerTest {
  @isTest
  static void getUsersThreads() {
    User usr = AAREG_TestDataFactory.getStandardUser();
    insert usr;

    Account acct = AAREG_TestDataFactory.getAccount();
    insert acct;

    List<Thread__c> threads = new List<Thread__c>();

    Thread__c firstThread = new Thread__c(Name = 'Test Thread', CRM_FROM__c = usr.Id, CRM_Account__c = acct.Id);
    Thread__c secondThread = new Thread__c(Name = 'Test Thread', CRM_FROM__c = usr.Id);
    threads.add(firstThread);
    threads.add(secondThread);

    insert threads;

    List<Thread__c> userThreads;

    Test.startTest();
    userThreads = AAREG_MyThreadsController.getUsersThreads(String.valueOf(usr.Id));
    Test.stopTest();

    System.assertEquals(1, userThreads.size(), '1 Thread for the user.');
  }

  @isTest
  static void getUsersThreadsNone() {
    User usr = AAREG_TestDataFactory.getStandardUser();
    insert usr;

    Thread__c thread = new Thread__c(Name = 'Test Thread');
    insert thread;

    List<Thread__c> userThreads;

    Test.startTest();
    userThreads = AAREG_MyThreadsController.getUsersThreads(String.valueOf(usr.Id));
    Test.stopTest();

    System.assertEquals(0, userThreads.size(), 'User has 0 threads');
  }
}
