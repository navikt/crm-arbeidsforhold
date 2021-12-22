public with sharing class AAREG_MyThreadsController {
  
  @AuraEnabled(cacheable=true)
  public static List<Thread__c> getUsersThreads(String userId) {
    List<Thread__c> threads;
       
      try {
          String lastUsedOrganizationNumber = [SELECT LastUsedOrganization__c FROM USER WHERE Id = :userId]
          ?.LastUsedOrganization__c;
          list<Account> accountIdList = AAREG_accountSelector.selectAccountByOrganizationNumber(lastUsedOrganizationNumber);
            
            if(accountIdList.size()>0 || accountIdList!=null){
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
            }
          
        } catch (Exception e) {
          system.debug(e.getMessage());
          LoggerUtility logger = new LoggerUtility();
          logger.error(e.getMessage(), null);
          logger.publish();
          throw new AuraHandledException(e.getMessage());
        }
      
    return threads;
  }
}