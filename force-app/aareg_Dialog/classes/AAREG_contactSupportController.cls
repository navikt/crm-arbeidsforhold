/**
 * Controller for AAREG contact support form, responsible for creating threads and messages in the system based on user input from the form. 
 * It also handles file attachments by creating ContentVersion records and linking them to the relevant records.
 *
 * @since February 2026
 * @group AAREG DIALOG
 */
public with sharing class AAREG_contactSupportController {
  public class FileData {
    @AuraEnabled public String base64  {get; set;}
    @AuraEnabled public String fileName  {get; set;}
  }

  /**
   * Creates a new thread for a given application and posts an initial message based on the provided description and subject.
   * This method is designed to be called from the AAREG contact support form when a user submits an inquiry related to a specific application.
   *
   * @param userId The ID of the user creating the thread, used to associate the thread with the correct contact.
   * @param relatedApplicationId The ID of the related application (or record) that the thread will be associated with.
   * @param description The initial message content that will be posted in the thread.
   * @param subject The subject of the thread, which can help categorize or identify the thread in the system.
   * @return Id The ID of the created thread, which can be used for further processing or navigation.
   * @example
   * {@code
   * Id newThreadId = AAREG_contactSupportController.createThreadForApplication(userId, relatedApplicationId, 'Description of issue', 'Subject of inquiry');
   * }
   */
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

  /**
   * Creates a new inquiry record and an associated thread with an initial message based on the provided description and subject.
   * This method is designed to be called from the AAREG contact support form when a user submits a general inquiry that is not necessarily tied to a specific application.
   * It also handles file attachments by creating ContentVersion records and linking them to the created inquiry.
   * @param userId The ID of the user creating the inquiry, used to associate the inquiry with the correct contact and organization.
   * @param inquiry The Inquiry__c record containing the details of the inquiry, such as
   *  
   * Subject and InquiryDescription__c, which are used to populate the thread and message content.
   * @param files A list of FileData objects representing the files to be attached to the inquiry, where each FileData contains a base64-encoded string of the file content and the file name.
   * @return void
   * @example
   * {@code
   * List<FileData> files = new List<FileData>{
   * new FileData(base64: 'base64EncodedContent', fileName: 'example.pdf')
   * };
   * AAREG_contactSupportController.createNewInquiry(userId, inquiryRecord, files);
   * 
   */
  @AuraEnabled
  public static void createNewInquiry(String userId, Inquiry__c inquiry, List<FileData> files) {
    try {
      String lastUsedOrganizationNumber = [SELECT LastUsedOrganization__c FROM USER WHERE Id = :userId]
      ?.LastUsedOrganization__c;

      inquiry.CreatedByOrganizationNumber__c = lastUsedOrganizationNumber;
      insert inquiry;

      createThreadWithMessage(userId, inquiry.Id, inquiry.InquiryDescription__c, inquiry.Subject__c );

      // Optionally attach files to the created Thread
      if (files != null && !files.isEmpty()) {
        for (FileData file : files) {
          if (file.base64 != null && file.fileName != null) {
            insertDocumentWithLink(inquiry.Id, file.base64, file.fileName);
          }
        }
      }
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }

  /**
   * Creates a new thread with an initial message based on the provided description and subject.
   * @param userId The ID of the user creating the thread.
   * @param relatedRecordId The ID of the related record to which the thread is associated.
   * @param description The description of the message to be included in the thread.
   * @param subject The subject of the thread.
   * @return Id The ID of the created thread.
   */
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

  /**
   * Inserts a new document and links it to the specified parent record.
   * @param parentId The ID of the parent record to which the document is linked.
   * @param base64 The base64-encoded content of the document.
   * @param fileName The name of the document.
   */
  private static void insertDocumentWithLink(Id parentId, String base64, String fileName) {
    if (String.isBlank(base64) || String.isBlank(fileName)) {
      return;
    }
    ContentVersion cv = generateContentVersion(base64, fileName);
    generateContentDocumentLink(parentId, cv.Id);
  }

  /**
   * Generates a new ContentVersion record with the specified base64-encoded content and filename.
   * @param base64 The base64-encoded content of the document.
   * @param filename The name of the document.
   * @return ContentVersion The generated ContentVersion record.
   */
  private static ContentVersion generateContentVersion(String base64, String filename) {
    ContentVersion cv = new ContentVersion();
    cv.VersionData = EncodingUtil.base64Decode(base64);
    cv.Title = filename;
    cv.PathOnClient = filename;
    insert cv;
    return cv;
  }

  /**
   * Generates a ContentDocumentLink record to link a ContentDocument to a parent record.
   * @param parentId The ID of the parent record to which the document is linked.
   * @param contentVersionId The ID of the ContentVersion record that contains the document to be linked.
   */
  private static void generateContentDocumentLink(Id parentId, Id contentVersionId) {
    ContentVersion version = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :contentVersionId];
    ContentDocumentLink cdl = new ContentDocumentLink(
      LinkedEntityId = parentId,
      ContentDocumentId = version.ContentDocumentId,
      ShareType = 'I'
    );
    insert cdl;
  }

  /**
   * Retrieves the ContactId associated with the current user.
   * This method is used to link messages and threads to the correct contact based on the user who is creating them.
   * @return String The ContactId of the current user, or null if the user does not have an associated contact.
   */
  public static string getUserContactId() {
      return [SELECT Id, ContactId FROM User WHERE Id = :UserInfo.getUserId()]?.ContactId;
  }
}