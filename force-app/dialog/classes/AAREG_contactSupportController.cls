/**
 * Controller for AAREG contact support form, responsible for creating threads and messages in the system based on user input from the form.
 * It also handles file attachments by creating ContentVersion records and linking them to the relevant records.
 *
 * @since February 2026
 * @group TEAMS AAREG
 */
public with sharing class AAREG_contactSupportController {
    /**
     * Wrapper for file upload payloads from the client.
     */
    public class FileData {
        /** Base64-encoded file contents. */
        @AuraEnabled
        public String base64 { get; set; }
        /** Original filename provided by the client. */
        @AuraEnabled
        public String fileName { get; set; }
    }

    /**
     * Initialize a draft Inquiry__c to host lightning-file-upload attachments pre-submit.
     * Returns the Id of the created draft record.
     *
     * @param userId The Id of the current user for lookup of the organization number.
     * @return Id The Id of the newly created Inquiry__c draft.
     */
    @AuraEnabled
    public static Id initDraftRecord(String userId) {
        Inquiry__c draft = new Inquiry__c();
        draft.Subject__c = 'Draft - File Uploads';
        if (Schema.sObjectType.Inquiry__c.fields.Status__c != null) {
            draft.Status__c = 'Draft';
        }

        try {
            if (String.isNotBlank(userId)) {
                List<User> users = [
                    SELECT LastUsedOrganization__c
                    FROM User
                    WHERE Id = :userId
                    WITH USER_MODE
                    LIMIT 1
                ];
                draft.CreatedByOrganizationNumber__c = users.isEmpty() ? null : users[0].LastUsedOrganization__c;
            }
            Database.SaveResult sr = Database.insert(draft, AccessLevel.USER_MODE);
            validateSaveResult(sr, 'Kunne ikke opprette utkast.');
            return sr.getId();
        } catch (Exception e) {
            LoggerUtility logger = new LoggerUtility();
            logger.error('Feil ved initDraftRecord. ' + e.getMessage(), null);
            logger.publish();
            throw new AuraHandledException('Kunne ikke initialisere utkastet.');
        }
    }

    /**
     * Update draft Inquiry__c using an existing draft and metadata from the client.
     * Returns the final Inquiry__c Id (same as draft if updating in place).
     *
     * @param draftId The Id of the draft Inquiry__c that should be updated.
     * @param metadataJson JSON payload containing field values to update.
     * @return Id The Id of the updated Inquiry__c record.
     */
    @AuraEnabled
    public static Id updateDraftRecord(Id draftId, String metadataJson) {
        if (draftId == null) {
            throw new AuraHandledException('Manglende draftId');
        }

        try {
            Map<String, Object> meta = metadataJson == null
                ? new Map<String, Object>()
                : (Map<String, Object>) JSON.deserializeUntyped(metadataJson);
            Inquiry__c rec = [
                SELECT Id, Subject__c, InquiryDescription__c, Email__c, TypeOfInquiry__c
                FROM Inquiry__c
                WHERE Id = :draftId
                WITH USER_MODE
                LIMIT 1
            ];

            applyInquiryMetadata(rec, meta);

            Database.SaveResult sr = Database.update(rec, AccessLevel.USER_MODE);
            validateSaveResult(sr, 'Kunne ikke oppdatere utkastet.');
            return rec.Id;
        } catch (Exception e) {
            LoggerUtility logger = new LoggerUtility();
            logger.error('Feil ved updateDraftRecord. ' + e.getMessage(), null);
            logger.publish();
            throw new AuraHandledException('Kunne ikke oppdatere utkastet.');
        }
    }

    /**
     * Completes the final Inquiry__c using an existing draft and metadata from the client.
     * Returns the final Inquiry__c Id (same as draft if updating in place).
     *
     * @param userId The Id of the current user creating the inquiry.
     * @param draftId The Id of the draft Inquiry__c to finalize.
     * @param metadataJson JSON payload containing final inquiry field values.
     * @return Id The Id of the finalized Inquiry__c.
     */
    @AuraEnabled
    public static Id createFinalInquiry(String userId, Id draftId, String metadataJson) {
        if (draftId == null) {
            throw new AuraHandledException('Manglende draftId');
        }

        try {
            Map<String, Object> meta = metadataJson == null
                ? new Map<String, Object>()
                : (Map<String, Object>) JSON.deserializeUntyped(metadataJson);
            Inquiry__c rec = [
                SELECT Id, Subject__c, InquiryDescription__c, Email__c, TypeOfInquiry__c
                FROM Inquiry__c
                WHERE Id = :draftId
                WITH USER_MODE
                LIMIT 1
            ];

            applyInquiryMetadata(rec, meta);
            rec.Status__c = 'New';

            createThreadWithMessage(userId, draftId, rec.InquiryDescription__c, rec.Subject__c);

            Database.SaveResult sr = Database.update(rec, AccessLevel.USER_MODE);
            validateSaveResult(sr, 'Kunne ikke fullføre henvendelsen.');

            return rec.Id;
        } catch (Exception e) {
            LoggerUtility logger = new LoggerUtility();
            logger.error('Feil ved createFinalInquiry. ' + e.getMessage(), null);
            logger.publish();
            throw new AuraHandledException('Kunne ikke fullføre henvendelsen.');
        }
    }

    /**
     * Update latest ContentVersion Title/Description for given ContentDocuments,
     * and ensure a link exists to the specified parent.
     *
     * @param documentIds The list of ContentDocument IDs to link.
     * @param recordId The parent record Id to link the documents to.
     */
    @AuraEnabled
    public static void enrichUploadedFiles(List<Id> documentIds, Id recordId) {
        if (documentIds == null || documentIds.isEmpty() || recordId == null) {
            return;
        }

        try {
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
                    links.add(
                        new ContentDocumentLink(
                            ContentDocumentId = docId,
                            LinkedEntityId = recordId,
                            ShareType = 'V',
                            Visibility = 'AllUsers'
                        )
                    );
                }
            }
            if (!links.isEmpty()) {
                Database.SaveResult[] results = Database.insert(links, AccessLevel.USER_MODE);
                for (Database.SaveResult sr : results) {
                    validateSaveResult(sr, 'Kunne ikke koble vedlagte filer til posten.');
                }
            }
        } catch (Exception e) {
            LoggerUtility logger = new LoggerUtility();
            logger.error('Feil ved enrichUploadedFiles. ' + e.getMessage(), null);
            logger.publish();
            throw new AuraHandledException('Kunne ikke oppdatere filkoblinger.');
        }
    }

    /**
     * Delete multiple ContentDocuments (and all associated links and versions).
     * This is a bulk version that handles multiple document IDs at once.
     *
     * @param documentIds List of ContentDocument IDs to delete
     */
    @AuraEnabled
    public static void deleteFiles(List<Id> documentIds) {
        if (documentIds == null || documentIds.isEmpty()) {
            return;
        }

        try {
            List<ContentDocument> documents = [
                SELECT Id
                FROM ContentDocument
                WHERE Id IN :documentIds
                WITH USER_MODE
            ];
            if (!documents.isEmpty()) {
                Database.DeleteResult[] results = Database.delete(documents, AccessLevel.USER_MODE);
                for (Database.DeleteResult dr : results) {
                    if (!dr.isSuccess()) {
                        String msg = dr.getErrors().isEmpty() ? 'Ukjent feil' : dr.getErrors()[0].getMessage();
                        LoggerUtility logger = new LoggerUtility();
                        logger.error('Kunne ikke slette ContentDocument. ' + msg, null);
                        logger.publish();
                        throw new AuraHandledException('Kunne ikke slette filer.');
                    }
                }
            }
        } catch (Exception e) {
            LoggerUtility logger = new LoggerUtility();
            logger.error('Feil ved deleteFiles. ' + e.getMessage(), null);
            logger.publish();
            throw new AuraHandledException('Kunne ikke slette filer.');
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
    public static Id createThreadForApplication(
        String userId,
        String relatedApplicationId,
        String description,
        String subject
    ) {
        Id threadId;
        try {
            threadId = createThreadWithMessage(userId, relatedApplicationId, description, subject);
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
        if (inquiry == null) {
            throw new AuraHandledException('Henvendelse mangler.');
        }

        try {
            if (String.isNotBlank(userId)) {
                List<User> users = [
                    SELECT LastUsedOrganization__c
                    FROM User
                    WHERE Id = :userId
                    WITH USER_MODE
                    LIMIT 1
                ];
                inquiry.CreatedByOrganizationNumber__c = users.isEmpty() ? null : users[0].LastUsedOrganization__c;
            }

            Database.SaveResult sr = Database.insert(inquiry, AccessLevel.USER_MODE);
            validateSaveResult(sr, 'Kunne ikke opprette henvendelsen.');

            createThreadWithMessage(userId, inquiry.Id, inquiry.InquiryDescription__c, inquiry.Subject__c);

            if (files != null && !files.isEmpty()) {
                for (FileData file : files) {
                    if (file != null && String.isNotBlank(file.base64) && String.isNotBlank(file.fileName)) {
                        insertDocumentWithLink(inquiry.Id, file.base64, file.fileName);
                    }
                }
            }
        } catch (Exception e) {
            LoggerUtility logger = new LoggerUtility();
            logger.error('Feil ved createNewInquiry. ' + e.getMessage(), null);
            logger.publish();
            throw new AuraHandledException('Kunne ikke opprette henvendelsen.');
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
    private static Id createThreadWithMessage(
        String userId,
        String relatedRecordId,
        String description,
        String subject
    ) {
        Id relatedObjectId = Id.valueOf(relatedRecordId);
        String sObjName = relatedObjectId.getSObjectType().getDescribe().getName();

        String henvendelsesId = '';
        if (sObjName == 'Inquiry__c') {
            henvendelsesId = [SELECT Name FROM Inquiry__c WHERE Id = :relatedRecordId WITH USER_MODE LIMIT 1]?.Name;
        }

        Thread__c thread = new Thread__c(
            CRM_Related_Object__c = relatedRecordId,
            CRM_Related_Object_Type__c = sObjName,
            CRM_HenvendelseId__c = henvendelsesId,
            RecordTypeId = AAREG_Utility.getInstance().getThreadRecordTypeId(),
            AAREG_Thread_Subject__c = subject,
            CRM_Thread_Type__c = 'AAREG_EXP'
        );
        Database.SaveResult threadResult = Database.insert(thread, AccessLevel.USER_MODE);
        validateSaveResult(threadResult, 'Kunne ikke opprette tråd.');

        Message__c msg = new Message__c(
            CRM_Thread__c = thread.Id,
            CRM_From_Contact__c = getUserContactId(),
            CRM_Message_Text__c = description
        );
        Database.SaveResult msgResult = Database.insert(msg, AccessLevel.USER_MODE);
        validateSaveResult(msgResult, 'Kunne ikke opprette melding.');
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
        Database.SaveResult sr = Database.insert(cdl, AccessLevel.USER_MODE);
        validateSaveResult(sr, 'Kunne ikke koble fil til forespørselen.');
    }

    /**
     * Retrieves the ContactId associated with the current user.
     * This method is used to link messages and threads to the correct contact based on the user who is creating them.
     * @return String The ContactId of the current user, or null if the user does not have an associated contact.
     */
    public static string getUserContactId() {
        return [SELECT Id, ContactId FROM User WHERE Id = :UserInfo.getUserId() WITH USER_MODE LIMIT 1]?.ContactId;
    }

    private static void applyInquiryMetadata(Inquiry__c rec, Map<String, Object> meta) {
        if (rec == null || meta == null || meta.isEmpty()) {
            return;
        }

        String subj = (String) meta.get('Subject__c');
        if (String.isNotBlank(subj)) {
            rec.Subject__c = subj.left(255);
        }

        String descVal = (String) meta.get('InquiryDescription__c');
        if (String.isNotBlank(descVal)) {
            rec.InquiryDescription__c = descVal.left(32000);
        }

        String email = (String) meta.get('Email__c');
        if (String.isNotBlank(email)) {
            rec.Email__c = email.left(255);
        }

        String typeOfInquiry = (String) meta.get('TypeOfInquiry__c');
        if (String.isNotBlank(typeOfInquiry)) {
            rec.TypeOfInquiry__c = typeOfInquiry;
        }
    }

    private static void validateSaveResult(Database.SaveResult sr, String errorMessage) {
        if (sr == null) {
            LoggerUtility logger = new LoggerUtility();
            logger.error(errorMessage, null);
            logger.publish();
            throw new AuraHandledException(errorMessage);
        }
        if (!sr.isSuccess()) {
            String details = sr.getErrors().isEmpty() ? 'Ukjent feil' : sr.getErrors()[0].getMessage();
            LoggerUtility logger = new LoggerUtility();
            logger.error(errorMessage + ' ' + details, null);
            logger.publish();
            throw new AuraHandledException(errorMessage);
        }
    }
}
