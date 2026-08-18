/**
 * AAREG_MyApplicationsController is a controller class designed to handle
 * operations related to "My Applications" in the external application.
 *
 * This class enforces sharing rules to ensure that the operations respect
 * the user's access permissions.
 *
 * @author Jordan Mathews
 * @author Ann Kristin Olsen
 * @author Erik Fladby
 * @since August 2021
 * @group AAREG External Application
 */
public with sharing class AAREG_MyApplicationsController {
    /** Test-only toggle to simulate insufficient Application__c access in getApplications. */
    @TestVisible
    static Boolean forceNoApplicationAccess = false;
    /** Test-only toggle to simulate an unexpected error in getDecisionPDF. */
    @TestVisible
    static Boolean forceUnexpectedGetDecisionPdfError = false;

    /**
     * Retrieves a list of applications associated with the specified user. Result is
     * cacheable (`cacheable=true`); the calling LWC must invoke `refreshApex()` to
     * force a refresh after the underlying data changes.
     *
     * @param userId The ID of the user whose applications are to be retrieved.
     * @return A list of Application__c records associated with the given user.
     */
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

    /**
     * Retrieves the decision PDF for the specified application.
     *
     * @param applicationId The ID of the application for which the decision PDF is to be retrieved.
     * @return The decision PDF as a String.
     */
    @AuraEnabled
    public static String getDecisionPDF(Id applicationId) {
        String documentTitle = 'Vedtak til søknad %';
        try {
            if (Test.isRunningTest() && forceUnexpectedGetDecisionPdfError) {
                Integer fail = 1 / 0;
            }

            // First, query Application_Decision__c records for the given application
            List<Application_Decision__c> decisions = [
                SELECT Id
                FROM Application_Decision__c
                WHERE Application__c = :applicationId
                ORDER BY CreatedDate DESC
                LIMIT 1
            ];

            if (decisions.isEmpty()) {
                throw new AuraHandledException('No decision found for the given Application.');
            }

            // Query the ContentDocumentLink associated with the Application_Decision__c
            List<ContentDocumentLink> contentDocumentLinks = [
                SELECT ContentDocumentId
                FROM ContentDocumentLink
                WHERE LinkedEntityId = :decisions[0].Id
            ];

            // Collect all ContentDocumentIds from ContentDocumentLinks
            Set<Id> contentDocumentIds = new Set<Id>();
            for (ContentDocumentLink contentDocumentLink : contentDocumentLinks) {
                contentDocumentIds.add(contentDocumentLink.ContentDocumentId);
            }

            if (contentDocumentIds.isEmpty()) {
                throw new AuraHandledException('No documents linked to the decision.');
            }

            // Query ContentVersions outside the loop
            List<ContentVersion> contentVersions = [
                SELECT Id, ContentDocumentId
                FROM ContentVersion
                WHERE ContentDocumentId IN :contentDocumentIds AND Title LIKE :documentTitle AND IsLatest = TRUE
                ORDER BY VersionNumber DESC
                LIMIT 1
            ];

            // If no matching ContentVersion is found, throw an error
            if (contentVersions.isEmpty()) {
                throw new AuraHandledException('No matching file found for the given Application Decision.');
            }

            ContentVersion selectedContentVersion = contentVersions[0];

            // Return the download URL for the ContentVersion
            return '/sfc/servlet.shepherd/document/download/' +
                selectedContentVersion.ContentDocumentId +
                '?operationContext=S1';
        } catch (AuraHandledException e) {
            throw e;
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving the PDF: ' + e.getMessage());
        }
    }

    /**
     * Retrieves the user's applications for the given organization, translating each
     * application's status to its Norwegian label.
     *
     * @param lastUsedOrganization Organization number to filter applications by.
     * @return The matching Application__c records for the organization, newest submission first.
     * @throws AuraHandledException If the running user cannot access Application__c records.
     */
    private static List<Application__c> getApplications(String lastUsedOrganization) {
        List<Application__c> applications = new List<Application__c>();
        if (Schema.sObjectType.Application__c.isAccessible() && !(Test.isRunningTest() && forceNoApplicationAccess)) {
            List<Application__c> applicationstemp = new List<Application__c>(
                [
                    SELECT
                        Id,
                        Name,
                        CreatedDate,
                        Status__c,
                        ApplicationSubmittedDate__c,
                        ApplicationDeadlineForReply__c,
                        DecisionDate__c,
                        AA_CasehandlerDecisionTemplate__c
                    FROM Application__c
                    WHERE
                        OrganizationNumber__c = :lastUsedOrganization
                        AND Status__c IN (
                            'In Progress',
                            'Draft',
                            'New',
                            'Additional Information Required',
                            'Declined',
                            'Suspension'
                        )
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

    /**
     * Translates an application status to its Norwegian label.
     *
     * @param status The English status value.
     * @return The Norwegian label, or "Ukjent status" if the value is not recognized.
     */
    private static String translateStatus(String status) {
        Map<String, String> statusLabels = new Map<String, String>{
            'In Progress' => 'Under behandling',
            'Draft' => 'Utkast',
            'New' => 'Ny',
            'Additional Information Required' => 'Venter på svar',
            'Approved' => 'Innvilget',
            'Approved Partially' => 'Delvis innvilget',
            'Declined' => 'Avslag',
            'Suspension' => 'Henlagt'
        };
        return statusLabels.containsKey(status) ? statusLabels.get(status) : 'Ukjent status';
    }

    @TestVisible
    private static String translateStatusForTest(String status) {
        return translateStatus(status);
    }
}
