@isTest
public class AAREG_MyThreadsControllerTest {
    static final String STRING_CONST = 'Test Thread';
  @isTest
  static void getUsersThreads() {
    User usr;
    User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
      System.runAs(thisUser){
        usr = AAREG_TestDataFactory.getStandardUser();
    	insert usr;  
      }
    
    Account acct = AAREG_TestDataFactory.getAccount();
    insert acct;
    
    Application__c app = AAREG_TestDataFactory.getApplication(acct.id);
    insert app;

    List<Thread__c> threads = new List<Thread__c>();

    Thread__c firstThread = new Thread__c(Name =STRING_CONST,CRM_Related_Object__c=app.id, CRM_FROM__c = usr.Id, CRM_Account__c = acct.Id);
    Thread__c secondThread = new Thread__c(Name =STRING_CONST, CRM_FROM__c = usr.Id);
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
   User usr;
    User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
      System.runAs(thisUser){
        usr = AAREG_TestDataFactory.getStandardUser();
    	insert usr;  
      }

    Thread__c thread = new Thread__c(Name = STRING_CONST);
    insert thread;

    List<Thread__c> userThreads;

    Test.startTest();
      try{
       userThreads = AAREG_MyThreadsController.getUsersThreads(String.valueOf(usr.Id));   
      }catch(exception e){}
    
    Test.stopTest();

    System.assertEquals(true, userThreads.isEmpty(), 'User has 0 threads');
  }
}