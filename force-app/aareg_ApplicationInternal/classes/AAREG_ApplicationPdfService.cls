/**
 * @description Genererer PDF for søknader og håndterer versjonering.
 * @group AAREG
 */
public with sharing class AAREG_ApplicationPdfService {

    private static final String PDF_TITLE_PREFIX = 'Soknad_';
    private static final String PDF_EXTENSION    = '.pdf';

    /**
     * @description Genererer og lagrer PDF-er for gitte søknader.
     *              Hvis en PDF allerede finnes for søknaden, opprettes en ny versjon.
     * @param applicationIds Set med Id-er til Application__c
     */
    public static void generatePdfs(Set<Id> applicationIds) {
        if (applicationIds == null || applicationIds.isEmpty()) {
            return;
        }

        Map<Id, Id> existingDocByApp = findExistingPdfDocuments(applicationIds);
        List<ContentVersion> versionsToInsert = new List<ContentVersion>();
        List<Id> appsNeedingLink = new List<Id>();

        for (Id appId : applicationIds) {
            try {
                Blob pdfBlob = renderApplicationPdf(appId);
                String title = PDF_TITLE_PREFIX + appId;

                ContentVersion cv = new ContentVersion(
                    Title           = title,
                    PathOnClient    = title + PDF_EXTENSION,
                    VersionData     = pdfBlob,
                    ReasonForChange = 'Automatisk generert PDF'
                );

                // Versjonering: hvis dokumentet eksisterer, knytt til samme ContentDocument
                if (existingDocByApp.containsKey(appId)) {
                    cv.ContentDocumentId = existingDocByApp.get(appId);
                } else {
                    appsNeedingLink.add(appId);
                }

                versionsToInsert.add(cv);
            } catch (Exception e) {
                logError('Kunne ikke generere PDF for ' + appId, e);
            }
        }

        if (versionsToInsert.isEmpty()) {
            return;
        }

        insert versionsToInsert;

        // For nye dokumenter: opprett ContentDocumentLink mot søknaden
        createDocumentLinks(versionsToInsert, appsNeedingLink);
    }

    /**
     * @description Renderer Visualforce-siden som PDF-blob.
     */
    private static Blob renderApplicationPdf(Id applicationId) {
        PageReference pageRef = Page.AAREG_ApplicationInternalPDF;
        pageRef.getParameters().put('id', applicationId);

        if (Test.isRunningTest()) {
            return Blob.valueOf('TEST PDF CONTENT');
        }
        return pageRef.getContentAsPDF();
    }

    /**
     * @description Finner eksisterende PDF-dokumenter knyttet til søknader 
     *              basert på tittel-konvensjonen.
     * @return Map<applicationId, ContentDocumentId>
     */
    private static Map<Id, Id> findExistingPdfDocuments(Set<Id> applicationIds) {
        Map<Id, Id> result = new Map<Id, Id>();

        Set<String> expectedTitles = new Set<String>();
        for (Id appId : applicationIds) {
            expectedTitles.add(PDF_TITLE_PREFIX + appId);
        }

        // Finn alle koblinger mellom søknader og ContentDocuments
        Map<Id, ContentDocumentLink> linkByDocId = new Map<Id, ContentDocumentLink>();
        for (ContentDocumentLink link : [
            SELECT ContentDocumentId, LinkedEntityId
            FROM ContentDocumentLink
            WHERE LinkedEntityId IN :applicationIds
        ]) {
            linkByDocId.put(link.ContentDocumentId, link);
        }

        if (linkByDocId.isEmpty()) {
            return result;
        }

        // Finn ContentDocuments med matchende tittel
        for (ContentDocument doc : [
            SELECT Id, Title
            FROM ContentDocument
            WHERE Id IN :linkByDocId.keySet()
              AND Title IN :expectedTitles
        ]) {
            ContentDocumentLink link = linkByDocId.get(doc.Id);
            if (link != null) {
                result.put(link.LinkedEntityId, doc.Id);
            }
        }

        return result;
    }

    /**
     * @description Oppretter ContentDocumentLink for nye PDF-er.
     */
    private static void createDocumentLinks(
        List<ContentVersion> versions,
        List<Id> appsNeedingLink
    ) {
        if (appsNeedingLink.isEmpty()) {
            return;
        }

        Set<Id> needsLinkSet = new Set<Id>(appsNeedingLink);

        // Hent ContentDocumentId fra de nylig insertede versions
        Map<Id, Id> docIdByVersionId = new Map<Id, Id>();
        for (ContentVersion cv : [
            SELECT Id, ContentDocumentId, Title
            FROM ContentVersion
            WHERE Id IN :versions
        ]) {
            // Tittel inneholder applicationId
            String appIdStr = cv.Title.removeStart(PDF_TITLE_PREFIX);
            Id appId = Id.valueOf(appIdStr);
            if (needsLinkSet.contains(appId)) {
                docIdByVersionId.put(appId, cv.ContentDocumentId);
            }
        }

        List<ContentDocumentLink> links = new List<ContentDocumentLink>();
        for (Id appId : docIdByVersionId.keySet()) {
            links.add(new ContentDocumentLink(
                ContentDocumentId = docIdByVersionId.get(appId),
                LinkedEntityId    = appId,
                ShareType         = 'V',          // Viewer
                Visibility        = 'AllUsers'
            ));
        }

        if (!links.isEmpty()) {
            insert links;
        }
    }

    private static void logError(String context, Exception e) {
        LoggerUtility logger = new LoggerUtility();
        logger.error(
            context + '. Melding: ' + e.getMessage() 
            + '. Stack: ' + e.getStackTraceString(),
            null
        );
        logger.publish();
    }
}