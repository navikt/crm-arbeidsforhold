public with sharing class AAREG_contactSupportController {
  @AuraEnabled
  public static Id createThreadForApplication(String userId, String relatedApplicationId, String description) {
    try {
      Thread__c thread = new Thread__c(CRM_Related_Object__c = relatedApplicationId);
      insert thread;

      Message__c msg = new Message__c(CRM_Thread__c = thread.Id, CRM_Message_Text__c = description);
      insert msg;
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }

    return thread.Id;
  }
}
