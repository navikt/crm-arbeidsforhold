public class AAREG_ArchiveService {
  private static final String JOURNAL_POST_STATUS = 'J';
  private static final String OUTGOING_POST = 'U';
  private static final String INCOMING_POST = 'I';
  private static final String BUSINESS_UNIT = 'NAV Registerforvaltning';
  private static final String BUSINESS_UNIT_ID = '4534000';
  private static final String MANIFEST_NAME = ' manifest.xml';
  private static final String DECISION_NAME = ' AAREGVEDTAK';
  private static final String APPLICATION_NAME = ' AAREGSOKNAD';
  private static final String DEFALUT_FILE_FORMAT = '.html';

  public void archiveApplications(Application__c[] applicationList) {
    Map<Id, Application__c> applications = new Map<Id, Application__c>(applicationList);
    Map<Id, List<ContentVersion>> contentVersions = getRealtedContentVersions(applications.keySet());
    List<Application__c> applicationsToUpdate = new List<Application__c>();

    for (Application__c application : applicationList) {
      String applicationFileName = application.Name + APPLICATION_NAME + DEFALUT_FILE_FORMAT;

      Map<String, String> fileNameFormatMap = new Map<String, String>();
      fileNameFormatMap.put(applicationFileName, DEFALUT_FILE_FORMAT);

      Map<String, Blob> filesToSend = new Map<String, Blob>();
      filesToSend.put(applicationFileName, Blob.valueOf(application.AA_register_application_text__c));
      filesToSend.put(
        application.Name + MANIFEST_NAME,
        getManifest(fileNameFormatMap, application, INCOMING_POST, application.ApplicationSubmittedDate__c)
      );

      if (contentVersions.get(application.Id) != null) {
        fileNameFormatMap.putAll(getFileNameFormatMap(contentVersions.get(application.Id), application.Name));
        filesToSend.putAll(getContentVersionFileMap(contentVersions.get(application.Id), application.Name));
      }

      Boolean success = sendFiles(filesToSend);

      if (success) {
        application.AA_ApplicationArchived__c = true;
        application.AA_ApplicationArchivedDate__c = Datetime.now();
        applicationsToUpdate.add(application);
      }
    }
    Database.update(applicationsToUpdate);
  }

  public void archiveDecisions(List<Application__c> applications) {
    List<Application__c> applicationsToUpdate = new List<Application__c>();

    for (Application__c application : applications) {
      String reference = application.Name;
      String decisionFileName = reference + DECISION_NAME + DEFALUT_FILE_FORMAT;

      Map<String, String> fileNameFormat = new Map<String, String>();
      fileNameFormat.put(reference + DECISION_NAME, DEFALUT_FILE_FORMAT);

      Map<String, Blob> filesToSend = new Map<String, Blob>();
      filesToSend.put(decisionFileName, Blob.valueOf(application.AA_DecisionArchiveText__c));
      filesToSend.put(
        reference + MANIFEST_NAME,
        getManifest(fileNameFormat, application, OUTGOING_POST, application.DecisionDate__c)
      );

      Boolean success = sendFiles(filesToSend);

      if (success) {
        application.AA_DecisionArchived__c = true;
        application.AA_DecisionArchivedDate__c = Datetime.now();
        applicationsToUpdate.add(application);
      }
    }
    Database.update(applicationsToUpdate);
  }

  private Boolean sendFiles(Map<String, Blob> files) {
    Boolean success = true;
    for (String file : files.keySet()) {
      Blob fileData = files.get(file);
      WebSakFileService.WebSakFileResponse response = new WebSakFileService().postFile(file, fileData);
      if (!response.success) {
        success = false;
      }
    }
    return success;
  }

  private Blob getManifest(
    Map<String, String> fileInfo,
    Application__c application,
    String postType,
    Date referenceDate
  ) {
    AAREG_WebsakXMLGenerator generator = new AAREG_WebsakXMLGenerator()
      .businessUnitId(BUSINESS_UNIT_ID)
      .businessUnitName(BUSINESS_UNIT)
      .journalPostStatus(JOURNAL_POST_STATUS)
      .journalPostType(postType)
      .applicationId(application.Id)
      .userNavIdent(application.AA_CaseHandlerNavIdent__c)
      .organizationName(application.AccountName__c)
      .organizationNumber(application.OrganizationNumber__c)
      .mailingAddress(application.MailingAddress__c)
      .mailingCity(application.MailingCity__c)
      .mailingPostalCode(application.MailingPostalCode__c)
      .submissionDate(referenceDate)
      .documentNameFormat(fileInfo)
      .build();

    return Blob.valueOf(generator.generateXML());
  }

  private Map<String, Blob> getContentVersionFileMap(List<ContentVersion> content, String applicationName) {
    Map<String, Blob> contentFileMap = new Map<String, Blob>();
    for (ContentVersion cv : content) {
      String fileName = cv.title + ' ' + applicationName;
      contentFileMap.put(fileName, cv.VersionData);
    }
    return contentFileMap;
  }

  private Map<String, String> getFileNameFormatMap(List<ContentVersion> contentVersions, String refrenceNumber) {
    Map<String, String> fileNameFormat = new Map<String, String>();

    for (ContentVersion cv : contentVersions) {
      String fileName = cv.title + ' ' + refrenceNumber;
      fileNameFormat.put(fileName, cv.fileType);
    }
    return fileNameFormat;
  }

  private Map<Id, List<ContentVersion>> getRealtedContentVersions(set<Id> relatedIds) {
    Map<Id, ContentDocumentLink> documentLinkMap = getDocumentLinkMap(relatedIds);

    if (documentLinkMap.isEmpty()) {
      return new Map<Id, List<ContentVersion>>();
    }
    return getContentVersionMap(documentLinkMap);
  }

  private Map<Id, List<ContentVersion>> getContentVersionMap(Map<Id, ContentDocumentLink> documentLinkMap) {
    Map<Id, List<ContentVersion>> contentVersionMap = new Map<Id, List<ContentVersion>>();
    List<ContentVersion> contentVersions = [
      SELECT Id, ContentDocumentId, Title, FileType, VersionData
      FROM ContentVersion
      WHERE ContentDocumentId = :documentLinkMap.keySet()
    ];

    for (ContentVersion cv : contentVersions) {
      Id linkedEntityId = documentLinkMap.get(cv.ContentDocumentId).LinkedEntityId;
      if (!contentVersionMap.containsKey(linkedEntityId)) {
        contentVersionMap.put(linkedEntityId, new List<ContentVersion>());
      }
      contentVersionMap.get(linkedEntityId).add(cv);
    }
    return contentVersionMap;
  }

  private Map<Id, ContentDocumentLink> getDocumentLinkMap(set<Id> relatedIds) {
    Map<Id, ContentDocumentLink> documentLinkMap = new Map<Id, ContentDocumentLink>();
    List<ContentDocumentLink> documentLinks = [
      SELECT ContentDocumentId, Id, LinkedEntityId
      FROM ContentDocumentLink
      WHERE LinkedEntityId = :relatedIds
    ];

    if (documentLinks.isEmpty()) {
      return new Map<Id, ContentDocumentLink>();
    }

    for (ContentDocumentLink link : documentLinks) {
      documentLinkMap.put(link.ContentDocumentId, link);
    }
    return documentLinkMap;
  }
}