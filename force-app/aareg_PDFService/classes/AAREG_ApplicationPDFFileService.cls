public with sharing class AAREG_ApplicationPDFFileService {

    // =====================================================
    // Visualforce Controller Properties (for Application PDF)
    // =====================================================
    public List<AAREG_ApplicationInternal> application { get; set; }
    public List<AAREG_BasisCodesInternal> basisCodes { get; set; }
    public List<AAREG_RelatedContactInternal> relatedContacts { get; set; }

    public AAREG_ApplicationPDFFileService() {
        Id recordId = ApexPages.currentPage().getParameters().get('id');

        AAREG_ApplicationInternalController.ApplicationWrapper wrapper = 
            AAREG_ApplicationInternalController.getApplicationDetails(recordId);
        
        this.application = wrapper.application;
        this.basisCodes = wrapper.basisCodes;
        this.relatedContacts = wrapper.relatedContacts;
    }

    // =====================================================
    // Flow Invocable Method (handles both Application & Decision)
    // =====================================================
    @InvocableMethod(label='AAREG Generate PDF File')
    public static List<FlowOutput> generatePDFFromFlow(List<FlowInput> inputs) {
        List<FlowOutput> outputs = new List<FlowOutput>();

        for (FlowInput input : inputs) {
            FlowOutput output = new FlowOutput();

            if (input.pdfType == 'Application') {
                output.contentDocumentId = generateApplicationPDF(
                    input.accessRequestRecordId,
                    input.applicationRecordId,
                    input.fileTitle,
                    input.overwriteExisting
                );
            } else if (input.pdfType == 'Decision') {
                output.contentDocumentId = generateDecisionPDF(
                    input.decisionRecordId,
                    input.applicationRecordId,
                    input.fileTitle
                );
            }

            outputs.add(output);
        }

        return outputs;
    }

    // =====================================================
    // Application PDF Generation
    // =====================================================
    public static String generateApplicationPDF(Id accessRequestId, Id applicationId, String fileTitle, Boolean overwriteExisting) {
        Blob pdfBlob = getPDFBlob(Page.AAREG_ApplicationPDF, applicationId);

        if (overwriteExisting == true) {
            // Find existing PDF linked to the Access Request with same title
            List<ContentDocumentLink> existingLinks = [
                SELECT ContentDocumentId, ContentDocument.Title
                FROM ContentDocumentLink
                WHERE LinkedEntityId = :accessRequestId
            ];

            for (ContentDocumentLink link : existingLinks) {
                if (link.ContentDocument.Title == fileTitle) {
                    // Create a new version of the existing document
                    ContentVersion newVersion = new ContentVersion();
                    newVersion.ContentDocumentId = link.ContentDocumentId;
                    newVersion.Title = fileTitle;
                    newVersion.PathOnClient = fileTitle + '.pdf';
                    newVersion.VersionData = pdfBlob;
                    insert newVersion;

                    return link.ContentDocumentId;
                }
            }
        }

        // No existing file found or overwrite is false — create new
        return saveAsPDF(
            fileTitle,
            fileTitle + '.pdf',
            pdfBlob,
            accessRequestId
        );
    }

    // =====================================================
    // Decision PDF Generation
    // =====================================================
    public static String generateDecisionPDF(Id decisionId, Id applicationId, String fileTitle) {
        Blob pdfBlob = getPDFBlob(Page.AAREG_decisionInternalPDF, decisionId);

        return saveAsPDF(
            fileTitle,
            fileTitle + '.pdf',
            pdfBlob,
            applicationId
        );
    }

    // =====================================================
    // Shared Private Methods
    // =====================================================
    private static Blob getPDFBlob(PageReference page, Id recordId) {
        page.getParameters().put('id', recordId);

        if (Test.isRunningTest()) {
            return Blob.valueOf('Test PDF');
        }
        return page.getContentAsPDF();
    }

    private static String saveAsPDF(String title, String fileName, Blob pdfBlob, Id linkedEntityId) {
        ContentVersion cv = new ContentVersion();
        cv.Title = title;
        cv.PathOnClient = fileName;
        cv.VersionData = pdfBlob;
        insert cv;

        Id contentDocumentId = [
            SELECT ContentDocumentId 
            FROM ContentVersion 
            WHERE Id = :cv.Id
        ].ContentDocumentId;

        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.ContentDocumentId = contentDocumentId;
        cdl.LinkedEntityId = linkedEntityId;
        cdl.ShareType = 'V';
        cdl.Visibility = 'AllUsers';
        insert cdl;

        return contentDocumentId;
    }

    // =====================================================
    // Flow Input / Output Classes
    // =====================================================
    public class FlowInput {
        @InvocableVariable(label='PDF Type (Application or Decision)' required=true)
        public String pdfType;

        @InvocableVariable(label='Access Request Record Id' required=true)
        public String accessRequestRecordId;

        @InvocableVariable(label='Application Record Id')
        public String applicationRecordId;

        @InvocableVariable(label='Decision Record Id')
        public String decisionRecordId;

        @InvocableVariable(label='File Title' required=true)
        public String fileTitle;

        @InvocableVariable(label='True if there already exists a PDF and it should be overwritten, false to create a new PDF' required=true)
        public Boolean overwriteExisting;
    }

    public class FlowOutput {
        @InvocableVariable(label='Content Document Id')
        public String contentDocumentId;
    }
}