public with sharing class AAREG_contactSupportController {
  @AuraEnabled
  public static Id createThreadForApplication(String userId, String relatedApplicationId, String description) {
    Id threadId;

    try {
      threadId = createTheadWithMessages(userId, relatedApplicationId, description);
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
    return threadId;
  }

  @AuraEnabled
  public static void createNewInquiry(String userId, Inquiry__c inquiry) {
    try {
      insert inquiry;

      createTheadWithMessages(userId, inquiry.Id, inquiry.InquiryDescription__c);
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }

  private static Id createTheadWithMessages(String userId, String relatedRecordId, String description) {
    Thread__c thread = new Thread__c(CRM_Related_Object__c = relatedRecordId, CRM_From__c = userId);
    insert thread;

    Message__c msg = new Message__c(CRM_Thread__c = thread.Id, CRM_Message_Text__c = description);
    insert msg;

    return thread.Id;
  }
}
