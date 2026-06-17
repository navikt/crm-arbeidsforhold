public with sharing class AAREG_MyThreadsController {

  @AuraEnabled(cacheable=true)
  public static List<Thread__c> getUsersThreadsForOrganization(String userId) {
    List<Thread__c> threads;
    try {
      String lastUsedOrganizationNumber = [SELECT LastUsedOrganization__c FROM USER WHERE Id = :userId]
      ?.LastUsedOrganization__c;
      
      if (lastUsedOrganizationNumber == null) {
        return new List<Thread__c>();
      }
      List<Account> accountIdList = AAREG_accountSelector.selectAccountByOrganizationNumber(lastUsedOrganizationNumber);
      if (accountIdList.isEmpty()) {
        return new List<Thread__c>();
      }
      String accountId = accountIdList[0]?.Id;
      threads = [
        SELECT
          Id,
          Name,
          CreatedDate,
          CRM_Conversation_Summary__c,
          CRM_Number_of_External_Messages__c,
          CRM_Latest_Message_Datetime__c,
          CRM_Number_of_unread_Messages__c,
          CRM_Related_Object__c,
          CRM_HenvendelseId__c,
          AAREG_Thread_Subject__c,
          CRM_isActive__c
        FROM Thread__c
        WHERE CRM_Account__c = :accountId
        ORDER BY CRM_Latest_Message_Datetime__c DESC
        ];      
    } catch (Exception e) {
      LoggerUtility logger = new LoggerUtility();
      logger.error(e.getMessage(), null);
      logger.publish();
      throw new AuraHandledException(e.getMessage());
    }
    return threads;
  }
  @AuraEnabled(cacheable=true)
  public static List<Thread__c> getUsersThreadsForPerson(String userId) {
    List<Thread__c> threads;
    try {
      List<Account> accountIdList = AAREG_accountSelector.selectPersonAccountByUserId(userId);
      if (accountIdList.isEmpty()) {
        return new List<Thread__c>();
      }
      String accountId = accountIdList[0]?.Id;
      threads = [
        SELECT
          Id,
          Name,
          CreatedDate,
          CRM_Conversation_Summary__c,
          CRM_Number_of_External_Messages__c,
          CRM_Latest_Message_Datetime__c,
          CRM_Number_of_unread_Messages__c,
          CRM_Related_Object__c,
          CRM_HenvendelseId__c,
          AAREG_Thread_Subject__c,
          CRM_isActive__c
        FROM Thread__c
        WHERE CRM_Account__c = :accountId
        ORDER BY CRM_Latest_Message_Datetime__c DESC
        ];      
    } catch (Exception e) {
      LoggerUtility logger = new LoggerUtility();
      logger.error(e.getMessage(), null);
      logger.publish();
      throw new AuraHandledException(e.getMessage());
    }
    // return empty list if no threads found to avoid null pointer exceptions in the client code  
    if (threads == null) {
      return new List<Thread__c>();
    }
    return threads;
  }
}