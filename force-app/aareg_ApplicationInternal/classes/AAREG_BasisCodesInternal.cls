public with sharing class AAREG_BasisCodesInternal {
   /*
    * wrapperclass used by AAREG_ApplicationInternalController to send data to LWC
    * wrapperclass used by AAREG_ApplicationDecisionPDFController to send data to PDF generator
    **/

    @AuraEnabled public String KodeverkId{get;set;}
    @AuraEnabled public String KodeverkNummer{get;set;}
    @AuraEnabled public String SoknadsId{get;set;}
    @AuraEnabled public String OrganisasjonsType{get;set;}
    @AuraEnabled public String AndreHjemmel{get;set;} 
    @AuraEnabled public String AndreFormaal{get;set;}
    @AuraEnabled public String Hjemmel{get;set;}
    @AuraEnabled public String Formaal{get;set;}
    @AuraEnabled public String Behandlingsgrunnlag{get;set;}
    @AuraEnabled public Boolean APITilgang{get;set;}
    @AuraEnabled public Boolean Uttrekk{get;set;}
    @AuraEnabled public Boolean WebTilgang{get;set;}  
    @AuraEnabled public String VedtaksDetailId{get;set;}
    @AuraEnabled public String VedtaksDetailNr{get;set;}
    @AuraEnabled public String VedtaksNr{get;set;}
    @AuraEnabled public String Status{get;set;}
    @AuraEnabled public String Vedtaksbegrunnelse{get;set;}
    @AuraEnabled public Boolean BehandlingsgrunnlagGodkjent{get;set;}
}