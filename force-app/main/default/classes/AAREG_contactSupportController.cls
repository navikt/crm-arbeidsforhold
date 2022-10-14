public with sharing class AAREG_contactSupportController {
  @AuraEnabled
  public static Id createThreadForApplication(String userId, String relatedApplicationId, String description, String subject) {
    Id threadId;
    try {
      threadId = createThreadWithMessage(userId, relatedApplicationId, description,subject);
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
    return threadId;
  }

  @AuraEnabled
  public static void createNewInquiry(String userId, Inquiry__c inquiry) {
    try {
      String lastUsedOrganizationNumber = [SELECT LastUsedOrganization__c FROM USER WHERE Id = :userId]
      ?.LastUsedOrganization__c;

      inquiry.CreatedByOrganizationNumber__c = lastUsedOrganizationNumber;
      insert inquiry;

      createThreadWithMessage(userId, inquiry.Id, inquiry.InquiryDescription__c, inquiry.Subject__c );
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }

  private static Id createThreadWithMessage(String userId, String relatedRecordId, String description, String subject) {
    Id relatedObjectId = Id.valueOf(relatedRecordId);
    String sObjName = relatedObjectId.getSObjectType().getDescribe().getName();
      
    String henvendelsesId = '';
    if (sObjName == 'Inquiry__c') {
      henvendelsesId = [SELECT Name FROM Inquiry__c WHERE Id = :relatedRecordId]?.Name;
    }
          
    Thread__c thread = new Thread__c(
        CRM_Related_Object__c = relatedRecordId,
        CRM_Related_Object_Type__c = sObjName,
        CRM_HenvendelseId__c = henvendelsesId,
        AAREG_Thread_Subject__c = subject,
        CRM_Thread_Type__c = 'AAREG_EXP'
    );
    insert thread;

    Message__c msg = new Message__c(
      CRM_Thread__c = thread.Id,
      CRM_From_Contact__c = getUserContactId(),
      CRM_Message_Text__c = description
    );
    insert msg;
    return thread.Id;
  }

  public static string getUserContactId() {
      return [SELECT Id, ContactId FROM User WHERE Id = :UserInfo.getUserId()]?.ContactId;
  }
}