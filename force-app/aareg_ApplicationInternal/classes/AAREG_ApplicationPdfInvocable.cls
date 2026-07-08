/**
 * @description Invocable wrapper for PDF-generering, kallbar fra Flow.
 *              Trigger logikken bestemmes i Flow; denne klassen bulkifiserer 
 *              og delegerer til Queueable for asynkron utførelse.
 * @group AAREG
 */
public with sharing class AAREG_ApplicationPdfInvocable {

    /**
     * @description Invocable action for å generere PDF for søknader.
     *              Hvis det allerede finnes en PDF for søknaden, opprettes en 
     *              ny versjon. Ellers opprettes et nytt ContentDocument.
     * @param requests Liste med input-wrappere fra Flow
     */
    @InvocableMethod(
        label='Generer Søknads-PDF'
        description='Genererer PDF for søknad. Versjonerer eksisterende PDF hvis den finnes.'
        category='AAREG'
    )
    public static void generatePdfs(List<PdfRequest> requests) {
        if (requests == null || requests.isEmpty()) {
            return;
        }

        Set<Id> applicationIds = new Set<Id>();
        for (PdfRequest req : requests) {
            if (req.applicationId != null) {
                applicationIds.add(req.applicationId);
            }
        }

        if (applicationIds.isEmpty()) {
            return;
        }

        // Kjør asynkront for å unngå governor-issues fra Flow-kontekst
        if (System.isQueueable() || System.isFuture() || System.isBatch()) {
            AAREG_ApplicationPdfService.generatePdfs(applicationIds);
        } else {
            System.enqueueJob(new AAREG_ApplicationPdfQueueable(applicationIds));
        }
    }

    /**
     * @description Wrapper-klasse for Flow-input.
     *              Hvert request representerer én søknad som trenger PDF.
     */
    public class PdfRequest {
        @InvocableVariable(
            label='Application ID'
            description='Id til Application__c som skal få generert PDF.'
            required=true
        )
        public Id applicationId;
    }
}