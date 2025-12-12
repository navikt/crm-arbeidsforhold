public with sharing class AAREG_ApplicationDecisionPDFController {
    public Id currentRecordId { get; set; }
    public AAREG_ApplicationDecision currentRecord { get; set; }
    public AAREG_ApplicationInternal applicationRecord { get; set; }

    public AAREG_ApplicationDecisionPDFController(ApexPages.StandardController sc) {
        this.currentRecordId = sc.getId();
        this.currentRecord = getApplicationDecisionRecord(this.currentRecordId);
        this.applicationRecord = getApplicationRecord(this.currentRecord.SoknadsId);
       

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
               OrganizationNumber__c
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
    }
    return applicationWrapperTempList;
}

   private AAREG_ApplicationDecision getApplicationDecisionRecord(String currentRecordId) {
        AAREG_ApplicationDecision decisionWrapper = new AAREG_ApplicationDecision();
        
        List<Application_Decision__c> decisionRecords = [
            SELECT Id, Name, CreatedDate, Application__c, Status__c 
            FROM Application_Decision__c 
            WHERE Id = :currentRecordId 
            LIMIT 1
        ];

        if (!decisionRecords.isEmpty()) {
            Application_Decision__c app = decisionRecords[0];
            decisionWrapper.VedtaksNr = app.Name;
            decisionWrapper.VedtaksId = app.Id;
            decisionWrapper.Status = app.Status__c;
            decisionWrapper.SoknadsId = app.Application__c;
        }

        return decisionWrapper;
    }

}