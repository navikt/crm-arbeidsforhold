public with sharing class AAREG_contactSupportController {
  public class FileData {
    @AuraEnabled public String base64  {get; set;}
    @AuraEnabled public String fileName  {get; set;}
  }

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
  public static void createNewInquiry(String userId, Inquiry__c inquiry, List<FileData> files) {
    try {
      String lastUsedOrganizationNumber = [SELECT LastUsedOrganization__c FROM USER WHERE Id = :userId]
      ?.LastUsedOrganization__c;

      inquiry.CreatedByOrganizationNumber__c = lastUsedOrganizationNumber;
      insert inquiry;

      Id threadId = createThreadWithMessage(userId, inquiry.Id, inquiry.InquiryDescription__c, inquiry.Subject__c );

      // Optionally attach files to the created Thread
      if (files != null && !files.isEmpty()) {
        for (FileData file : files) {
//          System.debug('Processing file: ' + file.fileName);
//          try {
//              System.debug('Base64 length: ' + file.base64?.length());
//              Blob b = EncodingUtil.base64Decode(file.base64);
//              System.debug('Blob size: ' + b.size());
//          } catch (Exception e) {
//              System.debug('Decode failed: ' + e.getMessage());
//          }
          if (file.base64 != null && file.fileName != null) {
            insertDocumentWithLink(inquiry.Id, file.base64, file.fileName);
          }
        }
      }
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
        RecordTypeId = AAREG_Utility.getInstance().getThreadRecordTypeId(),
        AAREG_Thread_Subject__c = subject, // Subject is set directly in aaregcontactSupportForm.html input
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

  // Helper modeled after AAREG_ApplicationController
  private static void insertDocumentWithLink(Id parentId, String base64, String fileName) {
    if (String.isBlank(base64) || String.isBlank(fileName)) {
      return;
    }
    ContentVersion cv = generateContentVersion(base64, fileName);
    generateContentDocumentLink(parentId, cv.Id);
  }

  private static ContentVersion generateContentVersion(String base64, String filename) {
    ContentVersion cv = new ContentVersion();
    cv.VersionData = EncodingUtil.base64Decode(base64);
    cv.Title = filename;
    cv.PathOnClient = filename;
    insert cv;
    return cv;
  }

  private static void generateContentDocumentLink(Id parentId, Id contentVersionId) {
    ContentVersion version = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :contentVersionId];
    ContentDocumentLink cdl = new ContentDocumentLink(
      LinkedEntityId = parentId,
      ContentDocumentId = version.ContentDocumentId,
      ShareType = 'I'
    );
    insert cdl;
  }

  public static string getUserContactId() {
      return [SELECT Id, ContactId FROM User WHERE Id = :UserInfo.getUserId()]?.ContactId;
  }
}