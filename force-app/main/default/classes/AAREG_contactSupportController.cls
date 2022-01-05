public with sharing class AAREG_contactSupportController {
 
  private static String lastUsedOrganizationNumber;
  @AuraEnabled
  public static Id createThreadForApplication(String userId, String relatedApplicationId, String description, String subject) {
    Id threadId;

    try {
      threadId = createTheadWithMessages(userId, relatedApplicationId, description,subject);
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
    return threadId;
  }

  @AuraEnabled
  public static void createNewInquiry(String userId, Inquiry__c inquiry) {
    try {
      lastUsedOrganizationNumber = [SELECT LastUsedOrganization__c FROM USER WHERE Id = :userId]
      ?.LastUsedOrganization__c;
     
      inquiry.CreatedByOrganizationNumber__c = lastUsedOrganizationNumber;
      insert inquiry;

      createTheadWithMessages(userId, inquiry.Id, inquiry.InquiryDescription__c, inquiry.Subject__c );
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }

  private static Id createTheadWithMessages(String userId, String relatedRecordId, String description, String subject) {
    Id relatedObjectId = Id.valueOf(relatedRecordId);
    String henvendelsesID='';
    String accountId='';
    String sObjName = relatedObjectId.getSObjectType().getDescribe().getName();
    if(sObjName=='Inquiry__c'){
      henvendelsesID = [SELECT name FROM Inquiry__c WHERE Id = :relatedRecordId]
      ?.name;
      list<Account> accountIdList = AAREG_accountSelector.selectAccountByOrganizationNumber(lastUsedOrganizationNumber);
          if(!accountIdList.isEmpty()){
            accountId = accountIdList[0]?.Id;
          }
    }
          
    Thread__c thread = new Thread__c(
        CRM_Related_Object__c = relatedRecordId,
        CRM_Related_Object_Type__c=sObjName,
        CRM_HenvendelseId__c=henvendelsesID,
        CRM_Account__c = accountId,
        AAREG_Thread_Subject__c = subject
    );
    insert thread;

    Message__c msg = new Message__c(
      CRM_Thread__c = thread.Id,
      CRM_From_User__c = userId,
      CRM_Message_Text__c = description
    );
    insert msg;

    return thread.Id;
  }
}