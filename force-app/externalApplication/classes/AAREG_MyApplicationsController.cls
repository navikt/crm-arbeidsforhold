/**
 * AAREG_MyApplicationsController is a controller class designed to handle
 * operations related to "My Applications" in the external application.
 * 
 * This class enforces sharing rules to ensure that the operations respect
 * the user's access permissions.
 */
public with sharing class AAREG_MyApplicationsController {
  @AuraEnabled(cacheable=true)
  /**
   * Retrieves a list of applications associated with the specified user.
   *
   * @param userId The ID of the user whose applications are to be retrieved.
   * @return A list of Application__c records associated with the given user.
   */
  public static List<Application__c> getUsersApplications(String userId) {
    String lastUsedOrganization = [SELECT Id, lastUsedOrganization__c FROM User WHERE ID = :userid ]
    ?.LastUsedOrganization__c;

    if (lastUsedOrganization != null) {
      /**
       * Retrieves the applications associated with the last used organization.
       *
       * @param lastUsedOrganization The organization that was last used.
       * @return A list of applications for the specified organization.
       */
      return getApplications(lastUsedOrganization);
    } else {
      return new List<Application__c>();
    }
  }

  @AuraEnabled
  /**
   * Retrieves the decision PDF for the specified application.
   *
   * @param applicationId The ID of the application for which the decision PDF is to be retrieved.
   * @return The decision PDF as a String.
   */
  public static String getDecisionPDF(Id applicationId) {
    String documentTitle ='Vedtak til søknad %';
    try { 
       // Query the ContentDocumentLink associated with the Application_Decision__c
       List<ContentDocumentLink> contentDocumentLinks = [
          SELECT ContentDocumentId
          FROM ContentDocumentLink
          WHERE LinkedEntityId = :applicationId
        ];

        // Collect all ContentDocumentIds from ContentDocumentLinks
        Set<Id> contentDocumentIds = new Set<Id>();
        for (ContentDocumentLink contentDocumentLink : contentDocumentLinks) {
            contentDocumentIds.add(contentDocumentLink.ContentDocumentId);
        }

        // Query ContentVersions outside the loop
        Map<Id, ContentVersion> contentVersionMap = new Map<Id, ContentVersion>(
            [
                SELECT Id, ContentDocumentId
                FROM ContentVersion
                WHERE ContentDocumentId IN :contentDocumentIds
                AND Title LIKE :documentTitle
                ORDER BY VersionNumber DESC
            ]
        );

        // Find the correct ContentVersion
        ContentVersion selectedContentVersion;
        for (Id contentDocumentId : contentDocumentIds) {
            if (contentVersionMap.containsKey(contentDocumentId)) {
                selectedContentVersion = contentVersionMap.get(contentDocumentId);
                break; // Exit the loop once the correct ContentVersion is found
            }
        }

    // If no matching ContentVersion is found, throw an error
    if (selectedContentVersion == null) {
      throw new AuraHandledException('No matching file found for the given Application Decision.');
    }
    
    // Return the download URL for the ContentVersion
        return '/sfc/servlet.shepherd/document/download/' + selectedContentVersion.ContentDocumentId +'?operationContext=S1';
    } catch (Exception e) {
        throw new AuraHandledException('Error retrieving the PDF: ' + e.getMessage());
    }
}

  private static List<Application__c> getApplications(String lastUsedOrganization) {
    List<Application__c> applications = new List<Application__c>();
    if (Schema.sObjectType.Application__c.isAccessible()) {
      List<Application__c> applicationstemp = new List<Application__c>(
        [
          SELECT Id, Name, CreatedDate,Status__c, ApplicationSubmittedDate__c,ApplicationDeadlineForReply__c, AA_CasehandlerDecisionTemplate__c
          FROM Application__c
          WHERE OrganizationNumber__c = :lastUsedOrganization
          AND  Status__c IN ('In Progress', 'Draft', 'New', 'Additional Information Required', 'Declined')
          ORDER BY ApplicationSubmittedDate__c DESC NULLS LAST
        ]
      );
      for (Application__c app : applicationstemp) {
        app.Status__c = translateStatus(app.Status__c);
        applications.add(app);
      }
    } else {
      throw new AuraHandledException('Insufficient permissions to access Application__c records.');
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