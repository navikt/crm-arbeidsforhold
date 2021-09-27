@isTest
public class AAREG_MyThreadsControllerTest {
  @isTest
  static void getUsersThreadsRecipient() {
    User usr = AAREG_TestDataFactory.getStandardUser();
    insert usr;

    Thread__c thread = new Thread__c(Name = 'Test Thread', CRM_Recipient__c = usr.Id);
    insert thread;

    List<Thread__c> userThreads;

    Test.startTest();
    userThreads = AAREG_MyThreadsController.getUsersThreads(String.valueOf(usr.Id));
    Test.stopTest();

    System.assertEquals(1, userThreads.size(), 'User is recipient on 1 thread');
  }

  @isTest
  static void getUsersThreadsFrom() {
    User usr = AAREG_TestDataFactory.getStandardUser();
    insert usr;

    Thread__c thread = new Thread__c(Name = 'Test Thread', CRM_FROM__c = usr.Id);
    insert thread;

    List<Thread__c> userThreads;

    Test.startTest();
    userThreads = AAREG_MyThreadsController.getUsersThreads(String.valueOf(usr.Id));
    Test.stopTest();

    System.assertEquals(1, userThreads.size(), 'User has is sender on 1 thread');
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
