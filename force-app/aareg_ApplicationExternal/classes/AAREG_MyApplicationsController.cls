public with sharing class AAREG_MyApplicationsController {
  @AuraEnabled(cacheable=true)
  public static List<Application__c> getUsersApplications(String userId) {
    String lastUsedOrganization = [SELECT Id, lastUsedOrganization__c FROM User WHERE ID = :userid]
    ?.LastUsedOrganization__c;

    if (lastUsedOrganization != null) {
      return getApplications(lastUsedOrganization);
    } else {
      return new List<Application__c>();
    }
  }

  @AuraEnabled
  public static String getDecisionPDF(Id applicationId) {
    try {

        /* Query the Application_Decision__c record
        Application_Decision__c applicationDecision = [
            SELECT Id
            FROM Application_Decision__c
            WHERE Application__c = :applicationId 
            AND Process_status__c = 'Completed'
            LIMIT 1
        ];'*/
            
       // Query the ContentDocumentLink associated with the Application_Decision__c
       ContentDocumentLink contentDocumentLink = [
        SELECT ContentDocumentId
        FROM ContentDocumentLink
        //WHERE LinkedEntityId = :applicationDecision.Id
        WHERE LinkedEntityId = :applicationId
        LIMIT 1
    ];

    // Query the latest ContentVersion for the ContentDocument
    ContentVersion contentVersion = [
        SELECT Id, ContentDocumentId
        FROM ContentVersion
        WHERE ContentDocumentId = :contentDocumentLink.ContentDocumentId
        AND Title LIKE 'Vedtak til søknad %'
        ORDER BY VersionNumber DESC
        LIMIT 1
    ];

    // Check if a ContentDocumentLink already exists for the current user
    List<ContentDocumentLink> existingLinks = [
      SELECT Id
      FROM ContentDocumentLink
      WHERE ContentDocumentId = :contentVersion.ContentDocumentId
      AND LinkedEntityId = :UserInfo.getUserId()
      LIMIT 1
  ];

    // Create a ContentDocumentLink to share the file with the current user
    if (existingLinks.isEmpty()) {
      // Create a ContentDocumentLink to share the file with the current user
      ContentDocumentLink newLink = new ContentDocumentLink(
          ContentDocumentId = contentVersion.ContentDocumentId,
          LinkedEntityId = UserInfo.getUserId(), // Link to the current user
          ShareType = 'I', // Inferred access for user
          Visibility = 'AllUsers' // Make it visible to the user
      );
      insert newLink;
      System.debug('New ContentDocumentLink created for user.');
  } else {
      System.debug('ContentDocumentLink already exists for the user.');
  }

        // Return the download URL for the ContentVersion
        return '/sfc/servlet.shepherd/document/download/' + contentVersion.ContentDocumentId;
    } catch (Exception e) {
        throw new AuraHandledException('Error retrieving the PDF: ' + e.getMessage());
    }
}

  private static List<Application__c> getApplications(String lastUsedOrganization) {
    List<Application__c> applications = new List<Application__c>();
    List<Application__c> applicationstemp = new List<Application__c>(
      [
        SELECT Id, Name, CreatedDate, Casehandler_Status__c,Status__c, ApplicationSubmittedDate__c,ApplicationDeadlineForReply__c, AA_CasehandlerDecisionTemplate__c
        FROM Application__c
        WHERE OrganizationNumber__c = :lastUsedOrganization
        ORDER BY ApplicationSubmittedDate__c DESC NULLS LAST
      ]
    );
    for (Application__c app : applicationstemp) {
      app.Status__c = translateStatus(app.Status__c);
      applications.add(app);
    }
    return applications;
  }

  private static String translateStatus(String status) {
    Map<String, String> statusLabels = new Map<String, String>{
      'In Progress' => 'Under behandling',
      'Draft' => 'Utkast',
      'New' => 'Ny',
      'Additional Information Required' => 'Venter på svar',
      'Approved' => 'Innvilget',
      'Approved Partially' => 'Delvis innvilget',
      'Declined' => 'Avslag',
      'Suspension' => 'Trukket tilbake'
    };
    return statusLabels.containsKey(status) ? statusLabels.get(status) : 'Ukjent status';
  }
}