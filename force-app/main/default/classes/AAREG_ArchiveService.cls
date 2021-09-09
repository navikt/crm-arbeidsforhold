public class AAREG_ArchiveService {
  private static final String JOURNAL_POST_STATUS = 'J';
  private static final String OUTGOING_POST = 'U';
  private static final String INCOMING_POST = 'I';
  private static final String BUSINESS_UNIT = 'NAV Registerforvaltning';
  private static final String BUSINESS_UNIT_ID = '4534000';
  private static final String MANIFEST_FORMAT = '.xml';
  private static final String DECISION_NAME = 'VEDTAK';
  private static final String APPLICATION_NAME = 'SOKNAD';
  private static final String DEFALUT_FILE_FORMAT = '.html';

  public void archiveApplications(List<Application__c> applicationList) {
    Map<Id, Application__c> applications = new Map<Id, Application__c>(applicationList);
    Map<Id, List<ContentVersion>> contentVersions = getRealtedContentVersions(applications.keySet());
    List<Application__c> applicationsToUpdate = new List<Application__c>();

    for (Application__c application : applicationList) {
      Map<String, Blob> filesToSend = new Map<String, Blob>();
      Map<String, String> fileNameFormatMap = new Map<String, String>();
      String applicationFileName = formatFileName(application.Name + ' ' + APPLICATION_NAME + DEFALUT_FILE_FORMAT);
      String manifestName = getManifestName(application.Name, APPLICATION_NAME, Date.Today());

      filesToSend.put(applicationFileName, Blob.valueOf(application.AA_register_application_text__c));
      fileNameFormatMap.put(applicationFileName, DEFALUT_FILE_FORMAT);

      if (contentVersions.get(application.Id) != null) {
        fileNameFormatMap.putAll(getFileNameFormatMap(contentVersions.get(application.Id), application.Name));
        filesToSend.putAll(getContentVersionFileMap(contentVersions.get(application.Id), application.Name));
      }

      filesToSend.put(
        manifestName,
        getManifest(
          fileNameFormatMap,
          application,
          INCOMING_POST,
          getJournalPostName('Søknad', application.Name),
          application.ApplicationSubmittedDate__c
        )
      );

      Boolean success = sendFiles(filesToSend, manifestName);

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
      String decisionFileName = formatFileName(application.Name + ' ' + DECISION_NAME + DEFALUT_FILE_FORMAT);
      String manifestName = getManifestName(application.Name, DECISION_NAME, Date.Today());

      Map<String, String> fileNameFormat = new Map<String, String>();
      fileNameFormat.put(decisionFileName, DEFALUT_FILE_FORMAT);

      Map<String, Blob> filesToSend = new Map<String, Blob>();
      filesToSend.put(decisionFileName, Blob.valueOf(application.AA_DecisionArchiveText__c));
      filesToSend.put(
        manifestName,
        getManifest(
          fileNameFormat,
          application,
          OUTGOING_POST,
          getJournalPostName('Vedtak', application.Name),
          application.DecisionDate__c
        )
      );

      Boolean success = sendFiles(filesToSend, manifestName);

      if (success) {
        application.AA_DecisionArchived__c = true;
        application.AA_DecisionArchivedDate__c = Datetime.now();
        applicationsToUpdate.add(application);
      }
    }
    Database.update(applicationsToUpdate);
  }

  private Boolean sendFiles(Map<String, Blob> files, String xmlManifestName) {
    Boolean success = true;
    String xmlFileName;
    Blob xmlFileContent;

    if (files.containsKey(xmlManifestName)) {
      xmlFileName = xmlManifestName;
      xmlFileContent = files.get(xmlManifestName);
      files.remove(xmlManifestName);
    }

    for (String file : files.keySet()) {
      Blob fileData = files.get(file);
      WebSakFileService.WebSakFileResponse response = new WebSakFileService().postFile(file, fileData);

      if (!response.success) {
        success = false;
      }
    }

    if (xmlFileName != null && xmlFileContent != null) {
      success = sendXmlManifest(xmlFileName, xmlFileContent);
    }

    return success;
  }

  private Boolean sendXmlManifest(String xmlFileName, Blob xmlFileContent) {
    WebSakFileService.WebSakFileResponse xmlResponse = new WebSakFileService().postFile(xmlFileName, xmlFileContent);

    if (!xmlResponse.success) {
      return false;
    }
    return true;
  }

  private Blob getManifest(
    Map<String, String> fileInfo,
    Application__c application,
    String postType,
    String journalPostName,
    Date referenceDate
  ) {
    AAREG_WebsakXMLGenerator generator = new AAREG_WebsakXMLGenerator()
      .businessUnitId(BUSINESS_UNIT_ID)
      .businessUnitName(BUSINESS_UNIT)
      .journalPostStatus(JOURNAL_POST_STATUS)
      .journalPostType(postType)
      .journalPostName(journalPostName)
      .applicationId(application.Name)
      .userNavIdent(application.AA_CaseHandlerNavIdent__c)
      .organizationName(application.AccountName__c)
      .organizationNumber(application.OrganizationNumber__c)
      .mailingAddress(application.MailingAddress__c)
      .mailingCity(application.MailingCity__c)
      .mailingPostalCode(application.MailingPostalCode__c)
      .submissionDate(referenceDate)
      .documentNameFormat(fileInfo)
      .build();

    system.debug(generator.generateXML());
    return Blob.valueOf(generator.generateXML());
  }

  private Map<String, Blob> getContentVersionFileMap(List<ContentVersion> content, String applicationName) {
    Map<String, Blob> contentFileMap = new Map<String, Blob>();
    for (ContentVersion cv : content) {
      String fileName = formatFileName(applicationName + formatFileName(cv.title));
      contentFileMap.put(fileName, cv.VersionData);
    }
    return contentFileMap;
  }

  private Map<String, String> getFileNameFormatMap(List<ContentVersion> contentVersions, String refrenceNumber) {
    Map<String, String> fileNameFormat = new Map<String, String>();

    for (ContentVersion cv : contentVersions) {
      String fileName = formatFileName(refrenceNumber + formatFileName(cv.title));
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

  private String getManifestName(String applicationNumber, String type, Date archiveDate) {
    return applicationNumber.replaceAll('-', '') + '_' + type + '_' + formatDateString(archiveDate) + MANIFEST_FORMAT;
  }

  private String getJournalPostName(String type, String applicationNumber) {
    return type + ' - tilgang til AA-registeret - ' + applicationNumber.replaceAll('-', '');
  }

  private String formatFileName(String fileName) {
    return fileName.replaceAll('-', '').replaceAll(' ', '_');
  }

  private String formatDateString(Date input) {
    Datetime dateToFormat = input;
    return dateToFormat.formatGmt('YYYYMMdd');
  }
}
