public with sharing class AAREG_BasisCodesInternal {
   /*
    * wrapperclass used by AAREG_ApplicationInternalController to send data to LWC
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
}