public class AAREG_MyThreadsController {
  @AuraEnabled(cacheable=true)
  public static List<Thread__c> getUsersThreads(String userId) {
    List<Thread__c> threads;
    try {
      threads = [
        SELECT
          Id,
          Name,
          CRM_Number_of_External_Messages__c,
          CRM_Latest_Message_Datetime__c,
          CRM_Number_of_unread_Messages__c,
          CRM_Related_Object__c,
          CRM_isActive__c
        FROM Thread__c
      ];
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
    return threads;
  }
}
