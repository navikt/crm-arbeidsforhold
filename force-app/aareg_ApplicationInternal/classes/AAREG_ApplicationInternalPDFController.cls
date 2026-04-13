public with sharing class AAREG_ApplicationInternalPDFController {

    public List<AAREG_ApplicationInternal> application { get; set; }
    public List<AAREG_BasisCodesInternal> basisCodes { get; set; }
    public List<AAREG_RelatedContactInternal> relatedContacts { get; set; }

    public AAREG_ApplicationInternalPDFController() {
        Id recordId = ApexPages.currentPage().getParameters().get('id');

        AAREG_ApplicationInternalController.ApplicationWrapper wrapper = 
            AAREG_ApplicationInternalController.getApplicationDetails(recordId);
        
        this.application = wrapper.application;
        this.basisCodes = wrapper.basisCodes;
        this.relatedContacts = wrapper.relatedContacts;
    }

    @InvocableMethod(
        label='Generate Application PDF'
        description='Generates a PDF from the application and saves it as a file on the record'
    )

    public static void generatePDFs(List<Id> applicationIds) {
        for (Id applicationId : applicationIds) {
            generatePDF(applicationId);
        }
    }

    private static void generatePDF(Id applicationId) {
        Application__c app = [
            SELECT Name,Access_Request__c FROM Application__c WHERE Id = :applicationId LIMIT 1
        ];

        PageReference pdfPage = Page.AAREG_ApplicationPDF;
        pdfPage.getParameters().put('id', applicationId);

        Blob pdfBlob;
        if (Test.isRunningTest()) {
            pdfBlob = Blob.valueOf('Test PDF');
        } else {
            pdfBlob = pdfPage.getContentAsPDF();
        }

        ContentVersion cv = new ContentVersion();
        cv.Title = 'Søknad - ' + app.Name;
        cv.PathOnClient = 'Soknad_' + app.Name + '.pdf';
        cv.VersionData = pdfBlob;
        insert cv;

        Id contentDocumentId = [
            SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id
        ].ContentDocumentId;

        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.ContentDocumentId = contentDocumentId;
        cdl.LinkedEntityId = applicationId;
        cdl.ShareType = 'V';
        cdl.Visibility = 'AllUsers';
        insert cdl;
    }
}