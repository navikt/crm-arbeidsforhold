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
   * Initialize a draft Inquiry__c to host lightning-file-upload attachments pre-submit.
   * Returns the Id of the created draft record.
   */
  @AuraEnabled
  public static Id initDraftRecord() {
    Inquiry__c draft = new Inquiry__c();
    // Set minimal draft defaults; adjust fields as needed in your org
    draft.Subject__c = 'Draft - File Uploads';
    // Set a status field to indicate this is a draft record
    // If you have a Status field, set Draft here, e.g. draft.Status__c = 'Draft';
    // Try to set a status field if it exists
    if (Schema.sObjectType.Inquiry__c.fields.Status__c != null) {
        draft.Status__c = 'Draft';
    }
    Database.SaveResult sr = Database.insert(draft, AccessLevel.USER_MODE);
    if (!sr.isSuccess()) {
      throw new AuraHandledException('Could not initialize draft Inquiry__c');
    }
    return sr.getId();
  }

  /**
   * Completes the final Inquiry__c using an existing draft and metadata from the client.
   * Returns the final Inquiry__c Id (same as draft if updating in place).
   */
  @AuraEnabled
  public static Id createFinalInquiry(Id draftId, String metadataJson) {
    if (draftId == null) {
      throw new AuraHandledException('Missing draftId');
    }
    Map<String, Object> meta = (Map<String, Object>) JSON.deserializeUntyped(metadataJson);
    Inquiry__c rec = [
      SELECT Id, Subject__c, InquiryDescription__c, Email__c, TypeOfInquiry__c
      FROM Inquiry__c
      WHERE Id = :draftId
      WITH USER_MODE
      LIMIT 1
    ];

    // Map provided fields cautiously with limits
    String subj = (String) meta.get('Subject__c');
    if (String.isNotBlank(subj)) rec.Subject__c = subj.left(255);
    String descVal = (String) meta.get('InquiryDescription__c');
    if (String.isNotBlank(descVal)) rec.InquiryDescription__c = descVal.left(32000);
    String email = (String) meta.get('Email__c');
    if (String.isNotBlank(email)) rec.Email__c = email.left(255);
    String typeOfInquiry = (String) meta.get('TypeOfInquiry__c');
    if (String.isNotBlank(typeOfInquiry)) rec.TypeOfInquiry__c = typeOfInquiry;

    Database.update(rec, AccessLevel.USER_MODE);
    return rec.Id;
  }

  /**
   * Add ContentDocumentLink from a set of ContentDocuments to a new parent,
   * and optionally remove links from the old parent.
   */
  @AuraEnabled
  public static void relinkFilesToParent(List<Id> documentIds, Id fromParentId, Id toParentId) {
    if (toParentId == null || documentIds == null || documentIds.isEmpty() || fromParentId == toParentId) return;

    List<ContentDocumentLink> toInsert = new List<ContentDocumentLink>();
    for (Id docId : documentIds) {
      toInsert.add(new ContentDocumentLink(
        ContentDocumentId = docId,
        LinkedEntityId = toParentId,
        ShareType = 'V',
        Visibility = 'AllUsers'
      ));
    }
    if (!toInsert.isEmpty()) {
      Database.insert(toInsert, AccessLevel.USER_MODE);
    }

    if (fromParentId != null) {
      List<ContentDocumentLink> toDelete = [
        SELECT Id
        FROM ContentDocumentLink
        WHERE ContentDocumentId IN :documentIds AND LinkedEntityId = :fromParentId
        WITH USER_MODE
      ];
      if (!toDelete.isEmpty()) {
        Database.delete(toDelete, AccessLevel.USER_MODE);
      }
    }
  }

  /**
   * Update latest ContentVersion Title/Description for given ContentDocuments,
   * and ensure a link exists to the specified parent.
   * metadataJson expects keys: subject, description
   */
  @AuraEnabled
  public static void enrichUploadedFiles(List<Id> documentIds, Id recordId, String metadataJson) {
    if (documentIds == null || documentIds.isEmpty() || recordId == null) return;

    // Ensure link to target parent exists
    Set<Id> alreadyLinked = new Set<Id>();
    for (ContentDocumentLink cdl : [
      SELECT Id, ContentDocumentId
      FROM ContentDocumentLink
      WHERE ContentDocumentId IN :documentIds AND LinkedEntityId = :recordId
      WITH USER_MODE
    ]) {
      alreadyLinked.add(cdl.ContentDocumentId);
    }
    List<ContentDocumentLink> links = new List<ContentDocumentLink>();
    for (Id docId : documentIds) {
      if (!alreadyLinked.contains(docId)) {
        links.add(new ContentDocumentLink(
          ContentDocumentId = docId,
          LinkedEntityId = recordId,
          ShareType = 'V',
          Visibility = 'AllUsers'
        ));
      }
    }
    if (!links.isEmpty()) {
      Database.insert(links, AccessLevel.USER_MODE);
    }
  }

  /**
   * Unlink a ContentDocument from a parent record (does not delete the document).
   */
  @AuraEnabled
  public static void removeFileLink(Id documentId, Id parentId) {
    if (documentId == null || parentId == null) return;
    List<ContentDocumentLink> links = [
      SELECT Id
      FROM ContentDocumentLink
      WHERE ContentDocumentId = :documentId AND LinkedEntityId = :parentId
      WITH USER_MODE
    ];
    if (!links.isEmpty()) {
      Database.delete(links, AccessLevel.USER_MODE);
    }
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
    // Guard lengths per platform limits
    String safeName = String.isBlank(filename) ? 'file' : filename;
    cv.Title = safeName.left(80);
    cv.PathOnClient = safeName.left(260);
    // Strip inaccessible fields before insert to respect FLS in addition to USER_MODE
    List<ContentVersion> toInsert = new List<ContentVersion>{ cv };
    SObjectAccessDecision dec = Security.stripInaccessible(AccessType.CREATABLE, toInsert);
    List<SObject> sanitized = dec.getRecords();
    ContentVersion sanitizedCv = (ContentVersion) sanitized[0];

    // Insert in USER MODE to respect FLS/sharing and avoid inaccessible field DML
    Database.SaveResult sr = Database.insert(sanitizedCv, AccessLevel.USER_MODE);
    if (!sr.isSuccess()) {
      // Surface first error in a handled way for the caller
      Database.Error err = sr.getErrors().isEmpty() ? null : sr.getErrors()[0];
      String msg = (err == null) ? 'Failed to insert file' : err.getMessage();
      throw new AuraHandledException('File upload failed: ' + msg);
    }
    // Ensure we return a ContentVersion with Id populated
    if (sanitizedCv.Id == null) {
      ContentVersion reloaded = [
        SELECT Id
        FROM ContentVersion
        WHERE Id = :sr.getId()
        WITH USER_MODE
        LIMIT 1
      ];
      return reloaded;
    }
    return sanitizedCv;
  }

  /**
   * Generates a ContentDocumentLink record to link a ContentDocument to a parent record.
   * @param parentId The ID of the parent record to which the document is linked.
   * @param contentVersionId The ID of the ContentVersion record that contains the document to be linked.
   */
  private static void generateContentDocumentLink(Id parentId, Id contentVersionId) {
    ContentVersion version = [
      SELECT ContentDocumentId
      FROM ContentVersion
      WHERE Id = :contentVersionId
      WITH USER_MODE
      LIMIT 1
    ];
    ContentDocumentLink cdl = new ContentDocumentLink(
      LinkedEntityId = parentId,
      ContentDocumentId = version.ContentDocumentId,
      ShareType = 'I'
    );
    Database.insert(cdl, AccessLevel.USER_MODE);
  }

  /**
   * Retrieves the ContactId associated with the current user.
   * This method is used to link messages and threads to the correct contact based on the user who is creating them.
   * @return String The ContactId of the current user, or null if the user does not have an associated contact.
   */
  public static string getUserContactId() {
      return [SELECT Id, ContactId FROM User WHERE Id = :UserInfo.getUserId() WITH USER_MODE LIMIT 1]?.ContactId;
  }
}