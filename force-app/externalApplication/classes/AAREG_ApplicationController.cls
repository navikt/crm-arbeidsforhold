/**
 * Controller class for handling application-specific logic related to AAREG.
 * This class is defined without sharing, meaning it does not enforce the sharing rules
 * of the current user context.
 */
public without sharing class AAREG_ApplicationController {
    private static final String ADDITIONAL_INFORMATION = 'Additional Information Required';
    private static final String DRAFT_APPLICATION = 'Draft';
    private static final String NEW_APPLICATION = 'New';
    private static final String IN_PROGRESS = 'In Progress';
    @TestVisible
    private static final String ATTACHMENT_ACCESS_DENIED = 'Access to the application is denied.';
    @TestVisible
    private static final String ATTACHMENT_ACCESS_UNVERIFIED = 'Unable to verify application access.';
    private static final Set<String> SUBMISSION_FIELDS = new Set<String>{
        'Casehandler_Status__c',
        'ApplicationSubmittedDate__c',
        'AA_ApplicationArchived__c'
    };
    private static Datetime dt = System.now();
    @TestVisible
    private static Boolean forceSanitizeAllowedBranch = false;
    @TestVisible
    private static Boolean forceSanitizeUnknownFieldBranch = false;

    @AuraEnabled
    /**
     * Retrieves the last used organization information for a given user.
     *
     * @param userId The ID of the user for whom the last used organization information is to be retrieved.
     * @return An Account object containing the last used organization information.
     */
    public static Account getLastUsedOrganizationInformation(String userId) {
        User currentUser = [SELECT Id, LastUsedOrganization__c FROM USER WHERE Id = :userId];
        Account lastUsedOrganization = [
            SELECT
                Id,
                Name,
                INT_OrganizationNumber__c,
                INT_OrganizationalStructure__c,
                AAREG_OrganizationCategory__c,
                ShippingStreet,
                ShippingPostalCode,
                ShippingCity
            FROM Account
            WHERE INT_OrganizationNumber__c = :currentUser.LastUsedOrganization__c
        ];

        return lastUsedOrganization;
    }

    @AuraEnabled
    /**
     * Retrieves the name of an account based on the provided organization number.
     *
     * @param orgNumber The organization number used to look up the account name.
     * @return The name of the account associated with the given organization number.
     */
    public static string getAccountNameByOrgNumber(String orgNumber) {
        String accountName = [
            SELECT Id, Name, INT_OrganizationNumber__c
            FROM Account
            WHERE INT_OrganizationNumber__c = :orgNumber
            LIMIT 1
        ]
        ?.Name;

        return accountName;
    }

    @AuraEnabled
    /**
     * Retrieves the draft application associated with the given record ID.
     *
     * @param recordId The ID of the record for which the draft application is to be retrieved.
     * @return The draft application corresponding to the provided record ID.
     */
    public static DraftApplication getDraftApplication(String recordId) {
        return new DraftApplication(
            getApplication(recordId),
            getAccessRequest(recordId),
            getBasisCodes(recordId),
            getRelatedContacts(recordId)
        );
    }

    /**
     * Returns the attachments associated with an application and their current selection state.
     * Enforces user-mode access to the application and files and checks the signed-in user's Altinn rights.
     *
     * @param applicationId The application whose attachments are requested.
     * @return The application's current attachment selection.
     * @throws AuraHandledException If access is denied or the Altinn decision cannot be verified.
     */
    @AuraEnabled
    public static List<AttachmentSelection> getApplicationAttachments(Id applicationId) {
        if (applicationId == null) {
            throw attachmentAccessError('An application is required.');
        }

        List<Application__c> applications = [
            SELECT OrganizationNumber__c
            FROM Application__c
            WHERE Id = :applicationId
            WITH USER_MODE
            LIMIT 1
        ];
        if (applications.isEmpty()) {
            throw attachmentAccessError(ATTACHMENT_ACCESS_DENIED);
        }

        User currentUser = [
            SELECT LastUsedOrganization__c
            FROM User
            WHERE Id = :UserInfo.getUserId()
            LIMIT 1
        ];
        String organizationNumber = currentUser.LastUsedOrganization__c;
        if (String.isBlank(organizationNumber) || organizationNumber != applications[0].OrganizationNumber__c) {
            throw attachmentAccessError(ATTACHMENT_ACCESS_DENIED);
        }

        AltinnCalloutService.AltinnRightsResponse response = AAREG_CommunityUtils.getUserRights(
            UserInfo.getUserId(),
            organizationNumber,
            'nav_arbeidsforhold_aa-registeret-sok-tilgang'
        );
        Boolean permitted = false;
        Boolean denied = false;
        if (response?.rights != null) {
            for (AltinnCalloutService.Right right : response.rights) {
                if (right.Action == 'Access' && right.Decision == 'Permit') {
                    permitted = true;
                } else if (right.Action == 'Access' && right.Decision == 'Deny') {
                    denied = true;
                }
            }
        }
        if (denied) {
            throw attachmentAccessError(ATTACHMENT_ACCESS_DENIED);
        }
        if (response?.success != true || !permitted) {
            throw attachmentAccessError(ATTACHMENT_ACCESS_UNVERIFIED);
        }

        List<AttachmentSelection> attachments = new List<AttachmentSelection>();
        for (ContentDocumentLink link : [
            SELECT ContentDocumentId, ContentDocument.Title
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :applicationId
            WITH USER_MODE
        ]) {
            AttachmentSelection attachment = new AttachmentSelection();
            attachment.contentDocumentId = link.ContentDocumentId;
            attachment.title = link.ContentDocument.Title;
            attachment.selected = true;
            attachments.add(attachment);
        }
        return attachments;
    }

    private static AuraHandledException attachmentAccessError(String message) {
        AuraHandledException error = new AuraHandledException(message);
        error.setMessage(message);
        return error;
    }

    private static Access_Request__c getAccessRequest(Id applicationId) {
        Application__c app = [SELECT Access_Request__c FROM Application__c WHERE Id = :applicationId LIMIT 1];
        if (app.Access_Request__c != null) {
            return [SELECT Id FROM Access_Request__c WHERE Id = :app.Access_Request__c LIMIT 1];
        }
        return null;
    }

    @AuraEnabled
    public static Id saveAsDraft(
        Application__c application,
        List<ApplicationBasisCode__c> basisCode,
        List<RelatedContact__c> relatedContacts,
        String base64,
        String filename
    ) {
        if (application.Status__c != ADDITIONAL_INFORMATION) {
            application.Status__c = DRAFT_APPLICATION;
        }

        // If application already exists, check for existing Access Request
        if (application.Id != null && application.Access_Request__c == null) {
            Application__c existing = [
                SELECT Access_Request__c
                FROM Application__c
                WHERE Id = :application.Id
                LIMIT 1
            ];
            application.Access_Request__c = existing.Access_Request__c;
        }

        Id accessRequestId = upsertAccessRequest(application.Access_Request__c);
        application.Access_Request__c = accessRequestId;
        upsert application;
        upsertRelatedContacts(application.Id, relatedContacts);
        upsertBasisCodes(application.Id, basisCode);
        insertDocumentWithLink(application.Id, application.Access_Request__c, base64, filename);
        return application.Id;
    }

    @AuraEnabled
    /**
     * Submits the application. The application, related contacts and basis codes are saved before the status
     * changes, so the submission flows (applicant contact, confirmation e-mail and generated application text)
     * read the submitted data.
     *
     * @param application The application from the portal. A new application is first saved as a draft.
     * @param basisCode Basis codes to save on the application.
     * @param relatedContacts Notification contacts to save on the application.
     * @param base64 Optional file content to link to the application and access request.
     * @param fileName Optional file name for the uploaded file.
     * @return The ID of the processed application.
     */
    public static Id processApplication(
        Application__c application,
        List<ApplicationBasisCode__c> basisCode,
        List<RelatedContact__c> relatedContacts,
        String base64,
        String fileName
    ) {
        Boolean isResubmission = application.Status__c == ADDITIONAL_INFORMATION;
        requireSubmissionStatusAccess(application);
        Application__c submission = buildSubmissionStatus(isResubmission);

        // If application already exists, check for existing Access Request
        if (application.Id != null && application.Access_Request__c == null) {
            Application__c existing = [
                SELECT Access_Request__c
                FROM Application__c
                WHERE Id = :application.Id
                LIMIT 1
            ];
            application.Access_Request__c = existing.Access_Request__c;
        }

        Id accessRequestId = upsertAccessRequest(application.Access_Request__c);
        application.Access_Request__c = accessRequestId;
        application.Status__c = isResubmission ? ADDITIONAL_INFORMATION : DRAFT_APPLICATION;
        application = sanitizeApplicationForDml(application, SUBMISSION_FIELDS);
        upsert application;
        upsertRelatedContacts(application.Id, relatedContacts);
        upsertBasisCodes(application.Id, basisCode);
        insertDocumentWithLink(application.Id, accessRequestId, base64, fileName);

        submission.Id = application.Id;
        update sanitizeApplicationForDml(submission);
        P360_ArchiveJobService.requestApplicationArchiveOnSubmit(accessRequestId, application.Id);
        return application.Id;
    }

    private static void requireSubmissionStatusAccess(Application__c application) {
        Schema.DescribeFieldResult statusField = Application__c.Status__c.getDescribe();
        Schema.DescribeFieldResult casehandlerStatusField = Application__c.Casehandler_Status__c.getDescribe();
        Boolean allowed = application.Id == null
            ? statusField.isCreateable() && casehandlerStatusField.isCreateable()
            : statusField.isUpdateable() && casehandlerStatusField.isUpdateable();
        if (!allowed) {
            String message = 'You do not have permission to submit this application.';
            AuraHandledException error = new AuraHandledException(message);
            error.setMessage(message);
            throw error;
        }
    }

    private static Application__c buildSubmissionStatus(Boolean isResubmission) {
        Application__c submission = new Application__c();
        if (isResubmission) {
            submission.AA_ApplicationArchived__c = false;
            submission.Casehandler_Status__c = IN_PROGRESS;
            submission.Status__c = IN_PROGRESS;
        } else {
            submission.Casehandler_Status__c = NEW_APPLICATION;
            submission.Status__c = NEW_APPLICATION;
            submission.ApplicationSubmittedDate__c = date.newInstance(dt.year(), dt.month(), dt.day());
        }
        return submission;
    }

    @AuraEnabled
    /**
     * Deletes a draft record from the database.
     *
     * @param record The SObject record to be deleted. It is expected to be a draft record.
     */
    public static void deleteDraftRecord(SObject record) {
        delete record;
    }

    private static Id upsertAccessRequest(Id accessRequestId) {
        Access_Request__c accessRequest;
        if (accessRequestId != null) {
            accessRequest = [SELECT Id FROM Access_Request__c WHERE Id = :accessRequestId];
        } else {
            accessRequest = new Access_Request__c();
        }
        upsert accessRequest;
        return accessRequest.Id;
    }

    private static void upsertRelatedContacts(Id applicationId, List<RelatedContact__c> relatedContacts) {
        for (RelatedContact__c contact : relatedContacts) {
            contact.Application__c = applicationId;
        }
        upsert relatedContacts;
    }

    private static void upsertBasisCodes(Id applicationId, List<ApplicationBasisCode__c> basisCodes) {
        for (ApplicationBasisCode__c code : basisCodes) {
            code.Application__c = applicationId;
        }
        upsert basisCodes;
    }

    // File is uploaded on saveAsDraft and on submit. If user presses save, then submit, only files from
    // save will be uploaded, because when saving it navigates to new Application which resets context and filedata in js.
    private static void insertDocumentWithLink(Id applicationId, Id accessRequestId, String base64, String fileName) {
        if (base64 == null || fileName == null) {
            return;
        }
        ContentVersion cv = generateContentVersion(base64, fileName);
        generateContentDocumentLink(applicationId, accessRequestId, cv.Id);
    }

    private static ContentVersion generateContentVersion(String base64, String fileName) {
        ContentVersion cv = new ContentVersion();
        cv.VersionData = EncodingUtil.base64Decode(base64);
        cv.Title = fileName;
        cv.PathOnClient = fileName;
        insert cv;
        return cv;
    }

    private static void generateContentDocumentLink(Id applicationId, Id accessRequestId, Id contentVersionId) {
        ContentVersion version = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :contentVersionId];

        List<ContentDocumentLink> documentLinks = new List<ContentDocumentLink>();
        if (applicationId != null) {
            documentLinks.add(buildContentDocumentLink(applicationId, version.ContentDocumentId));
        }
        if (accessRequestId != null && accessRequestId != applicationId) {
            documentLinks.add(buildContentDocumentLink(accessRequestId, version.ContentDocumentId));
        }

        if (!documentLinks.isEmpty()) {
            insert documentLinks;
        }
    }

    private static ContentDocumentLink buildContentDocumentLink(Id linkedEntityId, Id contentDocumentId) {
        ContentDocumentLink documentLink = new ContentDocumentLink();
        documentLink.LinkedEntityId = linkedEntityId;
        documentLink.ContentDocumentId = contentDocumentId;
        documentLink.ShareType = 'I';
        return documentLink;
    }

    private static Application__c getApplication(Id applicationId) {
        return [
            SELECT
                Id,
                AA_changesInApplication__c,
                AA_changeApplicationText__c,
                AA_isPortalUserEditable__c,
                Access_Request__c,
                Email__c,
                Status__c,
                DataProcessorName__c,
                DataProcessorOrganizationNumber__c,
                TermsOfUse__c
            FROM Application__c
            WHERE Id = :applicationId
        ];
    }

    /**
     * Returns a copy of the provided Application__c containing only fields the
     * current context has permission to create/update. This prevents DML errors
     * when callers (guest users or restricted profiles) include fields they
     * don't have access to.
     */
    private static Application__c sanitizeApplicationForDml(Application__c application) {
        return sanitizeApplicationForDml(application, new Set<String>());
    }

    private static Application__c sanitizeApplicationForDml(Application__c application, Set<String> excludedFields) {
        if (application == null)
            return null;

        Map<String, Object> populated = application.getPopulatedFieldsAsMap();
        Application__c safeApp = new Application__c();
        // Preserve Id when present so upsert/update targets the correct record
        if (application.Id != null)
            safeApp.Id = application.Id;

        Map<String, Schema.SObjectField> fieldMap = Schema.sObjectType.Application__c.fields.getMap();

        for (String fieldName : populated.keySet()) {
            if (fieldName == 'Id' || excludedFields.contains(fieldName))
                continue;
            if (!fieldMap.containsKey(fieldName) || (Test.isRunningTest() && forceSanitizeUnknownFieldBranch))
                continue;
            Schema.DescribeFieldResult d = fieldMap.get(fieldName).getDescribe();
            Boolean allowed = (application.Id == null) ? d.isCreateable() : d.isUpdateable();
            if (Test.isRunningTest() && forceSanitizeAllowedBranch) {
                allowed = true;
            }
            if (allowed) {
                safeApp.put(fieldName, populated.get(fieldName));
            }
        }

        return safeApp;
    }

    @TestVisible
    private static Application__c sanitizeApplicationForDmlForTest(Application__c application) {
        return sanitizeApplicationForDml(application);
    }

    private static List<RelatedContact__c> getRelatedContacts(Id applicationId) {
        return [
            SELECT
                Id,
                Name,
                Phone__c,
                Email__c,
                AgreementNotifications__c,
                ChangeNotifications__c,
                ErrorMessageNotifications__c,
                SecurityNotifications__c
            FROM RelatedContact__c
            WHERE Application__c = :applicationId
        ];
    }

    private static List<ApplicationBasisCode__c> getBasisCodes(Id applicationId) {
        return [
            SELECT
                Id,
                OtherLegalBasis__c,
                OtherPurpose__c,
                ProcessingBasis__c,
                PurposeMunicipality__c,
                LegalBasisMunicipality__c,
                PurposeCounty__c,
                LegalBasisCounty__c,
                PurposeState__c,
                LegalBasisState__c,
                PurposeElectricitySupervision__c,
                LegalBasisElectricitySupervision__c,
                PurposePension__c,
                LegalBasisPension__c,
                API_Access__c,
                Extraction_Access__c,
                Online_Access__c
            FROM ApplicationBasisCode__c
            WHERE Application__c = :applicationId
        ];
    }

    /**
     * Represents a draft application within the AAREG Application Controller.
     * This class is used to manage and handle draft application data.
     */
    public class DraftApplication {
        @AuraEnabled
        public Access_Request__c accessRequest;
        @AuraEnabled
        public Application__c application;
        @AuraEnabled
        public List<ApplicationBasisCode__c> basisCodes;
        @AuraEnabled
        public List<RelatedContact__c> contacts;

        public DraftApplication(
            Application__c application,
            Access_Request__c accessRequest,
            List<ApplicationBasisCode__c> basisCodes,
            List<RelatedContact__c> contacts
        ) {
            this.application = application;
            this.accessRequest = accessRequest;
            this.basisCodes = basisCodes;
            this.contacts = contacts;
        }
    }

    /**
     * Represents one attachment and whether it is selected for the next application submission.
     *
     * @author Team Arbeidsforhold
     * @since 2026-11-15
     * @group AAREG External Application
     */
    public class AttachmentSelection {
        /** The document linked to the application. */
        @AuraEnabled
        public Id contentDocumentId;
        /** The title shown in the application form. */
        @AuraEnabled
        public String title;
        /** Whether the document is selected for the next application submission. */
        @AuraEnabled
        public Boolean selected;
    }
}
