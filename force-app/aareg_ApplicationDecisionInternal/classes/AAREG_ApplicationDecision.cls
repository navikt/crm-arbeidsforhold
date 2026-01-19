public with sharing class AAREG_ApplicationDecision {
        /*
         * wrapperclass used by AAREG_ApplicationDecisionController to send data to LWC
         **/
         @AuraEnabled public String VedtaksId{get;set;}
         @AuraEnabled public String VedtaksNr{get;set;}
         @AuraEnabled public String Status{get;set;}
         @AuraEnabled public String StatusProsess{get;set;}
         @AuraEnabled public String SoknadsId{get;set;}
         @AuraEnabled public String OpprettelseDato{get;set;}
         @AuraEnabled public String Klagetekst{get;set;}
         @AuraEnabled public String Vilkaartekst{get;set;}
         @AuraEnabled public String Vedtaksbegrunnelse{get;set;}
         @AuraEnabled public Date Vedtaksdato{get;set;}
}