public with sharing class AAREG_ApplicationDecisionPDFController {
    public Id currentRecordId { get; set; }
    public AAREG_ApplicationDecision currentRecord { get; set; }
    public AAREG_ApplicationInternal applicationRecord { get; set; }
    public List<AAREG_BasisCodesInternal> decisionDetailsRecords { get; set; }  

    public AAREG_ApplicationDecisionPDFController(ApexPages.StandardController sc) {
        this.currentRecordId = sc.getId();
        this.currentRecord = getApplicationDecisionRecord(this.currentRecordId);
        this.applicationRecord = getApplicationRecord(this.currentRecord.SoknadsId);
        this.decisionDetailsRecords = getApplicationDecisionDetails(this.currentRecordId);
       

    }

    private AAREG_ApplicationInternal getApplicationRecord(String currentRecordId){
        AAREG_ApplicationInternal applicationWrapperTempList = new AAREG_ApplicationInternal(); 
        List<Application__c> application = [
        SELECT Id,
               Name,
               AccountId__c, 
               AccountName__c, 
               Account__c, 
               ApplicationSubmittedDate__c,
               Contact__c, 
               DataProcessorName__c, 
               DataProcessorOrganizationNumber__c, 
               Email__c, 
               MailingAddress__c, 
               MailingCity__c, 
               MailingPostalCode__c,
               OrganizationNumber__c,
               CasehandlerOwner__r.Name
        FROM Application__c
        WHERE Id = :currentRecordId
        LIMIT 1
    ];
    if (application != null) {
        Application__c app = application[0];
          applicationWrapperTempList.SoknadsId = app.Id;
          applicationWrapperTempList.SoknadsNavn = app.Name;
          applicationWrapperTempList.KonsumentId = app.Account__c;
          applicationWrapperTempList.KonsumentNavn = app.AccountName__c;
          applicationWrapperTempList.KonsumentKontaktNavn = app.Contact__c;
          applicationWrapperTempList.KonsumentOrganisasjonsnummer = app.OrganizationNumber__c;
          applicationWrapperTempList.KonsumentAdresse = app.MailingAddress__c;
          applicationWrapperTempList.KonsumentPoststed = app.MailingCity__c;
          applicationWrapperTempList.KonsumentPostnummer = app.MailingPostalCode__c;
          applicationWrapperTempList.KonsumentEpost = app.Email__c;
          applicationWrapperTempList.SoknadLevert = app.ApplicationSubmittedDate__c;
          applicationWrapperTempList.DatabehandlerNavn = app.DataProcessorName__c;
          applicationWrapperTempList.DatabehandlerOrganisasjonsnummer = app.DataProcessorOrganizationNumber__c;
          applicationWrapperTempList.Sakseier = app.CasehandlerOwner__r.Name;
    }
    return applicationWrapperTempList;
}

   private AAREG_ApplicationDecision getApplicationDecisionRecord(String currentRecordId) {
        AAREG_ApplicationDecision decisionWrapper = new AAREG_ApplicationDecision();
        
        List<Application_Decision__c> decisionRecords = [
            SELECT Id, Name, CreatedDate, Application__c, Status__c,decision_description__c,Letter_complaint_text__c, Letter_terms_text__c,Decision_date__c
            FROM Application_Decision__c 
            WHERE Id = :currentRecordId 
            LIMIT 1
        ];

        if (!decisionRecords.isEmpty()) {
            Application_Decision__c app = decisionRecords[0];
            decisionWrapper.VedtaksNr = app.Name;
            decisionWrapper.Vedtaksdato = app.Decision_date__c;
            decisionWrapper.Vedtaksbegrunnelse =app.Decision_description__c;
            decisionWrapper.VedtaksId = app.Id;
            decisionWrapper.Status = app.Status__c;
            decisionWrapper.SoknadsId = app.Application__c;
            decisionWrapper.Klagetekst = app.Letter_complaint_text__c;
            decisionWrapper.Vilkaartekst = app.Letter_terms_text__c;
        }

        return decisionWrapper;
    }

    private List<AAREG_BasisCodesInternal> getApplicationDecisionDetails(String currentRecordId) {
        List<AAREG_BasisCodesInternal> decisionDetailsRecords = new List<AAREG_BasisCodesInternal>();

        List<Application_Decision_Details__c> detailRecords = [
            SELECT 
                Id, 
                Name,
                Application_Decision__c,
                API_Access__c,
                Extraction_Access__c,
                Legal_Basis__c,
                Online_Access__c,
                Processing_Basis__c,
                Purpose__c,
                Decision_description__c,
                Approved__c
            FROM Application_Decision_Details__c
            WHERE Application_Decision__c = :currentRecordId
        ];

        if(detailRecords != null && detailRecords.size() > 0){
            for(Application_Decision_Details__c detail : detailRecords){
                AAREG_BasisCodesInternal detailWrapper = new AAREG_BasisCodesInternal();
                detailWrapper.VedtaksDetailId = detail.Id;
                detailWrapper.VedtaksDetailNr = detail.Name;
                detailWrapper.Behandlingsgrunnlag = detail.Processing_Basis__c;
                detailWrapper.Hjemmel = detail.Legal_Basis__c;
                detailWrapper.Formaal = detail.Purpose__c;
                detailWrapper.APITilgang = detail.API_Access__c;
                detailWrapper.Uttrekk = detail.Extraction_Access__c;
                detailWrapper.WebTilgang = detail.Online_Access__c;
                detailWrapper.Vedtaksbegrunnelse = detail.Decision_description__c;
                detailWrapper.BehandlingsgrunnlagGodkjent = detail.Approved__c;
                decisionDetailsRecords.add(detailWrapper);
            }
        }
        return decisionDetailsRecords;
    }

}