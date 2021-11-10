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
      String lastUsedOrganizationNumber = [SELECT LastUsedOrganization__c FROM USER WHERE Id = :userId]
      ?.LastUsedOrganization__c;
      String accountId;
      
      if(lastUsedOrganizationNumber!=null){
        accountId = [SELECT id FROM ACCOUNT WHERE INT_OrganizationNumber__c =:lastUsedOrganizationNumber]?.id;
      }
      inquiry.CreatedByOrganizationNumber__c = lastUsedOrganizationNumber;
      inquiry.AccountId__c = accountId;
      insert inquiry;

      createTheadWithMessages(userId, inquiry.Id, inquiry.InquiryDescription__c);
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }

  private static Id createTheadWithMessages(String userId, String relatedRecordId, String description) {
    String accountId = null;
    String contactId = null;
   // String crmThreadType ='AAREG_EXP';//type indicate thread is created externally.
    Id relatedObjectId = Id.valueOf(relatedRecordId);
    String sObjName = relatedObjectId.getSObjectType().getDescribe().getName();
    String lastUsedOrganizationNumber = [SELECT LastUsedOrganization__c FROM USER WHERE Id = :userId]?.LastUsedOrganization__c;
      if(lastUsedOrganizationNumber!=null){
        accountId = [SELECT id FROM ACCOUNT WHERE INT_OrganizationNumber__c =:lastUsedOrganizationNumber]?.id;
      }
      if(sObjName =='Application__c'){
          contactId = [SELECT Contact__c FROM Application__c WHERE id =:relatedObjectId]?.Contact__c;
      }
  
    Thread__c thread = new Thread__c(
        CRM_Related_Object__c = relatedRecordId,
        CRM_Related_Object_Type__c=sObjName,
     //   CRM_Thread_Type__c =crmThreadType,
        CRM_Contact__c =contactId,
        CRM_Account__c=accountId
    );
    insert thread;

    Message__c msg = new Message__c(
      CRM_Thread__c = thread.Id,
      CRM_From_User__c = userId,
      CRM_From_Contact__c =contactId,
      CRM_Message_Text__c = description
    );
    insert msg;

    return thread.Id;
  }
}